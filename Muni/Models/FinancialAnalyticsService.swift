//
//  FinancialAnalyticsService.swift
//  Muni
//
//  Created by Yaduraj Singh on 20/03/25.
//

import Foundation

struct CategoryAnalytics {
    var category: TransactionCategory
    var currentAmount: Double
    var previousAmount: Double
    var percentageChange: Double
    var trend: TrendDirection
}

struct MonthlySpendingAnalytics {
    var month: Int
    var year: Int
    var totalExpense: Double
    var totalIncome: Double
    var categories: [CategoryAnalytics]
}

enum TrendDirection: String {
    case increasing
    case decreasing
    case stable
    
    var icon: String {
        switch self {
        case .increasing: return "arrow.up.right"
        case .decreasing: return "arrow.down.right"
        case .stable: return "arrow.right"
        }
    }
    
    var color: String {
        switch self {
        case .increasing: return "ExpenseColor" // Red
        case .decreasing: return "IncomeColor"  // Green
        case .stable: return "PrimaryColor"     // Blue
        }
    }
}

class FinancialAnalyticsService {
    static let shared = FinancialAnalyticsService()
    
    private init() {}
    
    // Helper function to determine if a date is in the current year
    private func isDateInThisYear(date: Date, calendar: Calendar = Calendar.current) -> Bool {
        let today = Date()
        let todayComponents = calendar.dateComponents([.year], from: today)
        let dateComponents = calendar.dateComponents([.year], from: date)
        
        return todayComponents.year == dateComponents.year
    }
    
