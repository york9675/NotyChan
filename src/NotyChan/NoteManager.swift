import Foundation
import SwiftUI
import PhotosUI

class NoteManager: ObservableObject {
    @Published var notes: [Note] = []
    @Published var folders: [Folder] = []
    
    private let notesKey = "notychan_notes"
    private let foldersKey = "notychan_folders"
    private let deletionPeriod: TimeInterval = 30 * 24 * 60 * 60 // 30 days in seconds
    
    private var watchSyncTask: Task<Void, Never>? = nil
    private var lastWatchSync: Date? = nil
    private let minWatchSyncInterval: TimeInterval = 1.0 // 1 second
    
    init() {
        loadData()
        cleanupExpiredNotes()
    }
    
    // MARK: - Notes Management
    
    func addNote(inFolder folderId: UUID? = nil) -> Note {
        let newNote = Note(folderId: folderId)
        notes.insert(newNote, at: 0)
        saveData()
        return newNote
    }
    
    func updateNote(_ updatedNote: Note) {
        if let index = notes.firstIndex(where: { $0.id == updatedNote.id }) {
            notes[index] = updatedNote
            saveData()
        }
    }
    
    func deleteNote(_ note: Note) {
        if let index = notes.firstIndex(where: { $0.id == note.id }) {
            var noteToDelete = notes[index]
            noteToDelete.isDeleted = true
            noteToDelete.deletedDate = Date()
            notes[index] = noteToDelete
            saveData()
        }
    }
    
    func permanentlyDeleteNote(_ note: Note) {
        // Remove images from disk
        let dir = imagesDirectory(for: note)
        try? FileManager.default.removeItem(at: dir)
        // Remove note from array
        notes.removeAll(where: { $0.id == note.id })
        saveData()
    }
    
    func restoreNote(_ note: Note) {
        if let index = notes.firstIndex(where: { $0.id == note.id }) {
            var noteToRestore = notes[index]
            noteToRestore.isDeleted = false
            noteToRestore.deletedDate = nil
            notes[index] = noteToRestore
            saveData()
        }
    }
    
    func moveNote(_ note: Note, toFolder folderId: UUID?) {
        if let index = notes.firstIndex(where: { $0.id == note.id }) {
            var noteToMove = notes[index]
            noteToMove.folderId = folderId
            notes[index] = noteToMove
            saveData()
        }
    }
    
    // MARK: - Notes Lock/Unlock
    func lockNote(_ note: Note) {
        if let idx = notes.firstIndex(where: { $0.id == note.id }) {
            notes[idx].isLocked = true
            saveData()
        }
    }
    
    func unlockNote(_ note: Note) {
        if let idx = notes.firstIndex(where: { $0.id == note.id }) {
            notes[idx].isLocked = false
            saveData()
        }
    }
    
    // MARK: - Notes Archive/Unarchive
    func archiveNote(_ note: Note) {
        if let idx = notes.firstIndex(where: { $0.id == note.id }) {
            notes[idx].isArchived = true
            notes[idx].archivedDate = Date()
            saveData()
        }
    }
    
    func unarchiveNote(_ note: Note) {
        if let idx = notes.firstIndex(where: { $0.id == note.id }) {
            notes[idx].isArchived = false
            notes[idx].archivedDate = nil
            saveData()
        }
    }
    
    // MARK: - Folders Management
    
    func addFolder(name: String) {
        let newFolder = Folder(name: name)
        folders.append(newFolder)
        saveData()
    }
    
    func updateFolder(_ folder: Folder) {
        if let index = folders.firstIndex(where: { $0.id == folder.id }) {
            folders[index] = folder
            saveData()
        }
    }
    
    func deleteFolder(_ folder: Folder) {
        // Move all notes from this folder to no folder
        for (index, note) in notes.enumerated() {
            if note.folderId == folder.id {
                var updatedNote = note
                updatedNote.folderId = nil
                notes[index] = updatedNote
            }
        }
        
        // Remove the folder
        folders.removeAll(where: { $0.id == folder.id })
        saveData()
    }
    
    // MARK: - Folder Lock/Unlock
    func lockFolder(_ folder: Folder) {
        if let idx = folders.firstIndex(where: { $0.id == folder.id }) {
            folders[idx].isLocked = true
            saveData()
        }
    }
    
    func unlockFolder(_ folder: Folder) {
        if let idx = folders.firstIndex(where: { $0.id == folder.id }) {
            folders[idx].isLocked = false
            saveData()
        }
    }
    
    // MARK: - Notes & Folders Filtering

    func getNotes(inFolder folderId: UUID? = nil, includeDeleted: Bool = false, includeArchived: Bool = false, respectFolderLock: Bool = true) -> [Note] {
        return notes.filter { note in
            let folderMatch = note.folderId == folderId
            let deletedMatch = includeDeleted ? note.isDeleted : !note.isDeleted
            let archivedMatch = includeArchived ? true : !note.isArchived
            
            // Check if note is in a locked folder and respect the lock
            let folderLockMatch: Bool
            if respectFolderLock, let noteFolderId = note.folderId {
                if let folder = folders.first(where: { $0.id == noteFolderId }) {
                    folderLockMatch = !folder.isLocked
                } else {
                    folderLockMatch = true // If folder not found, allow access
                }
            } else {
                folderLockMatch = true // Don't restrict if not respecting folder lock
            }
            
            return folderMatch && deletedMatch && archivedMatch && folderLockMatch
        }
    }

