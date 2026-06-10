import Foundation
import CoreData

final class DataStore {
    static let shared = DataStore()
    private let defaults = UserDefaults.standard
    private let stack = CoreDataStack.shared

    static let dataChangedNotification = Notification.Name("DataStoreDataChanged")

    private init() {
        migrateFromUserDefaultsIfNeeded()
    }

    var pin: String? {
        get { defaults.string(forKey: "pin") }
        set { defaults.set(newValue, forKey: "pin") }
    }

    var isPINSet: Bool { !(pin?.isEmpty ?? true) }

    var userName: String {
        get { defaults.string(forKey: "userName") ?? "Користувач" }
        set { defaults.set(newValue, forKey: "userName") }
    }

    var isFaceIDEnabled: Bool {
        get { defaults.bool(forKey: "faceIDEnabled") }
        set { defaults.set(newValue, forKey: "faceIDEnabled") }
    }

    var themeStyle: Int {
        get { defaults.integer(forKey: "themeStyle") }
        set { defaults.set(newValue, forKey: "themeStyle") }
    }

    var transactions: [Transaction] {
        fetchAll(CDTransaction.self, sortedBy: [
            NSSortDescriptor(key: "date", ascending: false),
            NSSortDescriptor(key: "createdAt", ascending: false),
        ]).map(Self.transaction(from:))
    }

    func addTransaction(_ t: Transaction) {
        let cd = CDTransaction(context: stack.context)
        apply(t, to: cd)
        cd.createdAt = Date()
        adjustBalance(for: t, factor: 1)
        persistAndNotify()
    }

    func updateTransaction(_ t: Transaction) {
        guard let cd = first(CDTransaction.self, id: t.id) else { return }
        adjustBalance(for: Self.transaction(from: cd), factor: -1)
        apply(t, to: cd)
        adjustBalance(for: t, factor: 1)
        persistAndNotify()
    }

    func deleteTransaction(id: UUID) {
        guard let cd = first(CDTransaction.self, id: id) else { return }
        adjustBalance(for: Self.transaction(from: cd), factor: -1)
        stack.context.delete(cd)
        persistAndNotify()
    }

    private func adjustBalance(for t: Transaction, factor: Double) {
        switch t.type {
        case .income:
            updateBalance(id: t.accountId, delta: t.amount * factor)
        case .expense:
            updateBalance(id: t.accountId, delta: -t.amount * factor)
        case .transfer:
            updateBalance(id: t.accountId, delta: -t.amount * factor)
            if let toId = t.toAccountId { updateBalance(id: toId, delta: t.amount * factor) }
        }
    }

    var accounts: [Account] {
        fetchAll(CDAccount.self).map(Self.account(from:))
    }

    func addAccount(_ a: Account) {
        let cd = CDAccount(context: stack.context)
        apply(a, to: cd)
        cd.createdAt = Date()
        persistAndNotify()
    }

    func deleteAccount(id: UUID) {
        guard let cd = first(CDAccount.self, id: id) else { return }
        stack.context.delete(cd)
        persistAndNotify()
    }

    private func updateBalance(id: UUID, delta: Double) {
        guard let cd = first(CDAccount.self, id: id) else { return }
        cd.balance += delta
    }

    var budgets: [Budget] {
        fetchAll(CDBudget.self).map(Self.budget(from:))
    }

    func addBudget(_ b: Budget) {
        let cd = CDBudget(context: stack.context)
        apply(b, to: cd)
        cd.createdAt = Date()
        persistAndNotify()
    }

    func deleteBudget(id: UUID) {
        guard let cd = first(CDBudget.self, id: id) else { return }
        stack.context.delete(cd)
        persistAndNotify()
    }

    var goals: [Goal] {
        fetchAll(CDGoal.self).map(Self.goal(from:))
    }

    func addGoal(_ g: Goal) {
        let cd = CDGoal(context: stack.context)
        apply(g, to: cd)
        cd.createdAt = Date()
        persistAndNotify()
    }

    func updateGoal(_ g: Goal) {
        guard let cd = first(CDGoal.self, id: g.id) else { return }
        apply(g, to: cd)
        persistAndNotify()
    }

    func deleteGoal(id: UUID) {
        guard let cd = first(CDGoal.self, id: id) else { return }
        stack.context.delete(cd)
        persistAndNotify()
    }

    var recurringPayments: [RecurringPayment] {
        fetchAll(CDRecurringPayment.self).map(Self.recurringPayment(from:))
    }

