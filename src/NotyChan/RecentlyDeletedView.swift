import SwiftUI

struct RecentlyDeletedView: View {
    @EnvironmentObject var noteManager: NoteManager
    @State private var searchText = ""
    @State private var selectedNote: Note?
    @State private var showingDeleteConfirmation = false
    @State private var showingRestorePrompt = false

    @State private var isSelecting = false
    @State private var selectedNoteIds: Set<UUID> = []
    @State private var isDeleteAllConfirmationPresented = false
    @State private var isRestoreAllConfirmationPresented = false

    @State private var showingEmptyConfirmation = false
    @State private var showingRestoreAllConfirmation = false

    var body: some View {
        let deletedNotes = filteredNotes
        let selectionCount = selectedNoteIds.count
        let allSelected = selectionCount == deletedNotes.count && !deletedNotes.isEmpty
        let noneSelected = selectionCount == 0

        VStack(spacing: 0) {
            List {
                if deletedNotes.isEmpty {
                    Section {
                        VStack {
                            if searchText.isEmpty {
                                Image(systemName: "trash")
                                    .padding(.bottom, 5)
                                    .font(.largeTitle)
                                    .foregroundColor(.secondary)
                                Text("No deleted notes")
                                    .font(.headline)
                                Text("Notes you delete will appear here for 30 days.")
                                    .font(.subheadline)
                                    .foregroundColor(.secondary)
                                    .multilineTextAlignment(.center)
                            } else {
                                Image(systemName: "magnifyingglass")
                                    .padding(.bottom, 5)
                                    .font(.largeTitle)
                                    .foregroundColor(.secondary)
                                Text("No search results")
                                    .font(.headline)
                                Text("Try a different search term.")
                                    .font(.subheadline)
                                    .foregroundColor(.secondary)
                                    .multilineTextAlignment(.center)
                            }
                        }
                        .frame(maxWidth: .infinity)
                        .padding()
                    }
                } else {
                    Section(header: Text("Notes you delete will appear here for 30 days.")) {
                        ForEach(deletedNotes) { note in
                            noteRow(note: note)
                        }
                    }
                }
            }
            .searchable(text: $searchText, prompt: "Search Deleted Notes")
            // Selection action bar
            if isSelecting && !deletedNotes.isEmpty {
                Divider()
                HStack(spacing: 0) {
                    ScrollView(.horizontal, showsIndicators: false) {
                        HStack(spacing: 8) {
                            if noneSelected || !allSelected {
                                Button {
                                    selectedNoteIds = Set(deletedNotes.map(\.id))
                                } label: {
                                    Label("Select All", systemImage: "checkmark.circle")
                                }
                                .buttonStyle(.bordered)
                            }
                            if allSelected {
                                Button {
                                    selectedNoteIds.removeAll()
                                } label: {
                                    Label("Deselect All", systemImage: "circle")
                                }
                                .buttonStyle(.bordered)
                            }
                            if noneSelected {
                                Button {
                                    isRestoreAllConfirmationPresented = true
                                } label: {
                                    Label("Restore All", systemImage: "arrow.uturn.left")
                                }
                                .buttonStyle(.bordered)
                                .tint(.blue)
                                Button(role: .destructive) {
                                    showingEmptyConfirmation = true
                                } label: {
                                    Label("Empty Trash", systemImage: "trash")
                                }
                                .buttonStyle(.bordered)
                                .tint(.red)
                            } else {
                                Button {
                                    isRestoreAllConfirmationPresented = true
                                } label: {
                                    Label("Restore", systemImage: "arrow.uturn.left")
                                }
                                .buttonStyle(.bordered)
                                .tint(.blue)
                                Button(role: .destructive) {
                                    isDeleteAllConfirmationPresented = true
                                } label: {
                                    Label("Delete", systemImage: "trash")
                                }
                                .buttonStyle(.bordered)
                                .tint(.red)
                            }
                        }
                        .padding(.vertical, 8)
                        .padding(.leading)
                    }
                    Button("Done") {
                        isSelecting = false
                        selectedNoteIds.removeAll()
                    }
                    .bold()
                    .padding(.horizontal)
                }
                .background(.regularMaterial)
            }
        }
        .navigationTitle(
            isSelecting && !deletedNotes.isEmpty
                ? (selectedNoteIds.isEmpty
                    ? String(localized: "Select Notes")
                   : String(localized:"\(selectedNoteIds.count) Selected"))
            : String(localized: "Recently Deleted")
        )
        .toolbar {
            if !deletedNotes.isEmpty {
                ToolbarItem(placement: .topBarTrailing) {
                    Menu {
                        Button {
                            isSelecting = true
                            selectedNoteIds.removeAll()
                        } label: {
                            Label("Select", systemImage: "checkmark.circle")
                        }
                        .tint(.primary)
                        
                        Divider()
                        
                        Button {
                            showingRestoreAllConfirmation = true
                        } label: {
                            Label("Restore All", systemImage: "arrow.uturn.left")
                        }
                        .tint(.primary)
                        
                        Button(role: .destructive) {
                            showingEmptyConfirmation = true
                        } label: {
                            Label("Empty Trash", systemImage: "trash")
                                .foregroundColor(.red)
                        }
                        .tint(.red)
                    } label: {
                        Image(systemName: "ellipsis.circle")
                    }
                }
            }
        }
        // Alert for deleting selected/all notes
        .alert("Delete", isPresented: $isDeleteAllConfirmationPresented
        ) {
            Button("Cancel", role: .cancel) { }
            Button("Delete", role: .destructive) {
                let idsToDelete = selectedNoteIds.isEmpty ? Set(deletedNotes.map(\.id)) : selectedNoteIds
                for note in deletedNotes where idsToDelete.contains(note.id) {
                    noteManager.permanentlyDeleteNote(note)
                }
                isSelecting = false
                selectedNoteIds.removeAll()
            }
        } message: {
            Text("These notes and images inside will be permanently deleted. This action cannot be undone.")
        }
        // Alert for restoring selected/all notes
        .alert(
            selectedNoteIds.isEmpty ? "Restore All" : "Restore",
            isPresented: $isRestoreAllConfirmationPresented
        ) {
            Button("Cancel", role: .cancel) { }
            Button("Restore") {
                let idsToRestore = selectedNoteIds.isEmpty ? Set(deletedNotes.map(\.id)) : selectedNoteIds
                for note in deletedNotes where idsToRestore.contains(note.id) {
                    noteManager.restoreNote(note)
                }
                isSelecting = false
                selectedNoteIds.removeAll()
            }
        } message: {
            Text("Are you sure you want to restore these notes?")
        }
        // Alert for "Restore All" from menu
        .alert("Restore All", isPresented: $showingRestoreAllConfirmation) {
            Button("Cancel", role: .cancel) { }
            Button("Restore All") {
                for note in deletedNotes {
                    noteManager.restoreNote(note)
                }
            }
        } message: {
            Text("Are you sure you want to restore all recently deleted notes?")
        }
        .alert("Permanently Delete", isPresented: $showingDeleteConfirmation) {
            Button("Cancel", role: .cancel) { }
            Button("Delete", role: .destructive) {
                if let note = selectedNote {
                    noteManager.permanentlyDeleteNote(note)
                }
            }
        } message: {
            Text("This note and images inside will be permanently deleted. This action cannot be undone.")
        }
        .alert("Empty Trash", isPresented: $showingEmptyConfirmation) {
            Button("Cancel", role: .cancel) { }
            Button("Empty", role: .destructive) {
                for note in noteManager.getRecentlyDeletedNotes() {
                    noteManager.permanentlyDeleteNote(note)
                }
            }
        } message: {
            Text("All notes and images inside it in the trash will be permanently deleted. This action cannot be undone.")
        }
        .alert("Restore or Delete?", isPresented: $showingRestorePrompt) {
            Button("Cancel", role: .cancel) {}
            Button("Restore") {
                if let note = selectedNote {
                    noteManager.restoreNote(note)
                }
            }
            Button("Delete", role: .destructive) {
                if let note = selectedNote {
                    noteManager.permanentlyDeleteNote(note)
                }
            }
        } message: {
            Text("Would you like to restore this note or permanently delete it?")
        }
    }

