import CoreData
import SwiftUI
import Combine

class CoreDataManager: ObservableObject {
    static let shared = CoreDataManager()
    
    let container: NSPersistentCloudKitContainer
    
    @Published var items: [Item] = []
    @Published var rooms: [Room] = []
    
    private init() {
        container = NSPersistentCloudKitContainer(name: "HomeInventory")
        
        guard let description = container.persistentStoreDescriptions.first else {
            fatalError("Failed to retrieve persistent store description")
        }
        
        description.setOption(true as NSNumber, forKey: NSPersistentHistoryTrackingKey)
        description.setOption(true as NSNumber, forKey: NSPersistentStoreRemoteChangeNotificationPostOptionKey)
        
        container.loadPersistentStores { description, error in
            if let error = error {
                print("Core Data failed to load: \(error.localizedDescription)")
            }
        }
        
        container.viewContext.automaticallyMergesChangesFromParent = true
        container.viewContext.mergePolicy = NSMergeByPropertyObjectTrumpMergePolicy
        
        fetchAllData()
    }
    
    // MARK: - Fetch Methods
    func fetchAllData() {
        fetchItems()
        fetchRooms()
    }
    
    func fetchItems() {
        let request = NSFetchRequest<NSManagedObject>(entityName: "ItemEntity")
        request.sortDescriptors = [NSSortDescriptor(key: "createdAt", ascending: false)]
        
        do {
            let results = try container.viewContext.fetch(request)
            items = results.compactMap { convertToItem($0) }
        } catch {
            print("Error fetching items: \(error)")
        }
    }
    
    func fetchRooms() {
        let request = NSFetchRequest<NSManagedObject>(entityName: "RoomEntity")
        request.sortDescriptors = [NSSortDescriptor(key: "name", ascending: true)]
        
        do {
            let results = try container.viewContext.fetch(request)
            rooms = results.compactMap { convertToRoom($0) }
        } catch {
            print("Error fetching rooms: \(error)")
        }
    }
    
    // MARK: - Item CRUD
    func addItem(_ item: Item) {
        let entity = NSEntityDescription.insertNewObject(forEntityName: "ItemEntity", into: container.viewContext)
        updateItemEntity(entity, with: item)
        saveContext()
        fetchItems()
    }
    
    func updateItem(_ item: Item) {
        let request = NSFetchRequest<NSManagedObject>(entityName: "ItemEntity")
        request.predicate = NSPredicate(format: "id == %@", item.id as CVarArg)
        
        do {
            let results = try container.viewContext.fetch(request)
            if let entity = results.first {
                updateItemEntity(entity, with: item)
                saveContext()
                fetchItems()
            }
        } catch {
            print("Error updating item: \(error)")
        }
    }
    
    func deleteItem(_ item: Item) {
        let request = NSFetchRequest<NSManagedObject>(entityName: "ItemEntity")
        request.predicate = NSPredicate(format: "id == %@", item.id as CVarArg)
        
        do {
            let results = try container.viewContext.fetch(request)
            if let entity = results.first {
                container.viewContext.delete(entity)
                saveContext()
                fetchItems()
            }
        } catch {
            print("Error deleting item: \(error)")
        }
    }
    
    // MARK: - Room CRUD
    func addRoom(_ room: Room) {
        let entity = NSEntityDescription.insertNewObject(forEntityName: "RoomEntity", into: container.viewContext)
        entity.setValue(room.id, forKey: "id")
        entity.setValue(room.name, forKey: "name")
        entity.setValue(room.location, forKey: "location")
        entity.setValue(room.createdAt, forKey: "createdAt")
        
        saveContext()
        fetchRooms()
    }
    
    func deleteRoom(_ room: Room) {
        let request = NSFetchRequest<NSManagedObject>(entityName: "RoomEntity")
        request.predicate = NSPredicate(format: "id == %@", room.id as CVarArg)
        
        do {
            let results = try container.viewContext.fetch(request)
            if let entity = results.first {
                container.viewContext.delete(entity)
                saveContext()
                fetchRooms()
            }
        } catch {
            print("Error deleting room: \(error)")
        }
    }
    
