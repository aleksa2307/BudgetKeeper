import Foundation

// MARK: - Transaction Type

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

// MARK: - Category

struct Category: Codable, Identifiable {
    let id: UUID
    var name: String
    var icon: String
    var colorHex: String
    var type: TransactionType
}

// MARK: - Transaction

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

// MARK: - Account

struct Account: Codable, Identifiable {
    let id: UUID
    var name: String
    var typeName: String
    var balance: Double
    var colorHex: String
    var icon: String
    var currency: String
}

// MARK: - Budget

struct Budget: Codable, Identifiable {
    let id: UUID
    var name: String
    var limit: Double
    var categoryId: UUID
    var colorHex: String
}

// MARK: - Goal

struct Goal: Codable, Identifiable {
    let id: UUID
    var name: String
    var target: Double
    var saved: Double
    var colorHex: String
    var icon: String

    var progress: Double { target > 0 ? min(saved / target, 1.0) : 0 }
}

// MARK: - Recurring Payment

struct RecurringPayment: Codable, Identifiable {
    let id: UUID
    var name: String
    var amount: Double
    var nextDate: Date
    var icon: String
    var colorHex: String
}

// MARK: - Debt

struct Debt: Codable, Identifiable {
    let id: UUID
    var personName: String
    var amount: Double
    var dueDate: Date
    var iOwe: Bool
    var note: String
}
