//
//  DashboardView.swift
//  Muni
//
//  Created by Yaduraj Singh on 20/03/25.
//

import SwiftUI

struct DashboardView: View {
    @EnvironmentObject private var transactionManager: TransactionManager
    @EnvironmentObject private var userManager: UserManager
    @State private var selectedMonth = Calendar.current.component(.month, from: Date())
    @State private var selectedYear = Calendar.current.component(.year, from: Date())
    
    var body: some View {
        NavigationView {
            ScrollView {
                VStack(spacing: Theme.paddingMedium) {
                    // Month selector
                    MonthYearPicker(selectedMonth: $selectedMonth, selectedYear: $selectedYear)
                        .padding(.horizontal)
                    
                    // Balance summary
                    BalanceSummaryView()
                        .environmentObject(transactionManager)
                        .environmentObject(userManager)
                        .padding(.horizontal)
                    
                    // Budget progress
                    BudgetProgressView(selectedMonth: selectedMonth, selectedYear: selectedYear)
                        .environmentObject(transactionManager)
                        .environmentObject(userManager)
                        .padding(.horizontal)
                    
                    // Expense by category
                    ExpenseByCategoryView(selectedMonth: selectedMonth, selectedYear: selectedYear)
                        .environmentObject(transactionManager)
                        .environmentObject(userManager)
                        .padding(.horizontal)
                    
                    // Recent transactions
                    RecentTransactionsView()
                        .environmentObject(transactionManager)
                        .environmentObject(userManager)
                        .padding(.horizontal)
                }
                .padding(.vertical)
            }
            .background(Theme.background.ignoresSafeArea())
            .navigationTitle("Dashboard")
        }
    }
}

// MARK: - Month Year Picker
struct MonthYearPicker: View {
    @Binding var selectedMonth: Int
    @Binding var selectedYear: Int
    
    private let months = ["Jan", "Feb", "Mar", "Apr", "May", "Jun", "Jul", "Aug", "Sep", "Oct", "Nov", "Dec"]
    
    var body: some View {
        HStack {
            Button(action: previousMonth) {
                Image(systemName: "chevron.left")
                    .foregroundColor(Theme.primary)
            }
            
            Spacer()
            
            Text("\(months[selectedMonth - 1]) \(String(selectedYear))")
                .font(.system(size: Theme.subtitleSize, weight: .semibold))
                .foregroundColor(Theme.text)
            
            Spacer()
            
            Button(action: nextMonth) {
                Image(systemName: "chevron.right")
                    .foregroundColor(Theme.primary)
            }
        }
        .padding()
        .background(Theme.secondary.opacity(0.3))
        .cornerRadius(Theme.cornerRadiusMedium)
    }
    
    private func previousMonth() {
        var newMonth = selectedMonth - 1
        var newYear = selectedYear
        
        if newMonth < 1 {
            newMonth = 12
            newYear -= 1
        }
        
        selectedMonth = newMonth
        selectedYear = newYear
    }
    
    private func nextMonth() {
        var newMonth = selectedMonth + 1
        var newYear = selectedYear
        
        if newMonth > 12 {
            newMonth = 1
            newYear += 1
        }
        
        selectedMonth = newMonth
        selectedYear = newYear
    }
}

// MARK: - Balance Summary View
struct BalanceSummaryView: View {
    @EnvironmentObject private var transactionManager: TransactionManager
    @EnvironmentObject private var userManager: UserManager
    
    var body: some View {
        VStack(spacing: Theme.paddingMedium) {
            Text("Balance")
                .font(.system(size: Theme.subtitleSize, weight: .semibold))
                .foregroundColor(Theme.text)
                .frame(maxWidth: .infinity, alignment: .leading)
            
            HStack(spacing: Theme.paddingLarge) {
                BalanceCard(title: "Income", amount: transactionManager.totalIncome(), color: Theme.income, icon: "arrow.down")
                BalanceCard(title: "Expense", amount: transactionManager.totalExpense(), color: Theme.expense, icon: "arrow.up")
            }
            
            BalanceCard(title: "Balance", amount: transactionManager.balance(), color: Theme.primary, icon: "indianrupeesign.circle")
                .frame(maxWidth: .infinity)
        }
        .padding()
        .background(Theme.background)
        .cardStyle()
    }
}

struct BalanceCard: View {
    @EnvironmentObject private var userManager: UserManager
    
    let title: String
    let amount: Double
    let color: Color
    let icon: String
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Image(systemName: icon)
                    .foregroundColor(color)
                
