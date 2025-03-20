//
//  UserManager.swift
//  Muni
//
//  Created by Yaduraj Singh on 20/03/25.
//

import Foundation
import SwiftUI

class UserManager: ObservableObject {
    @Published var name: String = ""
    @Published var currency: String = "₹"
    @Published var monthlyBudget: Double = 0.0
    @Published var monthlyIncome: Double = 0.0
    @Published var financialGoal: String = ""
    @Published var primaryExpenseCategory: TransactionCategory = .food
    @Published var darkModeEnabled: Bool = false
    @Published var notificationsEnabled: Bool = true
    @Published var onboardingCompleted: Bool = false
    
    init() {
        loadUserData()
    }
    
    // Save user data to UserDefaults
    func saveUserData() {
        let defaults = UserDefaults.standard
        defaults.set(name, forKey: "userName")
        defaults.set(currency, forKey: "userCurrency")
        defaults.set(monthlyBudget, forKey: "monthlyBudget")
        defaults.set(monthlyIncome, forKey: "monthlyIncome")
        defaults.set(financialGoal, forKey: "financialGoal")
        defaults.set(primaryExpenseCategory.rawValue, forKey: "primaryExpenseCategory")
        defaults.set(darkModeEnabled, forKey: "darkModeEnabled")
        defaults.set(notificationsEnabled, forKey: "notificationsEnabled")
        defaults.set(onboardingCompleted, forKey: "onboardingCompleted")
    }
    
    // Load user data from UserDefaults
    func loadUserData() {
        let defaults = UserDefaults.standard
        name = defaults.string(forKey: "userName") ?? ""
        currency = defaults.string(forKey: "userCurrency") ?? "₹"
        monthlyBudget = defaults.double(forKey: "monthlyBudget")
        monthlyIncome = defaults.double(forKey: "monthlyIncome")
        financialGoal = defaults.string(forKey: "financialGoal") ?? ""
        
        if let categoryString = defaults.string(forKey: "primaryExpenseCategory"),
           let category = TransactionCategory(rawValue: categoryString) {
            primaryExpenseCategory = category
        }
        
        darkModeEnabled = defaults.bool(forKey: "darkModeEnabled")
        notificationsEnabled = defaults.bool(forKey: "notificationsEnabled")
        onboardingCompleted = defaults.bool(forKey: "onboardingCompleted")
    }
    
    // Complete onboarding
    func completeOnboarding() {
        onboardingCompleted = true
        saveUserData()
        UserDefaults.standard.set(true, forKey: "hasCompletedOnboarding")
    }
    
    // Financial goals options
    static func financialGoalOptions() -> [String] {
        return [
            "Save for an emergency fund",
            "Pay off debt",
            "Save for a major purchase",
            "Build investment portfolio",
            "Track day-to-day expenses",
            "Reduce unnecessary spending",
            "Financial independence",
            "Other"
        ]
    }
} 