    // Calculate progress toward a financial goal
    func calculateGoalProgress(transactions: [Transaction], goal: String, monthlyIncome: Double) -> Double {
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "yyyy-MM"
        
        // Group transactions by month
        let calendar = Calendar.current
        var goalProgress: Double = 0
        
        switch goal {
        case "Save for an emergency fund":
            // Track savings transactions marked as miscellaneous or with notes containing "savings"/"emergency"
            let savingsTransactions = transactions.filter { transaction in
                let isIncome = transaction.type == .income
                let isRecent = isDateInThisYear(date: transaction.date)
                let isSavings = transaction.category == .miscellaneous || 
                                transaction.note.lowercased().contains("savings") ||
                                transaction.note.lowercased().contains("emergency")
                
                return isIncome && isRecent && isSavings
            }
            
            // Calculate total saved amount
            let totalSaved = savingsTransactions.reduce(0) { $0 + $1.amount }
            
            // Target is typically 3-6 months of expenses. Using 3 months of income as a benchmark
            let targetAmount = monthlyIncome * 3
            
            return min(1.0, targetAmount > 0 ? totalSaved / targetAmount : 0)
            
        case "Pay off debt":
            // Identify debt payments (bills category with "loan", "debt", "emi", etc. in the note)
            let debtPayments = transactions.filter { transaction in
                let isExpense = transaction.type == .expense
                let isRecentPayment = isDateInThisYear(date: transaction.date)
                let isDebtPayment = transaction.category == .bills && 
                                   (transaction.note.lowercased().contains("loan") ||
                                    transaction.note.lowercased().contains("debt") ||
                                    transaction.note.lowercased().contains("emi") ||
                                    transaction.note.lowercased().contains("payment"))
                
                return isExpense && isRecentPayment && isDebtPayment
            }
            
            // Assuming a 12-month debt repayment plan (based on available data)
            let totalPaid = debtPayments.reduce(0) { $0 + $1.amount }
            let estimatedTotalDebt = monthlyIncome * 0.5 * 12 // Assuming 50% of monthly income for 12 months
            
            return min(1.0, estimatedTotalDebt > 0 ? totalPaid / estimatedTotalDebt : 0)
            
        case "Save for a major purchase":
            // Identify savings specifically for major purchase
            let savingsTransactions = transactions.filter { transaction in
                let isIncome = transaction.type == .income
                let isRecent = isDateInThisYear(date: transaction.date)
                let isSavings = transaction.category == .miscellaneous || 
                                transaction.note.lowercased().contains("savings") ||
                                transaction.note.lowercased().contains("purchase")
                
                return isIncome && isRecent && isSavings
            }
            
            let totalSaved = savingsTransactions.reduce(0) { $0 + $1.amount }
            
            // Target amount (assuming a major purchase costs approximately 6 months of income)
            let targetAmount = monthlyIncome * 6
            
            return min(1.0, targetAmount > 0 ? totalSaved / targetAmount : 0)
            
        case "Build investment portfolio":
            // Identify investment transactions
            let investmentTransactions = transactions.filter { transaction in
                let isIncome = transaction.type == .income
                let isInvestment = transaction.category == .investment || 
                                   transaction.note.lowercased().contains("invest") ||
                                   transaction.note.lowercased().contains("portfolio")
                
                return isIncome && isInvestment
            }
            
            let totalInvested = investmentTransactions.reduce(0) { $0 + $1.amount }
            
            // Target: 1 year of income in investments
            let targetAmount = monthlyIncome * 12
            
            return min(1.0, targetAmount > 0 ? totalInvested / targetAmount : 0)
            
        case "Track day-to-day expenses":
            // For tracking goals, progress is based on consistent tracking
            // Calculate the percentage of days in the last month with at least one transaction
            
            let now = Date()
            let startOfLastMonth = calendar.date(byAdding: .month, value: -1, to: calendar.startOfDay(for: now))!
            let endOfLastMonth = calendar.date(byAdding: .month, value: 1, to: startOfLastMonth)!
            
            // Get transactions from last month
            let lastMonthTransactions = transactions.filter { 
                $0.date >= startOfLastMonth && $0.date < endOfLastMonth
            }
            
            // Group by day
            let daysWithTransactions = Set(lastMonthTransactions.map { 
                calendar.startOfDay(for: $0.date)
            })
            
            // Count days in last month
            let daysInLastMonth = calendar.range(of: .day, in: .month, for: startOfLastMonth)?.count ?? 30
            
            // Calculate percentage of days with transactions
            return min(1.0, Double(daysWithTransactions.count) / Double(daysInLastMonth))
            
        case "Reduce unnecessary spending":
            // Compare current month's discretionary spending with previous month
            let currentDate = Date()
            
            guard let startOfCurrentMonth = calendar.date(byAdding: .day, value: 1 - calendar.component(.day, from: currentDate), to: currentDate),
                  let startOfPreviousMonth = calendar.date(byAdding: .month, value: -1, to: startOfCurrentMonth) else {
                return 0
            }
            
            // Discretionary categories
            let discretionaryCategories: [TransactionCategory] = [.entertainment, .shopping, .travel]
            
            // Previous month's discretionary spending
            let previousMonthTransactions = transactions.filter {
                $0.date >= startOfPreviousMonth && $0.date < startOfCurrentMonth &&
                $0.type == .expense && discretionaryCategories.contains($0.category)
            }
            
            let previousDiscretionaryTotal = previousMonthTransactions.reduce(0) { $0 + $1.amount }
            
            // Current month's discretionary spending
            let currentMonthTransactions = transactions.filter {
                $0.date >= startOfCurrentMonth && $0.date <= currentDate &&
                $0.type == .expense && discretionaryCategories.contains($0.category)
            }
            
            let currentDiscretionaryTotal = currentMonthTransactions.reduce(0) { $0 + $1.amount }
            
            // If no data from previous month, assume 50% progress
            if previousDiscretionaryTotal == 0 {
                return 0.5
            }
            
            // Calculate percentage decrease (or increase)
            let decreaseRatio = (previousDiscretionaryTotal - currentDiscretionaryTotal) / previousDiscretionaryTotal
            
            // Target is 20% reduction, so 20% reduction = 100% goal completion
            let normalizedProgress = decreaseRatio / 0.2
            
            return min(1.0, max(0, normalizedProgress))
            
        case "Financial independence":
            // Financial independence = having emergency fund + investments + regular income
            
            // Check emergency fund
            let emergencyFundTransactions = transactions.filter {
                $0.type == .income && ($0.category == .miscellaneous || 
                                       $0.note.lowercased().contains("emergency") || 
                                       $0.note.lowercased().contains("savings"))
            }
            
            let emergencyFundTotal = emergencyFundTransactions.reduce(0) { $0 + $1.amount }
            let emergencyFundTarget = monthlyIncome * 6
            let emergencyFundProgress = min(1.0, emergencyFundTarget > 0 ? emergencyFundTotal / emergencyFundTarget : 0)
            
            // Check investments
            let investmentTransactions = transactions.filter {
                $0.type == .income && ($0.category == .investment || 
                                       $0.note.lowercased().contains("invest"))
            }
            
            let investmentTotal = investmentTransactions.reduce(0) { $0 + $1.amount }
            let investmentTarget = monthlyIncome * 24
            let investmentProgress = min(1.0, investmentTarget > 0 ? investmentTotal / investmentTarget : 0)
            
            // Check passive income
            let passiveIncomeTransactions = transactions.filter {
                $0.type == .income && ($0.category == .investment || 
                                       $0.note.lowercased().contains("passive") || 
                                       $0.note.lowercased().contains("dividend"))
            }
            
            let monthlyPassiveIncome = passiveIncomeTransactions.count > 0 ? passiveIncomeTransactions.reduce(0) { $0 + $1.amount } / Double(passiveIncomeTransactions.count) : 0
            let passiveIncomeTarget = monthlyIncome * 0.5
            let passiveIncomeProgress = min(1.0, passiveIncomeTarget > 0 ? monthlyPassiveIncome / passiveIncomeTarget : 0)
            
            // Financial independence progress (weighted average)
            return (emergencyFundProgress * 0.3) + (investmentProgress * 0.4) + (passiveIncomeProgress * 0.3)
            
        default:
            // For any other goals, track general savings
            let savingsTransactions = transactions.filter {
                $0.type == .income && $0.category == .miscellaneous
            }
            
            let totalSaved = savingsTransactions.reduce(0) { $0 + $1.amount }
            let targetAmount = monthlyIncome * 6
            
            return min(1.0, targetAmount > 0 ? totalSaved / targetAmount : 0)
        }
    }
    
