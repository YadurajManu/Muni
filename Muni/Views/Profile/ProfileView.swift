//
//  ProfileView.swift
//  Muni
//
//  Created by Yaduraj Singh on 20/03/25.
//

import SwiftUI
import UniformTypeIdentifiers
import PDFKit
import QuickLook

struct ProfileView: View {
    @EnvironmentObject private var userManager: UserManager
    @EnvironmentObject private var transactionManager: TransactionManager
    @State private var userName = ""
    @State private var monthlyBudget = ""
    @State private var monthlyIncome = ""
    @State private var showAlert = false
    @State private var alertTitle = ""
    @State private var alertMessage = ""
    @State private var showingExportOptions = false
    @State private var exportFormat: ExportFormat = .pdf
    @State private var showingShareSheet = false
    @State private var exportURL: URL? = nil
    @State private var isExporting = false
    @State private var showingDeveloperInfo = false
    
    enum ExportFormat: String, CaseIterable, Identifiable {
        case pdf = "PDF"
        case csv = "CSV"
        case excel = "Excel"
        
        var id: String { self.rawValue }
        
        var icon: String {
            switch self {
            case .pdf: return "doc.viewfinder"
            case .csv: return "tablecells"
            case .excel: return "tablecells.badge.ellipsis"
            }
        }
        
        var fileExtension: String {
            switch self {
            case .pdf: return "pdf"
            case .csv: return "csv"
            case .excel: return "xlsx"
            }
        }
        
        var mimeType: String {
            switch self {
            case .pdf: return "application/pdf"
            case .csv: return "text/csv"
            case .excel: return "application/vnd.openxmlformats-officedocument.spreadsheetml.sheet"
            }
        }
    }
    
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
                    
                    // Export options card
                    exportOptionsCard
                    
                    // Data management card
                    dataManagementCard
                    
                    // About app card
                    aboutAppCard
                    
