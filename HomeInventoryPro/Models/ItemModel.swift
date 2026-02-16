import Foundation
import CoreData
import SwiftUI

enum ItemCondition: String, CaseIterable {
    case new = "New"
    case good = "Good"
    case fair = "Fair"
    case needsRepair = "Needs Repair"
}

enum ItemCategory: String, CaseIterable {
    case electronics = "Electronics"
    case furniture = "Furniture"
    case clothing = "Clothing"
    case kitchen = "Kitchen"
    case tools = "Tools"
    case other = "Other"
}

struct Item: Identifiable {
    let id: UUID
    var name: String
    var brand: String?
    var modelNumber: String?
    var serialNumber: String?
    var barcode: String?
    var purchaseDate: Date?
    var purchasePrice: Double
    var warrantyEndDate: Date?
    var isLifetimeWarranty: Bool
    var condition: ItemCondition
    var notes: String?
    var category: ItemCategory
    var room: Room?
    var images: [ItemImage]
    var maintenanceTasks: [MaintenanceTask]
    var createdAt: Date
    var updatedAt: Date
    
    init(
        id: UUID = UUID(),
        name: String,
        brand: String? = nil,
        modelNumber: String? = nil,
        serialNumber: String? = nil,
        barcode: String? = nil,
        purchaseDate: Date? = nil,
        purchasePrice: Double = 0,
        warrantyEndDate: Date? = nil,
        isLifetimeWarranty: Bool = false,
        condition: ItemCondition = .good,
        notes: String? = nil,
        category: ItemCategory = .other,
        room: Room? = nil,
        images: [ItemImage] = [],
        maintenanceTasks: [MaintenanceTask] = [],
        createdAt: Date = Date(),
        updatedAt: Date = Date()
    ) {
        self.id = id
        self.name = name
        self.brand = brand
        self.modelNumber = modelNumber
        self.serialNumber = serialNumber
        self.barcode = barcode
        self.purchaseDate = purchaseDate
        self.purchasePrice = purchasePrice
        self.warrantyEndDate = warrantyEndDate
        self.isLifetimeWarranty = isLifetimeWarranty
        self.condition = condition
        self.notes = notes
        self.category = category
        self.room = room
        self.images = images
        self.maintenanceTasks = maintenanceTasks
        self.createdAt = createdAt
        self.updatedAt = updatedAt
    }
    
    var warrantyStatus: WarrantyStatus {
        guard let endDate = warrantyEndDate, !isLifetimeWarranty else {
            return isLifetimeWarranty ? .lifetime : .none
        }
        
        let days = endDate.daysUntil()
        if days < 0 {
            return .expired
        } else if days <= 30 {
            return .critical
        } else if days <= 90 {
            return .warning
        } else {
            return .valid
        }
    }
}

enum WarrantyStatus {
    case none
    case valid
    case warning
    case critical
    case expired
    case lifetime
    
    var color: Color {
        switch self {
        case .none: return Theme.Colors.textSecondary
        case .valid: return Theme.Colors.success
        case .warning: return Theme.Colors.warning
        case .critical: return Color.orange
        case .expired: return Theme.Colors.error
        case .lifetime: return Theme.Colors.gold
        }
    }
    
    var icon: String {
        switch self {
        case .none: return "minus.circle"
        case .valid: return "checkmark.shield.fill"
        case .warning: return "exclamationmark.shield.fill"
        case .critical: return "exclamationmark.triangle.fill"
        case .expired: return "xmark.shield.fill"
        case .lifetime: return "infinity"
        }
    }
}

struct ItemImage: Identifiable {
    let id: UUID
    var imageData: Data
    var isPrimary: Bool
    var createdAt: Date
    
    init(id: UUID = UUID(), imageData: Data, isPrimary: Bool = false, createdAt: Date = Date()) {
        self.id = id
        self.imageData = imageData
        self.isPrimary = isPrimary
        self.createdAt = createdAt
    }
}
