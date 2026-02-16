import Foundation

struct Room: Identifiable, Hashable {
    let id: UUID
    var name: String
    var location: String?
    var createdAt: Date
    
    init(id: UUID = UUID(), name: String, location: String? = nil, createdAt: Date = Date()) {
        self.id = id
        self.name = name
        self.location = location
        self.createdAt = createdAt
    }
}
