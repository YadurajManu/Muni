//
//  HomeWidgetsView.swift
//  Muni
//
//  Created by Yaduraj Singh on 20/03/25.
//

import SwiftUI

struct HomeWidgetsView: View {
    @EnvironmentObject private var transactionManager: TransactionManager
    @EnvironmentObject private var userManager: UserManager
    @ObservedObject private var widgetManager = WidgetManager.shared
    
    var body: some View {
        VStack(spacing: 15) {
            Text("Widgets")
                .font(.system(size: 22, weight: .bold, design: .rounded))
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(.horizontal)
            
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 15) {
                    ForEach(widgetManager.enabledWidgets) { widget in
                        widget.view
                            .environmentObject(transactionManager)
                            .environmentObject(userManager)
                            .frame(width: 300, height: 160)
                    }
                    
                    // Add widget button
                    Button(action: {
                        widgetManager.showWidgetPicker = true
                    }) {
                        VStack {
                            Image(systemName: "plus.circle")
                                .font(.system(size: 28))
                                .foregroundColor(Theme.primary)
                            
                            Text("Add Widget")
                                .font(.system(size: 15, weight: .medium))
                                .foregroundColor(Theme.text)
                        }
                        .frame(width: 130, height: 160)
                        .background(Color(UIColor.secondarySystemBackground))
                        .cornerRadius(16)
                    }
                }
                .padding(.horizontal)
            }
            .sheet(isPresented: $widgetManager.showWidgetPicker) {
                WidgetPickerView()
                    .environmentObject(widgetManager)
            }
        }
    }
}

// MARK: - Widget Manager
class WidgetManager: ObservableObject {
    static let shared = WidgetManager()
    
    @Published var enabledWidgets: [AnyHomeWidget] = []
    @Published var showWidgetPicker: Bool = false
    
    private let allWidgetsKey = "enabledWidgets"
    
    init() {
        loadWidgets()
        
        // If no widgets are enabled yet, add some default ones
        if enabledWidgets.isEmpty {
            enabledWidgets = [
                AnyHomeWidget(BalanceWidget()),
                AnyHomeWidget(SpendingTrendWidget()),
                AnyHomeWidget(BudgetWidget()),
                AnyHomeWidget(GoalWidget())
            ]
            saveWidgets()
        }
    }
    
    func addWidget(_ widget: any HomeWidget) {
        // Check if widget already exists
        if !enabledWidgets.contains(where: { $0.id == widget.id }) {
            enabledWidgets.append(AnyHomeWidget(widget))
            saveWidgets()
        }
    }
    
    func removeWidget(_ widget: AnyHomeWidget) {
        enabledWidgets.removeAll(where: { $0.id == widget.id })
        saveWidgets()
    }
    
    func moveWidget(from source: IndexSet, to destination: Int) {
        enabledWidgets.move(fromOffsets: source, toOffset: destination)
        saveWidgets()
    }
    
    private func saveWidgets() {
        let widgetIDs = enabledWidgets.map { $0.id.uuidString }
        UserDefaults.standard.set(widgetIDs, forKey: allWidgetsKey)
    }
    
    private func loadWidgets() {
        guard let widgetIDs = UserDefaults.standard.stringArray(forKey: allWidgetsKey) else {
            return
        }
        
        enabledWidgets = widgetIDs.compactMap { idString in
            guard let uuid = UUID(uuidString: idString) else { return nil }
            if let widget = createWidget(for: uuid) {
                return AnyHomeWidget(widget)
            }
            return nil
        }
    }
    
    private func createWidget(for id: UUID) -> (any HomeWidget)? {
        // Find the widget type from the ID (in a real app, you'd store the type too)
        let widgetTypes: [any HomeWidget.Type] = [
            BalanceWidget.self,
            SpendingTrendWidget.self,
            BudgetWidget.self,
            GoalWidget.self,
            ExpenseCategoryWidget.self,
            SavedThisMonthWidget.self
        ]
        
        // Try to find a matching widget with the ID
        for type in widgetTypes {
            if let widget = type.init(id: id) {
                return widget
            }
        }
        
        return nil
    }
    
