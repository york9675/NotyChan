import SwiftUI

enum NoteSortField: String, CaseIterable, Identifiable, Codable {
    case lastEdited = "Last Edited"
    case title = "Title"

    var id: String { rawValue }
    var displayName: String {
        switch self {
        case .lastEdited: return String(localized: "Last Edited Date")
        case .title: return String(localized: "Title")
        }
    }
}

enum NoteSortOrder: String, CaseIterable, Identifiable, Codable {
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

struct NoteSortOptions: Equatable, Codable {
    var field: NoteSortField = .lastEdited
    var order: NoteSortOrder = .descending
    var groupByDate: Bool = true

    private static let key = "notychan_sort_options"

    func save() {
        if let encoded = try? JSONEncoder().encode(self) {
            UserDefaults.standard.set(encoded, forKey: Self.key)
        }
    }

    static func load() -> NoteSortOptions {
        if let data = UserDefaults.standard.data(forKey: Self.key),
           let decoded = try? JSONDecoder().decode(NoteSortOptions.self, from: data) {
            return decoded
        }
        return NoteSortOptions()
    }
}

struct NoteListView: View {
    @EnvironmentObject var noteManager: NoteManager
    @State private var searchText = ""
    var folderFilter: UUID?

    @State private var noteToMove: Note?
    @State private var sortOptions = NoteSortOptions.load()
    @State private var selectedNoteId: UUID?

    @State private var isSelecting = false
    @State private var selectedNoteIds: Set<UUID> = []
    @State private var isMultiMoveSheetPresented = false
    @State private var isDeleteConfirmationPresented = false
    @State private var isSingleDeleteConfirmationPresented = false
    @State private var isArchiveConfirmationPresented = false

    // Sharing state
    @State private var noteToShare: Note? = nil
    @State private var isShareSheetPresented: Bool = false
    @State private var isShareTypeDialogPresented: Bool = false
    @State private var shareItems: [Any] = []
    @State private var tempPDFURL: URL? = nil

    @State private var isRenamingFolder = false
    @State private var renameFolderName = ""
    
    @State private var showGallery = false

    var notesInThisFolderWithImages: [Note] {
        let notes = folderFilter == nil ? noteManager.getAllNotes() : noteManager.getNotes(inFolder: folderFilter)
        return notes.filter { !$0.images.isEmpty }
    }
    
    var folder: Folder? {
        folderFilter.flatMap { id in
            noteManager.folders.first(where: { $0.id == id })
        }
    }

