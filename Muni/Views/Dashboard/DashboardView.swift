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
    @State private var showingGoalDetails = false
    
    var body: some View {
        NavigationView {
            ScrollView {
                VStack(spacing: Theme.paddingMedium) {
                    // Month selector
                    MonthYearPicker(selectedMonth: $selectedMonth, selectedYear: $selectedYear)
                        .padding(.horizontal)
                    
                    // Personalized greeting
                    if !userManager.name.isEmpty {
                        PersonalizedGreetingView()
                            .environmentObject(userManager)
                            .padding(.horizontal)
                    }
                    
                    // Financial Goal Tracker (new component)
                    if !userManager.financialGoal.isEmpty {
                        FinancialGoalView(goal: userManager.financialGoal)
                            .environmentObject(transactionManager)
                            .environmentObject(userManager)
                            .padding(.horizontal)
                            .onTapGesture {
                                showingGoalDetails = true
                            }
                    }
                    
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
                    
                    // Smart Insights Card (new component)
                    SmartInsightsView(selectedMonth: selectedMonth, selectedYear: selectedYear)
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
            .sheet(isPresented: $showingGoalDetails) {
                GoalDetailView(goal: userManager.financialGoal)
                    .environmentObject(transactionManager)
                    .environmentObject(userManager)
            }
        }
    }
}

// MARK: - Personalized Greeting View
struct PersonalizedGreetingView: View {
    @EnvironmentObject private var userManager: UserManager
    
    private var greeting: String {
        let hour = Calendar.current.component(.hour, from: Date())
        if hour < 12 {
            return "Good morning"
        } else if hour < 17 {
            return "Good afternoon"
        } else {
            return "Good evening"
        }
    }
    
    private var financialTip: String {
        let tips = [
            "Saving just ₹100 a day adds up to ₹36,500 a year!",
            "Try the 50/30/20 rule: 50% needs, 30% wants, 20% savings.",
            "Track every expense to find hidden saving opportunities.",
            "Consider automating your savings to stay on track.",
            "Focus on reducing your biggest expense category first."
        ]
        return tips.randomElement() ?? tips[0]
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text("\(greeting), \(userManager.name)")
                        .font(.system(size: 22, weight: .bold, design: .rounded))
                        .foregroundColor(Theme.text)
                    
                    Text(Date(), style: .date)
                        .font(.system(size: 15))
                        .foregroundColor(Theme.text.opacity(0.7))
                }
                
                Spacer()
                
                Image(systemName: "sun.max.fill")
                    .font(.system(size: 30))
                    .foregroundColor(.orange)
            }
            
            HStack(spacing: 16) {
                Image(systemName: "lightbulb.fill")
                    .foregroundColor(.yellow)
                
                Text(financialTip)
                    .font(.system(size: 14, design: .rounded))
                    .foregroundColor(Theme.text.opacity(0.8))
                    .fixedSize(horizontal: false, vertical: true)
            }
            .padding(12)
            .background(Theme.secondary.opacity(0.3))
            .cornerRadius(10)
        }
        .padding()
        .background(Theme.background)
        .cardStyle()
    }
}

// MARK: - Financial Goal View
struct FinancialGoalView: View {
    @EnvironmentObject private var transactionManager: TransactionManager
    @EnvironmentObject private var userManager: UserManager
    let goal: String
    
    private var goalIcon: String {
        switch goal {
        case "Save for an emergency fund":
            return "umbrella.fill"
        case "Pay off debt":
            return "creditcard.fill"
        case "Save for a major purchase":
            return "cart.fill"
        case "Build investment portfolio":
            return "chart.line.uptrend.xyaxis.circle.fill"
        case "Track day-to-day expenses":
            return "list.bullet.clipboard.fill"
        case "Reduce unnecessary spending":
            return "scissors"
        case "Financial independence":
            return "star.fill"
        default:
            return "ellipsis.circle.fill"
        }
    }
    
    private var goalProgress: Double {
        return FinancialAnalyticsService.shared.calculateGoalProgress(
            transactions: transactionManager.transactions,
            goal: goal,
            monthlyIncome: userManager.monthlyIncome
        )
    }
    