    @ViewBuilder
    private func noteRow(note: Note) -> some View {
        if isSelecting {
            HStack(alignment: .top, spacing: 12) {
                Image(systemName: selectedNoteIds.contains(note.id) ? "checkmark.circle.fill" : "circle")
                    .font(.title2)
                    .foregroundColor(selectedNoteIds.contains(note.id) ? .accentColor : .secondary)
                    .contentShape(Rectangle())
                    .onTapGesture {
                        toggleSelection(for: note)
                    }
                    .padding(.top, 2)

                VStack(alignment: .leading, spacing: 2) {
                    HStack {
                        Text(displayTitle(for: note))
                            .font(.headline)
                            .lineLimit(1)
                        if !note.images.isEmpty {
                            Image(systemName: "photo")
                                .foregroundColor(.gray)
                                .padding(.leading, 2)
                        }
                        if note.isLocked {
                            Image(systemName: "lock.fill")
                                .foregroundColor(.gray)
                                .padding(.leading, 2)
                        }
                    }
                    if note.isLocked {
                        Text("This note is locked")
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                            .italic()
                            .lineLimit(1)
                    } else {
                        Text(firstLine(of: note))
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                            .lineLimit(1)
                    }

                    if note.folderId != nil {
                        HStack(spacing: 3) {
                            Image(systemName: "folder")
                                .font(.caption)
                            Text(noteManager.getFolderName(for: note.folderId))
                        }
                        .font(.caption)
                        .padding(.horizontal, 6)
                        .padding(.vertical, 2)
                        .background(Color.gray.opacity(0.2))
                        .cornerRadius(4)
                    }

                    if let deletedDate = note.deletedDate {
                        Text("Deleted: \(formattedDate(deletedDate))")
                            .font(.caption2)
                            .foregroundColor(.gray)
                    }
                }
            }
            .padding(.vertical, 2)
            .contentShape(Rectangle())
            .onTapGesture {
                toggleSelection(for: note)
            }
        } else {
            VStack(alignment: .leading, spacing: 2) {
                HStack {
                    Text(displayTitle(for: note))
                        .font(.headline)
                        .lineLimit(1)
                    if !note.images.isEmpty {
                        Image(systemName: "photo")
                            .foregroundColor(.gray)
                            .padding(.leading, 2)
                    }
                    if note.isLocked {
                        Image(systemName: "lock.fill")
                            .foregroundColor(.gray)
                            .padding(.leading, 2)
                    }
                }
                if note.isLocked {
                    Text("This note is locked")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                        .italic()
                        .lineLimit(1)
                } else {
                    Text(firstLine(of: note))
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                        .lineLimit(1)
                }

                if note.folderId != nil {
                    HStack(spacing: 3) {
                        Image(systemName: "folder")
                            .font(.caption)
                        Text(noteManager.getFolderName(for: note.folderId))
                    }
                    .font(.caption)
                    .padding(.horizontal, 6)
                    .padding(.vertical, 2)
                    .background(Color.gray.opacity(0.2))
                    .cornerRadius(4)
                }

                if let deletedDate = note.deletedDate {
                    Text("Deleted: \(formattedDate(deletedDate))")
                        .font(.caption2)
                        .foregroundColor(.gray)
                }
            }
            .padding(.vertical, 2)
            .onTapGesture {
                selectedNote = note
                showingRestorePrompt = true
            }
            .swipeActions(edge: .trailing) {
                Button(role: .destructive) {
                    selectedNote = note
                    showingDeleteConfirmation = true
                } label: {
                    Label("Delete", systemImage: "trash")
                }
                .tint(.red)

                Button {
                    noteManager.restoreNote(note)
                } label: {
                    Label("Restore", systemImage: "arrow.uturn.left")
                }
                .tint(.blue)
            }
            .contextMenu {
                Button {
                    noteManager.restoreNote(note)
                } label: {
                    Label("Restore", systemImage: "arrow.uturn.left")
                }
                .tint(.primary)
                
                Button(role: .destructive) {
                    selectedNote = note
                    showingDeleteConfirmation = true
                } label: {
                    Label("Delete", systemImage: "trash")
                }
                .tint(.red)
            }
        }
    }

