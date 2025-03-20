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
        let calendar = Calendar.current
        return transactions.filter { transaction in
            let components = calendar.dateComponents([.month, .year], from: transaction.date)
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
    
    // Update transaction method for bulk edit operations
    func updateTransaction(_ transaction: Transaction) {
        if let index = transactions.firstIndex(where: { $0.id == transaction.id }) {
            transactions[index] = transaction
            saveTransactions()
        }
    }
    
    // Remove transaction by ID
    func removeTransaction(withID id: UUID) {
        transactions.removeAll(where: { $0.id == id })
        saveTransactions()
    }
    
    // Add a recurring transaction
    func addRecurringTransaction(_ transaction: Transaction, frequency: RecurringFrequency, endDate: Date?) {
        let recurringTransaction = RecurringTransaction(
            baseTransaction: transaction,
            frequency: frequency,
            startDate: transaction.date,
            endDate: endDate
        )
        
        // Save recurring transaction
        saveRecurringTransaction(recurringTransaction)
        
        // Also add the first instance as a regular transaction
        addTransaction(transaction)
    }
    
    // Process recurring transactions (call this on app launch and periodically)
    func processRecurringTransactions() {
        let today = Date()
        let calendar = Calendar.current
        
        for recurringTransaction in loadRecurringTransactions() {
            // Calculate next occurrence date
            if let nextDate = calculateNextOccurrence(for: recurringTransaction, after: today) {
                // Check if next date is still within bounds
                if let endDate = recurringTransaction.endDate, nextDate > endDate {
                    continue
                }
                
                // Create a new transaction based on recurring template
                var newTransaction = recurringTransaction.baseTransaction
                newTransaction.id = UUID() // New unique ID
                newTransaction.date = nextDate
                
                // Add transaction
                addTransaction(newTransaction)
                
                // Update lastProcessedDate to current date
                updateLastProcessedDate(for: recurringTransaction.id, to: today)
            }
        }
    }
    
    // Helper method to calculate next occurrence
    private func calculateNextOccurrence(for recurringTransaction: RecurringTransaction, after date: Date) -> Date? {
        let calendar = Calendar.current
        let startDate = recurringTransaction.startDate
        let lastProcessed = recurringTransaction.lastProcessedDate ?? startDate
        
        // If lastProcessed is after the reference date, no new transaction needed yet
        if lastProcessed > date {
            return nil
        }
        
        // Calculate next date based on frequency
        var nextDate: Date?
        var dateComponents = DateComponents()
        
        switch recurringTransaction.frequency {
        case .daily:
            dateComponents.day = 1
        case .weekly:
            dateComponents.day = 7
        case .biweekly:
            dateComponents.day = 14
        case .monthly:
            dateComponents.month = 1
        case .quarterly:
            dateComponents.month = 3
        case .yearly:
            dateComponents.year = 1
        }
        
        nextDate = calendar.date(byAdding: dateComponents, to: lastProcessed)
        return nextDate
    }
    
    // Persistence for recurring transactions
    private func saveRecurringTransaction(_ recurringTransaction: RecurringTransaction) {
        var recurringTransactions = loadRecurringTransactions()
        
        // Update if exists, otherwise add
        if let index = recurringTransactions.firstIndex(where: { $0.id == recurringTransaction.id }) {
            recurringTransactions[index] = recurringTransaction
        } else {
            recurringTransactions.append(recurringTransaction)
        }
        
        if let encodedData = try? JSONEncoder().encode(recurringTransactions) {
            UserDefaults.standard.set(encodedData, forKey: "recurringTransactions")
        }
    }
    
    private func loadRecurringTransactions() -> [RecurringTransaction] {
        if let savedData = UserDefaults.standard.data(forKey: "recurringTransactions"),
           let decodedTransactions = try? JSONDecoder().decode([RecurringTransaction].self, from: savedData) {
            return decodedTransactions
        }
        return []
    }
    
    private func updateLastProcessedDate(for id: UUID, to date: Date) {
        var recurringTransactions = loadRecurringTransactions()
        if let index = recurringTransactions.firstIndex(where: { $0.id == id }) {
            recurringTransactions[index].lastProcessedDate = date
            
            if let encodedData = try? JSONEncoder().encode(recurringTransactions) {
                UserDefaults.standard.set(encodedData, forKey: "recurringTransactions")
            }
        }
    }
} 