    private var monthsToGoal: Int {
        return FinancialAnalyticsService.shared.calculateMonthsToGoal(
            transactions: transactionManager.transactions,
            goal: goal,
            monthlyIncome: userManager.monthlyIncome
        )
    }
    
    private var targetDate: String {
        let calendar = Calendar.current
        let currentDate = Date()
        
        if let futureDate = calendar.date(byAdding: .month, value: monthsToGoal, to: currentDate) {
            let formatter = DateFormatter()
            formatter.dateFormat = "MMM yyyy" // Format as "Jan 2023"
            return formatter.string(from: futureDate)
        }
        
        return "Unknown"
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Image(systemName: goalIcon)
                    .font(.system(size: 20))
                    .foregroundColor(.white)
                    .frame(width: 36, height: 36)
                    .background(Theme.primary)
                    .clipShape(Circle())
                
                VStack(alignment: .leading, spacing: 2) {
                    Text("Financial Goal")
                        .font(.system(size: 14, weight: .medium))
                        .foregroundColor(Theme.text.opacity(0.7))
                    
                    Text(goal)
                        .font(.system(size: 16, weight: .bold))
                        .foregroundColor(Theme.text)
                }
                
                Spacer()
                
                Image(systemName: "chevron.right")
                    .foregroundColor(Theme.text.opacity(0.5))
            }
            
            // Progress bar
            VStack(alignment: .leading, spacing: 8) {
                GeometryReader { geometry in
                    ZStack(alignment: .leading) {
                        // Background
                        RoundedRectangle(cornerRadius: 6)
                            .fill(Color.gray.opacity(0.2))
                            .frame(height: 12)
                        
                        // Progress
                        RoundedRectangle(cornerRadius: 6)
                            .fill(Theme.primary.opacity(0.8))
                            .frame(width: geometry.size.width * goalProgress, height: 12)
                    }
                }
                .frame(height: 12)
                
                HStack {
                    Text("\(Int(goalProgress * 100))% Complete")
                        .font(.system(size: 14, weight: .medium))
                        .foregroundColor(Theme.text)
                    
                    Spacer()
                    
                    if monthsToGoal < 36 {
                        Text("Target: \(targetDate)")
                            .font(.system(size: 13))
                            .foregroundColor(Theme.primary)
                    } else {
                        Text("Tap for details")
                            .font(.system(size: 13))
                            .foregroundColor(Theme.primary)
                    }
                }
            }
        }
        .padding()
        .background(Theme.background)
        .cardStyle()
    }
}

// MARK: - Smart Insights View
struct SmartInsightsView: View {
    @EnvironmentObject private var transactionManager: TransactionManager
    @EnvironmentObject private var userManager: UserManager
    @State private var showingBudgetPlanner = false
    @State private var currentInsightIndex = 0
    let selectedMonth: Int
    let selectedYear: Int
    
    private var spendingTrends: [CategoryAnalytics] {
        return FinancialAnalyticsService.shared.analyzeSpendingTrends(
            transactions: transactionManager.transactions
        )
    }
    
    private var primarySpendingCategory: (TransactionCategory, Double)? {
        if spendingTrends.isEmpty {
            return nil
        }
        return (spendingTrends[0].category, spendingTrends[0].currentAmount)
    }
    
    private var insights: [String] {
        return FinancialAnalyticsService.shared.generateSmartInsights(
            transactions: transactionManager.transactions, 
            monthlyIncome: userManager.monthlyIncome
        )
    }
    
