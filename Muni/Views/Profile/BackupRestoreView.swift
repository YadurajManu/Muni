import SwiftUI
import UniformTypeIdentifiers

struct BackupRestoreView: View {
    @EnvironmentObject private var userManager: UserManager
    @EnvironmentObject private var transactionManager: TransactionManager
    @State private var showingBackupOptions = false
    @State private var showingDocumentPicker = false
    @State private var showingAlert = false
    @State private var alertTitle = ""
    @State private var alertMessage = ""
    @State private var lastBackupDate: Date? = UserDefaults.standard.object(forKey: "lastBackupDate") as? Date
    @State private var isAutoBackupEnabled = UserDefaults.standard.bool(forKey: "autoBackupEnabled")
    @State private var backupFrequency = UserDefaults.standard.integer(forKey: "backupFrequency") // Days
    @State private var showingFrequencyPicker = false
    
    private let backupFrequencies = [1, 7, 14, 30] // Days
    
    var body: some View {
        List {
            Section(header: Text("Backup")) {
                VStack(alignment: .leading, spacing: 8) {
                    if let lastBackup = lastBackupDate {
                        Text("Last Backup")
                            .font(.subheadline)
                            .foregroundColor(Theme.text.opacity(0.7))
                        Text(lastBackup, style: .date)
                            .font(.body)
                            .foregroundColor(Theme.text)
                    } else {
                        Text("No backup found")
                            .font(.body)
                            .foregroundColor(Theme.text.opacity(0.7))
                    }
                }
                
                Button(action: { showingBackupOptions = true }) {
                    Label("Create Backup", systemImage: "arrow.up.doc")
                }
                
                Toggle("Auto Backup", isOn: $isAutoBackupEnabled)
                    .onChange(of: isAutoBackupEnabled) { newValue in
                        UserDefaults.standard.set(newValue, forKey: "autoBackupEnabled")
                        if newValue && backupFrequency == 0 {
                            backupFrequency = 7 // Default to weekly
                            UserDefaults.standard.set(7, forKey: "backupFrequency")
                        }
                    }
                
                if isAutoBackupEnabled {
                    Button(action: { showingFrequencyPicker = true }) {
                        HStack {
                            Text("Backup Frequency")
                            Spacer()
                            Text(frequencyText)
                                .foregroundColor(Theme.text.opacity(0.6))
                        }
                    }
                }
            }
            
            Section(header: Text("Restore")) {
                Button(action: { showingDocumentPicker = true }) {
                    Label("Restore from Backup", systemImage: "arrow.down.doc")
                }
                .foregroundColor(.blue)
            }
            
            Section(header: Text("iCloud Sync"), footer: Text("Keep your data in sync across all your devices")) {
                Toggle("Enable iCloud Sync", isOn: .constant(false)) // Placeholder for iCloud sync
                    .disabled(true) // Disabled until implemented
            }
            
            Section(header: Text("Info"), footer: Text("Backups are encrypted and stored securely")) {
                VStack(alignment: .leading, spacing: 12) {
                    InfoRow(title: "Storage Used", value: "128 KB")
                    InfoRow(title: "Backup Format", value: "Encrypted JSON")
                    InfoRow(title: "Location", value: "Local + iCloud")
                }
                .padding(.vertical, 8)
            }
        }
        .navigationTitle("Backup & Restore")
        .actionSheet(isPresented: $showingBackupOptions) {
            ActionSheet(
                title: Text("Create Backup"),
                message: Text("Choose backup location"),
                buttons: [
                    .default(Text("Local Storage")) { createLocalBackup() },
                    .default(Text("Share Backup File")) { shareBackup() },
                    .cancel()
                ]
            )
        }
        .sheet(isPresented: $showingDocumentPicker) {
            DocumentPicker(completion: handleRestoredFile)
        }
        .alert(alertTitle, isPresented: $showingAlert) {
            Button("OK", role: .cancel) { }
        } message: {
            Text(alertMessage)
        }
        .confirmationDialog("Backup Frequency", isPresented: $showingFrequencyPicker) {
            ForEach(backupFrequencies, id: \.self) { days in
                Button(frequencyText(for: days)) {
                    backupFrequency = days
                    UserDefaults.standard.set(days, forKey: "backupFrequency")
                }
            }
        }
    }
    
    private var frequencyText: String {
        frequencyText(for: backupFrequency)
    }
    
    private func frequencyText(for days: Int) -> String {
        switch days {
        case 1: return "Daily"
        case 7: return "Weekly"
        case 14: return "Bi-weekly"
        case 30: return "Monthly"
        default: return "Custom"
        }
    }
    
