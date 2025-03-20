//
//  Transaction.swift
//  Muni
//
//  Created by Yaduraj Singh on 20/03/25.
//

import Foundation

enum TransactionType: String, Codable, CaseIterable {
    case income = "Income"
    case expense = "Expense"
}

enum TransactionCategory: String, Codable, CaseIterable {
    // Income categories
    case salary = "Salary"
    case investment = "Investment"
    case gift = "Gift"
    case other = "Other"
    
    // Expense categories
    case food = "Food"
    case transportation = "Transportation"
    case entertainment = "Entertainment"
    case shopping = "Shopping"
    case bills = "Bills"
    case health = "Health"
    case education = "Education"
    case travel = "Travel"
    case miscellaneous = "Miscellaneous"
    
    var icon: String {
        switch self {
        case .salary: return "banknote"
        case .investment: return "chart.line.uptrend.xyaxis"
        case .gift: return "gift"
        case .other: return "ellipsis.circle"
        case .food: return "fork.knife"
        case .transportation: return "car"
        case .entertainment: return "tv"
        case .shopping: return "bag"
        case .bills: return "doc.text"
        case .health: return "heart"
        case .education: return "book"
        case .travel: return "airplane"
        case .miscellaneous: return "ellipsis"
        }
    }
    
    static func expenseCategories() -> [TransactionCategory] {
        return [.food, .transportation, .entertainment, .shopping, .bills, .health, .education, .travel, .miscellaneous]
    }
    
    static func incomeCategories() -> [TransactionCategory] {
        return [.salary, .investment, .gift, .other]
    }
}

struct Transaction: Identifiable, Codable {
    var id: UUID = UUID()
    var amount: Double
    var type: TransactionType
    var category: TransactionCategory
    var date: Date
    var note: String
} 