    func addRecurringPayment(_ r: RecurringPayment) {
        let cd = CDRecurringPayment(context: stack.context)
        apply(r, to: cd)
        cd.createdAt = Date()
        persistAndNotify()
    }

    func updateRecurringPayment(_ r: RecurringPayment) {
        guard let cd = first(CDRecurringPayment.self, id: r.id) else { return }
        apply(r, to: cd)
        persistAndNotify()
    }

    func deleteRecurringPayment(id: UUID) {
        guard let cd = first(CDRecurringPayment.self, id: id) else { return }
        stack.context.delete(cd)
        persistAndNotify()
    }

    var debts: [Debt] {
        fetchAll(CDDebt.self).map(Self.debt(from:))
    }

    func addDebt(_ d: Debt) {
        let cd = CDDebt(context: stack.context)
        apply(d, to: cd)
        cd.createdAt = Date()
        persistAndNotify()
    }

    func updateDebt(_ d: Debt) {
        guard let cd = first(CDDebt.self, id: d.id) else { return }
        apply(d, to: cd)
        persistAndNotify()
    }

    func deleteDebt(id: UUID) {
        guard let cd = first(CDDebt.self, id: id) else { return }
        stack.context.delete(cd)
        persistAndNotify()
    }

    var customCategories: [Category] {
        fetchAll(CDCategory.self).map(Self.category(from:))
    }

    func addCategory(_ c: Category) {
        let cd = CDCategory(context: stack.context)
        apply(c, to: cd)
        cd.createdAt = Date()
        persistAndNotify()
    }

    func updateCategory(_ c: Category) {
        guard let cd = first(CDCategory.self, id: c.id) else { return }
        apply(c, to: cd)
        persistAndNotify()
    }

    func deleteCategory(id: UUID) {
        guard let cd = first(CDCategory.self, id: id) else { return }
        stack.context.delete(cd)
        persistAndNotify()
    }

    func categories(for type: TransactionType) -> [Category] {
        let builtIn = type == .income ? Self.incomeCategories : Self.expenseCategories
        return builtIn + customCategories.filter { $0.type == type }
    }

    var totalBalance: Double { accounts.reduce(0) { $0 + $1.balance } }

    var monthlyIncome: Double {
        let cal = Calendar.current; let now = Date()
        return transactions
            .filter { $0.type == .income && cal.isDate($0.date, equalTo: now, toGranularity: .month) }
            .reduce(0) { $0 + $1.amount }
    }

    var monthlyExpense: Double {
        let cal = Calendar.current; let now = Date()
        return transactions
            .filter { $0.type == .expense && cal.isDate($0.date, equalTo: now, toGranularity: .month) }
            .reduce(0) { $0 + $1.amount }
    }

    func monthlySpent(for budget: Budget) -> Double {
        spent(for: budget, granularity: .month)
    }

    func spent(for budget: Budget, granularity: Calendar.Component) -> Double {
        let cal = Calendar.current; let now = Date()
        return transactions
            .filter {
                $0.type == .expense
                    && $0.categoryId == budget.categoryId
                    && cal.isDate($0.date, equalTo: now, toGranularity: granularity)
            }
            .reduce(0) { $0 + $1.amount }
    }

    static let expenseCategories: [Category] = [
        Category(id: UUID(uuidString: "00000000-0000-0000-0000-000000000001")!, name: "Продукти",    icon: "cart.fill",             colorHex: "#FF9500", type: .expense),
        Category(id: UUID(uuidString: "00000000-0000-0000-0000-000000000002")!, name: "Кафе",        icon: "fork.knife",            colorHex: "#5856D6", type: .expense),
        Category(id: UUID(uuidString: "00000000-0000-0000-0000-000000000003")!, name: "Транспорт",   icon: "car.fill",              colorHex: "#34C759", type: .expense),
        Category(id: UUID(uuidString: "00000000-0000-0000-0000-000000000004")!, name: "Розваги",     icon: "gamecontroller.fill",   colorHex: "#0066FF", type: .expense),
        Category(id: UUID(uuidString: "00000000-0000-0000-0000-000000000005")!, name: "Одяг",        icon: "bag.fill",              colorHex: "#FF3B30", type: .expense),
        Category(id: UUID(uuidString: "00000000-0000-0000-0000-000000000006")!, name: "Здоров'я",    icon: "heart.fill",            colorHex: "#FF3B30", type: .expense),
        Category(id: UUID(uuidString: "00000000-0000-0000-0000-000000000007")!, name: "Підписки",    icon: "tv.fill",               colorHex: "#FF3B30", type: .expense),
        Category(id: UUID(uuidString: "00000000-0000-0000-0000-000000000008")!, name: "Інше",        icon: "ellipsis.circle.fill",  colorHex: "#8A8A8E", type: .expense),
    ]

