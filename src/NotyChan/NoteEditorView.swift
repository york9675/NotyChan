import SwiftUI
import RichTextKit

struct NoteEditorView: View {
    @Environment(\.dismiss) var dismiss
    @EnvironmentObject var noteManager: NoteManager
    @State private var title: String
    @State private var richText: NSAttributedString
    @StateObject private var context = RichTextContext()
    @State private var isMoveToFolderPresented = false
    @State private var isShareSheetPresented = false
    @State private var isDeleteConfirmationPresented = false

    @State private var workingNote: Note
    @State private var saveTask: Task<Void, Never>?
    @State private var alreadyDeleted: Bool = false

    @State private var isUnlocked = false
    @State private var isAuthenticating = false
    @State private var authFailed = false

    @State private var hasChanges = false
    
    @State private var showGallery = false

    let note: Note
    let onUpdate: (Note) -> Void

    init(note: Note, onUpdate: @escaping (Note) -> Void) {
        self.note = note
        _title = State(initialValue: note.title)
        let attributedText = try? NSAttributedString(
            data: note.rtfData,
            options: [.documentType: NSAttributedString.DocumentType.rtf],
            documentAttributes: nil
        )
        _richText = State(initialValue: attributedText ?? NSAttributedString(string: ""))
        _workingNote = State(initialValue: note)
        self.onUpdate = onUpdate
    }

    var body: some View {
        Group {
            if workingNote.isLocked && !isUnlocked {
                VStack(spacing: 24) {
                    Image(systemName: "lock.fill")
                        .font(.system(size: 48))
                        .foregroundColor(.accentColor)
                    Text("This note is locked")
                        .font(.title2)
                        .bold()
                    if authFailed {
                        Text("Authentication failed. Try again.")
                            .foregroundColor(.red)
                    }
                    Button {
                        Task {
                            isAuthenticating = true
                            let success = await BiometricAuth.authenticate(reason: String(localized: "Unlock this note"))
                            isAuthenticating = false
                            if success {
                                noteManager.unlockNote(workingNote)
                                syncLocalWithManager()
                                isUnlocked = true
                                authFailed = false
                            } else {
                                authFailed = true
                            }
                        }
                    } label: {
                        Label("Unlock this note", systemImage: "lock.open")
                            .font(.headline)
                    }
                    .disabled(isAuthenticating)
                }
                .padding()
            } else {
                VStack(spacing: 0) {
                    // Title Field
                    TextField("Title", text: $title)
                        .font(.title)
                        .bold()
                        .padding(.horizontal)
                        .zIndex(1)
                        .onChange(of: title) { _, newValue in
                            if newValue != workingNote.title {
                                hasChanges = true
                                saveDebounced()
                            }
                        }

                    // Last edited
                    Text("Last edited: \(formattedDate(workingNote.lastEdited))")
                        .font(.footnote)
                        .foregroundColor(.secondary)
                        .padding(.horizontal)
                        .padding(.top, 4)
                        .padding(.bottom, 4)
                        .zIndex(1)

                    // Platform specific formatting toolbar
                    #if os(macOS)
                    RichTextFormat.Toolbar(context: context)
                    #endif

                    // Rich Text Editor from RichTextKit
                    RichTextEditor(
                        text: $richText,
                        context: context
                    ) {
                        $0.textContentInset = CGSize(width: 20, height: 20)
                    }
                    .frame(minHeight: 200, maxHeight: .infinity)
                    .zIndex(0)
                    .onChange(of: richText) { _, newValue in
                        if !richTextEqual(newValue, workingNote.rtfData) {
                            hasChanges = true
                            saveDebounced()
                        }
                    }

                    // iOS Keyboard formatting toolbar at bottom
                    #if os(iOS)
                    RichTextKeyboardToolbar(
                        context: context,
                        leadingButtons: { $0 },
                        trailingButtons: { $0 },
                        formatSheet: { $0 }
                    )
                    #endif
                }
                .navigationBarTitleDisplayMode(.inline)
                .toolbar {
                    // Main note menu (move, pin, share, lock, delete)
                    ToolbarItem(placement: .topBarTrailing) {
                        HStack {
                            Button {
                                showGallery = true
                            } label: {
                                Label("Gallery", systemImage: "photo.on.rectangle.angled")
                            }
                            
                            Button {
                                isShareSheetPresented = true
                            } label: {
                                Label("Share Note", systemImage: "square.and.arrow.up")
                            }
                            
                            Menu {
                                Button {
                                    isMoveToFolderPresented = true
                                } label: {
                                    Label("Move", systemImage: "folder")
                                }
                                
                                Button {
                                    togglePin()
                                } label: {
                                    Label(workingNote.isPinned ? "Unpin Note" : "Pin Note",
                                          systemImage: workingNote.isPinned ? "pin.slash" : "pin")
                                }
                                
                                Divider()
                                
                                Button {
                                    Task {
                                        let authenticated = await BiometricAuth.authenticate(reason: String(localized:"Lock this note"))
                                        if authenticated {
                                            noteManager.lockNote(workingNote)
                                            isUnlocked = false
                                            syncLocalWithManager()
                                        }
                                    }
                                } label: {
                                    Label("Lock Note", systemImage: "lock")
                                }
                                
                                Divider()
                                
                                Button(role: .destructive) {
                                    isDeleteConfirmationPresented = true
                                } label: {
                                    Label("Delete Note", systemImage: "trash")
                                        .foregroundColor(.red)
                                }
                            } label: {
                                Image(systemName: "ellipsis.circle")
                            }
                        }
                    }
                }
                .sheet(isPresented: $isMoveToFolderPresented) {
                    MoveToFolderView(note: workingNote)
                        .environmentObject(noteManager)
                        .onDisappear {
                            if let updated = noteManager.notes.first(where: { $0.id == workingNote.id }) {
                                workingNote = updated
                            }
                        }
                }
                .sheet(isPresented: $isShareSheetPresented) {
                    ActivityView(activityItems: [titleAndTextToShare()])
                }
                .sheet(isPresented: $showGallery) {
                    GalleryView(note: workingNote)
                        .environmentObject(noteManager)
                }
                .alert("Delete Note", isPresented: $isDeleteConfirmationPresented) {
                    Button("Cancel", role: .cancel) { }
                    Button("Delete", role: .destructive) {
                        saveTask?.cancel()
                        noteManager.deleteNote(workingNote)
                        alreadyDeleted = true
                        dismiss()
                    }
                } message: {
                    Text("Are you sure you want to delete this note? You can restore it from Recently Deleted.")
                }
                .onAppear {
                    syncLocalWithManager()
                    if workingNote.isLocked {
                        isUnlocked = false
                    }
                    hasChanges = false
                }
                .onDisappear {
                    saveTask?.cancel()
                    if !alreadyDeleted && hasChanges {
                        saveImmediately()
                        hasChanges = false
                    }
                }
                .focusedValue(\.richTextContext, context)
                .toolbarRole(.automatic)
                .richTextFormatSheetConfig(.init(colorPickers: [.foreground, .background]))
                .richTextFormatSidebarConfig(
                    .init(
                        colorPickers: [.foreground, .background],
                        fontPicker: isMac
                    )
                )
                .richTextFormatToolbarConfig(.init(colorPickers: []))
            }
        }
    }