                Text(title)
                    .font(.system(size: Theme.captionSize, weight: .medium))
                    .foregroundColor(Theme.text.opacity(0.8))
            }
            
            Text("\(userManager.currency)\(amount, specifier: "%.2f")")
                .font(.system(size: Theme.subtitleSize, weight: .bold))
                .foregroundColor(Theme.text)
        }
        .padding()
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(color.opacity(0.1))
        .cornerRadius(Theme.cornerRadiusMedium)
    }
}

// MARK: - Budget Progress View
struct BudgetProgressView: View {
    @EnvironmentObject private var transactionManager: TransactionManager
    @EnvironmentObject private var userManager: UserManager
    
    let selectedMonth: Int
    let selectedYear: Int
    
    private var monthlyExpenses: Double {
        let transactions = transactionManager.getTransactionsForMonth(month: selectedMonth, year: selectedYear)
        return transactions.filter { $0.type == .expense }.map { $0.amount }.reduce(0, +)
    }
    
    private var budgetPercentage: Double {
        guard userManager.monthlyBudget > 0 else { return 0 }
        return min(monthlyExpenses / userManager.monthlyBudget, 1.0)
    }
    
    private var remainingBudget: Double {
        max(userManager.monthlyBudget - monthlyExpenses, 0)
    }
    
    private var progressColor: Color {
        if budgetPercentage < 0.75 {
            return Theme.income
        } else if budgetPercentage < 0.9 {
            return Color.orange
        } else {
            return Theme.expense
        }
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: Theme.paddingMedium) {
            Text("Monthly Budget")
                .font(.system(size: Theme.subtitleSize, weight: .semibold))
                .foregroundColor(Theme.text)
            
            if userManager.monthlyBudget <= 0 {
                noBudgetView
            } else {
                budgetProgressView
            }
        }
        .padding()
        .background(Theme.background)
        .cardStyle()
    }
    
    private var noBudgetView: some View {
        VStack(spacing: Theme.paddingMedium) {
            Text("No monthly budget set")
                .font(.system(size: Theme.bodySize))
                .foregroundColor(Theme.text.opacity(0.7))
            
            Text("Set a budget in your profile to track your spending")
                .font(.system(size: Theme.captionSize))
                .foregroundColor(Theme.text.opacity(0.5))
                .multilineTextAlignment(.center)
                
            HStack {
                Spacer()
                
                NavigationLink(destination: ProfileView()) {
                    Text("Set Budget")
                        .font(.system(size: Theme.bodySize, weight: .medium))
                        .foregroundColor(.white)
                        .padding(.vertical, 8)
                        .padding(.horizontal, 16)
                        .background(Theme.primary)
                        .cornerRadius(Theme.cornerRadiusMedium)
                }
                
                Spacer()
            }
        }
    }
    
    private var budgetProgressView: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Text("Spent")
                    .font(.system(size: Theme.captionSize))
                    .foregroundColor(Theme.text.opacity(0.7))
                
                Spacer()
                
                Text("\(userManager.currency)\(monthlyExpenses, specifier: "%.2f") / \(userManager.currency)\(userManager.monthlyBudget, specifier: "%.2f")")
                    .font(.system(size: Theme.captionSize, weight: .medium))
                    .foregroundColor(Theme.text)
            }
            
            // Progress bar
            GeometryReader { geometry in
                ZStack(alignment: .leading) {
                    // Background
                    RoundedRectangle(cornerRadius: Theme.cornerRadiusSmall)
                        .fill(Color.gray.opacity(0.2))
                        .frame(height: 10)
                    
                    // Progress
                    RoundedRectangle(cornerRadius: Theme.cornerRadiusSmall)
                        .fill(progressColor)
                        .frame(width: geometry.size.width * budgetPercentage, height: 10)
                }
            }
            .frame(height: 10)
            
            HStack {
                Text("Remaining")
                    .font(.system(size: Theme.captionSize))
                    .foregroundColor(Theme.text.opacity(0.7))
                
                Spacer()
                
                Text("\(userManager.currency)\(remainingBudget, specifier: "%.2f")")
                    .font(.system(size: Theme.bodySize, weight: .semibold))
                    .foregroundColor(userManager.monthlyBudget > monthlyExpenses ? Theme.income : Theme.expense)
            }
        }
    }
}

// MARK: - Expense By Category View
struct ExpenseByCategoryView: View {
    @EnvironmentObject private var transactionManager: TransactionManager
    @EnvironmentObject private var userManager: UserManager
    
