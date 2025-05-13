import Foundation

struct NoteImage: Identifiable, Codable, Equatable {
    let id: UUID
    var filename: String
    var description: String

    init(id: UUID = UUID(), filename: String, description: String = "") {
        self.id = id
        self.filename = filename
        self.description = description
    }
}
