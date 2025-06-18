import SwiftUI

enum FolderSortField: String, CaseIterable, Identifiable, Codable {
    case title = "Title"
    case createdDate = "Created Date"

    var id: String { rawValue }
    var displayName: String {
        switch self {
        case .title: return String(localized: "Title")
        case .createdDate: return String(localized: "Created Date")
        }
    }
}

enum FolderSortOrder: String, CaseIterable, Identifiable, Codable {
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

struct FolderSortOptions: Equatable, Codable {
    var field: FolderSortField = .title
    var order: FolderSortOrder = .ascending

    private static let key = "notychan_folder_sort_options"

    func save() {
        if let encoded = try? JSONEncoder().encode(self) {
            UserDefaults.standard.set(encoded, forKey: Self.key)
        }
    }

    static func load() -> FolderSortOptions {
        if let data = UserDefaults.standard.data(forKey: Self.key),
           let decoded = try? JSONDecoder().decode(FolderSortOptions.self, from: data) {
            return decoded
        }
        return FolderSortOptions()
    }
}

struct FolderListView: View {
    @EnvironmentObject var noteManager: NoteManager
    @State private var isAddingFolder = false
    @State private var newFolderName = String(localized: "New Folder")
    @State private var isSettingsPresented = false

    @State private var folderToRename: Folder?
    @State private var renameFolderName: String = ""
    @State private var folderToDelete: Folder?
    @State private var folderToUnlock: Folder?

    @State private var isSelecting = false
    @State private var selectedFolderIds: Set<UUID> = []
    @State private var isDeleteConfirmationPresented = false

    @State private var searchText: String = ""
    @State private var sortOptions = FolderSortOptions.load()
    @State private var showGallery = false
    @State private var isAuthenticating = false

    var allNotesWithImages: [Note] {
        noteManager.getAllNotes().filter { !$0.images.isEmpty }
    }

    var filteredFolders: [Folder] {
        let folders = noteManager.folders
        let filtered = searchText.isEmpty
            ? folders
            : folders.filter { $0.name.localizedCaseInsensitiveContains(searchText) }
        return sortFolders(filtered)
    }

    func sortFolders(_ folders: [Folder]) -> [Folder] {
        switch sortOptions.field {
        case .title:
            return folders.sorted {
                sortOptions.order == .ascending
                    ? $0.name.localizedCaseInsensitiveCompare($1.name) == .orderedAscending
                    : $0.name.localizedCaseInsensitiveCompare($1.name) == .orderedDescending
            }
        case .createdDate:
            return folders.sorted {
                sortOptions.order == .ascending
                    ? $0.createdDate < $1.createdDate
                    : $0.createdDate > $1.createdDate
            }
        }
    }

