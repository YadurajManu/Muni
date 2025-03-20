//
//  BudgetPlanningView.swift
//  Muni
//
//  Created by Yaduraj Singh on 20/03/25.
//

import SwiftUI

struct BudgetPlanningView: View {
    @EnvironmentObject private var transactionManager: TransactionManager
    @EnvironmentObject private var userManager: UserManager
    @Environment(\.presentationMode) var presentationMode
    
    @State private var allocations: [BudgetAllocation] = []
    @State private var isEditing = false
    @State private var editedAllocations: [BudgetAllocation] = []
    @State private var showingSaveConfirmation = false
    
    private let gridColumns = [
        GridItem(.flexible()),
        GridItem(.flexible())
    ]
    
    var body: some View {
        NavigationView {
            ScrollView {
                VStack(spacing: 24) {
                    // Header
                    budgetSummaryHeader
                    
                    // AI recommendation explanation
                    aiExplanationCard
                    
                    // Budget allocations
                    budgetAllocationsSection
                    
                    // Savings recommendation based on financial goal
                    financialGoalSection
                    
                    // Action buttons
                    actionButtons
                }
                .padding()
            }
            .background(Theme.background.ignoresSafeArea())
            .navigationTitle("Smart Budget Plan")
            .navigationBarTitleDisplayMode(.inline)
            .navigationBarItems(leading: Button("Cancel") {
                presentationMode.wrappedValue.dismiss()
            }, trailing: Button(isEditing ? "Done" : "Edit") {
                if isEditing {
                    saveChanges()
                } else {
                    startEditing()
                }
            })
            .onAppear {
                generateRecommendations()
            }
            .alert(isPresented: $showingSaveConfirmation) {
                Alert(
                    title: Text("Budget Updated"),
                    message: Text("Your personalized budget has been saved."),
                    dismissButton: .default(Text("OK")) {
                        presentationMode.wrappedValue.dismiss()
                    }
                )
            }
        }
    }
    
    private var budgetSummaryHeader: some View {
        VStack(spacing: 16) {
            HStack {
                Text("Monthly Income")
                    .font(.system(size: 16, weight: .medium))
                    .foregroundColor(Theme.text.opacity(0.7))
                
                Spacer()
                
                Text(CurrencyFormatter.shared.formatForDisplay(number: userManager.monthlyIncome))
                    .font(.system(size: 20, weight: .bold))
                    .foregroundColor(Theme.text)
            }
            
            HStack {
                Text("Available for Budgeting")
                    .font(.system(size: 16, weight: .medium))
                    .foregroundColor(Theme.text.opacity(0.7))
                
                Spacer()
                
                Text(CurrencyFormatter.shared.formatForDisplay(number: userManager.monthlyIncome))
                    .font(.system(size: 20, weight: .bold))
                    .foregroundColor(Theme.income)
            }
            
            Divider()
                .background(Theme.text.opacity(0.2))
                .padding(.vertical, 8)
            
            HStack {
                Text("Goal")
                    .font(.system(size: 16, weight: .medium))
                    .foregroundColor(Theme.text.opacity(0.7))
                
                Spacer()
                
                Text(userManager.financialGoal.isEmpty ? "None set" : userManager.financialGoal)
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundColor(Theme.text)
            }
        }
        .padding()
        .background(Theme.background)
        .cardStyle()
    }
    
    private var aiExplanationCard: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack {
                Image(systemName: "brain.fill")
                    .font(.system(size: 22))
                    .foregroundColor(Theme.primary)
                
                Text("AI-Powered Budget Recommendations")
                    .font(.system(size: 18, weight: .semibold))
                    .foregroundColor(Theme.text)
            }
            