    func getAllWidgetTypes() -> [AnyHomeWidget] {
        return [
            AnyHomeWidget(BalanceWidget()),
            AnyHomeWidget(SpendingTrendWidget()),
            AnyHomeWidget(BudgetWidget()),
            AnyHomeWidget(GoalWidget()),
            AnyHomeWidget(ExpenseCategoryWidget()),
            AnyHomeWidget(SavedThisMonthWidget())
        ]
    }
}

// MARK: - Widget Type Eraser
struct AnyHomeWidget: Identifiable {
    private let _widget: any HomeWidget
    
    var id: UUID { _widget.id }
    var title: String { _widget.title }
    var description: String { _widget.description }
    var iconName: String { _widget.iconName }
    var view: AnyView { _widget.view }
    
    init(_ widget: any HomeWidget) {
        self._widget = widget
    }
}

// MARK: - Widget Protocols
protocol HomeWidget {
    var id: UUID { get }
    var title: String { get }
    var description: String { get }
    var iconName: String { get }
    var view: AnyView { get }
    
    init()
    init?(id: UUID)
}

// MARK: - Balance Widget
struct BalanceWidget: HomeWidget {
    var id = UUID()
    var title = "Balance"
    var description = "Shows your current balance"
    var iconName = "indianrupeesign.circle.fill"
    
    var view: AnyView {
        AnyView(BalanceWidgetView())
    }
    
    init() {}
    
    init?(id: UUID) {
        self.id = id
        return
    }
}

struct BalanceWidgetView: View {
    @EnvironmentObject var transactionManager: TransactionManager
    @EnvironmentObject var userManager: UserManager
    
    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack {
                Image(systemName: "indianrupeesign.circle.fill")
                    .font(.system(size: 18))
                    .foregroundColor(.white)
                
                Text("Balance")
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundColor(.white)
                
                Spacer()
                
                Image(systemName: "ellipsis")
                    .foregroundColor(.white.opacity(0.8))
            }
            
            Spacer()
            
            Text("\(userManager.currency)\(String(format: "%.2f", transactionManager.balance()))")
                .font(.system(size: 30, weight: .bold))
                .foregroundColor(.white)
            
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text("Income")
                        .font(.system(size: 12))
                        .foregroundColor(.white.opacity(0.8))
                    
                    Text("\(userManager.currency)\(String(format: "%.2f", transactionManager.totalIncome()))")
                        .font(.system(size: 14, weight: .medium))
                        .foregroundColor(.white)
                }
                
                Spacer()
                
                VStack(alignment: .leading, spacing: 4) {
                    Text("Expense")
                        .font(.system(size: 12))
                        .foregroundColor(.white.opacity(0.8))
                    
                    Text("\(userManager.currency)\(String(format: "%.2f", transactionManager.totalExpense()))")
                        .font(.system(size: 14, weight: .medium))
                        .foregroundColor(.white)
                }
                
                Spacer()
            }
        }
        .padding()
        .background(LinearGradient(
            gradient: Gradient(colors: [Theme.primary, Theme.primary.opacity(0.8)]),
            startPoint: .topLeading,
            endPoint: .bottomTrailing
        ))
        .cornerRadius(16)
    }
}

// MARK: - Spending Trend Widget
struct SpendingTrendWidget: HomeWidget {
    var id = UUID()
    var title = "Spending Trend"
    var description = "Visualizes your spending trend"
    var iconName = "chart.line.uptrend.xyaxis"
    
    var view: AnyView {
        AnyView(SpendingTrendWidgetView())
    }
    
    init() {}
    
    init?(id: UUID) {
        self.id = id
        return
    }
}

struct SpendingTrendWidgetView: View {
    @EnvironmentObject var transactionManager: TransactionManager
    @EnvironmentObject var userManager: UserManager
    
