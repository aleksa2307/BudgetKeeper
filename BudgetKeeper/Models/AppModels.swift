import Foundation

enum TransactionType: String, Codable, CaseIterable {
    case expense, income, transfer

    var displayName: String {
        switch self {
        case .expense: return "Витрата"
        case .income: return "Дохід"
        case .transfer: return "Переказ"
        }
    }
}

struct Category: Codable, Identifiable {
    let id: UUID
    var name: String
    var icon: String
    var colorHex: String
    var type: TransactionType
}

struct Transaction: Codable, Identifiable {
    let id: UUID
    var type: TransactionType
    var amount: Double
    var categoryId: UUID
    var accountId: UUID
    var toAccountId: UUID?
    var date: Date
    var note: String
}

struct Account: Codable, Identifiable {
    let id: UUID
    var name: String
    var typeName: String
    var balance: Double
    var colorHex: String
    var icon: String
    var currency: String
}

struct Budget: Codable, Identifiable {
    let id: UUID
    var name: String
    var limit: Double
    var categoryId: UUID
    var colorHex: String
}

struct Goal: Codable, Identifiable {
    let id: UUID
    var name: String
    var target: Double
    var saved: Double
    var colorHex: String
    var icon: String

    var progress: Double { target > 0 ? min(saved / target, 1.0) : 0 }
}

struct RecurringPayment: Codable, Identifiable {
    let id: UUID
    var name: String
    var amount: Double
    var nextDate: Date
    var icon: String
    var colorHex: String
    var isPaused: Bool

    init(id: UUID, name: String, amount: Double, nextDate: Date,
         icon: String, colorHex: String, isPaused: Bool = false) {
        self.id = id
        self.name = name
        self.amount = amount
        self.nextDate = nextDate
        self.icon = icon
        self.colorHex = colorHex
        self.isPaused = isPaused
    }

    init(from decoder: Decoder) throws {
        let c = try decoder.container(keyedBy: CodingKeys.self)
        id = try c.decode(UUID.self, forKey: .id)
        name = try c.decode(String.self, forKey: .name)
        amount = try c.decode(Double.self, forKey: .amount)
        nextDate = try c.decode(Date.self, forKey: .nextDate)
        icon = try c.decode(String.self, forKey: .icon)
        colorHex = try c.decode(String.self, forKey: .colorHex)
        isPaused = try c.decodeIfPresent(Bool.self, forKey: .isPaused) ?? false
    }
}

struct Debt: Codable, Identifiable {
    let id: UUID
    var personName: String
    var amount: Double
    var dueDate: Date
    var iOwe: Bool
    var note: String
}
