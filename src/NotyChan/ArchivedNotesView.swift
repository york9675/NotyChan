import SwiftUI

enum ArchivedNoteSortField: String, CaseIterable, Identifiable, Codable {
    case dateArchived = "Date Archived"
    case title = "Title"

    var id: String { rawValue }
    var displayName: String {
        switch self {
        case .dateArchived: return String(localized: "Date Archived")
        case .title: return String(localized: "Title")
        }
    }
}

enum ArchivedNoteSortOrder: String, CaseIterable, Identifiable, Codable {
    case ascending = "Ascending"
    case descending = "Descending"

    var id: String { rawValue }
    var displayName: String {
        switch self {
        case .ascending: return String(localized: "Ascending")
        case .descending: return String(localized: "Descending")
        }
    }
}

struct ArchivedNoteSortOptions: Equatable, Codable {
    var field: ArchivedNoteSortField = .dateArchived
    var order: ArchivedNoteSortOrder = .descending

    private static let key = "notychan_archived_sort_options"

    func save() {
        if let encoded = try? JSONEncoder().encode(self) {
            UserDefaults.standard.set(encoded, forKey: Self.key)
        }
    }

    static func load() -> ArchivedNoteSortOptions {
        if let data = UserDefaults.standard.data(forKey: Self.key),
           let decoded = try? JSONDecoder().decode(ArchivedNoteSortOptions.self, from: data) {
            return decoded
        }
        return ArchivedNoteSortOptions()
    }
}

struct ArchivedNotesView: View {
    @EnvironmentObject var noteManager: NoteManager
    @State private var searchText = ""
    @State private var sortOptions = ArchivedNoteSortOptions.load()
    @State private var selectedNoteIds: Set<UUID> = []
    @State private var isSelecting = false
    @State private var isDeleteConfirmationPresented = false
    @State private var isUnarchiveConfirmationPresented = false
    @State private var noteToUnarchive: Note?
    @State private var noteToDelete: Note?

    private var filteredNotes: [Note] {
        let archivedNotes = noteManager.getArchivedNotes()
        if searchText.isEmpty {
            return archivedNotes
        } else {
            return archivedNotes.filter {
                $0.title.localizedCaseInsensitiveContains(searchText) ||
                firstLine(of: $0).localizedCaseInsensitiveContains(searchText)
            }
        }
    }

    private var sortedNotes: [Note] {
        let notes = filteredNotes
        switch sortOptions.field {
        case .dateArchived:
            return notes.sorted {
                guard let date1 = $0.archivedDate, let date2 = $1.archivedDate else {
                    return false
                }
                return sortOptions.order == .ascending ? date1 < date2 : date1 > date2
            }
        case .title:
            return notes.sorted {
                sortOptions.order == .ascending
                    ? $0.title.localizedCaseInsensitiveCompare($1.title) == .orderedAscending
                    : $0.title.localizedCaseInsensitiveCompare($1.title) == .orderedDescending
            }
        }
    }