    // MARK: - Actions

    private func saveDebounced() {
        saveTask?.cancel()
        guard hasChanges else { return }
        let currentTitle = title
        let currentRichText = richText
        saveTask = Task { @MainActor in
            try? await Task.sleep(nanoseconds: 300_000_000)
            if hasChanges { // Only save if there are changes
                saveImmediately(title: currentTitle, richText: currentRichText)
                hasChanges = false
            }
        }
    }

    private func saveImmediately(title: String? = nil, richText: NSAttributedString? = nil) {
        var updated = workingNote
        let newTitle = title ?? self.title
        let newRichText = richText ?? self.richText
        let rtfData = try? newRichText.data(
            from: NSRange(location: 0, length: newRichText.length),
            documentAttributes: [.documentType: NSAttributedString.DocumentType.rtf]
        )

        // Only update and set lastEdited if content or title actually changed
        let contentChanged = updated.title != newTitle ||
            !richTextEqual(newRichText, updated.rtfData)

        if contentChanged {
            updated.title = newTitle
            updated.rtfData = rtfData ?? Data()
            updated.lastEdited = Date()
            workingNote = updated
            onUpdate(updated)
            noteManager.updateNote(updated)
        }
    }

    private func togglePin() {
        noteManager.togglePin(for: workingNote)
        if let updated = noteManager.notes.first(where: { $0.id == workingNote.id }) {
            workingNote = updated
        }
    }

    private func syncLocalWithManager() {
        if let realNote = noteManager.notes.first(where: { $0.id == note.id }) {
            workingNote = realNote
            title = realNote.title
            if let attributed = try? NSAttributedString(
                data: realNote.rtfData,
                options: [.documentType: NSAttributedString.DocumentType.rtf],
                documentAttributes: nil
            ) {
                richText = attributed
            } else {
                richText = NSAttributedString(string: "")
            }
        }
    }

    private func formattedDate(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        formatter.timeStyle = .short
        return formatter.string(from: date)
    }

    private func titleAndTextToShare() -> String {
        var text = title
        let plainText = richText.string.trimmingCharacters(in: .whitespacesAndNewlines)
        if !plainText.isEmpty {
            text += "\n\n" + plainText
        }
        return text
    }

    private func richTextEqual(_ text: NSAttributedString, _ data: Data) -> Bool {
        guard let other = try? NSAttributedString(
            data: data,
            options: [.documentType: NSAttributedString.DocumentType.rtf],
            documentAttributes: nil
        ) else {
            return false
        }
        return text.isEqual(to: other)
    }

    private var isMac: Bool {
        #if os(macOS)
        return true
        #else
        return false
        #endif
    }
}

// MARK: - ActivityView for Sharing

import UIKit

struct ActivityView: UIViewControllerRepresentable {
    let activityItems: [Any]
    let applicationActivities: [UIActivity]? = nil

    func makeUIViewController(context: Context) -> UIActivityViewController {
        UIActivityViewController(
            activityItems: activityItems,
            applicationActivities: applicationActivities
        )
    }

    func updateUIViewController(_ uiViewController: UIActivityViewController, context: Context) {}
}

private extension NSAttributedString {
    func isEqual(to other: NSAttributedString) -> Bool {
        return self.string == other.string && self.isEqual(other)
    }
}
