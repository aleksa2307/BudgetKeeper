import Foundation

final class DataStore {
    static let shared = DataStore()
    private let defaults = UserDefaults.standard

    static let dataChangedNotification = Notification.Name("DataStoreDataChanged")

    private init() {}

    // MARK: - PIN

    var pin: String? {
        get { defaults.string(forKey: "pin") }
        set { defaults.set(newValue, forKey: "pin") }
    }

    var isPINSet: Bool { !(pin?.isEmpty ?? true) }

    // MARK: - Settings

    var userName: String {
        get { defaults.string(forKey: "userName") ?? "Користувач" }
        set { defaults.set(newValue, forKey: "userName") }
    }

    var isFaceIDEnabled: Bool {
        get { defaults.bool(forKey: "faceIDEnabled") }
        set { defaults.set(newValue, forKey: "faceIDEnabled") }
    }

    // MARK: - Transactions

    var transactions: [Transaction] {
        get { load([Transaction].self, key: "transactions") ?? [] }
        set { save(newValue, key: "transactions") }
    }

    func addTransaction(_ t: Transaction) {
        var list = transactions
        list.insert(t, at: 0)
        transactions = list
        adjustBalance(for: t, factor: 1)
        notify()
    }

    func deleteTransaction(id: UUID) {
        guard let idx = transactions.firstIndex(where: { $0.id == id }) else { return }
        let t = transactions[idx]
        adjustBalance(for: t, factor: -1)
        var list = transactions
        list.remove(at: idx)
        transactions = list
        notify()
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

    // MARK: - Accounts

    var accounts: [Account] {
        get { load([Account].self, key: "accounts") ?? [] }
        set { save(newValue, key: "accounts") }
    }

    func addAccount(_ a: Account) {
        var list = accounts; list.append(a); accounts = list; notify()
    }

    func deleteAccount(id: UUID) {
        accounts = accounts.filter { $0.id != id }; notify()
    }

    private func updateBalance(id: UUID, delta: Double) {
        var list = accounts
        guard let idx = list.firstIndex(where: { $0.id == id }) else { return }
        list[idx].balance += delta
        accounts = list
    }

    // MARK: - Budgets

    var budgets: [Budget] {
        get { load([Budget].self, key: "budgets") ?? [] }
        set { save(newValue, key: "budgets") }
    }

    func addBudget(_ b: Budget) {
        var list = budgets; list.append(b); budgets = list; notify()
    }

    func deleteBudget(id: UUID) {
        budgets = budgets.filter { $0.id != id }; notify()
    }

    // MARK: - Goals

    var goals: [Goal] {
        get { load([Goal].self, key: "goals") ?? [] }
        set { save(newValue, key: "goals") }
    }

    func addGoal(_ g: Goal) {
        var list = goals; list.append(g); goals = list; notify()
    }

    func updateGoal(_ g: Goal) {
        var list = goals
        guard let idx = list.firstIndex(where: { $0.id == g.id }) else { return }
        list[idx] = g; goals = list; notify()
    }

    func deleteGoal(id: UUID) {
        goals = goals.filter { $0.id != id }; notify()
    }

    // MARK: - Recurring Payments

    var recurringPayments: [RecurringPayment] {
        get { load([RecurringPayment].self, key: "recurringPayments") ?? [] }
        set { save(newValue, key: "recurringPayments") }
    }

    func addRecurringPayment(_ r: RecurringPayment) {
        var list = recurringPayments; list.append(r); recurringPayments = list; notify()
    }

    func deleteRecurringPayment(id: UUID) {
        recurringPayments = recurringPayments.filter { $0.id != id }; notify()
    }

    // MARK: - Debts

    var debts: [Debt] {
        get { load([Debt].self, key: "debts") ?? [] }
        set { save(newValue, key: "debts") }
    }

    func addDebt(_ d: Debt) {
        var list = debts; list.append(d); debts = list; notify()
    }

    func deleteDebt(id: UUID) {
        debts = debts.filter { $0.id != id }; notify()
    }

    // MARK: - Computed Analytics

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
        let cal = Calendar.current; let now = Date()
        return transactions
            .filter {
                $0.type == .expense
                    && $0.categoryId == budget.categoryId
                    && cal.isDate($0.date, equalTo: now, toGranularity: .month)
            }
            .reduce(0) { $0 + $1.amount }
    }

    // MARK: - Categories (built-in, stable UUIDs)

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

    func category(for id: UUID) -> Category? { Self.allCategories.first(where: { $0.id == id }) }
    func account(for id: UUID)  -> Account?  { accounts.first(where: { $0.id == id }) }

    // MARK: - Persistence

    func notify() {
        NotificationCenter.default.post(name: Self.dataChangedNotification, object: nil)
    }

    private func load<T: Decodable>(_ type: T.Type, key: String) -> T? {
        guard let data = defaults.data(forKey: key) else { return nil }
        return try? JSONDecoder().decode(type, from: data)
    }

    private func save<T: Encodable>(_ value: T, key: String) {
        defaults.set(try? JSONEncoder().encode(value), forKey: key)
    }
}