    private var spendingTrends: [CategoryAnalytics] {
        return FinancialAnalyticsService.shared.analyzeSpendingTrends(
            transactions: transactionManager.transactions,
            timeframeMonths: 1
        )
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack {
                Image(systemName: "chart.line.uptrend.xyaxis")
                    .font(.system(size: 18))
                    .foregroundColor(Theme.text)
                
                Text("Spending Trend")
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundColor(Theme.text)
                
                Spacer()
                
                Text("This Month")
                    .font(.system(size: 12))
                    .foregroundColor(Theme.text.opacity(0.6))
            }
            
            if spendingTrends.isEmpty {
                Spacer()
                
                Text("No spending data yet")
                    .font(.system(size: 16))
                    .foregroundColor(Theme.text.opacity(0.7))
                    .frame(maxWidth: .infinity, alignment: .center)
                
                Spacer()
            } else {
                ScrollView {
                    VStack(spacing: 8) {
                        ForEach(spendingTrends.prefix(3), id: \.category) { trend in
                            HStack {
                                Image(systemName: trend.category.icon)
                                    .font(.system(size: 14))
                                    .foregroundColor(.white)
                                    .frame(width: 24, height: 24)
                                    .background(Theme.primary)
                                    .cornerRadius(12)
                                
                                Text(trend.category.rawValue)
                                    .font(.system(size: 14))
                                    .foregroundColor(Theme.text)
                                
                                Spacer()
                                
                                HStack(spacing: 4) {
                                    Text("\(userManager.currency)\(String(format: "%.0f", trend.currentAmount))")
                                        .font(.system(size: 14, weight: .medium))
                                        .foregroundColor(Theme.text)
                                    
                                    // Trend indicator
                                    Image(systemName: trend.trend.icon)
                                        .font(.system(size: 12))
                                        .foregroundColor(Color(trend.trend.color))
                                }
                            }
                        }
                    }
                }
            }
        }
        .padding()
        .background(Color(UIColor.secondarySystemBackground))
        .cornerRadius(16)
    }
}

// MARK: - Budget Widget
struct BudgetWidget: HomeWidget {
    var id = UUID()
    var title = "Budget"
    var description = "Shows your budget progress"
    var iconName = "chart.bar.fill"
    
    var view: AnyView {
        AnyView(BudgetWidgetView())
    }
    
    init() {}
    
    init?(id: UUID) {
        self.id = id
        return
    }
}

struct BudgetWidgetView: View {
    @EnvironmentObject var transactionManager: TransactionManager
    @EnvironmentObject var userManager: UserManager
    
    private var monthlyExpenses: Double {
        let calendar = Calendar.current
        let currentMonth = calendar.component(.month, from: Date())
        let currentYear = calendar.component(.year, from: Date())
        
        let transactions = transactionManager.getTransactionsForMonth(month: currentMonth, year: currentYear)
        return transactions.filter { $0.type == .expense }.map { $0.amount }.reduce(0, +)
    }
    
    private var budgetPercentage: Double {
        guard userManager.monthlyBudget > 0 else { return 0 }
        return min(1.0, monthlyExpenses / userManager.monthlyBudget)
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
        VStack(alignment: .leading, spacing: 10) {
            HStack {
                Image(systemName: "chart.bar.fill")
                    .font(.system(size: 18))
                    .foregroundColor(Theme.text)
                
                Text("Monthly Budget")
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundColor(Theme.text)
                
                Spacer()
            }
            
            if userManager.monthlyBudget <= 0 {
                Spacer()
                
                Text("No budget set")
                    .font(.system(size: 16))
                    .foregroundColor(Theme.text.opacity(0.7))
                    .frame(maxWidth: .infinity, alignment: .center)
                
                Spacer()
            } else {
                HStack {
                    Text("\(userManager.currency)\(String(format: "%.0f", monthlyExpenses))")
                        .font(.system(size: 24, weight: .bold))
                        .foregroundColor(Theme.text)
                    
                    Text("of \(userManager.currency)\(String(format: "%.0f", userManager.monthlyBudget))")
                        .font(.system(size: 16))
                        .foregroundColor(Theme.text.opacity(0.7))
                }
                .padding(.top, 5)
                
                // Progress bar
                GeometryReader { geometry in
                    ZStack(alignment: .leading) {
                        // Background
                        RoundedRectangle(cornerRadius: 6)
                            .fill(Color.gray.opacity(0.2))
                            .frame(height: 10)
                        
                        // Progress
                        RoundedRectangle(cornerRadius: 6)
                            .fill(progressColor)
                            .frame(width: geometry.size.width * budgetPercentage, height: 10)
                    }
                }
                .frame(height: 10)
                .padding(.vertical, 8)
                
                HStack {
                    Text("Remaining:")
                        .font(.system(size: 14))
                        .foregroundColor(Theme.text.opacity(0.7))
                    
                    Text("\(userManager.currency)\(String(format: "%.0f", max(0, userManager.monthlyBudget - monthlyExpenses)))")
                        .font(.system(size: 14, weight: .semibold))
                        .foregroundColor(progressColor)
                    
                    Spacer()
                    
                    Text("\(Int(budgetPercentage * 100))%")
                        .font(.system(size: 14, weight: .semibold))
                        .foregroundColor(progressColor)
                }
            }
        }
        .padding()
        .background(Color(UIColor.secondarySystemBackground))
        .cornerRadius(16)
    }
}