    var body: some View {
        let notes = filteredNotes
        let sortedNotes = sortNotes(notes)
        let pinnedNotes = sortedNotes.filter { $0.isPinned }
        let unpinnedNotes = sortedNotes.filter { !$0.isPinned }
        let selectionCount = selectedNoteIds.count
        let allSelected = selectionCount == notes.count && !notes.isEmpty
        let noneSelected = selectionCount == 0

        VStack(spacing: 0) {
            List(selection: isSelecting ? $selectedNoteIds : .constant([])) {
                if notes.isEmpty {
                    Section {
                        VStack {
                            if searchText.isEmpty {
                                Image(systemName: "square.and.pencil")
                                    .padding(.bottom, 5)
                                    .font(.largeTitle)
                                    .foregroundColor(.secondary)
                                Text("No notes yet")
                                    .font(.headline)
                                Text("Tap the pencil icon above to add your first note.")
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
                    if !pinnedNotes.isEmpty {
                        Section(header: Label("Pinned", systemImage: "pin.fill")) {
                            ForEach(pinnedNotes) { note in
                                noteRow(note: note)
                            }
                        }
                    }
                    if sortOptions.groupByDate {
                        ForEach(groupedNotesByDate(unpinnedNotes), id: \.0) { (section, sectionNotes) in
                            Section(header: Text(section)) {
                                ForEach(sectionNotes) { note in
                                    noteRow(note: note)
                                }
                            }
                        }
                    } else {
                        ForEach(unpinnedNotes) { note in
                            noteRow(note: note)
                        }
                    }
                }
            }
            .environment(\.editMode, .constant(isSelecting ? .active : .inactive))
            .searchable(text: $searchText, prompt: "Search Notes")
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
                                    isMultiMoveSheetPresented = true
                                } label: {
                                    Label("Move All", systemImage: "folder")
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
                                    isMultiMoveSheetPresented = true
                                } label: {
                                    Label("Move", systemImage: "folder")
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
                   : String(localized:"\(selectedNoteIds.count) Selected"))
                : (folderFilter == nil ? String(localized: "All Notes") : noteManager.getFolderName(for: folderFilter))
        )
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                HStack {
                    if folder != nil || !notes.isEmpty {
                        Menu {
                            if let folder = folder {
                                Button {
                                    renameFolderName = folder.name
                                    isRenamingFolder = true
                                } label: {
                                    Label("Rename Folder", systemImage: "pencil")
                                }
                            }
                            
                            if !notes.isEmpty {
                                Button {
                                    isSelecting = true
                                    selectedNoteIds.removeAll()
                                } label: {
                                    Label("Select Notes", systemImage: "checkmark.circle")
                                }
                                
                                Divider()
                                
                                Menu {
                                    Picker("Sort by", selection: $sortOptions.field) {
                                        ForEach(NoteSortField.allCases) { field in
                                            Text(field.displayName).tag(field)
                                        }
                                    }
                                    .pickerStyle(.inline)
                                } label: {
                                    Label("Sort by", systemImage: "arrow.up.arrow.down")
                                }
                                
                                Menu {
                                    Picker("Sort order", selection: $sortOptions.order) {
                                        ForEach(NoteSortOrder.allCases) { order in
                                            Text(order.displayName).tag(order)
                                        }
                                    }
                                    .pickerStyle(.inline)
                                } label: {
                                    Label("Sort order", systemImage: "arrow.up.arrow.down.circle")
                                }
                                
                                Divider()
                                
                                Toggle(isOn: $sortOptions.groupByDate) {
                                    Label("Group by Date", systemImage: "calendar")
                                }
                            }
                        } label: {
                            Image(systemName: "ellipsis.circle")
                        }
                    }
                    
                    Button {
                        showGallery = true
                    } label: {
                        Label("Gallery", systemImage: "photo.on.rectangle.angled")
                    }
                    
                    Button(action: {
                        let _ = noteManager.addNote(inFolder: folderFilter)
                    }) {
                        Image(systemName: "square.and.pencil")
                    }
                }
            }
        }
        .sheet(item: $noteToMove) { note in
            MoveToFolderView(note: note)
        }
        .sheet(isPresented: $isMultiMoveSheetPresented) {
            MultiMoveToFolderView(
                noteIds: selectedNoteIds.isEmpty ? notes.map(\.id) : Array(selectedNoteIds),
                onMove: { folderId in
                    let idsToMove = selectedNoteIds.isEmpty ? Set(notes.map(\.id)) : selectedNoteIds
                    for note in notes where idsToMove.contains(note.id) {
                        noteManager.moveNote(note, toFolder: folderId)
                    }
                    isMultiMoveSheetPresented = false
                    isSelecting = false
                    selectedNoteIds.removeAll()
                }
            )
            .environmentObject(noteManager)
        }
        // Replace the old sheet(item: $noteToShare) with this generic share sheet
        .sheet(isPresented: $isShareSheetPresented, onDismiss: {
            // Cleanup temp PDF file if created
            if let url = tempPDFURL {
                try? FileManager.default.removeItem(at: url)
            }
            tempPDFURL = nil
            shareItems = []
            noteToShare = nil
        }) {
            ActivityView(activityItems: shareItems)
        }
        .sheet(isPresented: $showGallery) {
            NavigationView {
                GalleryOverviewView(
                    notes: notesInThisFolderWithImages,
                    noteManager: noteManager,
                    folders: noteManager.folders,
                    showFolderName: folderFilter == nil
                )
                .navigationTitle(folderFilter == nil ? "All Images" : "Folder Images")
                .toolbar {
                    ToolbarItem(placement: .cancellationAction) {
                        Button("Close") { showGallery = false }
                    }
                }
            }
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
        .alert("Rename Folder", isPresented: $isRenamingFolder) {
            TextField("Folder Name", text: $renameFolderName)
            Button("Cancel", role: .cancel) { isRenamingFolder = false }
            Button("Rename") {
                if let folder = folder, !renameFolderName.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
                    var updated = folder
                    updated.name = renameFolderName
                    noteManager.updateFolder(updated)
                }
                isRenamingFolder = false
            }
        }
        // Dialog to choose share type when sharing from list
        .confirmationDialog("Share Note", isPresented: $isShareTypeDialogPresented, presenting: noteToShare) { note in
            Button("Share as Plain Text") {
                shareItems = [titleAndTextToShare(note: note)]
                isShareSheetPresented = true
            }
            Button("Export as PDF") {
                #if os(iOS)
                if let url = exportNoteAsPDF(note: note) {
                    tempPDFURL = url
                    shareItems = [url]
                    isShareSheetPresented = true
                }
                #endif
            }
        } message: { _ in
            Text("Choose how you want to share this note.")
        }
        .onChange(of: sortOptions) {
            sortOptions.save()
        }
    }