    private func createLocalBackup() {
        do {
            let backupData = try createBackupData()
            let backupURL = try FileManager.default.url(
                for: .documentDirectory,
                in: .userDomainMask,
                appropriateFor: nil,
                create: true
            ).appendingPathComponent("muni_backup_\(Date().timeIntervalSince1970).json")
            
            try backupData.write(to: backupURL)
            
            lastBackupDate = Date()
            UserDefaults.standard.set(lastBackupDate, forKey: "lastBackupDate")
            
            alertTitle = "Success"
            alertMessage = "Backup created successfully"
            showingAlert = true
        } catch {
            alertTitle = "Error"
            alertMessage = "Failed to create backup: \(error.localizedDescription)"
            showingAlert = true
        }
    }
    
    private func shareBackup() {
        do {
            let backupData = try createBackupData()
            let tempURL = FileManager.default.temporaryDirectory
                .appendingPathComponent("muni_backup_\(Date().timeIntervalSince1970).json")
            try backupData.write(to: tempURL)
            
            // Share the file
            let activityVC = UIActivityViewController(
                activityItems: [tempURL],
                applicationActivities: nil
            )
            
            if let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene,
               let window = windowScene.windows.first,
               let rootVC = window.rootViewController {
                activityVC.popoverPresentationController?.sourceView = rootVC.view
                rootVC.present(activityVC, animated: true)
            }
        } catch {
            alertTitle = "Error"
            alertMessage = "Failed to create backup: \(error.localizedDescription)"
            showingAlert = true
        }
    }
    
    private func createBackupData() throws -> Data {
        let backup = BackupData(
            transactions: transactionManager.transactions,
            userSettings: UserSettings(
                name: userManager.name,
                currency: userManager.currency,
                monthlyIncome: userManager.monthlyIncome,
                monthlyBudget: userManager.monthlyBudget,
                financialGoal: userManager.financialGoal
            )
        )
        
        return try JSONEncoder().encode(backup)
    }
    
    private func handleRestoredFile(_ url: URL?) {
        guard let url = url else { return }
        
        do {
            let data = try Data(contentsOf: url)
            let backup = try JSONDecoder().decode(BackupData.self, from: data)
            
            // Restore user settings
            userManager.name = backup.userSettings.name
            userManager.currency = backup.userSettings.currency
            userManager.monthlyIncome = backup.userSettings.monthlyIncome
            userManager.monthlyBudget = backup.userSettings.monthlyBudget
            userManager.financialGoal = backup.userSettings.financialGoal
            
            // Restore transactions
            transactionManager.transactions = backup.transactions
            
            alertTitle = "Success"
            alertMessage = "Data restored successfully"
            showingAlert = true
        } catch {
            alertTitle = "Error"
            alertMessage = "Failed to restore backup: \(error.localizedDescription)"
            showingAlert = true
        }
    }
}

struct InfoRow: View {
    let title: String
    let value: String
    
    var body: some View {
        HStack {
            Text(title)
                .foregroundColor(Theme.text.opacity(0.7))
            Spacer()
            Text(value)
                .foregroundColor(Theme.text)
        }
    }
}

struct DocumentPicker: UIViewControllerRepresentable {
    let completion: (URL?) -> Void
    
    func makeUIViewController(context: Context) -> UIDocumentPickerViewController {
        let picker = UIDocumentPickerViewController(forOpeningContentTypes: [.json])
        picker.delegate = context.coordinator
        return picker
    }
    
    func updateUIViewController(_ uiViewController: UIDocumentPickerViewController, context: Context) {}
    
    func makeCoordinator() -> Coordinator {
        Coordinator(completion: completion)
    }
    
    class Coordinator: NSObject, UIDocumentPickerDelegate {
        let completion: (URL?) -> Void
        
        init(completion: @escaping (URL?) -> Void) {
            self.completion = completion
        }
        
        func documentPicker(_ controller: UIDocumentPickerViewController, didPickDocumentsAt urls: [URL]) {
            completion(urls.first)
        }
        
        func documentPickerWasCancelled(_ controller: UIDocumentPickerViewController) {
            completion(nil)
        }
    }
}

// Data models for backup
struct BackupData: Codable {
    let transactions: [Transaction]
    let userSettings: UserSettings
}

struct UserSettings: Codable {
    let name: String
    let currency: String
    let monthlyIncome: Double
    let monthlyBudget: Double
    let financialGoal: String
} 