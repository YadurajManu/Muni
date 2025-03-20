//
//  TransactionManager.swift
//  Muni
//
//  Created by Yaduraj Singh on 20/03/25.
//

import Foundation
import SwiftUI

class TransactionManager: ObservableObject {
    @Published var transactions: [Transaction] = []
    private let transactionsKey = "savedTransactions"
    
    init() {
        loadTransactions()
    }
    
    func addTransaction(_ transaction: Transaction) {
        transactions.append(transaction)
        saveTransactions()
    }
    
    func deleteTransaction(at indexSet: IndexSet) {
        transactions.remove(atOffsets: indexSet)
        saveTransactions()
    }
    
    func deleteTransaction(withID id: UUID) {
        if let index = transactions.firstIndex(where: { $0.id == id }) {
            transactions.remove(at: index)
            saveTransactions()
        }
    }
    
    func saveTransactions() {
        if let encoded = try? JSONEncoder().encode(transactions) {
            UserDefaults.standard.set(encoded, forKey: transactionsKey)
        }
    }
    
    func loadTransactions() {
        if let savedTransactions = UserDefaults.standard.data(forKey: transactionsKey) {
            if let decodedTransactions = try? JSONDecoder().decode([Transaction].self, from: savedTransactions) {
                self.transactions = decodedTransactions
                return
            }
        }
        
        // Initialize with empty transactions array instead of mock data
        self.transactions = []
    }
    
    // Helper methods to get summary information
    func totalIncome() -> Double {
        transactions.filter { $0.type == .income }.map { $0.amount }.reduce(0, +)
    }
    
    func totalExpense() -> Double {
        transactions.filter { $0.type == .expense }.map { $0.amount }.reduce(0, +)
    }
    
    func balance() -> Double {
        totalIncome() - totalExpense()
    }
    
    func getTransactionsForMonth(month: Int, year: Int) -> [Transaction] {
        return transactions.filter { transaction in
            let components = Calendar.current.dateComponents([.month, .year], from: transaction.date)
            return components.month == month && components.year == year
        }
    }
    
    func getMonthlyExpensesByCategory(month: Int, year: Int) -> [TransactionCategory: Double] {
        let monthlyTransactions = getTransactionsForMonth(month: month, year: year)
        var expensesByCategory: [TransactionCategory: Double] = [:]
        
        for category in TransactionCategory.expenseCategories() {
            let total = monthlyTransactions
                .filter { $0.type == .expense && $0.category == category }
                .map { $0.amount }
                .reduce(0, +)
            
            expensesByCategory[category] = total
        }
        
        return expensesByCategory
    }
    
    // Add a method to get the top expense category
    func getTopExpenseCategory() -> (TransactionCategory?, Double) {
        let expensesByCategory = transactions
            .filter { $0.type == .expense }
            .reduce(into: [TransactionCategory: Double]()) { result, transaction in
                result[transaction.category, default: 0] += transaction.amount
            }
        
        if let topCategory = expensesByCategory.max(by: { $0.value < $1.value }) {
            return (topCategory.key, topCategory.value)
        }
        
        return (nil, 0)
    }
    
    // Add a method to get monthly expenses for a specific month and year
    func getMonthlyExpenses(for month: Int, year: Int) -> Double {
        let monthlyTransactions = getTransactionsForMonth(month: month, year: year)
        return monthlyTransactions
            .filter { $0.type == .expense }
            .reduce(0) { $0 + $1.amount }
    }
} 