    // MARK: - Helper Methods
    private func saveContext() {
        if container.viewContext.hasChanges {
            do {
                try container.viewContext.save()
            } catch {
                print("Error saving context: \(error)")
            }
        }
    }
    
    private func updateItemEntity(_ entity: NSManagedObject, with item: Item) {
        entity.setValue(item.id, forKey: "id")
        entity.setValue(item.name, forKey: "name")
        entity.setValue(item.brand, forKey: "brand")
        entity.setValue(item.modelNumber, forKey: "modelNumber")
        entity.setValue(item.serialNumber, forKey: "serialNumber")
        entity.setValue(item.barcode, forKey: "barcode")
        entity.setValue(item.purchaseDate, forKey: "purchaseDate")
        entity.setValue(item.purchasePrice, forKey: "purchasePrice")
        entity.setValue(item.warrantyEndDate, forKey: "warrantyEndDate")
        entity.setValue(item.isLifetimeWarranty, forKey: "isLifetimeWarranty")
        entity.setValue(item.condition.rawValue, forKey: "condition")
        entity.setValue(item.notes, forKey: "notes")
        entity.setValue(item.category.rawValue, forKey: "category")
        entity.setValue(item.createdAt, forKey: "createdAt")
        entity.setValue(Date(), forKey: "updatedAt")
        
        // Handle room relationship
        if let room = item.room {
            let roomRequest = NSFetchRequest<NSManagedObject>(entityName: "RoomEntity")
            roomRequest.predicate = NSPredicate(format: "id == %@", room.id as CVarArg)
            
            do {
                let rooms = try container.viewContext.fetch(roomRequest)
                entity.setValue(rooms.first, forKey: "room")
            } catch {
                print("Error fetching room: \(error)")
            }
        } else {
            entity.setValue(nil, forKey: "room")
        }
        
        // Handle images - delete old ones first
        if let existingImages = entity.value(forKey: "images") as? NSSet {
            for case let imageEntity as NSManagedObject in existingImages {
                container.viewContext.delete(imageEntity)
            }
        }
        
        // Add new images
        for image in item.images {
            let imageEntity = NSEntityDescription.insertNewObject(forEntityName: "ImageEntity", into: container.viewContext)
            imageEntity.setValue(image.id, forKey: "id")
            imageEntity.setValue(image.imageData, forKey: "imageData")
            imageEntity.setValue(image.isPrimary, forKey: "isPrimary")
            imageEntity.setValue(image.createdAt, forKey: "createdAt")
            imageEntity.setValue(entity, forKey: "item")
        }
        
        // Handle maintenance tasks - delete old ones first
        if let existingTasks = entity.value(forKey: "maintenanceTasks") as? NSSet {
            for case let taskEntity as NSManagedObject in existingTasks {
                container.viewContext.delete(taskEntity)
            }
        }
        
        // Add new tasks
        for task in item.maintenanceTasks {
            let taskEntity = NSEntityDescription.insertNewObject(forEntityName: "MaintenanceTaskEntity", into: container.viewContext)
            taskEntity.setValue(task.id, forKey: "id")
            taskEntity.setValue(task.name, forKey: "name")
            taskEntity.setValue(Int32(task.intervalDays), forKey: "intervalDays")
            taskEntity.setValue(task.lastCompletedDate, forKey: "lastCompletedDate")
            taskEntity.setValue(task.nextDueDate, forKey: "nextDueDate")
            taskEntity.setValue(task.notes, forKey: "notes")
            taskEntity.setValue(task.createdAt, forKey: "createdAt")
            taskEntity.setValue(entity, forKey: "item")
        }
    }
    
