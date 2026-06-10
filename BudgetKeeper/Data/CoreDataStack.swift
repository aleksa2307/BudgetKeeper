import CoreData

@objc(CDTransaction)
final class CDTransaction: NSManagedObject {
    @NSManaged var id: UUID
    @NSManaged var type: String
    @NSManaged var amount: Double
    @NSManaged var categoryId: UUID
    @NSManaged var accountId: UUID
    @NSManaged var toAccountId: UUID?
    @NSManaged var date: Date
    @NSManaged var note: String
    @NSManaged var createdAt: Date
}

@objc(CDAccount)
final class CDAccount: NSManagedObject {
    @NSManaged var id: UUID
    @NSManaged var name: String
    @NSManaged var typeName: String
    @NSManaged var balance: Double
    @NSManaged var colorHex: String
    @NSManaged var icon: String
    @NSManaged var currency: String
    @NSManaged var createdAt: Date
}

@objc(CDBudget)
final class CDBudget: NSManagedObject {
    @NSManaged var id: UUID
    @NSManaged var name: String
    @NSManaged var limit: Double
    @NSManaged var categoryId: UUID
    @NSManaged var colorHex: String
    @NSManaged var createdAt: Date
}

@objc(CDGoal)
final class CDGoal: NSManagedObject {
    @NSManaged var id: UUID
    @NSManaged var name: String
    @NSManaged var target: Double
    @NSManaged var saved: Double
    @NSManaged var colorHex: String
    @NSManaged var icon: String
    @NSManaged var createdAt: Date
}

@objc(CDRecurringPayment)
final class CDRecurringPayment: NSManagedObject {
    @NSManaged var id: UUID
    @NSManaged var name: String
    @NSManaged var amount: Double
    @NSManaged var nextDate: Date
    @NSManaged var icon: String
    @NSManaged var colorHex: String
    @NSManaged var isPaused: Bool
    @NSManaged var createdAt: Date
}

@objc(CDDebt)
final class CDDebt: NSManagedObject {
    @NSManaged var id: UUID
    @NSManaged var personName: String
    @NSManaged var amount: Double
    @NSManaged var dueDate: Date
    @NSManaged var iOwe: Bool
    @NSManaged var note: String
    @NSManaged var createdAt: Date
}

@objc(CDCategory)
final class CDCategory: NSManagedObject {
    @NSManaged var id: UUID
    @NSManaged var name: String
    @NSManaged var icon: String
    @NSManaged var colorHex: String
    @NSManaged var type: String
    @NSManaged var createdAt: Date
}

final class CoreDataStack {
    static let shared = CoreDataStack()

    static let allEntityNames = [
        "CDTransaction", "CDAccount", "CDBudget", "CDGoal",
        "CDRecurringPayment", "CDDebt", "CDCategory",
    ]

    let container: NSPersistentContainer
    var context: NSManagedObjectContext { container.viewContext }

    private init() {
        container = NSPersistentContainer(name: "BudgetKeeper")
        container.loadPersistentStores { _, error in
            if let error {
                fatalError("Не вдалося завантажити сховище Core Data: \(error)")
            }
        }
        container.viewContext.mergePolicy = NSMergeByPropertyObjectTrumpMergePolicy
    }

    func saveIfNeeded() {
        try? save()
    }

    func save() throws {
        guard context.hasChanges else { return }
        try context.save()
    }

    func wipeAllEntities() -> Bool {
        var succeeded = true
        for name in Self.allEntityNames {
            let fetch = NSFetchRequest<NSFetchRequestResult>(entityName: name)
            let delete = NSBatchDeleteRequest(fetchRequest: fetch)
            do { try context.execute(delete) } catch { succeeded = false }
        }
        context.reset()
        return succeeded
    }
}