    private var currentInsight: String {
        if insights.isEmpty {
            return "Add more transactions to see personalized insights."
        }
        return insights[min(currentInsightIndex, insights.count - 1)]
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack {
                Text("Smart Insights")
                    .font(.system(size: Theme.subtitleSize, weight: .semibold))
                    .foregroundColor(Theme.text)
                
                Spacer()
                
                Image(systemName: "brain.fill")
                    .foregroundColor(Theme.primary)
            }
            
            HStack(spacing: 16) {
                if let (category, _) = primarySpendingCategory {
                    Image(systemName: category.icon)
                        .font(.system(size: 24))
                        .foregroundColor(.white)
                        .frame(width: 48, height: 48)
                        .background(Theme.primary)
                        .clipShape(Circle())
                } else {
                    Image(systemName: "doc.text.magnifyingglass")
                        .font(.system(size: 24))
                        .foregroundColor(.white)
                        .frame(width: 48, height: 48)
                        .background(Theme.primary)
                        .clipShape(Circle())
                }
                
                Text(currentInsight)
                    .font(.system(size: Theme.bodySize))
                    .foregroundColor(Theme.text)
                    .fixedSize(horizontal: false, vertical: true)
                    .onTapGesture {
                        withAnimation {
                            // Cycle through insights
                            currentInsightIndex = (currentInsightIndex + 1) % max(1, insights.count)
                        }
                    }
            }
            
            if insights.count > 1 {
                HStack(spacing: 4) {
                    ForEach(0..<min(insights.count, 5), id: \.self) { index in
                        Circle()
                            .fill(index == currentInsightIndex ? Theme.primary : Theme.secondary.opacity(0.5))
                            .frame(width: 6, height: 6)
                    }
                }
                .frame(maxWidth: .infinity, alignment: .center)
                .padding(.top, -4)
            }
            
            if let (category, _) = primarySpendingCategory, 
               let categoryAnalytic = spendingTrends.first(where: { $0.category == category }) {
                HStack {
                    // Category trend icon
                    Image(systemName: categoryAnalytic.trend.icon)
                        .foregroundColor(Color(categoryAnalytic.trend.color))
                    
                    Text("\(Int(abs(categoryAnalytic.percentageChange)))% \(categoryAnalytic.trend == .increasing ? "increase" : categoryAnalytic.trend == .decreasing ? "decrease" : "change") from last period")
                        .font(.system(size: 14))
                        .foregroundColor(Theme.text.opacity(0.8))
                    
                    Spacer()
                    
                    Button(action: {
                        showingBudgetPlanner = true
                    }) {
                        Text("Set Budget")
                            .font(.system(size: 14, weight: .medium))
                            .foregroundColor(.white)
                            .padding(.vertical, 6)
                            .padding(.horizontal, 12)
                            .background(Theme.primary)
                            .cornerRadius(8)
                    }
                }
                .padding(.top, 8)
            }
        }
        .padding()
        .background(Theme.background)
        .cardStyle()
        .sheet(isPresented: $showingBudgetPlanner) {
            BudgetPlanningView()
                .environmentObject(transactionManager)
                .environmentObject(userManager)
        }
    }
}

// MARK: - Goal Detail View
struct GoalDetailView: View {
    @EnvironmentObject private var transactionManager: TransactionManager
    @EnvironmentObject private var userManager: UserManager
    @Environment(\.presentationMode) var presentationMode
    @State private var showingBudgetPlanner = false
    let goal: String
    
    private var goalProgress: Double {
        return FinancialAnalyticsService.shared.calculateGoalProgress(
            transactions: transactionManager.transactions,
            goal: goal,
            monthlyIncome: userManager.monthlyIncome
        )
    }
    
    private var monthsToGoal: Int {
        return FinancialAnalyticsService.shared.calculateMonthsToGoal(
            transactions: transactionManager.transactions,
            goal: goal,
            monthlyIncome: userManager.monthlyIncome
        )
    }
    
    private var projectedSavings: [Double] {
        // Calculate current savings
        let savingsTransactions = transactionManager.transactions.filter {
            $0.type == .income && ($0.category == .miscellaneous || $0.category == .investment) 
        }
        let currentSavings = savingsTransactions.reduce(0) { $0 + $1.amount }
        
        // Recommended monthly contribution (20% of income)
        let monthlyContribution = userManager.monthlyIncome * 0.2
        
        // Project growth over next 6 months
        return FinancialAnalyticsService.shared.projectSavingsGrowth(
            currentSavings: currentSavings,
            monthlyContribution: monthlyContribution,
            growthRate: 0.05, // 5% annual return
            months: 6
        )
    }
    