    var body: some View {
        let notes = sortedNotes
        let selectionCount = selectedNoteIds.count
        let allSelected = selectionCount == notes.count && !notes.isEmpty
        let noneSelected = selectionCount == 0

        VStack(spacing: 0) {
            List(selection: isSelecting ? $selectedNoteIds : .constant([])) {
                if notes.isEmpty {
                    VStack {
                        if searchText.isEmpty {
                            Image(systemName: "archivebox")
                                .padding(.bottom, 5)
                                .font(.largeTitle)
                                .foregroundColor(.secondary)
                            Text("No archived notes")
                                .font(.headline)
                            Text("Archived notes will show up here.")
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
                } else {
                    ForEach(notes) { note in
                        Button {
                            // Show action sheet for unarchive/delete options
                            showNoteActions(for: note)
                        } label: {
                            noteRow(note: note)
                        }
                        .buttonStyle(PlainButtonStyle())
                    }
                }
            }
            .environment(\.editMode, .constant(isSelecting ? .active : .inactive))
            .searchable(text: $searchText, prompt: "Search Archived Notes")

            // Selection actions bar
            if isSelecting && !notes.isEmpty {
                Divider()
                HStack(spacing: 0) {
                    ScrollView(.horizontal, showsIndicators: false) {
                        HStack(spacing: 8) {
                            if noneSelected || !allSelected {
                                Button {
                                    selectedNoteIds = Set(notes.map(\.id))
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
                                    isUnarchiveConfirmationPresented = true
                                } label: {
                                    Label("Unarchive All", systemImage: "arrow.up.bin")
                                }
                                .buttonStyle(.bordered)
                                .tint(.blue)
                                Button(role: .destructive) {
                                    isDeleteConfirmationPresented = true
                                } label: {
                                    Label("Delete All", systemImage: "trash")
                                }
                                .buttonStyle(.bordered)
                                .tint(.red)
                            } else {
                                Button {
                                    isUnarchiveConfirmationPresented = true
                                } label: {
                                    Label("Unarchive", systemImage: "arrow.up.bin")
                                }
                                .buttonStyle(.bordered)
                                .tint(.blue)
                                Button(role: .destructive) {
                                    isDeleteConfirmationPresented = true
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
            isSelecting && !notes.isEmpty
                ? (selectedNoteIds.isEmpty
                   ? String(localized: "Select Notes")
                   : String(localized: "\(selectedNoteIds.count) Selected"))
                : String(localized: "Archived Notes")
        )
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                if !notes.isEmpty {
                    Menu {
                        Button {
                            isSelecting = true
                            selectedNoteIds.removeAll()
                        } label: {
                            Label("Select Notes", systemImage: "checkmark.circle")
                        }
                        
                        Divider()
                        
                        Menu {
                            Picker("Sort by", selection: $sortOptions.field) {
                                ForEach(ArchivedNoteSortField.allCases) { field in
                                    Text(field.displayName).tag(field)
                                }
                            }
                            .pickerStyle(.inline)
                        } label: {
                            Label("Sort by", systemImage: "arrow.up.arrow.down")
                        }
                        
                        Menu {
                            Picker("Sort order", selection: $sortOptions.order) {
                                ForEach(ArchivedNoteSortOrder.allCases) { order in
                                    Text(order.displayName).tag(order)
                                }
                            }
                            .pickerStyle(.inline)
                        } label: {
                            Label("Sort order", systemImage: "arrow.up.arrow.down.circle")
                        }
                    } label: {
                        Image(systemName: "ellipsis.circle")
                    }
                }
            }
        }
        .alert(
            noneSelected ? "Unarchive All" : "Unarchive",
            isPresented: $isUnarchiveConfirmationPresented
        ) {
            Button("Cancel", role: .cancel) { }
            Button("Unarchive") {
                let idsToUnarchive = selectedNoteIds.isEmpty ? Set(notes.map(\.id)) : selectedNoteIds
                for note in notes where idsToUnarchive.contains(note.id) {
                    noteManager.unarchiveNote(note)
                }
                isSelecting = false
                selectedNoteIds.removeAll()
            }
        } message: {
            Text("Are you sure you want to unarchive the selected notes? They will be moved back to their original locations.")
        }
        .alert(
            noneSelected ? "Delete All" : "Delete",
            isPresented: $isDeleteConfirmationPresented
        ) {
            Button("Cancel", role: .cancel) { }
            Button("Delete", role: .destructive) {
                let idsToDelete = selectedNoteIds.isEmpty ? Set(notes.map(\.id)) : selectedNoteIds
                for note in notes where idsToDelete.contains(note.id) {
                    noteManager.deleteNote(note)
                }
                isSelecting = false
                selectedNoteIds.removeAll()
            }
        } message: {
            Text("Are you sure you want to delete the selected notes? You can restore them from Recently Deleted.")
        }
        .alert("Unarchive Note", isPresented: Binding(
            get: { noteToUnarchive != nil },
            set: { if !$0 { noteToUnarchive = nil } }
        )) {
            Button("Cancel", role: .cancel) { noteToUnarchive = nil }
            Button("Unarchive") {
                if let note = noteToUnarchive {
                    noteManager.unarchiveNote(note)
                }
                noteToUnarchive = nil
            }
        } message: {
            Text("This note will be moved back to its original location.")
        }
        .alert("Delete Note", isPresented: Binding(
            get: { noteToDelete != nil },
            set: { if !$0 { noteToDelete = nil } }
        )) {
            Button("Cancel", role: .cancel) { noteToDelete = nil }
            Button("Delete", role: .destructive) {
                if let note = noteToDelete {
                    noteManager.deleteNote(note)
                }
                noteToDelete = nil
            }
        } message: {
            Text("Are you sure you want to delete this note? You can restore it from Recently Deleted.")
        }
        .onChange(of: sortOptions) {
            sortOptions.save()
        }
    }

    private func showNoteActions(for note: Note) {
        let alert = UIAlertController(
            title: displayTitle(for: note),
            message: "Choose an action for this archived note",
            preferredStyle: .actionSheet
        )
        
        alert.addAction(UIAlertAction(title: "Unarchive", style: .default) { _ in
            noteToUnarchive = note
        })
        
        alert.addAction(UIAlertAction(title: "Delete", style: .destructive) { _ in
            noteToDelete = note
        })
        
        alert.addAction(UIAlertAction(title: "Cancel", style: .cancel))
        
        if let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene,
           let window = windowScene.windows.first {
            window.rootViewController?.present(alert, animated: true)
        }
    }

    @ViewBuilder
    private func noteRow(note: Note) -> some View {
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
                Spacer()
                Image(systemName: "archivebox.fill")
                    .foregroundColor(.orange)
                    .font(.caption)
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

            if let archivedDate = note.archivedDate {
                Text("Archived: \(formattedDate(archivedDate))")
                    .font(.caption2)
                    .foregroundColor(.gray)
            }
        }
        .padding(.vertical, 2)
        .swipeActions(edge: .trailing) {
            Button(role: .destructive) {
                noteToDelete = note
            } label: {
                Label("Delete", systemImage: "trash")
            }
            .tint(.red)
            
            Button {
                noteToUnarchive = note
            } label: {
                Label("Unarchive", systemImage: "arrow.up.bin")
            }
            .tint(.blue)
        }
        .contextMenu {
            Button {
                noteToUnarchive = note
            } label: {
                Label("Unarchive Note", systemImage: "arrow.up.bin")
            }
            Button(role: .destructive) {
                noteToDelete = note
            } label: {
                Label("Delete Note", systemImage: "trash")
            }
        }
    }

    private func displayTitle(for note: Note) -> String {
        let trimmed = note.title.trimmingCharacters(in: .whitespacesAndNewlines)
        return trimmed.isEmpty ? String(localized: "Untitled Note") : note.title
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