    let selectedMonth: Int
    let selectedYear: Int
    
    private var categoryExpenses: [TransactionCategory: Double] {
        transactionManager.getMonthlyExpensesByCategory(month: selectedMonth, year: selectedYear)
    }
    
    private var hasExpenses: Bool {
        !categoryExpenses.isEmpty && categoryExpenses.values.reduce(0, +) > 0
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: Theme.paddingMedium) {
            Text("Expenses by Category")
                .font(.system(size: Theme.subtitleSize, weight: .semibold))
                .foregroundColor(Theme.text)
            
            if hasExpenses {
                ForEach(Array(categoryExpenses.filter { $0.value > 0 }).sorted(by: { $0.value > $1.value }), id: \.key) { category, amount in
                    CategoryRow(category: category, amount: amount)
                }
            } else {
                Text("No expenses for this month")
                    .font(.system(size: Theme.bodySize))
                    .foregroundColor(Theme.text.opacity(0.7))
                    .frame(maxWidth: .infinity, alignment: .center)
                    .padding()
            }
        }
        .padding()
        .background(Theme.background)
        .cardStyle()
    }
}

struct CategoryRow: View {
    @EnvironmentObject private var userManager: UserManager
    
    let category: TransactionCategory
    let amount: Double
    
    var body: some View {
        HStack {
            Image(systemName: category.icon)
                .foregroundColor(Theme.primary)
                .frame(width: 30)
            
            Text(category.rawValue)
                .font(.system(size: Theme.bodySize))
                .foregroundColor(Theme.text)
            
            Spacer()
            
            Text("\(userManager.currency)\(amount, specifier: "%.2f")")
                .font(.system(size: Theme.bodySize, weight: .semibold))
                .foregroundColor(Theme.text)
        }
        .padding(.vertical, 4)
    }
}

// MARK: - Recent Transactions View
struct RecentTransactionsView: View {
    @EnvironmentObject private var transactionManager: TransactionManager
    
    private var recentTransactions: [Transaction] {
        Array(transactionManager.transactions.prefix(5))
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: Theme.paddingMedium) {
            HStack {
                Text("Recent Transactions")
                    .font(.system(size: Theme.subtitleSize, weight: .semibold))
                    .foregroundColor(Theme.text)
                
                Spacer()
                
                NavigationLink(destination: TransactionsView()) {
                    Text("See All")
                        .font(.system(size: Theme.captionSize))
                        .foregroundColor(Theme.primary)
                }
            }
            
            if recentTransactions.isEmpty {
                Text("No transactions yet")
                    .font(.system(size: Theme.bodySize))
                    .foregroundColor(Theme.text.opacity(0.7))
                    .frame(maxWidth: .infinity, alignment: .center)
                    .padding()
            } else {
                ForEach(recentTransactions) { transaction in
                    TransactionRow(transaction: transaction)
                }
            }
        }
        .padding()
        .background(Theme.background)
        .cardStyle()
    }
}

struct TransactionRow: View {
    @EnvironmentObject private var userManager: UserManager
    
    let transaction: Transaction
    
    private var dateFormatter: DateFormatter {
        let formatter = DateFormatter()
        formatter.dateFormat = "dd MMM"
        return formatter
    }
    
    var body: some View {
        HStack {
            Image(systemName: transaction.category.icon)
                .foregroundColor(transaction.type == .income ? Theme.income : Theme.expense)
                .frame(width: 35, height: 35)
                .background(
                    Circle()
                        .fill((transaction.type == .income ? Theme.income : Theme.expense).opacity(0.1))
                )
            
            VStack(alignment: .leading, spacing: 4) {
                Text(transaction.category.rawValue)
                    .font(.system(size: Theme.bodySize))
                    .foregroundColor(Theme.text)
                
                Text(transaction.note)
                    .font(.system(size: Theme.captionSize))
                    .foregroundColor(Theme.text.opacity(0.7))
                    .lineLimit(1)
            }
            
            Spacer()
            
            VStack(alignment: .trailing, spacing: 4) {
                Text("\(transaction.type == .income ? "+" : "-")\(userManager.currency)\(transaction.amount, specifier: "%.2f")")
                    .font(.system(size: Theme.bodySize, weight: .semibold))
                    .foregroundColor(transaction.type == .income ? Theme.income : Theme.expense)
                
                Text(dateFormatter.string(from: transaction.date))
                    .font(.system(size: Theme.captionSize))
                    .foregroundColor(Theme.text.opacity(0.7))
            }
        }
        .padding(.vertical, 8)
    }
} 