    @ViewBuilder
    private func noteRow(note: Note) -> some View {
        NavigationLink(destination: NoteEditorView(note: note, onUpdate: { updatedNote in
            noteManager.updateNote(updatedNote)
        })) {
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

                if folderFilter == nil && note.folderId != nil {
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

                Text("Last edited: \(formattedDate(note.lastEdited))")
                    .font(.caption2)
                    .foregroundColor(.gray)
            }
            .padding(.vertical, 2)
        }
        .swipeActions(edge: .leading) {
            Button {
                noteManager.togglePin(for: note)
            } label: {
                Label(note.isPinned ? "Unpin" : "Pin", systemImage: note.isPinned ? "pin.slash" : "pin")
            }
            .tint(.yellow)
        }
        .swipeActions(edge: .trailing) {
            Button {
                isSingleDeleteConfirmationPresented = true
            } label: {
                Label("Delete", systemImage: "trash")
            }
            .tint(.red)
            Button {
                noteToMove = note
            } label: {
                Label("Move", systemImage: "folder")
            }
            .tint(.purple)
            Button {
                isArchiveConfirmationPresented = true
            } label: {
                Label("Archive", systemImage: "archivebox")
            }
            .tint(.orange)
            if (!note.isLocked) {
                Button {
                    // Ask for share type on tap
                    noteToShare = note
                    isShareTypeDialogPresented = true
                } label: {
                    Label("Share", systemImage: "square.and.arrow.up")
                }
                .tint(.blue)
            }
        }
        .contextMenu {
            Button {
                noteManager.togglePin(for: note)
            } label: {
                Label(note.isPinned ? "Unpin Note" : "Pin Note", systemImage: note.isPinned ? "pin.slash" : "pin")
            }
            Button {
                noteToMove = note
            } label: {
                Label("Move", systemImage: "folder")
            }
            Button {
                isArchiveConfirmationPresented = true
            } label: {
                Label("Archive Note", systemImage: "archivebox")
            }
            Button {
                // Ask for share type from context menu, too
                noteToShare = note
                isShareTypeDialogPresented = true
            } label: {
                Label("Share Note", systemImage: "square.and.arrow.up")
            }
            .disabled(note.isLocked)
            Button(role: .destructive) {
                isSingleDeleteConfirmationPresented = true
            } label: {
                Label("Delete", systemImage: "trash")
            }
        }
        .alert("Delete Note", isPresented: $isSingleDeleteConfirmationPresented) {
            Button("Cancel", role: .cancel) { }
            Button("Delete", role: .destructive) {
                noteManager.deleteNote(note)
            }
        } message: {
            Text("Are you sure you want to delete this note? You can restore it from Recently Deleted.")
        }
        .alert("Archive Note", isPresented: $isArchiveConfirmationPresented) {
            Button("Cancel", role: .cancel) { }
            Button("Archive", role: .destructive) {
                noteManager.archiveNote(note)
            }
        } message: {
            Text("Are you sure you want to archive this notes? You can access it from settings.")
        }
    }

    private func displayTitle(for note: Note) -> String {
        let trimmed = note.title.trimmingCharacters(in: .whitespacesAndNewlines)
        return trimmed.isEmpty ? String(localized: "Untitled Note") : note.title
    }

    private var filteredNotes: [Note] {
        let notes = folderFilter == nil ?
            noteManager.getAllNotes(respectFolderLock: true) :
            noteManager.getNotes(inFolder: folderFilter, respectFolderLock: false)

        if searchText.isEmpty {
            return notes
        } else {
            return notes.filter {
                $0.title.localizedCaseInsensitiveContains(searchText) ||
                firstLine(of: $0).localizedCaseInsensitiveContains(searchText)
            }
        }
    }

    private func sortNotes(_ notes: [Note]) -> [Note] {
        let sorted: [Note]
        switch sortOptions.field {
        case .lastEdited:
            sorted = notes.sorted {
                sortOptions.order == .ascending
                    ? $0.lastEdited < $1.lastEdited
                    : $0.lastEdited > $1.lastEdited
            }
        case .title:
            sorted = notes.sorted {
                sortOptions.order == .ascending
                    ? $0.title.localizedCaseInsensitiveCompare($1.title) == .orderedAscending
                    : $0.title.localizedCaseInsensitiveCompare($1.title) == .orderedDescending
            }
        }
        return sorted
    }

