import SwiftUI
import LocalAuthentication
import UserNotifications

struct AppSettingsView: View {
    @Environment(\.presentationMode) private var presentationMode
    @AppStorage("appTheme") private var appTheme = AppTheme.system.rawValue
    @AppStorage("hapticFeedbackEnabled") private var hapticFeedbackEnabled = true
    @AppStorage("soundEffectsEnabled") private var soundEffectsEnabled = true
    @AppStorage("showTransactionAmounts") private var showTransactionAmounts = true
    @AppStorage("defaultCurrencyCode") private var defaultCurrencyCode = "INR"
    @AppStorage("defaultStartTab") private var defaultStartTab = 0
    
    private let tabOptions = ["Dashboard", "Transactions", "Budget", "Insights", "Profile"]
    @State private var showingTabPicker = false
    
    var body: some View {
        List {
            Section(header: Text("Appearance")) {
                Picker("Theme", selection: $appTheme) {
                    ForEach(AppTheme.allCases) { theme in
                        Label(theme.name, systemImage: theme.iconName)
                            .tag(theme.rawValue)
                    }
                }
                .pickerStyle(NavigationLinkPickerStyle())
            }
            
            Section(header: Text("Interaction")) {
                Toggle("Haptic Feedback", isOn: $hapticFeedbackEnabled)
                Toggle("Sound Effects", isOn: $soundEffectsEnabled)
            }
            
            Section(header: Text("Privacy")) {
                Toggle("Show Transaction Amounts", isOn: $showTransactionAmounts)
                    .onChange(of: showTransactionAmounts) { newValue in
                        if !newValue {
                            // Trigger authentication if hiding amounts
                            authenticateToHideAmounts()
                        }
                    }
            }
            
            Section(header: Text("Default Settings")) {
                Button(action: { showingTabPicker = true }) {
                    HStack {
                        Text("Start Tab")
                        Spacer()
                        Text(tabOptions[defaultStartTab])
                            .foregroundColor(.gray)
                    }
                }
            }
            
            Section(header: Text("Data & Privacy")) {
                Button(action: {
                    if let url = URL(string: UIApplication.openSettingsURLString) {
                        UIApplication.shared.open(url)
                    }
                }) {
                    Text("System Settings")
                }
                
                NavigationLink(destination: Text("Privacy Policy")) {
                    Text("Privacy Policy")
                }
                
                NavigationLink(destination: Text("Terms of Service")) {
                    Text("Terms of Service")
                }
            }
        }
        .navigationTitle("App Settings")
        .navigationBarItems(trailing: Button("Done") {
            presentationMode.wrappedValue.dismiss()
        })
        .actionSheet(isPresented: $showingTabPicker) {
            ActionSheet(
                title: Text("Choose Start Tab"),
                message: Text("Select which tab to show when app launches"),
                buttons: tabOptions.enumerated().map { index, name in
                    .default(Text(name)) {
                        defaultStartTab = index
                    }
                } + [.cancel()]
            )
        }
    }
    
    private func authenticateToHideAmounts() {
        let context = LAContext()
        var error: NSError?
        
        if context.canEvaluatePolicy(.deviceOwnerAuthentication, error: &error) {
            context.evaluatePolicy(.deviceOwnerAuthentication, localizedReason: "Authentication required to hide transaction amounts") { success, error in
                DispatchQueue.main.async {
                    if !success {
                        // Authentication failed, revert the toggle
                        showTransactionAmounts = true
                    }
                }
            }
        } else {
            // Device doesn't support authentication, revert the toggle
            showTransactionAmounts = true
        }
    }
}

struct AppSettingsView_Previews: PreviewProvider {
    static var previews: some View {
        NavigationView {
            AppSettingsView()
        }
    }
} 