                    // Developer info
                    developerInfoCard
                }
                .padding(.vertical)
            }
            .background(Theme.background.ignoresSafeArea())
            .navigationTitle("Profile")
            .onAppear {
                userName = userManager.name
                monthlyBudget = String(format: "%.2f", userManager.monthlyBudget)
                monthlyIncome = String(format: "%.2f", userManager.monthlyIncome)
            }
            .alert(isPresented: $showAlert) {
                Alert(
                    title: Text(alertTitle),
                    message: Text(alertMessage),
                    primaryButton: .destructive(Text("Reset")) {
                        performDataReset()
                    },
                    secondaryButton: .cancel()
                )
            }
            .sheet(isPresented: $showingExportOptions) {
                exportOptionsView
            }
            .sheet(isPresented: $showingDeveloperInfo) {
                DeveloperInfoView()
            }
            .overlay {
                if isExporting {
                    ZStack {
                        Color.black.opacity(0.4)
                            .ignoresSafeArea()
                        
                        VStack(spacing: 20) {
                            ProgressView()
                                .scaleEffect(1.5)
                                .progressViewStyle(CircularProgressViewStyle(tint: .white))
                            
                            Text("Preparing your financial report...")
                                .font(.system(size: 16, weight: .medium))
                                .foregroundColor(.white)
                        }
                        .padding(30)
                        .background(Theme.primary.opacity(0.8))
                        .cornerRadius(20)
                    }
                    .transition(.opacity)
                }
            }
            .animation(.easeInOut, value: isExporting)
            .sheet(isPresented: $showingShareSheet) {
                shareSheet
            }
        }
    }
    
    private var profileHeader: some View {
        VStack(spacing: Theme.paddingMedium) {
            ZStack(alignment: .bottomTrailing) {
                Image(systemName: "person.circle.fill")
                    .resizable()
                    .scaledToFit()
                    .frame(width: 100, height: 100)
                    .foregroundColor(Theme.primary)
                    .padding(.top)
                
                Button(action: {
                    // In a real app, this would open image picker
                }) {
                    Image(systemName: "camera.fill")
                        .foregroundColor(.white)
                        .padding(8)
                        .background(Theme.primary)
                        .clipShape(Circle())
                }
            }
            
            Text(userManager.name)
                .font(.system(size: Theme.titleSize, weight: .bold))
                .foregroundColor(Theme.text)
            
            HStack {
                Text("Muni Money Manager")
                    .font(.system(size: Theme.bodySize))
                    .foregroundColor(Theme.text.opacity(0.7))
                
                Image(systemName: "indianrupeesign.circle.fill")
                    .foregroundColor(Theme.primary)
            }
            
            // User's financial status chips
            HStack(spacing: 12) {
                // Financial goal tag
                if !userManager.financialGoal.isEmpty {
                    Text(userManager.financialGoal)
                        .font(.system(size: 12, weight: .medium))
                        .padding(.horizontal, 12)
                        .padding(.vertical, 6)
                        .background(Theme.primary.opacity(0.2))
                        .foregroundColor(Theme.primary)
                        .cornerRadius(20)
                }
                
                // Balance tag
                let balance = transactionManager.balance()
                Text(balance >= 0 ? "Positive Balance" : "Negative Balance")
                    .font(.system(size: 12, weight: .medium))
                    .padding(.horizontal, 12)
                    .padding(.vertical, 6)
                    .background(balance >= 0 ? Theme.income.opacity(0.2) : Theme.expense.opacity(0.2))
                    .foregroundColor(balance >= 0 ? Theme.income : Theme.expense)
                    .cornerRadius(20)
            }
        }
    }
    
    private var userInfoCard: some View {
        VStack(alignment: .leading, spacing: Theme.paddingMedium) {
            HStack {
                Text("User Information")
                    .font(.system(size: Theme.subtitleSize, weight: .semibold))
                    .foregroundColor(Theme.text)
                
                Spacer()
                
                Button(action: {
                    saveUserInfo()
                }) {
                    Text("Save")
                        .font(.system(size: 14, weight: .medium))
                        .foregroundColor(.white)
                        .padding(.horizontal, 16)
                        .padding(.vertical, 8)
                        .background(Theme.primary)
                        .cornerRadius(8)
                }
            }
            
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
                }
                
                // Monthly Income
                VStack(alignment: .leading, spacing: 4) {
                    Text("Monthly Income")
                        .font(.system(size: Theme.captionSize))
                        .foregroundColor(Theme.text.opacity(0.7))
                    
                    HStack {
                        Text("₹")
                            .font(.system(size: Theme.bodySize, weight: .semibold))
                            .foregroundColor(Theme.text)
                        
                        TextField("0.00", text: $monthlyIncome)
                            .keyboardType(.decimalPad)
                            .padding()
                    }
                    .background(Theme.secondary.opacity(0.3))
                    .cornerRadius(Theme.cornerRadiusSmall)
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
                    }
                    .background(Theme.secondary.opacity(0.3))
                    .cornerRadius(Theme.cornerRadiusSmall)
                }
                
                // Financial goal
                VStack(alignment: .leading, spacing: 4) {
                    Text("Financial Goal")
                        .font(.system(size: Theme.captionSize))
                        .foregroundColor(Theme.text.opacity(0.7))
                    
                    Menu {
                        ForEach(UserManager.financialGoalOptions(), id: \.self) { goal in
                            Button(action: {
                                userManager.financialGoal = goal
                                userManager.saveUserData()
                            }) {
                                HStack {
                                    Text(goal)
                                    
                                    if userManager.financialGoal == goal {
                                        Image(systemName: "checkmark")
                                    }
                                }
                            }
                        }
                    } label: {
                        HStack {
                            Text(userManager.financialGoal.isEmpty ? "Select a goal" : userManager.financialGoal)
                                .foregroundColor(Theme.text)
                                .frame(maxWidth: .infinity, alignment: .leading)
                            
                            Image(systemName: "chevron.down")
                                .foregroundColor(Theme.text.opacity(0.7))
                        }
                        .padding()
                        .background(Theme.secondary.opacity(0.3))
                        .cornerRadius(Theme.cornerRadiusSmall)
                    }
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
            
            // Additional statistics row
            HStack {
                StatisticItem(
                    title: "Income",
                    value: "\(userManager.currency)\(String(format: "%.2f", transactionManager.totalIncome()))",
                    icon: "arrow.down.circle"
                )
                
                Spacer()
                
                StatisticItem(
                    title: "Expenses",
                    value: "\(userManager.currency)\(String(format: "%.2f", transactionManager.totalExpense()))",
                    icon: "arrow.up.circle"
                )
            }
            .padding(.top, 8)
        }
        .padding()
        .background(Theme.background)
        .cardStyle()
        .padding(.horizontal)
    }
    
    private var exportOptionsCard: some View {
        VStack(alignment: .leading, spacing: Theme.paddingMedium) {
            Text("Export Data")
                .font(.system(size: Theme.subtitleSize, weight: .semibold))
                .foregroundColor(Theme.text)
            
            Button(action: {
                showingExportOptions = true
            }) {
                HStack {
                    Image(systemName: "square.and.arrow.up")
                        .foregroundColor(Theme.primary)
                    
                    Text("Export Transactions")
                        .foregroundColor(Theme.text)
                    
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
    
    private var exportOptionsView: some View {
        NavigationView {
            VStack(spacing: 20) {
                // Export format selection
                VStack(alignment: .leading, spacing: 10) {
                    Text("Select Export Format")
                        .font(.system(size: 18, weight: .semibold))
                        .foregroundColor(Theme.text)
                    
                    ForEach(ExportFormat.allCases) { format in
                        Button(action: {
                            exportFormat = format
                        }) {
                            HStack {
                                Image(systemName: format.icon)
                                    .font(.system(size: 20))
                                    .foregroundColor(exportFormat == format ? .white : Theme.primary)
                                    .frame(width: 30)
                                
                                Text(format.rawValue)
                                    .font(.system(size: 17))
                                    .foregroundColor(exportFormat == format ? .white : Theme.text)
                                
                                Spacer()
                                
                                if exportFormat == format {
                                    Image(systemName: "checkmark")
                                        .foregroundColor(.white)
                                }
                            }
                            .padding()
                            .background(exportFormat == format ? Theme.primary : Theme.secondary.opacity(0.3))
                            .cornerRadius(10)
                        }
                    }
                }
                .padding()
                
                // Export button
                Button(action: {
                    exportData()
                }) {
                    HStack {
                        Image(systemName: "square.and.arrow.up")
                        Text("Export as \(exportFormat.rawValue)")
                    }
                    .font(.system(size: 17, weight: .semibold))
                    .foregroundColor(.white)
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(Theme.primary)
                    .cornerRadius(10)
                    .padding(.horizontal)
                }
                
                Spacer()
            }
            .padding(.top)
            .navigationTitle("Export Options")
            .navigationBarTitleDisplayMode(.inline)
            .navigationBarItems(trailing: Button("Cancel") {
                showingExportOptions = false
            })
        }
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
            
            // Backup and restore
            Button(action: {
                // In a real app, this would handle backup functionality
            }) {
                HStack {
                    Image(systemName: "arrow.clockwise.icloud")
                        .foregroundColor(Theme.primary)
                    
                    Text("Backup & Restore")
                        .foregroundColor(Theme.text)
                    
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
                
                // Developer info - tappable
                Button(action: {
                    showingDeveloperInfo = true
                }) {
                    HStack {
                        Text("Developer")
                            .font(.system(size: Theme.bodySize))
                            .foregroundColor(Theme.text)
                        
                        Spacer()
                        
                        Text("Yaduraj Singh")
                            .font(.system(size: Theme.bodySize))
                            .foregroundColor(Theme.primary)
                        
                        Image(systemName: "chevron.right")
                            .font(.system(size: 14))
                            .foregroundColor(Theme.text.opacity(0.5))
                    }
                }
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
    
    private var developerInfoCard: some View {
        VStack(alignment: .leading, spacing: Theme.paddingMedium) {
            Text("Developer Contact")
                .font(.system(size: Theme.subtitleSize, weight: .semibold))
                .foregroundColor(Theme.text)
            
            Button(action: {
                if let url = URL(string: "https://github.com/YadurajManu") {
                    UIApplication.shared.open(url)
                }
            }) {
                HStack {
                    Image(systemName: "link")
                        .foregroundColor(Theme.primary)
                    
                    Text("GitHub Profile")
                        .foregroundColor(Theme.text)
                    
                    Spacer()
                    
                    Image(systemName: "chevron.right")
                        .foregroundColor(Theme.text.opacity(0.5))
                }
                .padding()
                .background(Theme.secondary.opacity(0.3))
                .cornerRadius(Theme.cornerRadiusMedium)
            }
            
            // Rate app button
            Button(action: {
                // In a real app, this would open App Store rating
            }) {
                HStack {
                    Image(systemName: "star.fill")
                        .foregroundColor(.yellow)
                    
                    Text("Rate This App")
                        .foregroundColor(Theme.text)
                    
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
    
    private func saveUserInfo() {
        userManager.name = userName
        
        if let budget = Double(monthlyBudget) {
            userManager.monthlyBudget = budget
        }
        
        if let income = Double(monthlyIncome) {
            userManager.monthlyIncome = income
        }
        
        userManager.saveUserData()
        
        // Show confirmation
        alertTitle = "Profile Updated"
        alertMessage = "Your profile information has been updated."
        showAlert = true
    }
    
    private func resetAllData() {
        // Show confirmation alert
        alertTitle = "Reset All Data"
        alertMessage = "Are you sure you want to reset all your data? This action cannot be undone."
        showAlert = true
    }
    
    private func performDataReset() {
        // Reset user data and transactions
        userManager.name = ""
        userManager.monthlyBudget = 0.0
        userManager.monthlyIncome = 0.0
        userManager.financialGoal = ""
        userManager.saveUserData()
        
        // Reset onboarding status to force onboarding again
        UserDefaults.standard.set(false, forKey: "hasCompletedOnboarding")
        
        transactionManager.transactions = []
        transactionManager.saveTransactions()
        
        // Reset UI fields
        userName = ""
        monthlyBudget = "0.00"
        monthlyIncome = "0.00"
    }
    
    private func exportData() {
        // Start export process
        isExporting = true
        showingExportOptions = false
        
        // Generate actual file data based on the selected format
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
            // Create a real file based on selected export format
            let fileName = "Muni_Financial_Report.\(exportFormat.fileExtension)"
            let temporaryDirectoryURL = URL(fileURLWithPath: NSTemporaryDirectory(), isDirectory: true)
            let fileURL = temporaryDirectoryURL.appendingPathComponent(fileName)
            
            // Generate appropriate content based on format
            switch exportFormat {
            case .pdf:
                generatePDFFile(fileURL: fileURL)
            case .csv:
                generateCSVFile(fileURL: fileURL)
            case .excel:
                generateExcelFile(fileURL: fileURL)
            }
            
            // Save file URL and show share sheet
            exportURL = fileURL
            isExporting = false
            showingShareSheet = true
        }
    }
    
    private func generatePDFFile(fileURL: URL) {
        // Create a PDF document with proper metadata that includes UTI information
        let pdfMetaData = [
            kCGPDFContextCreator: "Muni App" as CFString,
            kCGPDFContextAuthor: userManager.name as CFString,
            kCGPDFContextTitle: "Muni Financial Report" as CFString,
            kCGPDFContextOwnerPassword: "" as CFString,
            kCGPDFContextUserPassword: "" as CFString,
            kCGPDFContextAllowsPrinting: true as CFBoolean,
            kCGPDFContextAllowsCopying: true as CFBoolean
        ] as [CFString : Any]
        
        let format = UIGraphicsPDFRendererFormat()
        format.documentInfo = pdfMetaData as [String: Any]
        
        let pageWidth = 8.5 * 72.0
        let pageHeight = 11.0 * 72.0
        let pageRect = CGRect(x: 0, y: 0, width: pageWidth, height: pageHeight)
        
        let renderer = UIGraphicsPDFRenderer(bounds: pageRect, format: format)
        
        try? renderer.writePDF(to: fileURL) { context in
            context.beginPage()
            
            // Add logo/app name at the top
            let titleFont = UIFont.systemFont(ofSize: 28, weight: .bold)
            let titleAttributes: [NSAttributedString.Key: Any] = [
                .font: titleFont,
                .foregroundColor: UIColor.black
            ]
            
            let title = "Muni Financial Report"
            let titleSize = (title as NSString).size(withAttributes: titleAttributes)
            (title as NSString).draw(at: CGPoint(x: (pageWidth - titleSize.width) / 2, y: 50), withAttributes: titleAttributes)
            
            // Add date
            let dateFont = UIFont.systemFont(ofSize: 14)
            let dateAttributes: [NSAttributedString.Key: Any] = [
                .font: dateFont,
                .foregroundColor: UIColor.darkGray
            ]
            
            let dateFormatter = DateFormatter()
            dateFormatter.dateStyle = .long
            let date = "Generated on \(dateFormatter.string(from: Date()))"
            let dateSize = (date as NSString).size(withAttributes: dateAttributes)
            (date as NSString).draw(at: CGPoint(x: (pageWidth - dateSize.width) / 2, y: 80), withAttributes: dateAttributes)
            
            // Draw a line
            let path = UIBezierPath()
            path.move(to: CGPoint(x: 50, y: 110))
            path.addLine(to: CGPoint(x: pageWidth - 50, y: 110))
            UIColor.lightGray.setStroke()
            path.lineWidth = 0.5
            path.stroke()
            
            // Account Summary
            let summaryFont = UIFont.systemFont(ofSize: 22, weight: .medium)
            let summaryAttributes: [NSAttributedString.Key: Any] = [
                .font: summaryFont,
                .foregroundColor: UIColor.black
            ]
            
            let summary = "Financial Summary"
            (summary as NSString).draw(at: CGPoint(x: 50, y: 140), withAttributes: summaryAttributes)
            
            // Add summary content
            let contentFont = UIFont.systemFont(ofSize: 14)
            let contentAttributes: [NSAttributedString.Key: Any] = [
                .font: contentFont,
                .foregroundColor: UIColor.black
            ]
            
            let userName = "User: \(userManager.name)"
            (userName as NSString).draw(at: CGPoint(x: 50, y: 180), withAttributes: contentAttributes)
            
            let balance = "Current Balance: \(userManager.currency)\(String(format: "%.2f", transactionManager.totalIncome() - transactionManager.totalExpense()))"
            (balance as NSString).draw(at: CGPoint(x: 50, y: 200), withAttributes: contentAttributes)
            
            let income = "Total Income: \(userManager.currency)\(String(format: "%.2f", transactionManager.totalIncome()))"
            (income as NSString).draw(at: CGPoint(x: 50, y: 220), withAttributes: contentAttributes)
            
            let expenses = "Total Expenses: \(userManager.currency)\(String(format: "%.2f", transactionManager.totalExpense()))"
            (expenses as NSString).draw(at: CGPoint(x: 50, y: 240), withAttributes: contentAttributes)
            
            let monthlyIncome = "Monthly Income: \(userManager.currency)\(String(format: "%.2f", userManager.monthlyIncome))"
            (monthlyIncome as NSString).draw(at: CGPoint(x: 50, y: 260), withAttributes: contentAttributes)
            
            let monthlyBudget = "Monthly Budget: \(userManager.currency)\(String(format: "%.2f", userManager.monthlyBudget))"
            (monthlyBudget as NSString).draw(at: CGPoint(x: 50, y: 280), withAttributes: contentAttributes)
            
            if !userManager.financialGoal.isEmpty {
                let financialGoal = "Financial Goal: \(userManager.financialGoal)"
                (financialGoal as NSString).draw(at: CGPoint(x: 50, y: 300), withAttributes: contentAttributes)
            }
            
            // Transaction History
            let transactionsTitle = "Transaction History"
            let transactionsTitleAttributes: [NSAttributedString.Key: Any] = [
                .font: summaryFont,
                .foregroundColor: UIColor.black
            ]
            (transactionsTitle as NSString).draw(at: CGPoint(x: 50, y: 340), withAttributes: transactionsTitleAttributes)
            
            // Add table headers
            let headerAttributes: [NSAttributedString.Key: Any] = [
                .font: UIFont.systemFont(ofSize: 12, weight: .semibold),
                .foregroundColor: UIColor.black
            ]
            
            let headers = ["Date", "Type", "Category", "Amount", "Note"]
            let columnWidths: [CGFloat] = [80, 70, 100, 80, 200]
            var xPosition: CGFloat = 50
            
            for (index, header) in headers.enumerated() {
                (header as NSString).draw(at: CGPoint(x: xPosition, y: 380), withAttributes: headerAttributes)
                xPosition += columnWidths[index]
            }
            
            // Draw a line under headers
            let headerLine = UIBezierPath()
            headerLine.move(to: CGPoint(x: 50, y: 395))
            headerLine.addLine(to: CGPoint(x: pageWidth - 50, y: 395))
            UIColor.lightGray.setStroke()
            headerLine.lineWidth = 0.5
            headerLine.stroke()
            
            // Add transaction rows
            let rowAttributes: [NSAttributedString.Key: Any] = [
                .font: UIFont.systemFont(ofSize: 10),
                .foregroundColor: UIColor.black
            ]
            
            let dateFormatter2 = DateFormatter()
            dateFormatter2.dateStyle = .short
            
            var yPosition: CGFloat = 410
            let rowHeight: CGFloat = 20
            var currentPage = 1
            
            for transaction in transactionManager.transactions {
                // Check if we need a new page
                if yPosition > pageHeight - 50 {
                    context.beginPage()
                    yPosition = 50
                    
                    // Add page header on new page
                    let pageHeader = "Muni Financial Report - Page \(currentPage + 1)"
                    (pageHeader as NSString).draw(at: CGPoint(x: 50, y: yPosition), withAttributes: summaryAttributes)
                    yPosition += 30
                    
                    // Redraw table headers on new page
                    xPosition = 50
                    for (index, header) in headers.enumerated() {
                        (header as NSString).draw(at: CGPoint(x: xPosition, y: yPosition), withAttributes: headerAttributes)
                        xPosition += columnWidths[index]
                    }
                    
                    // Draw header line
                    let newHeaderLine = UIBezierPath()
                    newHeaderLine.move(to: CGPoint(x: 50, y: yPosition + 15))
                    newHeaderLine.addLine(to: CGPoint(x: pageWidth - 50, y: yPosition + 15))
                    UIColor.lightGray.setStroke()
                    newHeaderLine.lineWidth = 0.5
                    newHeaderLine.stroke()
                    
                    yPosition += 30
                    currentPage += 1
                }
                
                // Draw transaction data
                let date = dateFormatter2.string(from: transaction.date)
                xPosition = 50
                
                (date as NSString).draw(at: CGPoint(x: xPosition, y: yPosition), withAttributes: rowAttributes)
                xPosition += columnWidths[0]
                
                (transaction.type.rawValue as NSString).draw(at: CGPoint(x: xPosition, y: yPosition), withAttributes: rowAttributes)
                xPosition += columnWidths[1]
                
                (transaction.category.rawValue as NSString).draw(at: CGPoint(x: xPosition, y: yPosition), withAttributes: rowAttributes)
                xPosition += columnWidths[2]
                
                let amountString = "\(userManager.currency)\(String(format: "%.2f", transaction.amount))"
                (amountString as NSString).draw(at: CGPoint(x: xPosition, y: yPosition), withAttributes: rowAttributes)
                xPosition += columnWidths[3]
                
                (transaction.note as NSString).draw(at: CGPoint(x: xPosition, y: yPosition), withAttributes: rowAttributes)
                
                yPosition += rowHeight
            }
            
            // Add footer with page number
            let footerText = "Page \(currentPage) of \(currentPage)"
            let footerAttributes: [NSAttributedString.Key: Any] = [
                .font: UIFont.systemFont(ofSize: 10),
                .foregroundColor: UIColor.gray
            ]
            let footerSize = (footerText as NSString).size(withAttributes: footerAttributes)
            (footerText as NSString).draw(
                at: CGPoint(x: (pageWidth - footerSize.width) / 2, y: pageHeight - 30),
                withAttributes: footerAttributes
            )
        }
    }
    
    private func generateCSVFile(fileURL: URL) {
        // Create proper CSV with headers and data
        var csvString = "Date,Type,Category,Amount,Note\n"
        
        let dateFormatter = DateFormatter()
        dateFormatter.dateStyle = .short
        
        for transaction in transactionManager.transactions {
            let dateString = dateFormatter.string(from: transaction.date)
            // Escape any commas in the note field
            let escapedNote = transaction.note.replacingOccurrences(of: "\"", with: "\"\"")
            let csvLine = "\(dateString),\(transaction.type.rawValue),\(transaction.category.rawValue),\(String(format: "%.2f", transaction.amount)),\"\(escapedNote)\"\n"
            csvString.append(csvLine)
        }
        
        // Add summary section with a blank line separator
        csvString.append("\n")
        csvString.append("SUMMARY\n")
        csvString.append("Total Income,\(String(format: "%.2f", transactionManager.totalIncome()))\n")
        csvString.append("Total Expenses,\(String(format: "%.2f", transactionManager.totalExpense()))\n")
        csvString.append("Balance,\(String(format: "%.2f", transactionManager.balance()))\n")
        
        if !userManager.financialGoal.isEmpty {
            csvString.append("Financial Goal,\"\(userManager.financialGoal)\"\n")
        }
        
        // User details
        csvString.append("\nUSER DETAILS\n")
        csvString.append("Name,\"\(userManager.name)\"\n")
        csvString.append("Monthly Income,\(String(format: "%.2f", userManager.monthlyIncome))\n")
        csvString.append("Monthly Budget,\(String(format: "%.2f", userManager.monthlyBudget))\n")
        
        // Write to file
        try? csvString.write(to: fileURL, atomically: true, encoding: .utf8)
    }
    
    private func generateExcelFile(fileURL: URL) {
        // Create an Excel-compatible CSV with formatting
        var excelString = "sep=,\n" // Excel separator hint
        excelString.append("\"Date\",\"Type\",\"Category\",\"Amount\",\"Note\"\n")
        
        let dateFormatter = DateFormatter()
        dateFormatter.dateStyle = .short
        
        for transaction in transactionManager.transactions {
            let dateString = dateFormatter.string(from: transaction.date)
            // Proper Excel escaping for text fields
            let escapedNote = transaction.note.replacingOccurrences(of: "\"", with: "\"\"")
            let categoryName = transaction.category.rawValue.replacingOccurrences(of: "\"", with: "\"\"")
            let typeName = transaction.type.rawValue.replacingOccurrences(of: "\"", with: "\"\"")
            
            // Format amount as number for Excel
            let excelLine = "\"\(dateString)\",\"\(typeName)\",\"\(categoryName)\",\(String(format: "%.2f", transaction.amount)),\"\(escapedNote)\"\n"
            excelString.append(excelLine)
        }
        
        // Add blank rows
        excelString.append("\n\n")
        
        // Add summary with some Excel formatting
        excelString.append("\"SUMMARY\",\"\",\"\",\"\",\"\"\n")
        excelString.append("\"Total Income\",\"\",\"\",\(String(format: "%.2f", transactionManager.totalIncome())),\"\"\n")
        excelString.append("\"Total Expenses\",\"\",\"\",\(String(format: "%.2f", transactionManager.totalExpense())),\"\"\n")
        excelString.append("\"Balance\",\"\",\"\",\(String(format: "%.2f", transactionManager.balance())),\"\"\n")
        
        // Add excel formula for validation (will work when opened in Excel)
        let lastDataRow = transactionManager.transactions.count + 1
        excelString.append("\"Balance Check\",\"\",\"\",\"=SUM(D2:D\(lastDataRow))\",\"\"\n")
        
        // Add user details
        excelString.append("\n")
        excelString.append("\"USER DETAILS\",\"\",\"\",\"\",\"\"\n")
        excelString.append("\"Name\",\"\(userManager.name)\",\"\",\"\",\"\"\n")
        excelString.append("\"Monthly Income\",\(String(format: "%.2f", userManager.monthlyIncome)),\"\",\"\",\"\"\n")
        excelString.append("\"Monthly Budget\",\(String(format: "%.2f", userManager.monthlyBudget)),\"\",\"\",\"\"\n")
        
        if !userManager.financialGoal.isEmpty {
            excelString.append("\"Financial Goal\",\"\(userManager.financialGoal)\",\"\",\"\",\"\"\n")
        }
        
        // Add metadata
        excelString.append("\n")
        excelString.append("\"Generated by\",\"Muni App\",\"\",\"\",\"\"\n")
        excelString.append("\"Date\",\"\(DateFormatter.localizedString(from: Date(), dateStyle: .medium, timeStyle: .short))\",\"\",\"\",\"\"\n")
        
        try? excelString.write(to: fileURL, atomically: true, encoding: .utf8)
    }
    
    // Share sheet view
    private var shareSheet: some View {
        Group {
            if let exportURL = exportURL {
                ShareSheet(
                    activityItems: [exportURL],
                    applicationActivities: [],
                    excludedActivityTypes: nil,
                    completion: { activity, completed, items, error in
                        if completed {
                            // Clean up temp file after sharing
                            DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                                try? FileManager.default.removeItem(at: exportURL)
                            }
                        }
                    }
                )
            }
        }
    }
}

struct DeveloperInfoView: View {
    var body: some View {
        ScrollView {
            VStack(spacing: 20) {
                Image(systemName: "person.crop.circle.fill")
                    .resizable()
                    .aspectRatio(contentMode: .fit)
                    .frame(width: 150, height: 150)
                    .foregroundColor(Theme.primary)
                    .padding(.top, 40)
                
                Text("Yaduraj Singh")
                    .font(.system(size: 28, weight: .bold))
                    .foregroundColor(Theme.text)
                
                Text("iOS Developer & Designer")
                    .font(.system(size: 20))
                    .foregroundColor(Theme.text.opacity(0.7))
                
                Divider()
                    .padding(.horizontal, 40)
                    .padding(.vertical, 10)
                
                VStack(alignment: .leading, spacing: 20) {
                    Text("About the Developer")
                        .font(.system(size: 22, weight: .semibold))
                        .foregroundColor(Theme.text)
                    
                    Text("Yaduraj Singh is a passionate iOS developer with expertise in creating beautiful and functional applications. Muni is a showcase of clean design principles and intelligent financial management features.")
                        .font(.system(size: 16))
                        .foregroundColor(Theme.text.opacity(0.8))
                        .lineSpacing(4)
                        .fixedSize(horizontal: false, vertical: true)
                    
                    Text("Skills")
                        .font(.system(size: 20, weight: .semibold))
                        .foregroundColor(Theme.text)
                        .padding(.top, 10)
                    
                    HStack(spacing: 10) {
                        SkillTag(text: "Swift")
                        SkillTag(text: "SwiftUI")
                        SkillTag(text: "UI/UX")
                    }
                    
                    HStack(spacing: 10) {
                        SkillTag(text: "Financial Apps")
                        SkillTag(text: "AI Integration")
                    }
                    
                    Text("Contact")
                        .font(.system(size: 20, weight: .semibold))
                        .foregroundColor(Theme.text)
                        .padding(.top, 10)
                    
                    Button(action: {
                        if let url = URL(string: "mailto:yaduraj@example.com") {
                            UIApplication.shared.open(url)
                        }
                    }) {
                        HStack {
                            Image(systemName: "envelope.fill")
                                .foregroundColor(.white)
                            
                            Text("Contact via Email")
                                .foregroundColor(.white)
                        }
                        .padding()
                        .frame(maxWidth: .infinity)
                        .background(Theme.primary)
                        .cornerRadius(10)
                    }
                }
                .padding(.horizontal, 30)
                
                Spacer()
            }
        }
        .background(Theme.background)
        .navigationTitle("Developer Info")
        .navigationBarTitleDisplayMode(.inline)
    }
}

struct SkillTag: View {
    let text: String
    
    var body: some View {
        Text(text)
            .font(.system(size: 14, weight: .medium))
            .padding(.horizontal, 16)
            .padding(.vertical, 8)
            .background(Theme.primary.opacity(0.2))
            .foregroundColor(Theme.primary)
            .cornerRadius(20)
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

// Add a ShareSheet struct for iOS sharing
struct ShareSheet: UIViewControllerRepresentable {
    let activityItems: [Any]
    let applicationActivities: [UIActivity]?
    let excludedActivityTypes: [UIActivity.ActivityType]?
    let completion: UIActivityViewController.CompletionWithItemsHandler?
    
    init(
        activityItems: [Any],
        applicationActivities: [UIActivity]? = nil,
        excludedActivityTypes: [UIActivity.ActivityType]? = nil,
        completion: UIActivityViewController.CompletionWithItemsHandler? = nil
    ) {
        self.activityItems = activityItems
        self.applicationActivities = applicationActivities
        self.excludedActivityTypes = excludedActivityTypes
        self.completion = completion
    }
    
    func makeUIViewController(context: Context) -> UIActivityViewController {
        let controller = UIActivityViewController(
            activityItems: activityItems,
            applicationActivities: applicationActivities
        )
        controller.excludedActivityTypes = excludedActivityTypes
        controller.completionWithItemsHandler = completion
        return controller
    }
    
    func updateUIViewController(_ uiViewController: UIActivityViewController, context: Context) {
        // Nothing to update
    }
} 
