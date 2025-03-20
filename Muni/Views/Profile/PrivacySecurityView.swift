import SwiftUI
import LocalAuthentication

struct PrivacySecurityView: View {
    @AppStorage("useBiometrics") private var useBiometrics = false
    @AppStorage("requireAuthForTransactions") private var requireAuthForTransactions = false
    @AppStorage("hideBalanceInBackground") private var hideBalanceInBackground = true
    @AppStorage("exportDataEncryption") private var exportDataEncryption = true
    @State private var showingBiometricError = false
    @State private var biometricErrorMessage = ""
    @State private var showingPrivacyPolicy = false
    @State private var showingDataDeletion = false
    
    var body: some View {
        List {
            Section(header: Text("Authentication")) {
                Toggle("Use Face ID / Touch ID", isOn: $useBiometrics)
                    .onChange(of: useBiometrics) { newValue in
                        if newValue {
                            checkBiometricSupport()
                        }
                    }
                
                if useBiometrics {
                    Toggle("Require for Transactions", isOn: $requireAuthForTransactions)
                }
            }
            
            Section(header: Text("Privacy")) {
                Toggle("Hide Balance in Background", isOn: $hideBalanceInBackground)
                Toggle("Encrypt Exported Data", isOn: $exportDataEncryption)
            }
            
            Section {
                Button(action: { showingPrivacyPolicy = true }) {
                    Text("Privacy Policy")
                }
                
                Button(action: { showingDataDeletion = true }) {
                    Text("Delete All Data")
                        .foregroundColor(.red)
                }
            }
        }
        .navigationTitle("Privacy & Security")
        .alert("Biometric Error", isPresented: $showingBiometricError) {
            Button("OK", role: .cancel) {
                useBiometrics = false
            }
        } message: {
            Text(biometricErrorMessage)
        }
        .alert("Delete Data", isPresented: $showingDataDeletion) {
            Button("Delete", role: .destructive, action: deleteAllData)
            Button("Cancel", role: .cancel) { }
        } message: {
            Text("This will permanently delete all your financial data. This action cannot be undone.")
        }
        .sheet(isPresented: $showingPrivacyPolicy) {
            PrivacyPolicyView()
        }
    }
    
    private func checkBiometricSupport() {
        let context = LAContext()
        var error: NSError?
        
        if context.canEvaluatePolicy(.deviceOwnerAuthenticationWithBiometrics, error: &error) {
            // Biometric authentication is available
            authenticateUser()
        } else {
            biometricErrorMessage = error?.localizedDescription ?? "Biometric authentication is not available on this device."
            showingBiometricError = true
        }
    }
    
    private func authenticateUser() {
        let context = LAContext()
        context.evaluatePolicy(.deviceOwnerAuthenticationWithBiometrics,
                             localizedReason: "Enable biometric authentication for Muni") { success, error in
            DispatchQueue.main.async {
                if !success {
                    biometricErrorMessage = error?.localizedDescription ?? "Authentication failed."
                    showingBiometricError = true
                    useBiometrics = false
                }
            }
        }
    }
    
    private func deleteAllData() {
        // Clear UserDefaults
        if let bundleID = Bundle.main.bundleIdentifier {
            UserDefaults.standard.removePersistentDomain(forName: bundleID)
        }
        
        // Clear any stored files
        if let documentsPath = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first {
            try? FileManager.default.removeItem(at: documentsPath)
            try? FileManager.default.createDirectory(at: documentsPath, withIntermediateDirectories: true)
        }
        
        // Post notification to reset app state
        NotificationCenter.default.post(name: Notification.Name("ResetAppState"), object: nil)
    }
}

struct PrivacyPolicyView: View {
    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 20) {
                Text("Privacy Policy")
                    .font(.title)
                    .bold()
                
                Group {
                    Text("Data Collection")
                        .font(.headline)
                    Text("Muni collects only the financial data you input directly into the app. This includes transactions, budgets, and personal financial goals. We do not collect any data without your explicit input.")
                    
                    Text("Data Storage")
                        .font(.headline)
                    Text("All your data is stored locally on your device. We use industry-standard encryption to protect your sensitive financial information.")
                    
                    Text("Biometric Data")
                        .font(.headline)
                    Text("When you enable biometric authentication, we use Apple's secure Face ID/Touch ID systems. We never store or have access to your biometric data.")
                    
                    Text("Data Export")
                        .font(.headline)
                    Text("When you export your data, it is encrypted by default. You can disable this in settings, but we recommend keeping it enabled for security.")
                }
                
                Spacer()
            }
            .padding()
        }
        .navigationTitle("Privacy Policy")
        .navigationBarTitleDisplayMode(.inline)
    }
} 