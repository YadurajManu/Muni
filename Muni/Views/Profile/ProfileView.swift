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
    @State private var showingEditProfile = false
    @State private var showingAppSettings = false
    @State private var showingExportOptions = false
    @State private var showingShareSheet = false
    @State private var exportFormat: ExportFormat = .pdf
    @State private var isExporting = false
    @State private var exportURL: URL? = nil
    @State private var showingDeveloperInfo = false
    @State private var showingAppearanceOptions = false
    @State private var showingPrivacyPolicy = false
    @State private var selectedAppearance = AppTheme.system
    @State private var showingNotificationPreferences = false
    @State private var showingPrivacySettings = false
    @State private var showingCurrencySettings = false
    @State private var showingBackupOptions = false
    @State private var showingAboutView = false
    @State private var showingHelpCenter = false
    @State private var showingResetApp = false
    
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
                VStack(spacing: 24) {
                    // Profile header
                    profileHeader
                    
                    // Finance summary card
                    financeSummaryCard
                    
                    // Quick actions
                    quickActions
                    
                    // Settings sections
                    settingsSections
                    
                    // Version info at bottom
                    versionInfo
                }
                .padding(.bottom, 30)
            }
            .background(Theme.background.edgesIgnoringSafeArea(.all))
            .navigationTitle("Profile")
            .navigationBarTitleDisplayMode(.large)
            .sheet(isPresented: $showingEditProfile) {
                EditProfileView()
                    .environmentObject(userManager)
            }
            .sheet(isPresented: $showingAppSettings) {
                AppSettingsView()
            }
            .sheet(isPresented: $showingShareSheet) {
                shareSheet
            }
            .sheet(isPresented: $showingDeveloperInfo) {
                DeveloperInfoView()
            }
            .background(
                Group {
                    NavigationLink(isActive: $showingNotificationPreferences) {
                        NotificationPreferencesView()
                    } label: { EmptyView() }
                    
                    NavigationLink(isActive: $showingPrivacySettings) {
                        PrivacySecurityView()
                    } label: { EmptyView() }
                    
                    NavigationLink(isActive: $showingCurrencySettings) {
                        CurrencyLanguageView()
                            .environmentObject(userManager)
                    } label: { EmptyView() }
                    
                    NavigationLink(isActive: $showingBackupOptions) {
                        BackupRestoreView()
                            .environmentObject(userManager)
                            .environmentObject(transactionManager)
                    } label: { EmptyView() }
                    
                    NavigationLink(isActive: $showingAboutView) {
                        AboutView()
                    } label: { EmptyView() }
                    
                    NavigationLink(isActive: $showingHelpCenter) {
                        HelpCenterView()
                    } label: { EmptyView() }
                    
                    NavigationLink(isActive: $showingResetApp) {
                        ResetAppView()
                            .environmentObject(userManager)
                            .environmentObject(transactionManager)
                    } label: { EmptyView() }
                }
            )
            .alert(isPresented: $showingAppearanceOptions) {
                Alert(
                    title: Text("Choose Appearance"),
                    message: Text("Select your preferred theme"),
                    primaryButton: .default(Text("Light")) {
                        selectedAppearance = .light
                        applyAppearanceSettings()
                    },
                    secondaryButton: .default(Text("Dark")) {
                        selectedAppearance = .dark
                        applyAppearanceSettings()
                    }
                )
            }
            .actionSheet(isPresented: $showingExportOptions) {
                ActionSheet(
                    title: Text("Export Data"),
                    message: Text("Choose an export format"),
                    buttons: [
                        .default(Text("PDF")) {
                            exportFormat = .pdf
                            exportData()
                        },
                        .default(Text("CSV")) {
                            exportFormat = .csv
                            exportData()
                        },
                        .default(Text("Excel Compatible")) {
                            exportFormat = .excel
                            exportData()
                        },
                        .cancel()
                    ]
                )
            }
        }
    }
    
    // Profile header section
    private var profileHeader: some View {
        VStack(spacing: 16) {
            // Profile picture
            ZStack {
                Circle()
                    .fill(LinearGradient(
                        gradient: Gradient(colors: [Theme.primary.opacity(0.8), Theme.primary.opacity(0.6)]),
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    ))
                    .frame(width: 100, height: 100)
                    .shadow(color: Color.black.opacity(0.1), radius: 8, x: 0, y: 4)
                
                // If no profile image, show initials
                if userManager.name.isEmpty {
                    Image(systemName: "person.fill")
                        .font(.system(size: 40))
                        .foregroundColor(.white)
                } else {
                    Text(userManager.name.prefix(1).uppercased())
                        .font(.system(size: 40, weight: .semibold))
                        .foregroundColor(.white)
                }
            }
            
            // User name and edit button
            VStack(spacing: 4) {
                Text(userManager.name.isEmpty ? "Set Your Name" : userManager.name)
                    .font(.system(size: 24, weight: .bold))
                    .foregroundColor(Theme.text)
                
                Button(action: {
                    showingEditProfile = true
                }) {
                    Text("Edit Profile")
                        .font(.system(size: 14, weight: .medium))
                        .foregroundColor(Theme.primary)
                        .padding(.horizontal, 16)
                        .padding(.vertical, 8)
                        .background(
                            RoundedRectangle(cornerRadius: 20)
                                .stroke(Theme.primary.opacity(0.3), lineWidth: 1)
                        )
                }
                .buttonStyle(ScaleButtonStyle())
            }
        }
        .padding(.vertical, 20)
        .frame(maxWidth: .infinity)
        .background(Color(UIColor.secondarySystemBackground))
    }
    
    // Finance summary card
    private var financeSummaryCard: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Financial Summary")
                .font(.system(size: 18, weight: .bold))
                .foregroundColor(Theme.text)
            
            HStack(spacing: 20) {
                // Balance card
                financeInfoCard(
                    title: "Balance",
                    value: "\(userManager.currency)\(String(format: "%.2f", transactionManager.balance()))",
                    icon: "indianrupeesign.circle.fill",
                    color: Color.green
                )
                
                // Income card
                financeInfoCard(
                    title: "Income",
                    value: "\(userManager.currency)\(String(format: "%.2f", transactionManager.totalIncome()))",
                    icon: "arrow.down.circle.fill",
                    color: Color.blue
                )
                
                // Expense card
                financeInfoCard(
                    title: "Expenses",
                    value: "\(userManager.currency)\(String(format: "%.2f", transactionManager.totalExpense()))",
                    icon: "arrow.up.circle.fill",
                    color: Color.red
                )
            }
        }
        .padding()
        .background(Color(UIColor.secondarySystemBackground))
        .cornerRadius(12)
        .shadow(color: Color.black.opacity(0.05), radius: 5, x: 0, y: 2)
        .padding(.horizontal)
    }
    
    // Helper for finance info cards
    private func financeInfoCard(title: String, value: String, icon: String, color: Color) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Image(systemName: icon)
                    .font(.system(size: 16))
                    .foregroundColor(color)
                
                Text(title)
                    .font(.system(size: 14))
                    .foregroundColor(Theme.text.opacity(0.7))
            }
            
            Text(value)
                .font(.system(size: 16, weight: .bold))
                .foregroundColor(Theme.text)
                .lineLimit(1)
                .minimumScaleFactor(0.8)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(12)
        .background(color.opacity(0.1))
        .cornerRadius(10)
    }
    
    // Quick actions section
    private var quickActions: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Quick Actions")
                .font(.headline)
                .foregroundColor(Theme.text)
                .padding(.horizontal)
            
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 16) {
                    quickActionButton(
                        title: "Export Data",
                        icon: "square.and.arrow.up",
                        color: Color.blue,
                        action: { showingExportOptions = true }
                    )
                    
                    quickActionButton(
                        title: "Appearance",
                        icon: "paintbrush.fill",
                        color: Color.purple,
                        action: { showingAppearanceOptions = true }
                    )
                    
                    quickActionButton(
                        title: "Backup",
                        icon: "externaldrive.fill",
                        color: Color.green,
                        action: { /* Implement backup */ }
                    )
                    
                    quickActionButton(
                        title: "Settings",
                        icon: "gear",
                        color: Color.orange,
                        action: { showingAppSettings = true }
                    )
                }
                .padding(.horizontal)
            }
        }
    }
    
    // Helper for quick action buttons
    private func quickActionButton(title: String, icon: String, color: Color, action: @escaping () -> Void) -> some View {
        Button(action: {
            // Light haptic feedback
            UIImpactFeedbackGenerator(style: .light).impactOccurred()
            action()
        }) {
            VStack(spacing: 12) {
                ZStack {
                    Circle()
                        .fill(color.opacity(0.2))
                        .frame(width: 56, height: 56)
                    
                    Image(systemName: icon)
                        .font(.system(size: 24))
                        .foregroundColor(color)
                }
                
                Text(title)
                    .font(.system(size: 14))
                    .foregroundColor(Theme.text)
            }
            .frame(width: 80)
            .padding(.vertical, 12)
        }
        .buttonStyle(ScaleButtonStyle())
    }
    
    // Settings sections
    private var settingsSections: some View {
        VStack(spacing: 24) {
            // Account settings
            settingsSection(title: "Account", items: [
                SettingsItem(
                    title: "Personal Information",
                    icon: "person.fill",
                    color: .blue,
                    action: { showingEditProfile = true }
                ),
                SettingsItem(
                    title: "Notification Preferences",
                    icon: "bell.fill",
                    color: .orange,
                    action: { 
                        withAnimation {
                            showingNotificationPreferences = true
                        }
                    }
                ),
                SettingsItem(
                    title: "Privacy & Security",
                    icon: "lock.fill",
                    color: .green,
                    action: { 
                        withAnimation {
                            showingPrivacySettings = true
                        }
                    }
                )
            ])
            
            // App settings
            settingsSection(title: "App Settings", items: [
                SettingsItem(
                    title: "Currency & Language",
                    icon: "indianrupeesign.circle.fill",
                    color: .purple,
                    action: { 
                        withAnimation {
                            showingCurrencySettings = true
                        }
                    }
                ),
                SettingsItem(
                    title: "App Appearance",
                    icon: "paintbrush.fill",
                    color: .indigo,
                    action: { showingAppearanceOptions = true }
                ),
                SettingsItem(
                    title: "Backup & Restore",
                    icon: "arrow.clockwise",
                    color: .blue,
                    action: { 
                        withAnimation {
                            showingBackupOptions = true
                        }
                    }
                )
            ])
            
            // Help & Support
            settingsSection(title: "Help & Support", items: [
                SettingsItem(
                    title: "About Muni",
                    icon: "info.circle.fill",
                    color: .gray,
                    action: { 
                        withAnimation {
                            showingAboutView = true
                        }
                    }
                ),
                SettingsItem(
                    title: "Developer Information",
                    icon: "person.crop.rectangle.fill",
                    color: .orange,
                    action: { showingDeveloperInfo = true }
                ),
                SettingsItem(
                    title: "Help Center",
                    icon: "questionmark.circle.fill",
                    color: .blue,
                    action: { 
                        withAnimation {
                            showingHelpCenter = true
                        }
                    }
                )
            ])
            
            // Reset App Section
            settingsSection(title: "Advanced Options", items: [
                SettingsItem(
                    title: "Reset App",
                    icon: "arrow.counterclockwise",
                    color: .red,
                    action: { 
                        withAnimation {
                            showingResetApp = true
                        }
                    }
                )
            ])
        }
        .padding(.horizontal)
    }
    
    // Helper struct for settings items
    struct SettingsItem: Identifiable {
        let id = UUID()
        let title: String
        let icon: String
        let color: Color
        let action: () -> Void
    }
    
    // Helper function for settings sections
    private func settingsSection(title: String, items: [SettingsItem]) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(title)
                .font(.headline)
                .foregroundColor(Theme.text)
                .padding(.bottom, 4)
            
            VStack(spacing: 0) {
                ForEach(items) { item in
                    Button(action: {
                        // Light haptic feedback
                        UIImpactFeedbackGenerator(style: .light).impactOccurred()
                        item.action()
                    }) {
                        HStack(spacing: 16) {
                            Image(systemName: item.icon)
                                .font(.system(size: 16))
                                .foregroundColor(item.color)
                                .frame(width: 28, height: 28)
                                .background(item.color.opacity(0.1))
                                .clipShape(Circle())
                            
                            Text(item.title)
                                .font(.system(size: 16))
                                .foregroundColor(Theme.text)
                            
                            Spacer()
                            
                            Image(systemName: "chevron.right")
                                .font(.system(size: 14))
                                .foregroundColor(Color.gray)
                        }
                        .padding()
                        .frame(maxWidth: .infinity, alignment: .leading)
                    }
                    .buttonStyle(PlainButtonStyle())
                    
                    if items.last?.id != item.id {
                        Divider()
                            .padding(.leading, 60)
                    }
                }
            }
            .background(Color(UIColor.secondarySystemBackground))
            .cornerRadius(12)
            .shadow(color: Color.black.opacity(0.05), radius: 4, x: 0, y: 2)
        }
    }
    
    // Version info footer
    private var versionInfo: some View {
        VStack(spacing: 4) {
            Text("Muni Finance App")
                .font(.system(size: 14, weight: .medium))
                .foregroundColor(Theme.text)
            
            Text("Version 1.0.0")
                .font(.system(size: 12))
                .foregroundColor(Theme.text.opacity(0.5))
        }
        .padding(.top, 20)
    }
    
    // Apply appearance settings
    private func applyAppearanceSettings() {
        // In a real app, we would persist this setting and apply it to the app
        // For now we just print the selection
        print("Selected appearance: \(selectedAppearance)")
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
        // Create PDF document with enhanced styling and branding
        let pdfMetaData: [CFString: Any] = [
            kCGPDFContextCreator: "Muni Finance App" as CFString,
            kCGPDFContextAuthor: userManager.name as CFString,
            kCGPDFContextTitle: "Muni Financial Report" as CFString,
            kCGPDFContextKeywords: "finance, budget, transactions, report" as CFString,
            kCGPDFContextAllowsPrinting: true as CFBoolean,
            kCGPDFContextAllowsCopying: true as CFBoolean
        ]
        
        let format = UIGraphicsPDFRendererFormat()
        format.documentInfo = pdfMetaData as [String: Any]
        
        let pageWidth = 8.5 * 72.0
        let pageHeight = 11.0 * 72.0
        let pageRect = CGRect(x: 0, y: 0, width: pageWidth, height: pageHeight)
        let margin: CGFloat = 50
        let contentWidth = pageWidth - (margin * 2)
        
        let renderer = UIGraphicsPDFRenderer(bounds: pageRect, format: format)
        
        try? renderer.writePDF(to: fileURL) { context in
            let cgContext = context.cgContext
            var currentPage = 1
            var yPosition: CGFloat = 0
            
            func drawHeaderFooter() {
                // Add decorative banner at top of page
                let bannerHeight: CGFloat = 90
                let gradient = CGGradient(
                    colorsSpace: CGColorSpaceCreateDeviceRGB(),
                    colors: [UIColor(Theme.primary).cgColor, UIColor(Theme.primary.opacity(0.7)).cgColor] as CFArray,
                    locations: [0, 1]
                )!
                
                cgContext.saveGState()
                cgContext.addRect(CGRect(x: 0, y: 0, width: pageWidth, height: bannerHeight))
                cgContext.clip()
                cgContext.drawLinearGradient(
                    gradient,
                    start: CGPoint(x: 0, y: 0),
                    end: CGPoint(x: pageWidth, y: bannerHeight),
                    options: []
                )
                cgContext.restoreGState()
                
                // App logo/branding
                let logoSize: CGFloat = 60
                let logoRect = CGRect(x: margin, y: 15, width: logoSize, height: logoSize)
                let logoPath = UIBezierPath(roundedRect: logoRect, cornerRadius: 12)
                UIColor.white.setFill()
                logoPath.fill()
                
                // Draw the app logo or "M" for Muni
                let logoText = "M"
                let logoTextAttributes: [NSAttributedString.Key: Any] = [
                    .font: UIFont.systemFont(ofSize: 32, weight: .black),
                    .foregroundColor: UIColor(Theme.primary)
                ]
                let logoTextSize = (logoText as NSString).size(withAttributes: logoTextAttributes)
                (logoText as NSString).draw(
                    at: CGPoint(
                        x: margin + (logoSize - logoTextSize.width) / 2,
                        y: 15 + (logoSize - logoTextSize.height) / 2
                    ),
                    withAttributes: logoTextAttributes
                )
                
                // Report title
                let titleText = "Financial Report"
                let titleAttributes: [NSAttributedString.Key: Any] = [
                    .font: UIFont.systemFont(ofSize: 32, weight: .bold),
                    .foregroundColor: UIColor.white
                ]
                let titleSize = (titleText as NSString).size(withAttributes: titleAttributes)
                (titleText as NSString).draw(
                    at: CGPoint(x: margin + logoSize + 20, y: (bannerHeight - titleSize.height) / 2),
                    withAttributes: titleAttributes
                )
                
                // Add date to header
                let dateFormatter = DateFormatter()
                dateFormatter.dateStyle = .long
                let dateText = dateFormatter.string(from: Date())
                let dateAttributes: [NSAttributedString.Key: Any] = [
                    .font: UIFont.systemFont(ofSize: 14),
                    .foregroundColor: UIColor.white
                ]
                
                let dateTextSize = (dateText as NSString).size(withAttributes: dateAttributes)
                (dateText as NSString).draw(
                    at: CGPoint(x: pageWidth - margin - dateTextSize.width, y: bannerHeight - 30),
                    withAttributes: dateAttributes
                )
                
                // Add footer with page number
                let footerText = "Page \(currentPage)"
                let footerAttributes: [NSAttributedString.Key: Any] = [
                    .font: UIFont.systemFont(ofSize: 10),
                    .foregroundColor: UIColor.gray
                ]
                let footerSize = (footerText as NSString).size(withAttributes: footerAttributes)
                (footerText as NSString).draw(
                    at: CGPoint(x: (pageWidth - footerSize.width) / 2, y: pageHeight - 30),
                    withAttributes: footerAttributes
                )
                
                // Start y position for content after header
                yPosition = bannerHeight + 30
            }
            
            func drawSection(title: String, content: @escaping () -> CGFloat) -> CGFloat {
                let sectionTitleAttributes: [NSAttributedString.Key: Any] = [
                    .font: UIFont.systemFont(ofSize: 18, weight: .semibold),
                    .foregroundColor: UIColor(Theme.primary)
                ]
                
                // Check if we need a new page
                let titleHeight = (title as NSString).size(withAttributes: sectionTitleAttributes).height
                if yPosition + titleHeight + 10 > pageHeight - 50 {
                    context.beginPage()
                    currentPage += 1
                    drawHeaderFooter()
                }
                
                // Draw section title
                (title as NSString).draw(
                    at: CGPoint(x: margin, y: yPosition),
                    withAttributes: sectionTitleAttributes
                )
                yPosition += titleHeight + 10
                
                // Draw separator line
                cgContext.setStrokeColor(UIColor(Theme.primary.opacity(0.3)).cgColor)
                cgContext.setLineWidth(1)
                cgContext.move(to: CGPoint(x: margin, y: yPosition))
                cgContext.addLine(to: CGPoint(x: pageWidth - margin, y: yPosition))
                cgContext.strokePath()
                yPosition += 15
                
                // Draw section content
                let contentHeight = content()
                yPosition += contentHeight + 30
                
                return contentHeight
            }
            
            func drawTable(headers: [String], rows: [[String]], columnWidths: [CGFloat]) -> CGFloat {
                let startY = yPosition
                let rowHeight: CGFloat = 30
                
                // Calculate total width
                let tableWidth = columnWidths.reduce(0, +)
                
                // Draw headers
                let headerAttributes: [NSAttributedString.Key: Any] = [
                    .font: UIFont.systemFont(ofSize: 12, weight: .bold),
                    .foregroundColor: UIColor.white
                ]
                
                // Header background
                cgContext.setFillColor(UIColor(Theme.primary).cgColor)
                cgContext.fill(CGRect(x: margin, y: yPosition, width: tableWidth, height: rowHeight))
                
                var xOffset = margin
                for (index, header) in headers.enumerated() {
                    let headerWidth = columnWidths[index]
                    let rect = CGRect(x: xOffset, y: yPosition, width: headerWidth, height: rowHeight)
                    
                    // Center text in cell
                    let textSize = (header as NSString).size(withAttributes: headerAttributes)
                    let textX = xOffset + (headerWidth - textSize.width) / 2
                    let textY = yPosition + (rowHeight - textSize.height) / 2
                    
                    (header as NSString).draw(
                        at: CGPoint(x: textX, y: textY),
                        withAttributes: headerAttributes
                    )
                    
                    xOffset += headerWidth
                }
                
                yPosition += rowHeight
                
                // Draw rows
                let rowAttributes: [NSAttributedString.Key: Any] = [
                    .font: UIFont.systemFont(ofSize: 11),
                    .foregroundColor: UIColor.black
                ]
                
                for (rowIndex, row) in rows.enumerated() {
                    // Check if we need a new page
                    if yPosition + rowHeight > pageHeight - 50 {
                        context.beginPage()
                        currentPage += 1
                        drawHeaderFooter()
                        
                        // Redraw header on new page
                        cgContext.setFillColor(UIColor(Theme.primary).cgColor)
                        cgContext.fill(CGRect(x: margin, y: yPosition, width: tableWidth, height: rowHeight))
                        
                        xOffset = margin
                        for (index, header) in headers.enumerated() {
                            let headerWidth = columnWidths[index]
                            let rect = CGRect(x: xOffset, y: yPosition, width: headerWidth, height: rowHeight)
                            
                            // Center text in cell
                            let textSize = (header as NSString).size(withAttributes: headerAttributes)
                            let textX = xOffset + (headerWidth - textSize.width) / 2
                            let textY = yPosition + (rowHeight - textSize.height) / 2
                            
                            (header as NSString).draw(
                                at: CGPoint(x: textX, y: textY),
                                withAttributes: headerAttributes
                            )
                            
                            xOffset += headerWidth
                        }
                        
                        yPosition += rowHeight
                    }
                    
                    // Row background (alternating)
                    if rowIndex % 2 == 0 {
                        cgContext.setFillColor(UIColor(white: 0.95, alpha: 1.0).cgColor)
                    } else {
                        cgContext.setFillColor(UIColor.white.cgColor)
                    }
                    cgContext.fill(CGRect(x: margin, y: yPosition, width: tableWidth, height: rowHeight))
                    
                    // Draw cell data
                    xOffset = margin
                    for (index, cell) in row.enumerated() {
                        if index < columnWidths.count {
                            let cellWidth = columnWidths[index]
                            let cellAttributes = rowAttributes
                            
                            // Right-align amount columns
                            var cellX = xOffset + 5
                            if index == 3 { // Amount column
                                let textSize = (cell as NSString).size(withAttributes: cellAttributes)
                                cellX = xOffset + cellWidth - textSize.width - 5
                            }
                            
                            let cellY = yPosition + (rowHeight - (cell as NSString).size(withAttributes: cellAttributes).height) / 2
                            
                            (cell as NSString).draw(
                                at: CGPoint(x: cellX, y: cellY),
                                withAttributes: cellAttributes
                            )
                            
                            xOffset += cellWidth
                        }
                    }
                    
                    yPosition += rowHeight
                    
                    // Draw horizontal grid lines
                    cgContext.setStrokeColor(UIColor.lightGray.cgColor)
                    cgContext.setLineWidth(0.5)
                    cgContext.move(to: CGPoint(x: margin, y: yPosition))
                    cgContext.addLine(to: CGPoint(x: margin + tableWidth, y: yPosition))
                    cgContext.strokePath()
                }
                
                return yPosition - startY
            }
            
            // Begin PDF
            context.beginPage()
            drawHeaderFooter()
            
            // User information section
            drawSection(title: "Account Summary") {
                let infoAttributes: [NSAttributedString.Key: Any] = [
                    .font: UIFont.systemFont(ofSize: 14),
                    .foregroundColor: UIColor.black
                ]
                
                let valueAttributes: [NSAttributedString.Key: Any] = [
                    .font: UIFont.systemFont(ofSize: 14, weight: .semibold),
                    .foregroundColor: UIColor.black
                ]
                
                let startY = yPosition
                let lineHeight: CGFloat = 25
                
                // User name
                let nameLabel = "Account Name:"
                (nameLabel as NSString).draw(
                    at: CGPoint(x: margin, y: yPosition),
                    withAttributes: infoAttributes
                )
                
                let nameValue = userManager.name
                (nameValue as NSString).draw(
                    at: CGPoint(x: margin + 150, y: yPosition),
                    withAttributes: valueAttributes
                )
                yPosition += lineHeight
                
                // Monthly income
                let incomeLabel = "Monthly Income:"
                (incomeLabel as NSString).draw(
                    at: CGPoint(x: margin, y: yPosition),
                    withAttributes: infoAttributes
                )
                
                let incomeValue = "\(userManager.currency)\(String(format: "%.2f", userManager.monthlyIncome))"
                (incomeValue as NSString).draw(
                    at: CGPoint(x: margin + 150, y: yPosition),
                    withAttributes: valueAttributes
                )
                yPosition += lineHeight
                
                // Monthly budget
                let budgetLabel = "Monthly Budget:"
                (budgetLabel as NSString).draw(
                    at: CGPoint(x: margin, y: yPosition),
                    withAttributes: infoAttributes
                )
                
                let budgetValue = "\(userManager.currency)\(String(format: "%.2f", userManager.monthlyBudget))"
                (budgetValue as NSString).draw(
                    at: CGPoint(x: margin + 150, y: yPosition),
                    withAttributes: valueAttributes
                )
                yPosition += lineHeight
                
                // Financial goal
                if !userManager.financialGoal.isEmpty {
                    let goalLabel = "Financial Goal:"
                    (goalLabel as NSString).draw(
                        at: CGPoint(x: margin, y: yPosition),
                        withAttributes: infoAttributes
                    )
                    
                    let goalValue = "\(userManager.financialGoal)"
                    (goalValue as NSString).draw(
                        at: CGPoint(x: margin + 150, y: yPosition),
                        withAttributes: valueAttributes
                    )
                    yPosition += lineHeight
                }
                
                // Current balance
                let balanceLabel = "Current Balance:"
                (balanceLabel as NSString).draw(
                    at: CGPoint(x: margin, y: yPosition),
                    withAttributes: infoAttributes
                )
                
                let balanceValue = "\(userManager.currency)\(String(format: "%.2f", transactionManager.balance()))"
                let balanceAttributes: [NSAttributedString.Key: Any] = [
                    .font: UIFont.systemFont(ofSize: 14, weight: .bold),
                    .foregroundColor: transactionManager.balance() >= 0 ? UIColor.systemGreen : UIColor.systemRed
                ]
                
                (balanceValue as NSString).draw(
                    at: CGPoint(x: margin + 150, y: yPosition),
                    withAttributes: balanceAttributes
                )
                yPosition += lineHeight
                
                return yPosition - startY
            }
            
            // Draw financial summary section with visual styling
            drawSection(title: "Financial Summary") {
                let startY = yPosition
                let barHeight: CGFloat = 20
                let barWidth: CGFloat = contentWidth
                let labelAttributes: [NSAttributedString.Key: Any] = [
                    .font: UIFont.systemFont(ofSize: 12),
                    .foregroundColor: UIColor.black
                ]
                
                // Total income
                let totalIncome = transactionManager.totalIncome()
                let incomeLabel = "Total Income: \(userManager.currency)\(String(format: "%.2f", totalIncome))"
                (incomeLabel as NSString).draw(
                    at: CGPoint(x: margin, y: yPosition),
                    withAttributes: labelAttributes
                )
                yPosition += 20
                
                // Income bar
                cgContext.setFillColor(UIColor.systemGreen.cgColor)
                cgContext.fill(CGRect(x: margin, y: yPosition, width: barWidth, height: barHeight))
                yPosition += barHeight + 10
                
                // Total expenses
                let totalExpense = transactionManager.totalExpense()
                let expenseLabel = "Total Expenses: \(userManager.currency)\(String(format: "%.2f", totalExpense))"
                (expenseLabel as NSString).draw(
                    at: CGPoint(x: margin, y: yPosition),
                    withAttributes: labelAttributes
                )
                yPosition += 20
                
                // If income is greater than 0, calculate the expense ratio
                if totalIncome > 0 {
                    let expenseRatio = min(1.0, totalExpense / totalIncome)
                    cgContext.setFillColor(UIColor.systemRed.cgColor)
                    cgContext.fill(CGRect(x: margin, y: yPosition, width: barWidth * CGFloat(expenseRatio), height: barHeight))
                }
                yPosition += barHeight + 10
                
                // Balance
                let balance = totalIncome - totalExpense
                let balanceLabel = "Balance: \(userManager.currency)\(String(format: "%.2f", balance))"
                let balanceAttributes: [NSAttributedString.Key: Any] = [
                    .font: UIFont.systemFont(ofSize: 14, weight: .bold),
                    .foregroundColor: balance >= 0 ? UIColor.systemGreen : UIColor.systemRed
                ]
                (balanceLabel as NSString).draw(
                    at: CGPoint(x: margin, y: yPosition),
                    withAttributes: balanceAttributes
                )
                yPosition += 20
                
                // Draw a separator
                cgContext.setStrokeColor(UIColor.lightGray.cgColor)
                cgContext.setLineWidth(0.5)
                cgContext.move(to: CGPoint(x: margin, y: yPosition + 10))
                cgContext.addLine(to: CGPoint(x: pageWidth - margin, y: yPosition + 10))
                cgContext.strokePath()
                yPosition += 20
                
                return yPosition - startY
            }
            
            // Draw transactions table
            drawSection(title: "Transaction History") {
                let startY = yPosition
                
                // Prepare transaction data for table
                let headers = ["Date", "Type", "Category", "Amount", "Note"]
                var rows: [[String]] = []
                
                let dateFormatter = DateFormatter()
                dateFormatter.dateStyle = .short
                
                for transaction in transactionManager.transactions.sorted(by: { $0.date > $1.date }) {
                    let date = dateFormatter.string(from: transaction.date)
                    let type = transaction.type.rawValue
                    let category = transaction.category.rawValue
                    let amount = "\(userManager.currency)\(String(format: "%.2f", transaction.amount))"
                    let note = transaction.note
                    
                    rows.append([date, type, category, amount, note])
                }
                
                // Draw the table
                let columnWidths: [CGFloat] = [80, 80, 100, 100, contentWidth - 360]
                let tableHeight = drawTable(headers: headers, rows: rows, columnWidths: columnWidths)
                
                return tableHeight
            }
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

// Custom button style for scale animation
struct ScaleButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .scaleEffect(configuration.isPressed ? 0.96 : 1)
            .animation(.spring(response: 0.3, dampingFraction: 0.6), value: configuration.isPressed)
    }
}