    static let incomeCategories: [Category] = [
        Category(id: UUID(uuidString: "00000000-0000-0000-0000-000000000009")!, name: "Зарплата",   icon: "briefcase.fill",        colorHex: "#34C759", type: .income),
        Category(id: UUID(uuidString: "00000000-0000-0000-0000-000000000010")!, name: "Фріланс",    icon: "laptopcomputer",        colorHex: "#34C759", type: .income),
        Category(id: UUID(uuidString: "00000000-0000-0000-0000-000000000011")!, name: "Подарунок",  icon: "gift.fill",             colorHex: "#34C759", type: .income),
        Category(id: UUID(uuidString: "00000000-0000-0000-0000-000000000012")!, name: "Інше",       icon: "ellipsis.circle.fill",  colorHex: "#8A8A8E", type: .income),
    ]

    static let allCategories: [Category] = expenseCategories + incomeCategories

    func category(for id: UUID) -> Category? {
        (Self.allCategories + customCategories).first(where: { $0.id == id })
    }

    func account(for id: UUID) -> Account? { accounts.first(where: { $0.id == id }) }

    @discardableResult
    func wipeAllData() -> Bool {
        guard stack.wipeAllEntities() else { return false }
        let domain = Bundle.main.bundleIdentifier ?? ""
        defaults.removePersistentDomain(forName: domain)
        defaults.synchronize()
        return true
    }

    func notify() {
        NotificationCenter.default.post(name: Self.dataChangedNotification, object: nil)
    }

    private func persistAndNotify() {
        stack.saveIfNeeded()
        notify()
    }

    private func fetchAll<T: NSManagedObject>(_ type: T.Type,
                                              sortedBy descriptors: [NSSortDescriptor] = [NSSortDescriptor(key: "createdAt", ascending: true)]) -> [T] {
        let request = NSFetchRequest<T>(entityName: String(describing: type))
        request.sortDescriptors = descriptors
        return (try? stack.context.fetch(request)) ?? []
    }

    private func first<T: NSManagedObject>(_ type: T.Type, id: UUID) -> T? {
        let request = NSFetchRequest<T>(entityName: String(describing: type))
        request.predicate = NSPredicate(format: "id == %@", id as CVarArg)
        request.fetchLimit = 1
        return (try? stack.context.fetch(request))?.first
    }

    private static func transaction(from cd: CDTransaction) -> Transaction {
        Transaction(id: cd.id, type: TransactionType(rawValue: cd.type) ?? .expense,
                    amount: cd.amount, categoryId: cd.categoryId, accountId: cd.accountId,
                    toAccountId: cd.toAccountId, date: cd.date, note: cd.note)
    }

    private func apply(_ t: Transaction, to cd: CDTransaction) {
        cd.id = t.id; cd.type = t.type.rawValue; cd.amount = t.amount
        cd.categoryId = t.categoryId; cd.accountId = t.accountId; cd.toAccountId = t.toAccountId
        cd.date = t.date; cd.note = t.note
    }

    private static func account(from cd: CDAccount) -> Account {
        Account(id: cd.id, name: cd.name, typeName: cd.typeName, balance: cd.balance,
                colorHex: cd.colorHex, icon: cd.icon, currency: cd.currency)
    }

    private func apply(_ a: Account, to cd: CDAccount) {
        cd.id = a.id; cd.name = a.name; cd.typeName = a.typeName; cd.balance = a.balance
        cd.colorHex = a.colorHex; cd.icon = a.icon; cd.currency = a.currency
    }

    private static func budget(from cd: CDBudget) -> Budget {
        Budget(id: cd.id, name: cd.name, limit: cd.limit, categoryId: cd.categoryId, colorHex: cd.colorHex)
    }

    private func apply(_ b: Budget, to cd: CDBudget) {
        cd.id = b.id; cd.name = b.name; cd.limit = b.limit
        cd.categoryId = b.categoryId; cd.colorHex = b.colorHex
    }

    private static func goal(from cd: CDGoal) -> Goal {
        Goal(id: cd.id, name: cd.name, target: cd.target, saved: cd.saved,
             colorHex: cd.colorHex, icon: cd.icon)
    }