    private func convertToItem(_ entity: NSManagedObject) -> Item? {
        guard let id = entity.value(forKey: "id") as? UUID,
              let name = entity.value(forKey: "name") as? String else {
            return nil
        }
        
        let brand = entity.value(forKey: "brand") as? String
        let modelNumber = entity.value(forKey: "modelNumber") as? String
        let serialNumber = entity.value(forKey: "serialNumber") as? String
        let barcode = entity.value(forKey: "barcode") as? String
        let purchaseDate = entity.value(forKey: "purchaseDate") as? Date
        let purchasePrice = entity.value(forKey: "purchasePrice") as? Double ?? 0
        let warrantyEndDate = entity.value(forKey: "warrantyEndDate") as? Date
        let isLifetimeWarranty = entity.value(forKey: "isLifetimeWarranty") as? Bool ?? false
        let conditionString = entity.value(forKey: "condition") as? String ?? "Good"
        let notes = entity.value(forKey: "notes") as? String
        let categoryString = entity.value(forKey: "category") as? String ?? "Other"
        let createdAt = entity.value(forKey: "createdAt") as? Date ?? Date()
        let updatedAt = entity.value(forKey: "updatedAt") as? Date ?? Date()
        
        // Convert room
        var room: Room?
        if let roomEntity = entity.value(forKey: "room") as? NSManagedObject {
            room = convertToRoom(roomEntity)
        }
        
        // Convert images
        var images: [ItemImage] = []
        if let imageSet = entity.value(forKey: "images") as? NSSet {
            for case let imageEntity as NSManagedObject in imageSet {
                if let imageId = imageEntity.value(forKey: "id") as? UUID,
                   let imageData = imageEntity.value(forKey: "imageData") as? Data {
                    let isPrimary = imageEntity.value(forKey: "isPrimary") as? Bool ?? false
                    let imageCreatedAt = imageEntity.value(forKey: "createdAt") as? Date ?? Date()
                    
                    images.append(ItemImage(
                        id: imageId,
                        imageData: imageData,
                        isPrimary: isPrimary,
                        createdAt: imageCreatedAt
                    ))
                }
            }
        }
        images.sort { $0.isPrimary && !$1.isPrimary }
        
        // Convert maintenance tasks
        var tasks: [MaintenanceTask] = []
        if let taskSet = entity.value(forKey: "maintenanceTasks") as? NSSet {
            for case let taskEntity as NSManagedObject in taskSet {
                if let taskId = taskEntity.value(forKey: "id") as? UUID,
                   let taskName = taskEntity.value(forKey: "name") as? String {
                    let intervalDays = taskEntity.value(forKey: "intervalDays") as? Int32 ?? 30
                    let lastCompletedDate = taskEntity.value(forKey: "lastCompletedDate") as? Date
                    let taskNotes = taskEntity.value(forKey: "notes") as? String
                    let taskCreatedAt = taskEntity.value(forKey: "createdAt") as? Date ?? Date()
                    
                    tasks.append(MaintenanceTask(
                        id: taskId,
                        name: taskName,
                        intervalDays: Int(intervalDays),
                        lastCompletedDate: lastCompletedDate,
                        notes: taskNotes,
                        createdAt: taskCreatedAt
                    ))
                }
            }
        }
        
        return Item(
            id: id,
            name: name,
            brand: brand,
            modelNumber: modelNumber,
            serialNumber: serialNumber,
            barcode: barcode,
            purchaseDate: purchaseDate,
            purchasePrice: purchasePrice,
            warrantyEndDate: warrantyEndDate,
            isLifetimeWarranty: isLifetimeWarranty,
            condition: ItemCondition(rawValue: conditionString) ?? .good,
            notes: notes,
            category: ItemCategory(rawValue: categoryString) ?? .other,
            room: room,
            images: images,
            maintenanceTasks: tasks,
            createdAt: createdAt,
            updatedAt: updatedAt
        )
    }
    
    private func convertToRoom(_ entity: NSManagedObject) -> Room? {
        guard let id = entity.value(forKey: "id") as? UUID,
              let name = entity.value(forKey: "name") as? String else {
            return nil
        }
        
        let location = entity.value(forKey: "location") as? String
        let createdAt = entity.value(forKey: "createdAt") as? Date ?? Date()
        
        return Room(
            id: id,
            name: name,
            location: location,
            createdAt: createdAt
        )
    }
}
