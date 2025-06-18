import Foundation

struct Folder: Identifiable, Codable, Equatable {
    let id: UUID
    var name: String
    var createdDate: Date
    var isLocked: Bool
    
    init(
        id: UUID = UUID(),
        name: String, createdDate: Date = Date(),
        isLocked: Bool = false
    ) {
        self.id = id
        self.name = name
        self.createdDate = createdDate
        self.isLocked = isLocked
    }
}