    // Calculate time to reach financial goal
    func calculateMonthsToGoal(transactions: [Transaction], goal: String, monthlyIncome: Double) -> Int {
        let currentProgress = calculateGoalProgress(transactions: transactions, goal: goal, monthlyIncome: monthlyIncome)
        let monthlyProgress = calculateMonthlyProgressRate(transactions: transactions, goal: goal, monthlyIncome: monthlyIncome)
        
        if monthlyProgress <= 0 {
            return 36 // Default to 3 years if no progress is being made
        }
        
        let remainingProgress = 1.0 - currentProgress
        let monthsRemaining = Int(ceil(remainingProgress / monthlyProgress))
        
        return monthsRemaining
    }
    
    // Calculate monthly progress rate
    private func calculateMonthlyProgressRate(transactions: [Transaction], goal: String, monthlyIncome: Double) -> Double {
        let calendar = Calendar.current
        let currentDate = Date()
        
        // Get transactions from last 3 months to analyze trend
        guard let threeMonthsAgo = calendar.date(byAdding: .month, value: -3, to: currentDate) else {
            return 0.01 // Default progress rate (1% per month)
        }
        
        // Filter relevant transactions
        let relevantTransactions = transactions.filter { $0.date >= threeMonthsAgo }
        
        if relevantTransactions.isEmpty {
            return 0.01 // Default if no transactions
        }
        
        // Calculate progress at the start of period
        let oldProgress = calculateGoalProgress(transactions: transactions.filter { $0.date <= threeMonthsAgo }, 
                                               goal: goal, 
                                               monthlyIncome: monthlyIncome)
        
        // Calculate current progress
        let currentProgress = calculateGoalProgress(transactions: transactions, 
                                                  goal: goal, 
                                                  monthlyIncome: monthlyIncome)
        
        // Calculate monthly rate
        let progressDifference = currentProgress - oldProgress
        let monthlyRate = progressDifference / 3.0 // Divide by 3 months
        
        // If progress is negative or too small, use a default minimum rate
        return max(0.01, monthlyRate)
    }
    
    // Analyze spending by category and detect trends
    func analyzeSpendingTrends(transactions: [Transaction], timeframeMonths: Int = 3) -> [CategoryAnalytics] {
        let calendar = Calendar.current
        let currentDate = Date()
        
        // Calculate start of current and previous period
        guard let startOfCurrentPeriod = calendar.date(byAdding: .month, value: -timeframeMonths, to: currentDate),
              let startOfPreviousPeriod = calendar.date(byAdding: .month, value: -timeframeMonths * 2, to: currentDate) else {
            return []
        }
        
        // Get expense transactions for both periods
        let currentPeriodTransactions = transactions.filter {
            $0.type == .expense && $0.date >= startOfCurrentPeriod && $0.date <= currentDate
        }
        
        let previousPeriodTransactions = transactions.filter {
            $0.type == .expense && $0.date >= startOfPreviousPeriod && $0.date < startOfCurrentPeriod
        }
        
        var categoryAnalytics: [CategoryAnalytics] = []
        
        // Analyze each expense category
        for category in TransactionCategory.expenseCategories() {
            // Calculate totals for both periods
            let currentAmount = currentPeriodTransactions
                .filter { $0.category == category }
                .reduce(0) { $0 + $1.amount }
            
            let previousAmount = previousPeriodTransactions
                .filter { $0.category == category }
                .reduce(0) { $0 + $1.amount }
            
            // Calculate percentage change and trend
            var percentageChange: Double = 0
            var trend: TrendDirection = .stable
            
            if previousAmount > 0 {
                percentageChange = ((currentAmount - previousAmount) / previousAmount) * 100
                
                if percentageChange > 5 {
                    trend = .increasing
                } else if percentageChange < -5 {
                    trend = .decreasing
                } else {
                    trend = .stable
                }
            } else if currentAmount > 0 {
                // If no previous spending but current spending exists, it's increasing
                percentageChange = 100
                trend = .increasing
            }
            
            // Only include categories with spending
            if currentAmount > 0 || previousAmount > 0 {
                categoryAnalytics.append(CategoryAnalytics(
                    category: category,
                    currentAmount: currentAmount,
                    previousAmount: previousAmount,
                    percentageChange: percentageChange,
                    trend: trend
                ))
            }
        }
        
        // Sort by current amount descending
        return categoryAnalytics.sorted { $0.currentAmount > $1.currentAmount }
    }
    