// MARK: - Goal Widget
struct GoalWidget: HomeWidget {
    var id = UUID()
    var title = "Financial Goal"
    var description = "Tracks your financial goal progress"
    var iconName = "target"
    
    var view: AnyView {
        AnyView(GoalWidgetView())
    }
    
    init() {}
    
    init?(id: UUID) {
        self.id = id
        return
    }
}

struct GoalWidgetView: View {
    @EnvironmentObject var transactionManager: TransactionManager
    @EnvironmentObject var userManager: UserManager
    
    private var goalProgress: Double {
        guard !userManager.financialGoal.isEmpty else { return 0 }
        
        return FinancialAnalyticsService.shared.calculateGoalProgress(
            transactions: transactionManager.transactions,
            goal: userManager.financialGoal,
            monthlyIncome: userManager.monthlyIncome
        )
    }
    
    private var monthsToGoal: Int {
        guard !userManager.financialGoal.isEmpty else { return 0 }
        
        return FinancialAnalyticsService.shared.calculateMonthsToGoal(
            transactions: transactionManager.transactions,
            goal: userManager.financialGoal,
            monthlyIncome: userManager.monthlyIncome
        )
    }
    
    private var goalIcon: String {
        guard !userManager.financialGoal.isEmpty else { return "star.fill" }
        
        switch userManager.financialGoal {
        case "Save for an emergency fund": return "umbrella.fill"
        case "Pay off debt": return "creditcard.fill"
        case "Save for a major purchase": return "cart.fill"
        case "Build investment portfolio": return "chart.line.uptrend.xyaxis.circle.fill"
        case "Track day-to-day expenses": return "list.bullet.clipboard.fill"
        case "Reduce unnecessary spending": return "scissors"
        case "Financial independence": return "star.fill"
        default: return "target"
        }
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack {
                Image(systemName: goalIcon)
                    .font(.system(size: 18))
                    .foregroundColor(.white)
                
                Text(userManager.financialGoal.isEmpty ? "Financial Goal" : userManager.financialGoal)
                    .font(.system(size: 16, weight: .semibold))
                    .lineLimit(1)
                    .foregroundColor(.white)
                
                Spacer()
            }
            
            if userManager.financialGoal.isEmpty {
                Spacer()
                
                Text("No goal set")
                    .font(.system(size: 16))
                    .foregroundColor(.white.opacity(0.7))
                    .frame(maxWidth: .infinity, alignment: .center)
                
                Spacer()
            } else {
                // Progress circle
                HStack {
                    ZStack {
                        Circle()
                            .stroke(Color.white.opacity(0.3), lineWidth: 8)
                            .frame(width: 70, height: 70)
                        
                        Circle()
                            .trim(from: 0, to: goalProgress)
                            .stroke(Color.white, lineWidth: 8)
                            .frame(width: 70, height: 70)
                            .rotationEffect(.degrees(-90))
                        
                        Text("\(Int(goalProgress * 100))%")
                            .font(.system(size: 16, weight: .bold))
                            .foregroundColor(.white)
                    }
                    
                    VStack(alignment: .leading, spacing: 4) {
                        Text("Target")
                            .font(.system(size: 14))
                            .foregroundColor(.white.opacity(0.8))
                        
                        if monthsToGoal < 36 {
                            Text("\(monthsToGoal) months left")
                                .font(.system(size: 16, weight: .semibold))
                                .foregroundColor(.white)
                        } else {
                            Text("In progress")
                                .font(.system(size: 16, weight: .semibold))
                                .foregroundColor(.white)
                        }
                    }
                    .padding(.leading, 10)
                    
                    Spacer()
                }
            }
        }
        .padding()
        .background(LinearGradient(
            gradient: Gradient(colors: [Color.purple, Color.blue]),
            startPoint: .topLeading,
            endPoint: .bottomTrailing
        ))
        .cornerRadius(16)
    }
}