    var body: some View {
        let folders = filteredFolders
        let selectionCount = selectedFolderIds.count
        let allSelected = selectionCount == folders.count && !folders.isEmpty
        let noneSelected = selectionCount == 0

        VStack(spacing: 0) {
            NavigationView {
                List(selection: isSelecting ? $selectedFolderIds : .constant([])) {
                    NavigationLink(destination: NoteListView(folderFilter: nil)) {
                        HStack {
                            Image(systemName: "note.text")
                                .foregroundColor(.accentColor)
                            Text("All Notes")
                            Spacer()
                            Text("\(noteManager.getAllNotes(respectFolderLock: true).count)")
                                .foregroundColor(.secondary)
                        }
                    }

                    NavigationLink(destination: RecentlyDeletedView()) {
                        HStack {
                            Image(systemName: "trash")
                                .foregroundColor(.accentColor)
                            Text("Recently Deleted")
                            Spacer()
                            Text("\(noteManager.getRecentlyDeletedNotes().count)")
                                .foregroundColor(.secondary)
                        }
                    }

                    Section("Folders") {
                        if folders.isEmpty {
                            VStack {
                                if searchText.isEmpty {
                                    Image(systemName: "folder.badge.questionmark")
                                        .padding(.bottom, 5)
                                        .font(.largeTitle)
                                        .foregroundColor(.secondary)
                                    Text("No folders yet")
                                        .font(.headline)
                                    Text("Tap the folder-plus icon above to create your first folder.")
                                        .font(.subheadline)
                                        .foregroundColor(.secondary)
                                        .multilineTextAlignment(.center)
                                        .padding(.top, 2)
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
                                        .padding(.top, 2)
                                }
                            }
                            .frame(maxWidth: .infinity)
                            .padding()
                        } else {
                            ForEach(folders) { folder in
                                if folder.isLocked {
                                    // Locked folder row
                                    Button {
                                        folderToUnlock = folder
                                        Task {
                                            isAuthenticating = true
                                            let success = await BiometricAuth.authenticate(reason: String(localized: "Unlock folder '\(folder.name)'"))
                                            isAuthenticating = false
                                            if success {
                                                noteManager.unlockFolder(folder)
                                                folderToUnlock = nil
                                            }
                                        }
                                    } label: {
                                        HStack {
                                            Image(systemName: "folder")
                                                .foregroundColor(.accentColor)
                                            Text(folder.name)
                                            Spacer()
                                            Image(systemName: "lock.fill")
                                                .foregroundColor(.gray)
                                        }
                                    }
                                    .disabled(isAuthenticating)
                                    .swipeActions(edge: .trailing) {
                                        Button(role: .destructive) {
                                            folderToDelete = folder
                                        } label: {
                                            Label("Delete", systemImage: "trash")
                                        }
                                        .tint(.red)
                                        
                                        Button {
                                            Task {
                                                let success = await BiometricAuth.authenticate(reason: String(localized: "Unlock folder '\(folder.name)'"))
                                                if success {
                                                    noteManager.unlockFolder(folder)
                                                }
                                            }
                                        } label: {
                                            Label("Unlock", systemImage: "lock.open")
                                        }
                                        .tint(.green)
                                    }
                                    .contextMenu {
                                        Button {
                                            Task {
                                                let success = await BiometricAuth.authenticate(reason: String(localized: "Unlock folder '\(folder.name)'"))
                                                if success {
                                                    noteManager.unlockFolder(folder)
                                                }
                                            }
                                        } label: {
                                            Label("Unlock Folder", systemImage: "lock.open")
                                        }
                                        Button(role: .destructive) {
                                            folderToDelete = folder
                                        } label: {
                                            Label("Delete", systemImage: "trash")
                                        }
                                    }
                                } else {
                                    // Unlocked folder row
                                    NavigationLink(destination: NoteListView(folderFilter: folder.id)) {
                                        HStack {
                                            Image(systemName: "folder")
                                                .foregroundColor(.accentColor)
                                            Text(folder.name)
                                            Spacer()
                                            Text("\(noteManager.getNotes(inFolder: folder.id).count)")
                                                .foregroundColor(.secondary)
                                        }
                                    }
                                    .swipeActions(edge: .trailing) {
                                        Button(role: .destructive) {
                                            folderToDelete = folder
                                        } label: {
                                            Label("Delete", systemImage: "trash")
                                        }
                                        .tint(.red)
                                        
                                        Button {
                                            folderToRename = folder
                                            renameFolderName = folder.name
                                        } label: {
                                            Label("Rename", systemImage: "pencil")
                                        }
                                        .tint(.blue)
                                        
                                        Button {
                                            Task {
                                                let success = await BiometricAuth.authenticate(reason: String(localized: "Lock folder '\(folder.name)'"))
                                                if success {
                                                    noteManager.lockFolder(folder)
                                                }
                                            }
                                        } label: {
                                            Label("Lock", systemImage: "lock")
                                        }
                                        .tint(.orange)
                                    }
                                    .contextMenu {
                                        Button {
                                            folderToRename = folder
                                            renameFolderName = folder.name
                                        } label: {
                                            Label("Rename", systemImage: "pencil")
                                        }
                                        Button {
                                            Task {
                                                let success = await BiometricAuth.authenticate(reason: String(localized: "Lock folder '\(folder.name)'"))
                                                if success {
                                                    noteManager.lockFolder(folder)
                                                }
                                            }
                                        } label: {
                                            Label("Lock Folder", systemImage: "lock")
                                        }
                                        Button(role: .destructive) {
                                            folderToDelete = folder
                                        } label: {
                                            Label("Delete", systemImage: "trash")
                                        }
                                    }
                                }
                            }
                        }
                    }
                }
                .environment(\.editMode, .constant(isSelecting ? .active : .inactive))
                .navigationTitle(
                    isSelecting && !folders.isEmpty
                        ? (selectedFolderIds.isEmpty
                           ? String(localized: "Select Folders")
                           : String(localized: "\(selectedFolderIds.count) Selected"))
                    : String(localized: "Folders")
                )
                .toolbar {
                    ToolbarItem(placement: .topBarLeading) {
                        Button(action: {
                            isSettingsPresented = true
                        }) {
                            Image(systemName: "gear")
                        }
                    }

                    ToolbarItem(placement: .topBarTrailing) {
                        HStack {
                            if !folders.isEmpty {
                                Menu {
                                    Button {
                                        isSelecting = true
                                        selectedFolderIds.removeAll()
                                    } label: {
                                        Label("Select Folders", systemImage: "checkmark.circle")
                                    }
                                    
                                    Divider()
                                    
                                    Menu {
                                        Picker("Sort by", selection: $sortOptions.field) {
                                            ForEach(FolderSortField.allCases) { field in
                                                Text(field.displayName).tag(field)
                                            }
                                        }
                                        .pickerStyle(.inline)
                                    } label: {
                                        Label("Sort by", systemImage: "arrow.up.arrow.down")
                                    }
                                    
                                    Menu {
                                        Picker("Sort order", selection: $sortOptions.order) {
                                            ForEach(FolderSortOrder.allCases) { order in
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
                            
                            Button(action: {
                                showGallery = true
                            }) {
                                Image(systemName: "photo.on.rectangle.angled")
                            }

                            Button(action: {
                                isAddingFolder = true
                                newFolderName = String(localized: "New Folder")
                            }) {
                                Image(systemName: "folder.badge.plus")
                            }
                        }
                    }
                }
                .sheet(isPresented: $isSettingsPresented) {
                    SettingsView()
                }
                .sheet(isPresented: $showGallery) {
                    NavigationView {
                        GalleryOverviewView(
                            notes: allNotesWithImages,
                            noteManager: noteManager,
                            folders: noteManager.folders,
                            showFolderName: true
                        )
                        .navigationTitle("All Images")
                        .toolbar {
                            ToolbarItem(placement: .cancellationAction) {
                                Button("Close") { showGallery = false }
                            }
                        }
                    }
                }
                .alert("New Folder", isPresented: $isAddingFolder) {
                    TextField("Folder Name", text: $newFolderName)
                    Button("Cancel", role: .cancel) { }
                    Button("Create") {
                        if !newFolderName.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
                            noteManager.addFolder(name: newFolderName)
                        }
                    }
                }
                .alert("Rename Folder", isPresented: Binding(
                    get: { folderToRename != nil },
                    set: { if !$0 { folderToRename = nil } }
                )) {
                    TextField("Folder Name", text: $renameFolderName)
                    Button("Cancel", role: .cancel) { folderToRename = nil }
                    Button("Rename") {
                        if let folder = folderToRename,
                           !renameFolderName.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
                            var updated = folder
                            updated.name = renameFolderName
                            noteManager.updateFolder(updated)
                        }
                        folderToRename = nil
                    }
                }
                .alert("Delete Folder", isPresented: Binding(
                    get: { folderToDelete != nil },
                    set: { if !$0 { folderToDelete = nil } }
                )) {
                    Button("Cancel", role: .cancel) { folderToDelete = nil }
                    Button("Delete", role: .destructive) {
                        if let folder = folderToDelete {
                            noteManager.deleteFolder(folder)
                        }
                        folderToDelete = nil
                    }
                } message: {
                    Text("Are you sure you want to delete this folder? All notes in this folder will be moved to 'All Notes'.")
                }
                .searchable(text: $searchText, placement: .navigationBarDrawer(displayMode: .automatic), prompt: "Search Folders")
                .onChange(of: sortOptions) {
                    sortOptions.save()
                }
            }

            // Selection actions bar
            if isSelecting && !folders.isEmpty {
                Divider()
                HStack(spacing: 0) {
                    ScrollView(.horizontal, showsIndicators: false) {
                        HStack(spacing: 8) {
                            if noneSelected || !allSelected {
                                Button {
                                    selectedFolderIds = Set(folders.map(\.id))
                                } label: {
                                    Label("Select All", systemImage: "checkmark.circle")
                                }
                                .buttonStyle(.bordered)
                            }
                            if allSelected {
                                Button {
                                    selectedFolderIds.removeAll()
                                } label: {
                                    Label("Deselect All", systemImage: "circle")
                                }
                                .buttonStyle(.bordered)
                            }
                            if noneSelected {
                                Button(role: .destructive) {
                                    isDeleteConfirmationPresented = true
                                } label: {
                                    Label("Delete All", systemImage: "trash")
                                }
                                .buttonStyle(.bordered)
                                .tint(.red)
                            } else {
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
                        selectedFolderIds.removeAll()
                    }
                    .bold()
                    .padding(.horizontal)
                }
                .background(.regularMaterial)
                .alert(
                    selectedFolderIds.isEmpty ? "Delete All" : "Delete",
                    isPresented: $isDeleteConfirmationPresented
                ) {
                    Button("Cancel", role: .cancel) { }
                    Button("Delete", role: .destructive) {
                        let idsToDelete = selectedFolderIds.isEmpty ? Set(folders.map(\.id)) : selectedFolderIds
                        for folder in folders where idsToDelete.contains(folder.id) {
                            noteManager.deleteFolder(folder)
                        }
                        isSelecting = false
                        selectedFolderIds.removeAll()
                    }
                } message: {
                    Text("Are you sure you want to delete the selected folders? All notes in these folders will be moved to 'All Notes'.")
                }
            }
        }
    }
}
