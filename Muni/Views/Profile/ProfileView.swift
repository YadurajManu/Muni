//
//  ProfileView.swift
//  Muni
//
//  Created by Yaduraj Singh on 20/03/25.
//

import SwiftUI

struct ProfileView: View {
    @EnvironmentObject private var userManager: UserManager
    @EnvironmentObject private var transactionManager: TransactionManager
    @State private var userName: String = ""
    @State private var monthlyBudget: String = ""
    @State private var showAlert = false
    @State private var alertTitle = ""
    @State private var alertMessage = ""
    
    var body: some View {
        NavigationView {
            ScrollView {
                VStack(spacing: Theme.paddingLarge) {
                    // Profile header
                    profileHeader
                    
                    // User information card
                    userInfoCard
                    
                    // App statistics card
                    appStatisticsCard
                    
                    // Data management card
                    dataManagementCard
                    
                    // About app card
                    aboutAppCard
                }
                .padding(.vertical)
            }
            .background(Theme.background.ignoresSafeArea())
            .navigationTitle("Profile")
            .onAppear {
                userName = userManager.name
                monthlyBudget = String(format: "%.2f", userManager.monthlyBudget)
            }
            .alert(isPresented: $showAlert) {
                Alert(
                    title: Text(alertTitle),
                    message: Text(alertMessage),
                    dismissButton: .default(Text("OK"))
                )
            }
        }
    }
    
    private var profileHeader: some View {
        VStack(spacing: Theme.paddingMedium) {
            Image(systemName: "person.circle.fill")
                .resizable()
                .scaledToFit()
                .frame(width: 100, height: 100)
                .foregroundColor(Theme.primary)
                .padding(.top)
            
            Text(userManager.name)
                .font(.system(size: Theme.titleSize, weight: .bold))
                .foregroundColor(Theme.text)
            
            Text("Muni Money Manager")
                .font(.system(size: Theme.bodySize))
                .foregroundColor(Theme.text.opacity(0.7))
        }
    }
    
    private var userInfoCard: some View {
        VStack(alignment: .leading, spacing: Theme.paddingMedium) {
            Text("User Information")
                .font(.system(size: Theme.subtitleSize, weight: .semibold))
                .foregroundColor(Theme.text)
            
            VStack(spacing: Theme.paddingMedium) {
                // Name
                VStack(alignment: .leading, spacing: 4) {
                    Text("Your Name")
                        .font(.system(size: Theme.captionSize))
                        .foregroundColor(Theme.text.opacity(0.7))
                    
                    TextField("Enter your name", text: $userName)
                        .padding()
                        .background(Theme.secondary.opacity(0.3))
                        .cornerRadius(Theme.cornerRadiusSmall)
                        .onChange(of: userName) { newValue in
                            userManager.name = newValue
                            userManager.saveUserData()
                        }
                }
                
                // Monthly budget
                VStack(alignment: .leading, spacing: 4) {
                    Text("Monthly Budget")
                        .font(.system(size: Theme.captionSize))
                        .foregroundColor(Theme.text.opacity(0.7))
                    
                    HStack {
                        Text("₹")
                            .font(.system(size: Theme.bodySize, weight: .semibold))
                            .foregroundColor(Theme.text)
                        
                        TextField("0.00", text: $monthlyBudget)
                            .keyboardType(.decimalPad)
                            .padding()
                            .onChange(of: monthlyBudget) { newValue in
                                if let budget = Double(newValue) {
                                    userManager.monthlyBudget = budget
                                    userManager.saveUserData()
                                }
                            }
                    }
                    .background(Theme.secondary.opacity(0.3))
                    .cornerRadius(Theme.cornerRadiusSmall)
                }
            }
        }
        .padding()
        .background(Theme.background)
        .cardStyle()
        .padding(.horizontal)
    }
    