    var body: some View {
        NavigationView {
            ScrollView {
                VStack(spacing: 24) {
                    // Goal icon and title
                    goalHeader
                    
                    // Recommendations
                    goalRecommendations
                    
                    // Progress chart
                    goalProgressChart
                    
                    // Next steps
                    goalNextSteps
                }
                .padding()
            }
            .background(Theme.background.ignoresSafeArea())
            .navigationTitle("Goal Details")
            .navigationBarTitleDisplayMode(.inline)
            .navigationBarItems(trailing: Button("Done") {
                presentationMode.wrappedValue.dismiss()
            })
            .sheet(isPresented: $showingBudgetPlanner) {
                BudgetPlanningView()
                    .environmentObject(transactionManager)
                    .environmentObject(userManager)
            }
        }
    }
    
    private var goalHeader: some View {
        VStack(spacing: 16) {
            GoalIconView(goal: goal)
                .frame(width: 80, height: 80)
            
            Text(goal)
                .font(.system(size: 22, weight: .bold, design: .rounded))
                .foregroundColor(Theme.text)
                .multilineTextAlignment(.center)
            
            Text("Based on your spending patterns and income, here's our assessment and recommendations")
                .font(.system(size: 16))
                .foregroundColor(Theme.text.opacity(0.7))
                .multilineTextAlignment(.center)
        }
        .padding()
        .frame(maxWidth: .infinity)
        .background(Theme.secondary.opacity(0.3))
        .cornerRadius(16)
    }
    
    private var goalRecommendations: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Personalized Recommendations")
                .font(.system(size: 18, weight: .bold))
                .foregroundColor(Theme.text)
            
            recommendationRow(
                icon: "arrow.down.circle.fill",
                title: "Reduce Spending",
                description: "Cut back on \(userManager.primaryExpenseCategory.rawValue.lowercased()) expenses by 10%"
            )
            
            recommendationRow(
                icon: "dollarsign.circle.fill",
                title: "Save More",
                description: "Allocate ₹\(Int(userManager.monthlyIncome * 0.2)) monthly toward your goal"
            )
            