    // Group notes
    private func groupedNotesByDate(_ notes: [Note]) -> [(String, [Note])] {
        let calendar = Calendar.current
        let grouped = Dictionary(grouping: notes) { note -> String in
            if calendar.isDateInToday(note.lastEdited) {
                return String(localized: "Today")
            } else if calendar.isDateInYesterday(note.lastEdited) {
                return String(localized: "Yesterday")
            } else {
                let formatter = DateFormatter()
                formatter.dateStyle = .medium
                formatter.timeStyle = .none
                return formatter.string(from: note.lastEdited)
            }
        }
        let sorted = grouped.sorted {
            guard let d1 = grouped[$0.key]?.first?.lastEdited,
                  let d2 = grouped[$1.key]?.first?.lastEdited else { return false }
            return sortOptions.order == .ascending ? d1 < d2 : d1 > d2
        }
        // Also sort notes in each section
        return sorted.map { (key, value) in
            (key, sortNotes(value))
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

    private func titleAndTextToShare(note: Note) -> String {
        var text = note.title
        if let attributedString = try? NSAttributedString(
            data: note.rtfData,
            options: [.documentType: NSAttributedString.DocumentType.rtf],
            documentAttributes: nil
        ) {
            let plainText = attributedString.string.trimmingCharacters(in: .whitespacesAndNewlines)
            if !plainText.isEmpty {
                text += "\n\n" + plainText
            }
        }
        return text
    }

    // Export a single note as a paginated PDF preserving formatting.
    private func exportNoteAsPDF(note: Note) -> URL? {
        guard let attributed = try? NSAttributedString(
            data: note.rtfData,
            options: [.documentType: NSAttributedString.DocumentType.rtf],
            documentAttributes: nil
        ) else {
            return nil
        }

        let range = NSRange(location: 0, length: attributed.length)
        guard let htmlData = try? attributed.data(
            from: range,
            documentAttributes: [.documentType: NSAttributedString.DocumentType.html]
        ),
        let html = String(data: htmlData, encoding: .utf8) else {
            return nil
        }

        let printFormatter = UIMarkupTextPrintFormatter(markupText: html)
        let pageRenderer = UIPrintPageRenderer()
        pageRenderer.addPrintFormatter(printFormatter, startingAtPageAt: 0)

        // Paper size (US Letter). For A4, use 595.2 x 841.8
        let paperRect = CGRect(x: 0, y: 0, width: 612, height: 792)
        let printableRect = paperRect.insetBy(dx: 20, dy: 20)

        pageRenderer.setValue(paperRect, forKey: "paperRect")
        pageRenderer.setValue(printableRect, forKey: "printableRect")

        let data = NSMutableData()
        UIGraphicsBeginPDFContextToData(data, paperRect, nil)
        for pageIndex in 0..<pageRenderer.numberOfPages {
            UIGraphicsBeginPDFPage()
            let bounds = UIGraphicsGetPDFContextBounds()
            pageRenderer.drawPage(at: pageIndex, in: bounds)
        }
        UIGraphicsEndPDFContext()

        let safeTitle = note.title.isEmpty ? "Note" : note.title
        let fileName = safeTitle.replacingOccurrences(of: "/", with: "-") + ".pdf"
        let url = FileManager.default.temporaryDirectory.appendingPathComponent(fileName)

        do {
            try data.write(to: url, options: .atomic)
            return url
        } catch {
            return nil
        }
    }
}

// MARK: - MultiMoveToFolderView
struct MultiMoveToFolderView: View {
    @EnvironmentObject var noteManager: NoteManager
    let noteIds: [UUID]
    var onMove: (UUID?) -> Void

    @Environment(\.dismiss) var dismiss
    @State private var isAddingFolder = false
    @State private var newFolderName = String(localized: "New Folder")

    var body: some View {
        NavigationView {
            List {
                Button {
                    onMove(nil)
                    dismiss()
                } label: {
                    HStack {
                        Image(systemName: "note.text")
                        Text("All Notes")
                    }
                }
                Section("Folders") {
                    ForEach(noteManager.folders) { folder in
                        Button {
                            onMove(folder.id)
                            dismiss()
                        } label: {
                            HStack {
                                Image(systemName: "folder")
                                Text(folder.name)
                            }
                        }
                    }
                }
            }
            .navigationTitle("Move Notes")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button(action: {
                        isAddingFolder = true
                        newFolderName = String(localized: "New Folder")
                    }) {
                        Image(systemName: "folder.badge.plus")
                    }
                }
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Cancel") {
                        dismiss()
                    }
                }
            }
            .alert("New Folder", isPresented: $isAddingFolder) {
                TextField("Folder Name", text: $newFolderName)
                Button("Cancel", role: .cancel) { }
                Button("Create") {
                    let name = newFolderName.trimmingCharacters(in: .whitespacesAndNewlines)
                    if !name.isEmpty {
                        noteManager.addFolder(name: name)
                    }
                }
            }
        }
    }
}
