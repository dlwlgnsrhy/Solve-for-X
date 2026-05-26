import Foundation
import CoreData

@MainActor
final class DatabaseManager: ObservableObject {
    static let shared = DatabaseManager()
    
    let container: NSPersistentContainer
    
    var mainContext: NSManagedObjectContext {
        container.viewContext
    }
    
    public init() {
        container = NSPersistentContainer(name: "LegacyVaultModel")
        container.loadPersistentStores { _, error in
            if let error = error {
                fatalError("Core Data store failed to load: \(error)")
            }
        }
        container.viewContext.automaticallyMergesChangesFromParent = true
        container.viewContext.mergePolicy = NSMergeByPropertyObjectTrumpMergePolicy
    }
    
    func saveContext() throws {
        let context = mainContext
        if context.hasChanges {
            try context.save()
        }
    }
    
    func delete(_ object: NSManagedObject) {
        mainContext.delete(object)
        try? mainContext.save()
    }
}