// MARK: - Expense Category Widget
struct ExpenseCategoryWidget: HomeWidget {
    var id = UUID()
    var title = "Top Expenses"
    var description = "Shows your top expense categories"
    var iconName = "chart.pie.fill"
    
    var view: AnyView {
        AnyView(ExpenseCategoryWidgetView())
    }
    
    init() {}
    
    init?(id: UUID) {
        self.id = id
        return
    }
}

struct ExpenseCategoryWidgetView: View {
    @EnvironmentObject var transactionManager: TransactionManager
    @EnvironmentObject var userManager: UserManager
    
    private var topCategories: [TransactionCategory: Double] {
        let calendar = Calendar.current
        let currentMonth = calendar.component(.month, from: Date())
        let currentYear = calendar.component(.year, from: Date())
        
        let categories = transactionManager.getMonthlyExpensesByCategory(month: currentMonth, year: currentYear)
        
        return categories
    }
    
    private var sortedCategories: [(TransactionCategory, Double)] {
        return topCategories.sorted(by: { $0.value > $1.value })
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack {
                Image(systemName: "chart.pie.fill")
                    .font(.system(size: 18))
                    .foregroundColor(Theme.text)
                
                Text("Top Expenses")
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundColor(Theme.text)
                
                Spacer()
                
                Text("This Month")
                    .font(.system(size: 12))
                    .foregroundColor(Theme.text.opacity(0.6))
            }
            
            if sortedCategories.isEmpty {
                Spacer()
                
                Text("No expenses recorded yet")
                    .font(.system(size: 16))
                    .foregroundColor(Theme.text.opacity(0.7))
                    .frame(maxWidth: .infinity, alignment: .center)
                
                Spacer()
            } else {
                VStack(spacing: 8) {
                    ForEach(sortedCategories.prefix(3), id: \.0) { category, amount in
                        HStack {
                            Image(systemName: category.icon)
                                .font(.system(size: 14))
                                .foregroundColor(.white)
                                .frame(width: 24, height: 24)
                                .background(Theme.primary)
                                .cornerRadius(12)
                            
                            Text(category.rawValue)
                                .font(.system(size: 14))
                                .foregroundColor(Theme.text)
                            
                            Spacer()
                            
                            Text("\(userManager.currency)\(String(format: "%.0f", amount))")
                                .font(.system(size: 14, weight: .medium))
                                .foregroundColor(Theme.text)
                        }
                    }
                }
            }
        }
        .padding()
        .background(Color(UIColor.secondarySystemBackground))
        .cornerRadius(16)
    }
}

// MARK: - Saved This Month Widget
struct SavedThisMonthWidget: HomeWidget {
    var id = UUID()
    var title = "Saved This Month"
    var description = "Shows how much you saved this month"
    var iconName = "arrow.up.arrow.down"
    
    var view: AnyView {
        AnyView(SavedThisMonthWidgetView())
    }
    
    init() {}
    
    init?(id: UUID) {
        self.id = id
        return
    }
}

struct SavedThisMonthWidgetView: View {
    @EnvironmentObject var transactionManager: TransactionManager
    @EnvironmentObject var userManager: UserManager
    
    private var thisMonthIncome: Double {
        let calendar = Calendar.current
        let currentMonth = calendar.component(.month, from: Date())
        let currentYear = calendar.component(.year, from: Date())
        
        let transactions = transactionManager.getTransactionsForMonth(month: currentMonth, year: currentYear)
        return transactions.filter { $0.type == .income }.map { $0.amount }.reduce(0, +)
    }
    
    private var thisMonthExpenses: Double {
        let calendar = Calendar.current
        let currentMonth = calendar.component(.month, from: Date())
        let currentYear = calendar.component(.year, from: Date())
        
        let transactions = transactionManager.getTransactionsForMonth(month: currentMonth, year: currentYear)
        return transactions.filter { $0.type == .expense }.map { $0.amount }.reduce(0, +)
    }
    