    // Find smart insights based on spending analytics
    func generateSmartInsights(transactions: [Transaction], monthlyIncome: Double) -> [String] {
        var insights: [String] = []
        
        // Safeguard against zero or invalid income
        guard monthlyIncome > 0, !monthlyIncome.isNaN, !monthlyIncome.isInfinite else {
            insights.append("Please set your monthly income to receive personalized insights.")
            return insights
        }
        
        // Get spending trends
        let spendingTrends = analyzeSpendingTrends(transactions: transactions)
        
        // Find highest expense categories
        if let topExpense = spendingTrends.first, topExpense.currentAmount > 0 {
            let percentOfIncome = (topExpense.currentAmount / monthlyIncome) * 100
            
            // Check for valid percentage
            if percentOfIncome.isFinite && percentOfIncome > 30 {
                insights.append("Your \(topExpense.category.rawValue.lowercased()) expenses account for \(safeIntConversion(percentOfIncome))% of your income. Consider setting a budget limit.")
            }
            
            // Check for valid percentage change
            if topExpense.trend == .increasing && topExpense.percentageChange.isFinite && topExpense.percentageChange > 20 {
                insights.append("\(topExpense.category.rawValue) spending has increased by \(safeIntConversion(topExpense.percentageChange))% recently. Review these expenses to stay on track.")
            }
        }
        
        // Check for categories with significant decrease (improvements)
        let improvements = spendingTrends.filter { $0.trend == .decreasing && $0.percentageChange.isFinite && $0.percentageChange < -15 }
        if let improvement = improvements.first {
            insights.append("Great job! You've reduced \(improvement.category.rawValue.lowercased()) spending by \(safeIntConversion(abs(improvement.percentageChange)))%.")
        }
        
        // Check income vs expenses
        let totalIncome = transactions.filter { $0.type == .income }.reduce(0) { $0 + $1.amount }
        let totalExpense = transactions.filter { $0.type == .expense }.reduce(0) { $0 + $1.amount }
        
        // Check for valid expense to income ratio
        if totalIncome > 0 && totalExpense > 0 {
            let expenseRatio = (totalExpense / totalIncome) * 100
            if expenseRatio.isFinite && expenseRatio > 90 {
                insights.append("Your expenses are \(safeIntConversion(expenseRatio))% of your income. Try to keep this under 90% to build savings.")
            }
        }
        
        // Check for consistent savings
        let savingsTransactions = transactions.filter {
            $0.type == .income && ($0.category == .investment || $0.category == .miscellaneous)
        }
        
        if savingsTransactions.isEmpty {
            insights.append("No savings detected. Consider setting aside 10-20% of your income each month.")
        } else {
            let safeCount = max(1, savingsTransactions.count)
            let monthlySavings = savingsTransactions.reduce(0) { $0 + $1.amount } / Double(safeCount)
            
            if monthlySavings.isFinite && monthlyIncome > 0 {
                let savingsRate = (monthlySavings / monthlyIncome) * 100
                
                if savingsRate.isFinite {
                    if savingsRate < 10 {
                        insights.append("You're saving approximately \(safeIntConversion(savingsRate))% of your income. Financial experts recommend saving at least 20%.")
                    } else if savingsRate >= 20 {
                        insights.append("Excellent! You're saving \(safeIntConversion(savingsRate))% of your income, which puts you ahead of most people.")
                    }
                }
            }
        }
        
        // If we don't have enough insights, add a general tip
        if insights.isEmpty {
            insights.append("Track your expenses consistently to receive personalized financial insights.")
        }
        
        return insights
    }
    
    // Helper method to safely convert Double to Int
    private func safeIntConversion(_ value: Double) -> Int {
        guard value.isFinite else { return 0 }
        return Int(value)
    }
    
    // Calculate projected savings and growth
    func projectSavingsGrowth(currentSavings: Double, monthlyContribution: Double, growthRate: Double, months: Int) -> [Double] {
        var projectedValues: [Double] = []
        var runningTotal = currentSavings
        
        // Monthly growth rate (APR to monthly)
        let monthlyRate = growthRate / 12.0
        
        for _ in 0..<months {
            // Add monthly contribution
            runningTotal += monthlyContribution
            
            // Apply growth
            runningTotal += runningTotal * monthlyRate
            
            projectedValues.append(runningTotal)
        }
        
        return projectedValues
    }
} 