    private func apply(_ g: Goal, to cd: CDGoal) {
        cd.id = g.id; cd.name = g.name; cd.target = g.target; cd.saved = g.saved
        cd.colorHex = g.colorHex; cd.icon = g.icon
    }

    private static func recurringPayment(from cd: CDRecurringPayment) -> RecurringPayment {
        RecurringPayment(id: cd.id, name: cd.name, amount: cd.amount, nextDate: cd.nextDate,
                         icon: cd.icon, colorHex: cd.colorHex, isPaused: cd.isPaused)
    }

    private func apply(_ r: RecurringPayment, to cd: CDRecurringPayment) {
        cd.id = r.id; cd.name = r.name; cd.amount = r.amount; cd.nextDate = r.nextDate
        cd.icon = r.icon; cd.colorHex = r.colorHex; cd.isPaused = r.isPaused
    }

    private static func debt(from cd: CDDebt) -> Debt {
        Debt(id: cd.id, personName: cd.personName, amount: cd.amount,
             dueDate: cd.dueDate, iOwe: cd.iOwe, note: cd.note)
    }

    private func apply(_ d: Debt, to cd: CDDebt) {
        cd.id = d.id; cd.personName = d.personName; cd.amount = d.amount
        cd.dueDate = d.dueDate; cd.iOwe = d.iOwe; cd.note = d.note
    }

    private static func category(from cd: CDCategory) -> Category {
        Category(id: cd.id, name: cd.name, icon: cd.icon, colorHex: cd.colorHex,
                 type: TransactionType(rawValue: cd.type) ?? .expense)
    }

    private func apply(_ c: Category, to cd: CDCategory) {
        cd.id = c.id; cd.name = c.name; cd.icon = c.icon
        cd.colorHex = c.colorHex; cd.type = c.type.rawValue
    }

    private func migrateFromUserDefaultsIfNeeded() {
        guard !defaults.bool(forKey: "coreDataMigrationDone") else { return }

        let base = Date()
        func stamp(_ i: Int) -> Date { base.addingTimeInterval(Double(i) * 0.001) }

        var importedKeys: [String] = []

        if let old = load([Transaction].self, key: "transactions") {
            for (i, t) in old.enumerated() {
                let cd = CDTransaction(context: stack.context)
                apply(t, to: cd)
                cd.createdAt = stamp(old.count - i)
            }
            importedKeys.append("transactions")
        }
        if let old = load([Account].self, key: "accounts") {
            for (i, a) in old.enumerated() {
                let cd = CDAccount(context: stack.context)
                apply(a, to: cd)
                cd.createdAt = stamp(i)
            }
            importedKeys.append("accounts")
        }
        if let old = load([Budget].self, key: "budgets") {
            for (i, b) in old.enumerated() {
                let cd = CDBudget(context: stack.context)
                apply(b, to: cd)
                cd.createdAt = stamp(i)
            }
            importedKeys.append("budgets")
        }
        if let old = load([Goal].self, key: "goals") {
            for (i, g) in old.enumerated() {
                let cd = CDGoal(context: stack.context)
                apply(g, to: cd)
                cd.createdAt = stamp(i)
            }
            importedKeys.append("goals")
        }
        if let old = load([RecurringPayment].self, key: "recurringPayments") {
            for (i, r) in old.enumerated() {
                let cd = CDRecurringPayment(context: stack.context)
                apply(r, to: cd)
                cd.createdAt = stamp(i)
            }
            importedKeys.append("recurringPayments")
        }
        if let old = load([Debt].self, key: "debts") {
            for (i, d) in old.enumerated() {
                let cd = CDDebt(context: stack.context)
                apply(d, to: cd)
                cd.createdAt = stamp(i)
            }
            importedKeys.append("debts")
        }
        if let old = load([Category].self, key: "customCategories") {
            for (i, c) in old.enumerated() {
                let cd = CDCategory(context: stack.context)
                apply(c, to: cd)
                cd.createdAt = stamp(i)
            }
            importedKeys.append("customCategories")
        }

        do {
            try stack.save()
            importedKeys.forEach { defaults.removeObject(forKey: $0) }
            defaults.set(true, forKey: "coreDataMigrationDone")
        } catch {
            stack.context.reset()
        }
    }

    private func load<T: Decodable>(_ type: T.Type, key: String) -> T? {
        guard let data = defaults.data(forKey: key) else { return nil }
        return try? JSONDecoder().decode(type, from: data)
    }
}
