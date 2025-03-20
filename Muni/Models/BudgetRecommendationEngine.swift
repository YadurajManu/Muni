//
//  BudgetRecommendationEngine.swift
//  Muni
//
//  Created by Yaduraj Singh on 20/03/25.
//

import Foundation

struct BudgetAllocation {
    var category: TransactionCategory
    var amount: Double
    var percentage: Double
}

class BudgetRecommendationEngine {
    static let shared = BudgetRecommendationEngine()
    
    private init() {}
    
    // Main method to generate budget recommendations
    func generateRecommendations(
        monthlyIncome: Double,
        selectedGoal: String,
        primaryExpenseCategory: TransactionCategory,
        recentTransactions: [Transaction]
    ) -> [BudgetAllocation] {
        
        // Base allocation percentages
        var baseAllocations: [TransactionCategory: Double] = [
            .food: 0.25,
            .transportation: 0.15,
            .housing: 0.30,
            .entertainment: 0.05,
            .shopping: 0.05,
            .bills: 0.10,
            .health: 0.05,
            .education: 0.03,
            .travel: 0.02,
            .miscellaneous: 0.05
        ]
        
        // Adjust based on financial goal
        adjustForFinancialGoal(allocations: &baseAllocations, goal: selectedGoal)
        
        // Adjust based on primary expense category
        adjustForPrimaryExpenseCategory(allocations: &baseAllocations, category: primaryExpenseCategory)
        
        // Adjust based on transaction history if available
        if !recentTransactions.isEmpty {
            adjustForTransactionHistory(allocations: &baseAllocations, transactions: recentTransactions)
        }
        
        // Normalize percentages to ensure they sum to 100%
        normalizeAllocations(allocations: &baseAllocations)
        
        // Convert to budget allocations
        return baseAllocations.map { category, percentage in
            BudgetAllocation(
                category: category,
                amount: monthlyIncome * percentage,
                percentage: percentage * 100
            )
        }.sorted { $0.amount > $1.amount }
    }
    
    // Adjust allocations based on financial goal
    private func adjustForFinancialGoal(allocations: inout [TransactionCategory: Double], goal: String) {
        let savingsCategory: TransactionCategory = .miscellaneous // Using misc for savings
        var savingsIncrease: Double = 0
        
        switch goal {
        case "Save for an emergency fund":
            savingsIncrease = 0.15
            
        case "Pay off debt":
            savingsIncrease = 0.20
            
        case "Save for a major purchase":
            savingsIncrease = 0.15
            
        case "Build investment portfolio":
            savingsIncrease = 0.20
            
        case "Track day-to-day expenses":
            savingsIncrease = 0.05
            
        case "Reduce unnecessary spending":
            // Reduce entertainment and shopping
            allocations[.entertainment] = (allocations[.entertainment] ?? 0) * 0.5
            allocations[.shopping] = (allocations[.shopping] ?? 0) * 0.5
            savingsIncrease = 0.10
            
        case "Financial independence":
            savingsIncrease = 0.25
            
        default:
            savingsIncrease = 0.10
        }
        
        // Apply savings increase
        if savingsIncrease > 0 {
            // First reduce the other categories proportionally
            let totalToReduce = savingsIncrease
            let totalCurrentAllocation = allocations.values.reduce(0, +)
            
            for (category, value) in allocations {
                if category != savingsCategory {
                    let reductionFactor = (value / totalCurrentAllocation) * totalToReduce
                    allocations[category] = value - reductionFactor
                }
            }
            
            // Then increase the savings
            allocations[savingsCategory] = (allocations[savingsCategory] ?? 0) + savingsIncrease
        }
    }
    
    // Adjust based on user's primary expense category
    private func adjustForPrimaryExpenseCategory(allocations: inout [TransactionCategory: Double], category: TransactionCategory) {
        // If the user has selected a category, reduce that by 10% to optimize
        if let currentAllocation = allocations[category], currentAllocation > 0.15 {
            let reduction = currentAllocation * 0.1
            allocations[category] = currentAllocation - reduction
            
            // Redistribute to savings
            allocations[.miscellaneous] = (allocations[.miscellaneous] ?? 0) + reduction
        }
    }
    
    // Adjust based on transaction history
    private func adjustForTransactionHistory(allocations: inout [TransactionCategory: Double], transactions: [Transaction]) {
        // Calculate the current spending distribution
        var currentSpending: [TransactionCategory: Double] = [:]
        var totalSpent: Double = 0
        
        for transaction in transactions where transaction.type == .expense {
            currentSpending[transaction.category] = (currentSpending[transaction.category] ?? 0) + transaction.amount
            totalSpent += transaction.amount
        }
        
        // Skip if no expenses
        if totalSpent == 0 {
            return
        }
        
        // Convert to percentages
        for (category, amount) in currentSpending {
            currentSpending[category] = amount / totalSpent
        }
        
        // Blend current spending with recommendations (70% recommendation, 30% actual spending)
        for (category, currentPercentage) in currentSpending {
            if let recommendedPercentage = allocations[category] {
                allocations[category] = (recommendedPercentage * 0.7) + (currentPercentage * 0.3)
            }
        }
    }
    
    // Normalize allocations to ensure they sum to 1.0
    private func normalizeAllocations(allocations: inout [TransactionCategory: Double]) {
        let total = allocations.values.reduce(0, +)
        
        if total > 0 && abs(total - 1.0) > 0.001 { // Only normalize if not already close to 1.0
            for (category, value) in allocations {
                allocations[category] = value / total
            }
        }
    }
    
    // Generate a savings plan based on goal amount and timeframe
    func generateSavingsPlan(
        targetAmount: Double,
        monthsToTarget: Int,
        monthlyIncome: Double
    ) -> (monthlyContribution: Double, isRealistic: Bool, adjustedMonths: Int) {
        
        let idealMonthlyContribution = targetAmount / Double(monthsToTarget)
        
        // Check if this contribution is realistic (less than 50% of income)
        let maxRealisticContribution = monthlyIncome * 0.5
        
        if idealMonthlyContribution <= maxRealisticContribution {
            return (idealMonthlyContribution, true, monthsToTarget)
        } else {
            // If not realistic, suggest a longer timeframe
            let adjustedMonths = Int(ceil(targetAmount / maxRealisticContribution))
            return (maxRealisticContribution, false, adjustedMonths)
        }
    }
} 