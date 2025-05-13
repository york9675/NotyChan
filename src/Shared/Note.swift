import Foundation

struct Note: Identifiable, Codable, Equatable {
    let id: UUID
    var title: String
    var rtfData: Data
    var lastEdited: Date
    var folderId: UUID?
    var isDeleted: Bool
    var deletedDate: Date?
    var isPinned: Bool
    var isLocked: Bool
    var images: [NoteImage] = []

    init(
        id: UUID = UUID(),
        title: String = String(localized: "New Note"),
        rtfData: Data = Data(),
        lastEdited: Date = Date(),
        folderId: UUID? = nil,
        isDeleted: Bool = false,
        deletedDate: Date? = nil,
        isPinned: Bool = false,
        isLocked: Bool = false,
        images: [NoteImage] = []
    ) {
        self.id = id
        self.title = title
        self.rtfData = rtfData
        self.lastEdited = lastEdited
        self.folderId = folderId
        self.isDeleted = isDeleted
        self.deletedDate = deletedDate
        self.isPinned = isPinned
        self.isLocked = isLocked
        self.images = images
    }
}
