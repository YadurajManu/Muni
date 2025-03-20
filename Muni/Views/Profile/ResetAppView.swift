import SwiftUI

struct ResetAppView: View {
    @Environment(\.presentationMode) private var presentationMode
    @EnvironmentObject private var userManager: UserManager
    @EnvironmentObject private var transactionManager: TransactionManager
    
    @State private var showingConfirmation = false
    @State private var isResetCompleted = false
    @State private var selectedOptions = ResetOptions()
    
    var body: some View {
        List {
            Section(header: Text("Reset Options")) {
                Toggle("Transactions", isOn: $selectedOptions.transactions)
                Toggle("Budget Settings", isOn: $selectedOptions.budgetSettings)
                Toggle("Profile Information", isOn: $selectedOptions.profileInfo)
                Toggle("App Preferences", isOn: $selectedOptions.appPreferences)
                Toggle("Appearance Settings", isOn: $selectedOptions.appearanceSettings)
            }
            .listRowBackground(Color(UIColor.secondarySystemBackground))
            
            Section {
                VStack(alignment: .leading, spacing: 8) {
                    Text("Warning")
                        .font(.headline)
                        .foregroundColor(.red)
                    
                    Text("Resetting the app will permanently delete the selected data. This action cannot be undone.")
                        .font(.subheadline)
                        .foregroundColor(Theme.text.opacity(0.8))
                }
                .padding(.vertical, 8)
            }
            .listRowBackground(Color.red.opacity(0.1))
            
            Section {
                Button(action: {
                    showingConfirmation = true
                }) {
                    HStack {
                        Spacer()
                        Text("Reset App")
                            .fontWeight(.bold)
                        Spacer()
                    }
                }
                .foregroundColor(.red)
            }
            .listRowBackground(Color(UIColor.secondarySystemBackground))
        }
        .background(Theme.background)
        .navigationTitle("Reset App")
        .alert("Reset App", isPresented: $showingConfirmation) {
            Button("Cancel", role: .cancel) { }
            Button("Reset", role: .destructive) {
                resetApp()
            }
        } message: {
            Text("Are you sure you want to reset the app? This will delete all your selected data and cannot be undone.")
        }
        .alert("Reset Complete", isPresented: $isResetCompleted) {
            Button("OK") {
                presentationMode.wrappedValue.dismiss()
            }
        } message: {
            Text("The app has been reset successfully. The app will now close and you can relaunch it.")
        }
    }
    
    private func resetApp() {
        // Reset transactions
        if selectedOptions.transactions {
            transactionManager.transactions = []
        }
        
        // Reset budget settings
        if selectedOptions.budgetSettings {
            userManager.monthlyBudget = 0
            userManager.monthlyIncome = 0
            UserDefaults.standard.removeObject(forKey: "categoryBudgets")
        }
        
        // Reset profile information
        if selectedOptions.profileInfo {
            userManager.name = ""
            userManager.financialGoal = ""
        }
        
        // Reset app preferences
        if selectedOptions.appPreferences {
            UserDefaults.standard.removeObject(forKey: "notifyForLargeTransactions")
            UserDefaults.standard.removeObject(forKey: "notifyForBudgetExceeded")
            UserDefaults.standard.removeObject(forKey: "notifyForRecurringTransactions")
            UserDefaults.standard.removeObject(forKey: "notifyForGoalProgress")
            UserDefaults.standard.removeObject(forKey: "largeTransactionThreshold")
            UserDefaults.standard.removeObject(forKey: "useBiometrics")
            UserDefaults.standard.removeObject(forKey: "requireAuthForTransactions")
            UserDefaults.standard.removeObject(forKey: "autoBackupEnabled")
            UserDefaults.standard.removeObject(forKey: "backupFrequency")
            UserDefaults.standard.removeObject(forKey: "lastBackupDate")
        }
        
        // Reset appearance settings
        if selectedOptions.appearanceSettings {
            UserDefaults.standard.removeObject(forKey: "appTheme")
            UserDefaults.standard.removeObject(forKey: "accentColor")
        }
        
        // If all options are selected, reset everything including defaults
        if selectedOptions.isFullReset {
            if let bundleID = Bundle.main.bundleIdentifier {
                UserDefaults.standard.removePersistentDomain(forName: bundleID)
                UserDefaults.standard.synchronize()
            }
            
            // Reset all app data
            transactionManager.transactions = []
            userManager.name = ""
            userManager.monthlyBudget = 0
            userManager.monthlyIncome = 0
            userManager.financialGoal = ""
            userManager.currency = "₹" // Reset to default Indian Rupee
            
            // Post notification to reset app state
            NotificationCenter.default.post(name: Notification.Name("ResetAppState"), object: nil)
        }
        
        // Show completion alert
        isResetCompleted = true
    }
}

// Model to track which elements to reset
struct ResetOptions {
    var transactions = true
    var budgetSettings = true
    var profileInfo = true
    var appPreferences = true
    var appearanceSettings = true
    
    var isFullReset: Bool {
        transactions && budgetSettings && profileInfo && appPreferences && appearanceSettings
    }
}

struct ResetAppView_Previews: PreviewProvider {
    static var previews: some View {
        NavigationView {
            ResetAppView()
                .environmentObject(UserManager())
                .environmentObject(TransactionManager())
        }
    }
} 