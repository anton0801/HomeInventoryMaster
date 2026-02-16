import Foundation

struct MaintenanceTask: Identifiable, Equatable, Hashable {
    let id: UUID
    var name: String
    var intervalDays: Int
    var lastCompletedDate: Date?
    var nextDueDate: Date?
    var notes: String?
    var createdAt: Date
    
    init(
        id: UUID = UUID(),
        name: String,
        intervalDays: Int,
        lastCompletedDate: Date? = nil,
        notes: String? = nil,
        createdAt: Date = Date()
    ) {
        self.id = id
        self.name = name
        self.intervalDays = intervalDays
        self.lastCompletedDate = lastCompletedDate
        self.notes = notes
        self.createdAt = createdAt
        
        if let lastDate = lastCompletedDate {
            self.nextDueDate = Calendar.current.date(byAdding: .day, value: intervalDays, to: lastDate)
        } else {
            self.nextDueDate = nil
        }
    }
    
    var isOverdue: Bool {
        guard let dueDate = nextDueDate else { return false }
        return dueDate < Date()
    }
    
    var daysUntilDue: Int? {
        guard let dueDate = nextDueDate else { return nil }
        return dueDate.daysUntil()
    }
    
    mutating func markCompleted() {
        lastCompletedDate = Date()
        nextDueDate = Calendar.current.date(byAdding: .day, value: intervalDays, to: Date())
    }
    
    static func == (lhs: MaintenanceTask, rhs: MaintenanceTask) -> Bool {
        lhs.id == rhs.id
    }
}