            Text("Based on your income, goals, and spending habits, we've created a personalized budget that optimizes for your financial success.")
                .font(.system(size: 15))
                .foregroundColor(Theme.text.opacity(0.8))
                .fixedSize(horizontal: false, vertical: true)
        }
        .padding()
        .background(Theme.secondary.opacity(0.3))
        .cornerRadius(12)
    }
    
    private var budgetAllocationsSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Recommended Allocations")
                .font(.system(size: 18, weight: .semibold))
                .foregroundColor(Theme.text)
            
            if isEditing {
                editableBudgetAllocations
            } else {
                displayBudgetAllocations
            }
        }
        .padding()
        .background(Theme.background)
        .cardStyle()
    }
    
    private var displayBudgetAllocations: some View {
        VStack(spacing: 0) {
            ForEach(allocations, id: \.category) { allocation in
                HStack {
                    Image(systemName: allocation.category.icon)
                        .foregroundColor(Theme.primary)
                        .frame(width: 30)
                    
                    Text(allocation.category.rawValue)
                        .font(.system(size: 16))
                        .foregroundColor(Theme.text)
                    
                    Spacer()
                    
                    VStack(alignment: .trailing, spacing: 4) {
                        Text(CurrencyFormatter.shared.formatForDisplay(number: allocation.amount))
                            .font(.system(size: 16, weight: .semibold))
                            .foregroundColor(Theme.text)
                        
                        Text("\(Int(allocation.percentage))%")
                            .font(.system(size: 14))
                            .foregroundColor(Theme.text.opacity(0.7))
                    }
                }
                .padding(.vertical, 12)
                
                if allocation.category != allocations.last?.category {
                    Divider()
                        .background(Theme.text.opacity(0.1))
                }
            }
        }
    }
    
    private var editableBudgetAllocations: some View {
        VStack(spacing: 0) {
            ForEach(0..<editedAllocations.count, id: \.self) { index in
                HStack {
                    Image(systemName: editedAllocations[index].category.icon)
                        .foregroundColor(Theme.primary)
                        .frame(width: 30)
                    
                    Text(editedAllocations[index].category.rawValue)
                        .font(.system(size: 16))
                        .foregroundColor(Theme.text)
                    
                    Spacer()
                    
                    // Stepper for percentage
                    Stepper(
                        value: $editedAllocations[index].percentage,
                        in: 1...50,
                        step: 1,
                        onEditingChanged: { _ in updateAllocationAmount(index: index) }
                    ) {
                        VStack(alignment: .trailing, spacing: 4) {
                            Text(CurrencyFormatter.shared.formatForDisplay(number: editedAllocations[index].amount))
                                .font(.system(size: 16, weight: .semibold))
                                .foregroundColor(Theme.text)
                            
                            Text("\(Int(editedAllocations[index].percentage))%")
                                .font(.system(size: 14))
                                .foregroundColor(Theme.primary)
                        }
                    }
                }
                .padding(.vertical, 12)
                
                if index < editedAllocations.count - 1 {
                    Divider()
                        .background(Theme.text.opacity(0.1))
                }
            }
            
            // Total percentage indicator
            HStack {
                Text("Total Allocated")
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundColor(Theme.text)
                
                Spacer()
                
                Text("\(totalPercentage)%")
                    .font(.system(size: 18, weight: .bold))
                    .foregroundColor(totalPercentage == 100 ? Theme.income : Theme.expense)
            }
            .padding(.top, 20)
        }
    }
    
    private var totalPercentage: Int {
        Int(editedAllocations.map { $0.percentage }.reduce(0, +))
    }
    
    private var financialGoalSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Savings Recommendation")
                .font(.system(size: 18, weight: .semibold))
                .foregroundColor(Theme.text)
            
            if !userManager.financialGoal.isEmpty {
                VStack(alignment: .leading, spacing: 12) {
                    HStack(spacing: 16) {
                        GoalIconView(goal: userManager.financialGoal)
                            .frame(width: 50, height: 50)
                        
                        VStack(alignment: .leading, spacing: 4) {
                            Text(userManager.financialGoal)
                                .font(.system(size: 16, weight: .semibold))
                                .foregroundColor(Theme.text)
                            
                            Text("Based on your selected financial goal")
                                .font(.system(size: 14))
                                .foregroundColor(Theme.text.opacity(0.7))
                        }
                    }
                    
                    Divider()
                        .background(Theme.text.opacity(0.1))
                        .padding(.vertical, 4)
                    
                    HStack {
                        Text("Recommended Monthly Savings")
                            .font(.system(size: 16))
                            .foregroundColor(Theme.text)
                        
                        Spacer()
                        
                        // Calculate 20% of income as default savings recommendation
                        Text(CurrencyFormatter.shared.formatForDisplay(number: userManager.monthlyIncome * 0.2))
                            .font(.system(size: 16, weight: .semibold))
                            .foregroundColor(Theme.income)
                    }
                    
                    Text("We recommend setting aside this amount each month to achieve your financial goal. These funds should be allocated to a separate savings or investment account.")
                        .font(.system(size: 14))
                        .foregroundColor(Theme.text.opacity(0.7))
                        .fixedSize(horizontal: false, vertical: true)
                        .padding(.top, 4)
                }
            } else {
                HStack {
                    Image(systemName: "exclamationmark.triangle")
                        .foregroundColor(.orange)
                    
                    Text("Set a financial goal to get personalized savings recommendations")
                        .font(.system(size: 15))
                        .foregroundColor(Theme.text.opacity(0.7))
                }
                .padding()
                .frame(maxWidth: .infinity, alignment: .leading)
                .background(Theme.secondary.opacity(0.3))
                .cornerRadius(12)
            }
        }
        .padding()
        .background(Theme.background)
        .cardStyle()
    }
    
    private var actionButtons: some View {
        VStack(spacing: 12) {
            Button(action: {
                // Apply the budget (same as save)
                if isEditing {
                    saveChanges()
                } else {
                    // If not editing, set the recommendations as the budget
                    showingSaveConfirmation = true
                }
            }) {
                Text("Apply This Budget")
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundColor(.white)
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(Theme.primary)
                    .cornerRadius(12)
            }
            
            Button(action: {
                // This would trigger an AI explanation in a real app
            }) {
                HStack {
                    Image(systemName: "lightbulb.fill")
                        .foregroundColor(Theme.primary)
                    
                    Text("Explain This Budget")
                        .font(.system(size: 16))
                        .foregroundColor(Theme.primary)
                }
                .frame(maxWidth: .infinity)
                .padding()
                .background(Color.clear)
                .overlay(
                    RoundedRectangle(cornerRadius: 12)
                        .stroke(Theme.primary, lineWidth: 1)
                )
            }
        }
    }
    
    private func generateRecommendations() {
        // Generate personalized recommendations
        allocations = BudgetRecommendationEngine.shared.generateRecommendations(
            monthlyIncome: userManager.monthlyIncome,
            selectedGoal: userManager.financialGoal,
            primaryExpenseCategory: userManager.primaryExpenseCategory,
            recentTransactions: transactionManager.transactions
        )
        
        // Set initial edited allocations
        editedAllocations = allocations
    }
    
    private func startEditing() {
        editedAllocations = allocations
        isEditing = true
    }
    
    private func saveChanges() {
        if totalPercentage == 100 {
            allocations = editedAllocations
            isEditing = false
            showingSaveConfirmation = true
        } else {
            // In a real app, show an alert about the percentage not adding up to 100%
            normalizeAllocations()
            allocations = editedAllocations
            isEditing = false
            showingSaveConfirmation = true
        }
    }
    
    private func updateAllocationAmount(index: Int) {
        // Update the amount based on percentage
        let percentage = editedAllocations[index].percentage / 100.0
        editedAllocations[index].amount = userManager.monthlyIncome * percentage
    }
    
    private func normalizeAllocations() {
        // Get the total percentage
        let total = editedAllocations.map { $0.percentage }.reduce(0, +)
        
        // Normalize each allocation
        for i in 0..<editedAllocations.count {
            let normalizedPercentage = (editedAllocations[i].percentage / total) * 100
            editedAllocations[i].percentage = normalizedPercentage
            editedAllocations[i].amount = userManager.monthlyIncome * (normalizedPercentage / 100)
        }
    }
} 