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
    
    init() {
        loadUserData()
    }
    
    // Save user data to UserDefaults
    func saveUserData() {
        let defaults = UserDefaults.standard
        defaults.set(name, forKey: "userName")
        defaults.set(currency, forKey: "userCurrency")
        defaults.set(monthlyBudget, forKey: "monthlyBudget")
    }
    
    // Load user data from UserDefaults
    func loadUserData() {
        let defaults = UserDefaults.standard
        name = defaults.string(forKey: "userName") ?? ""
        currency = defaults.string(forKey: "userCurrency") ?? "₹"
        monthlyBudget = defaults.double(forKey: "monthlyBudget")
    }
} 