            if let (topCategory, _) = transactionManager.getMonthlyExpensesByCategory(
                month: Calendar.current.component(.month, from: Date()),
                year: Calendar.current.component(.year, from: Date())
            ).max(by: { $0.value < $1.value }) {
                recommendationRow(
                    icon: "chart.pie.fill",
                    title: "Focus Area",
                    description: "Your highest expense is \(topCategory.rawValue.lowercased()). Look for ways to optimize."
                )
            } else {
                recommendationRow(
                    icon: "chart.pie.fill",
                    title: "Optimize Budget",
                    description: "Review and adjust your monthly budget allocation"
                )
            }
        }
        .padding()
        .background(Theme.background)
        .cardStyle()
    }
    
    private func recommendationRow(icon: String, title: String, description: String) -> some View {
        HStack(spacing: 16) {
            Image(systemName: icon)
                .font(.system(size: 24))
                .foregroundColor(Theme.primary)
                .frame(width: 40, height: 40)
            
            VStack(alignment: .leading, spacing: 4) {
                Text(title)
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundColor(Theme.text)
                
                Text(description)
                    .font(.system(size: 14))
                    .foregroundColor(Theme.text.opacity(0.7))
                    .fixedSize(horizontal: false, vertical: true)
            }
        }
    }
    
    private var goalProgressChart: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Projected Timeline")
                .font(.system(size: 18, weight: .bold))
                .foregroundColor(Theme.text)
            
            // Progress bar
            VStack(alignment: .leading, spacing: 12) {
                GeometryReader { geometry in
                    ZStack(alignment: .leading) {
                        // Background
                        RoundedRectangle(cornerRadius: 6)
                            .fill(Color.gray.opacity(0.2))
                            .frame(height: 12)
                        
                        // Progress
                        RoundedRectangle(cornerRadius: 6)
                            .fill(Theme.primary.opacity(0.8))
                            .frame(width: geometry.size.width * goalProgress, height: 12)
                    }
                }
                .frame(height: 12)
                
                HStack {
                    Text("\(Int(goalProgress * 100))% Complete")
                        .font(.system(size: 16, weight: .medium))
                        .foregroundColor(Theme.text)
                    
                    Spacer()
                    
                    if monthsToGoal < 36 {
                        let months = monthsToGoal <= 1 ? "1 month" : "\(monthsToGoal) months"
                        Text("\(months) remaining")
                            .font(.system(size: 16))
                            .foregroundColor(Theme.primary)
                    }
                }
            }
            .padding(.bottom, 10)
            
            // Projected growth chart 
            if !projectedSavings.isEmpty {
                Text("Projected Savings Growth")
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundColor(Theme.text)
                    .padding(.top, 10)
                
                // Chart showing projected savings
                HStack(spacing: 0) {
                    ForEach(0..<projectedSavings.count, id: \.self) { index in
                        VStack {
                            // Normalize height based on max value
                            let maxValue = projectedSavings.max() ?? 1
                            let height = (projectedSavings[index] / maxValue) * 100
                            
                            Rectangle()
                                .fill(Theme.primary.opacity(0.7 - Double(index) * 0.05))
                                .frame(height: CGFloat(height))
                                .cornerRadius(4)
                            
                            Text("M\(index+1)")
                                .font(.system(size: 12))
                                .foregroundColor(Theme.text.opacity(0.8))
                        }
                        .frame(maxWidth: .infinity)
                    }
                }
                .frame(height: 140)
                .padding(.vertical)
            }
            
            Text("At your current rate, you'll reach your goal in approximately \(monthsToGoal) months")
                .font(.system(size: 14))
                .foregroundColor(Theme.text.opacity(0.7))
                .multilineTextAlignment(.center)
                .padding()
                .frame(maxWidth: .infinity)
                .background(Theme.secondary.opacity(0.3))
                .cornerRadius(10)
        }
        .padding()
        .background(Theme.background)
        .cardStyle()
    }
    
    private var goalNextSteps: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Next Steps")
                .font(.system(size: 18, weight: .bold))
                .foregroundColor(Theme.text)
            
            Button(action: {
                showingBudgetPlanner = true
            }) {
                HStack {
                    Image(systemName: "wand.and.stars")
                        .foregroundColor(Theme.primary)
                    
                    Text("Create a Smart Budget Plan")
                        .foregroundColor(Theme.text)
                    
                    Spacer()
                    
                    Image(systemName: "chevron.right")
                        .foregroundColor(Theme.text.opacity(0.5))
                }
                .padding()
                .background(Theme.secondary.opacity(0.3))
                .cornerRadius(10)
            }
            
            Button(action: {
                // In a real app, this would navigate to savings simulation
            }) {
                HStack {
                    Image(systemName: "chart.line.uptrend.xyaxis")
                        .foregroundColor(Theme.primary)
                    
                    Text("Run Savings Simulation")
                        .foregroundColor(Theme.text)
                    
                    Spacer()
                    
                    Image(systemName: "chevron.right")
                        .foregroundColor(Theme.text.opacity(0.5))
                }
                .padding()
                .background(Theme.secondary.opacity(0.3))
                .cornerRadius(10)
            }
        }
        .padding()
        .background(Theme.background)
        .cardStyle()
    }
}

struct GoalIconView: View {
    let goal: String
    
    private var iconName: String {
        switch goal {
        case "Save for an emergency fund":
            return "umbrella.fill"
        case "Pay off debt":
            return "creditcard.fill"
        case "Save for a major purchase":
            return "cart.fill"
        case "Build investment portfolio":
            return "chart.line.uptrend.xyaxis.circle.fill"
        case "Track day-to-day expenses":
            return "list.bullet.clipboard.fill"
        case "Reduce unnecessary spending":
            return "scissors"
        case "Financial independence":
            return "star.fill"
        default:
            return "ellipsis.circle.fill"
        }
    }
    
    var body: some View {
        ZStack {
            Circle()
                .fill(Theme.primary)
            
            Image(systemName: iconName)
                .resizable()
                .scaledToFit()
                .foregroundColor(.white)
                .padding(20)
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