    private var savedAmount: Double {
        return thisMonthIncome - thisMonthExpenses
    }
    
    private var savingRate: Double {
        guard thisMonthIncome > 0 else { return 0 }
        return (savedAmount / thisMonthIncome) * 100
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack {
                Image(systemName: "arrow.up.arrow.down")
                    .font(.system(size: 18))
                    .foregroundColor(Theme.text)
                
                Text("Saved This Month")
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundColor(Theme.text)
                
                Spacer()
            }
            
            Spacer()
            
            HStack(alignment: .bottom) {
                Text("\(userManager.currency)\(String(format: "%.0f", max(0, savedAmount)))")
                    .font(.system(size: 28, weight: .bold))
                    .foregroundColor(savedAmount >= 0 ? Theme.income : Theme.expense)
                
                Spacer()
                
                if thisMonthIncome > 0 {
                    Text("\(Int(max(0, savingRate)))% saved")
                        .font(.system(size: 16))
                        .foregroundColor(savingRate >= 0 ? Theme.income : Theme.expense)
                        .padding(.vertical, 4)
                        .padding(.horizontal, 10)
                        .background(savingRate >= 0 ? Theme.income.opacity(0.2) : Theme.expense.opacity(0.2))
                        .cornerRadius(12)
                }
            }
            
            if savedAmount < 0 {
                Text("You've spent more than you earned")
                    .font(.system(size: 14))
                    .foregroundColor(Theme.expense)
            } else if savingRate < 20 && thisMonthIncome > 0 {
                Text("Try to save at least 20% of your income")
                    .font(.system(size: 14))
                    .foregroundColor(Theme.text.opacity(0.7))
            } else if savingRate >= 20 && thisMonthIncome > 0 {
                Text("Great job saving! Keep it up")
                    .font(.system(size: 14))
                    .foregroundColor(Theme.income)
            }
            
            Spacer()
        }
        .padding()
        .background(Color(UIColor.secondarySystemBackground))
        .cornerRadius(16)
    }
}

// MARK: - Widget Picker View
struct WidgetPickerView: View {
    @Environment(\.presentationMode) var presentationMode
    @EnvironmentObject var widgetManager: WidgetManager
    
    var body: some View {
        NavigationView {
            List {
                ForEach(widgetManager.getAllWidgetTypes()) { widget in
                    Button(action: {
                        // Get the underlying widget from the AnyHomeWidget wrapper
                        let baseWidget = getBaseWidget(from: widget)
                        widgetManager.addWidget(baseWidget)
                        presentationMode.wrappedValue.dismiss()
                    }) {
                        HStack {
                            Image(systemName: widget.iconName)
                                .font(.system(size: 18))
                                .foregroundColor(.white)
                                .frame(width: 36, height: 36)
                                .background(Theme.primary)
                                .cornerRadius(8)
                            
                            VStack(alignment: .leading) {
                                Text(widget.title)
                                    .font(.system(size: 16, weight: .semibold))
                                    .foregroundColor(Theme.text)
                                
                                Text(widget.description)
                                    .font(.system(size: 14))
                                    .foregroundColor(Theme.text.opacity(0.7))
                            }
                            
                            Spacer()
                        }
                    }
                }
            }
            .navigationTitle("Add Widget")
            .navigationBarItems(trailing: Button("Cancel") {
                presentationMode.wrappedValue.dismiss()
            })
        }
    }
    
    // Helper function to get the base widget based on type
    private func getBaseWidget(from anyWidget: AnyHomeWidget) -> any HomeWidget {
        // This is a workaround since we can't extract the original widget
        // We create a new widget of the right type based on the widget's title
        switch anyWidget.title {
        case "Balance":
            return BalanceWidget()
        case "Spending Trend":
            return SpendingTrendWidget()
        case "Budget":
            return BudgetWidget()
        case "Goal":
            return GoalWidget()
        case "Expense Categories":
            return ExpenseCategoryWidget()
        case "Saved This Month":
            return SavedThisMonthWidget()
        default:
            return BalanceWidget() // Default fallback
        }
    }
} 