    private func toggleSelection(for note: Note) {
        if selectedNoteIds.contains(note.id) {
            selectedNoteIds.remove(note.id)
        } else {
            selectedNoteIds.insert(note.id)
        }
    }

    private func displayTitle(for note: Note) -> String {
        let trimmed = note.title.trimmingCharacters(in: .whitespacesAndNewlines)
        return trimmed.isEmpty ? String(localized: "Untitled Note") : note.title
    }

    private var filteredNotes: [Note] {
        let notes = noteManager.getRecentlyDeletedNotes()
        if searchText.isEmpty {
            return notes
        } else {
            return notes.filter {
                $0.title.localizedCaseInsensitiveContains(searchText) ||
                firstLine(of: $0).localizedCaseInsensitiveContains(searchText)
            }
        }
    }

    private func firstLine(of note: Note) -> String {
        if let attributedString = try? NSAttributedString(data: note.rtfData, options: [.documentType: NSAttributedString.DocumentType.rtf], documentAttributes: nil) {
            let plainText = attributedString.string
            let lines = plainText.components(separatedBy: .newlines)
            if let firstRealLine = lines.first(where: { !$0.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty && $0 != note.title }) {
                return firstRealLine
            }
        }
        return String(localized: "No additional text")
    }

    private func formattedDate(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        formatter.timeStyle = .short
        return formatter.string(from: date)
    }
}
