import SwiftUI
import UserNotifications

struct NotificationPreferencesView: View {
    @Environment(\.presentationMode) private var presentationMode
    @AppStorage("notifyForLargeTransactions") private var notifyForLargeTransactions = true
    @AppStorage("notifyForBudgetExceeded") private var notifyForBudgetExceeded = true
    @AppStorage("notifyForRecurringTransactions") private var notifyForRecurringTransactions = true
    @AppStorage("notifyForGoalProgress") private var notifyForGoalProgress = true
    @AppStorage("largeTransactionThreshold") private var largeTransactionThreshold = 1000.0
    @State private var showingPermissionDenied = false
    
    var body: some View {
        List {
            Section(header: Text("Transaction Alerts")) {
                Toggle("Large Transactions", isOn: $notifyForLargeTransactions)
                
                if notifyForLargeTransactions {
                    HStack {
                        Text("Threshold Amount")
                        Spacer()
                        TextField("Amount", value: $largeTransactionThreshold, format: .number)
                            .keyboardType(.decimalPad)
                            .multilineTextAlignment(.trailing)
                            .frame(width: 100)
                    }
                }
                
                Toggle("Budget Exceeded", isOn: $notifyForBudgetExceeded)
                Toggle("Recurring Transactions", isOn: $notifyForRecurringTransactions)
            }
            
            Section(header: Text("Goals & Progress")) {
                Toggle("Goal Progress Updates", isOn: $notifyForGoalProgress)
            }
            
            Section {
                Button(action: checkNotificationPermissions) {
                    Text("Test Notifications")
                }
                
                Button(action: openSettings) {
                    Text("Open System Settings")
                }
            }
        }
        .navigationTitle("Notifications")
        .alert("Permission Denied", isPresented: $showingPermissionDenied) {
            Button("Open Settings", action: openSettings)
            Button("Cancel", role: .cancel) { }
        } message: {
            Text("Please enable notifications in system settings to receive alerts.")
        }
        .onAppear {
            checkCurrentPermissionStatus()
        }
    }
    
    private func checkCurrentPermissionStatus() {
        UNUserNotificationCenter.current().getNotificationSettings { settings in
            DispatchQueue.main.async {
                if settings.authorizationStatus == .denied {
                    showingPermissionDenied = true
                }
            }
        }
    }
    
    private func checkNotificationPermissions() {
        UNUserNotificationCenter.current().requestAuthorization(options: [.alert, .badge, .sound]) { granted, error in
            DispatchQueue.main.async {
                if granted {
                    sendTestNotification()
                } else {
                    showingPermissionDenied = true
                }
            }
        }
    }
    
    private func sendTestNotification() {
        let content = UNMutableNotificationContent()
        content.title = "Test Notification"
        content.body = "Your notifications are working correctly!"
        content.sound = .default
        
        let trigger = UNTimeIntervalNotificationTrigger(timeInterval: 5, repeats: false)
        let request = UNNotificationRequest(identifier: UUID().uuidString, content: content, trigger: trigger)
        
        UNUserNotificationCenter.current().add(request)
    }
    
    private func openSettings() {
        if let url = URL(string: UIApplication.openSettingsURLString) {
            UIApplication.shared.open(url)
        }
    }
} 