    private var appStatisticsCard: some View {
        VStack(alignment: .leading, spacing: Theme.paddingMedium) {
            Text("App Statistics")
                .font(.system(size: Theme.subtitleSize, weight: .semibold))
                .foregroundColor(Theme.text)
            
            HStack {
                StatisticItem(
                    title: "Transactions",
                    value: "\(transactionManager.transactions.count)",
                    icon: "list.bullet"
                )
                
                Spacer()
                
                StatisticItem(
                    title: "Balance",
                    value: "\(userManager.currency)\(String(format: "%.2f", transactionManager.balance()))",
                    icon: "indianrupeesign.circle"
                )
            }
        }
        .padding()
        .background(Theme.background)
        .cardStyle()
        .padding(.horizontal)
    }
    
    private var dataManagementCard: some View {
        VStack(alignment: .leading, spacing: Theme.paddingMedium) {
            Text("Data Management")
                .font(.system(size: Theme.subtitleSize, weight: .semibold))
                .foregroundColor(Theme.text)
            
            Button(action: resetAllData) {
                HStack {
                    Image(systemName: "trash")
                        .foregroundColor(Theme.expense)
                    
                    Text("Reset All Data")
                        .foregroundColor(Theme.expense)
                    
                    Spacer()
                    
                    Image(systemName: "chevron.right")
                        .foregroundColor(Theme.text.opacity(0.5))
                }
                .padding()
                .background(Theme.secondary.opacity(0.3))
                .cornerRadius(Theme.cornerRadiusMedium)
            }
        }
        .padding()
        .background(Theme.background)
        .cardStyle()
        .padding(.horizontal)
    }
    
    private var aboutAppCard: some View {
        VStack(alignment: .leading, spacing: Theme.paddingMedium) {
            Text("About")
                .font(.system(size: Theme.subtitleSize, weight: .semibold))
                .foregroundColor(Theme.text)
            
            VStack(spacing: Theme.paddingSmall) {
                rowItem(title: "Version", detail: "1.0.0")
                rowItem(title: "Build", detail: "1")
                rowItem(title: "Developer", detail: "Yaduraj Singh")
            }
            
            Text("Muni is a personal money management app designed specifically for Indian users. Track your expenses, manage your budget, and get AI-powered financial advice.")
                .font(.system(size: Theme.captionSize))
                .foregroundColor(Theme.text.opacity(0.7))
                .padding(.top, 8)
        }
        .padding()
        .background(Theme.background)
        .cardStyle()
        .padding(.horizontal)
    }
    
    private func rowItem(title: String, detail: String) -> some View {
        HStack {
            Text(title)
                .font(.system(size: Theme.bodySize))
                .foregroundColor(Theme.text)
            
            Spacer()
            
            Text(detail)
                .font(.system(size: Theme.bodySize))
                .foregroundColor(Theme.text.opacity(0.7))
        }
    }
    
    private func resetAllData() {
        // Show confirmation alert
        alertTitle = "Reset All Data"
        alertMessage = "Are you sure you want to reset all your data? This action cannot be undone."
        showAlert = true
        
        // Reset user data and transactions
        userManager.name = ""
        userManager.monthlyBudget = 0.0
        userManager.saveUserData()
        
        transactionManager.transactions = []
        transactionManager.saveTransactions()
        
        // Reset UI fields
        userName = ""
        monthlyBudget = "0.00"
    }
}

struct StatisticItem: View {
    let title: String
    let value: String
    let icon: String
    
    var body: some View {
        VStack(spacing: 8) {
            Image(systemName: icon)
                .font(.system(size: 24))
                .foregroundColor(Theme.primary)
            
            Text(value)
                .font(.system(size: Theme.subtitleSize, weight: .bold))
                .foregroundColor(Theme.text)
            
            Text(title)
                .font(.system(size: Theme.captionSize))
                .foregroundColor(Theme.text.opacity(0.7))
        }
        .frame(maxWidth: .infinity)
        .padding()
        .background(Theme.secondary.opacity(0.3))
        .cornerRadius(Theme.cornerRadiusMedium)
    }
} 