    func getAllNotes(includeDeleted: Bool = false, includeArchived: Bool = false, respectFolderLock: Bool = true) -> [Note] {
        return notes.filter { note in
            let deletedMatch = includeDeleted ? true : !note.isDeleted
            let archivedMatch = includeArchived ? true : !note.isArchived
            
            // Check if note is in a locked folder and respect the lock
            let folderLockMatch: Bool
            if respectFolderLock, let noteFolderId = note.folderId {
                if let folder = folders.first(where: { $0.id == noteFolderId }) {
                    folderLockMatch = !folder.isLocked
                } else {
                    folderLockMatch = true // If folder not found, allow access
                }
            } else {
                folderLockMatch = true // Don't restrict if not respecting folder lock
            }
            
            return deletedMatch && archivedMatch && folderLockMatch
        }
    }

    // Add a method to get notes from locked folders (for internal use only)
    func getNotesFromLockedFolder(_ folderId: UUID) -> [Note] {
        return notes.filter { note in
            note.folderId == folderId && !note.isDeleted && !note.isArchived
        }
    }
    
    func getRecentlyDeletedNotes() -> [Note] {
        return notes.filter { $0.isDeleted }
    }
    
    func getArchivedNotes() -> [Note] {
        return notes.filter { $0.isArchived && !$0.isDeleted }
    }
    
    func getFolderName(for folderId: UUID?) -> String {
        guard let id = folderId else { return "" }
        return folders.first(where: { $0.id == id })?.name ?? ""
    }
    
    // MARK: - Pin/Unpin Note
    func togglePin(for note: Note) {
        if let idx = notes.firstIndex(where: { $0.id == note.id }) {
            notes[idx].isPinned.toggle()
            saveData()
        }
    }
    
    // MARK: - Persistence
    
    private func debouncedWatchSync() {
        watchSyncTask?.cancel()
        let now = Date()
        let timeSinceLast = lastWatchSync.map { now.timeIntervalSince($0) } ?? .infinity

        // If last sync was long enough ago, sync immediately
        if timeSinceLast > minWatchSyncInterval {
            actuallyPushToWatch()
        } else {
            // Otherwise, wait for the interval to pass, then sync
            watchSyncTask = Task { @MainActor in
                let delay = minWatchSyncInterval - timeSinceLast
                try? await Task.sleep(nanoseconds: UInt64((delay + 0.05) * 1_000_000_000))
                actuallyPushToWatch()
            }
        }
    }

    private func actuallyPushToWatch() {
        lastWatchSync = Date()
        WatchSyncPush.shared.pushAll(folders: folders, notes: notes)
    }
    
    private func saveData() {
        if let encodedNotes = try? JSONEncoder().encode(notes) {
            UserDefaults.standard.set(encodedNotes, forKey: notesKey)
        }
        if let encodedFolders = try? JSONEncoder().encode(folders) {
            UserDefaults.standard.set(encodedFolders, forKey: foldersKey)
        }
        // Debounced/throttled sync to watchOS
        debouncedWatchSync()
    }
    
    private func loadData() {
        if let data = UserDefaults.standard.data(forKey: notesKey),
           let decoded = try? JSONDecoder().decode([Note].self, from: data) {
            notes = decoded
        }
        
        if let data = UserDefaults.standard.data(forKey: foldersKey),
           let decoded = try? JSONDecoder().decode([Folder].self, from: data) {
            folders = decoded
        } else {
            // Create default "All Notes" folder if no folders exist
            folders = []
        }
    }
    
    private func cleanupExpiredNotes() {
        let now = Date()
        notes.removeAll { note in
            guard let deletedDate = note.deletedDate, note.isDeleted else { return false }
            return now.timeIntervalSince(deletedDate) > deletionPeriod
        }
        saveData()
    }
    
    // MARK: - Image Management
    private func imagesDirectory(for note: Note) -> URL {
        let dir = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0]
            .appendingPathComponent("NoteImages")
            .appendingPathComponent(note.id.uuidString)
        try? FileManager.default.createDirectory(at: dir, withIntermediateDirectories: true)
        return dir
    }

    func saveImage(_ image: UIImage, for note: Note, description: String = "") -> NoteImage? {
        guard let jpegData = image.jpegData(compressionQuality: 0.95) else { return nil }
        let filename = UUID().uuidString + ".jpg"
        let dir = imagesDirectory(for: note)
        let url = dir.appendingPathComponent(filename)
        do {
            try jpegData.write(to: url)
            var updatedNote = note
            var imgs = updatedNote.images
            let noteImage = NoteImage(filename: filename, description: description)
            imgs.append(noteImage)
            updatedNote.images = imgs
            updateNote(updatedNote)
            return noteImage
        } catch {
            print("Failed to save image: \(error)")
            return nil
        }
    }

    func loadImage(for note: Note, image: NoteImage) -> UIImage? {
        let dir = imagesDirectory(for: note)
        let url = dir.appendingPathComponent(image.filename)
        return UIImage(contentsOfFile: url.path)
    }

    func deleteImage(_ image: NoteImage, for note: Note) {
        let dir = imagesDirectory(for: note)
        let url = dir.appendingPathComponent(image.filename)
        try? FileManager.default.removeItem(at: url)
        if let idx = notes.firstIndex(where: { $0.id == note.id }) {
            var updated = notes[idx]
            updated.images.removeAll(where: { $0.id == image.id })
            notes[idx] = updated
            saveData()
        }
    }

    func updateImageDescription(_ image: NoteImage, for note: Note, newDescription: String) {
        if let idx = notes.firstIndex(where: { $0.id == note.id }) {
            var updated = notes[idx]
            if let imgIdx = updated.images.firstIndex(where: { $0.id == image.id }) {
                updated.images[imgIdx].description = newDescription
                notes[idx] = updated
                saveData()
            }
        }
    }
}
