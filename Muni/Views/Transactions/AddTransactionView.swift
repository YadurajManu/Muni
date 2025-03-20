//
//  AddTransactionView.swift
//  Muni
//
//  Created by Yaduraj Singh on 20/03/25.
//

import SwiftUI

struct AddTransactionView: View {
    @EnvironmentObject private var transactionManager: TransactionManager
    @EnvironmentObject private var userManager: UserManager
    @Environment(\.presentationMode) private var presentationMode
    
    @State private var transactionType: TransactionType = .expense
    @State private var selectedCategory: TransactionCategory = .food
    @State private var amount: String = ""
    @State private var date: Date = Date()
    @State private var note: String = ""
    @State private var location: String = ""
    @State private var showAlert: Bool = false
    @State private var alertMessage: String = ""
    @State private var isScanning: Bool = false
    @State private var showingScanner: Bool = false
    @State private var recurringFrequency: RecurringFrequency = .none
    @State private var paymentMethod: PaymentMethod = .cash
    
    enum RecurringFrequency: String, Identifiable, CaseIterable {
        case none = "None"
        case daily = "Daily"
        case weekly = "Weekly"
        case monthly = "Monthly"
        case yearly = "Yearly"
        
        var id: String { self.rawValue }
    }
    
    enum PaymentMethod: String, Identifiable, CaseIterable {
        case cash = "Cash"
        case creditCard = "Credit Card"
        case debitCard = "Debit Card"
        case upi = "UPI"
        case bankTransfer = "Bank Transfer"
        case other = "Other"
        
        var id: String { self.rawValue }
        
        var icon: String {
            switch self {
            case .cash: return "indianrupeesign.circle"
            case .creditCard: return "creditcard"
            case .debitCard: return "creditcard.fill"
            case .upi: return "iphone"
            case .bankTransfer: return "building.columns"
            case .other: return "ellipsis.circle"
            }
        }
    }
    
    private var categories: [TransactionCategory] {
        transactionType == .income ? TransactionCategory.incomeCategories() : TransactionCategory.expenseCategories()
    }
    
    private var isFormValid: Bool {
        !amount.isEmpty && Double(amount) ?? 0 > 0 && !note.isEmpty
    }
    
    var body: some View {
        NavigationView {
            ZStack {
                Color(uiColor: UIColor.systemGroupedBackground)
                    .ignoresSafeArea()
                
                VStack {
                    // Custom segmented control for transaction type
                    segmentedTypeSelector
                        .padding(.horizontal)
                        .padding(.top)
                    
                    ScrollView {
                        VStack(spacing: 16) {
                            // Amount input with currency
                            amountCard
                            
                            // Quick amount buttons for common amounts
                            if transactionType == .expense {
                                quickAmountSelector
                            }
                            
                            // Date picker
                            dateCard
                            
                            // Category selector
                            categoryCard
                            
                            // Payment method selector (for expenses only)
                            if transactionType == .expense {
                                paymentMethodCard
                            }
                            
                            // Recurring transaction
                            recurringCard
                            
                            // Note and location
                            detailsCard
                            
                            // Save button
                            Button(action: saveTransaction) {
                                Text("Save Transaction")
                                    .font(.system(size: Theme.bodySize, weight: .semibold))
                                    .foregroundColor(.white)
                                    .frame(maxWidth: .infinity)
                                    .padding()
                                    .background(isFormValid ? Theme.primary : Color.gray)
                                    .cornerRadius(Theme.cornerRadiusMedium)
                                    .padding(.horizontal)
                            }
                            .disabled(!isFormValid)
                            .padding(.vertical)
                            
                            Spacer()
                        }
                        .padding(.horizontal)
                        .padding(.top, 10)
                    }
                }
                .sheet(isPresented: $showingScanner) {
                    ReceiptScannerView(onScanComplete: handleScannedReceipt)
                }
                .overlay {
                    if isScanning {
                        scanningOverlay
                    }
                }
            }
            .navigationTitle(transactionType == .income ? "Add Income" : "Add Expense")
            .navigationBarTitleDisplayMode(.inline)
            .navigationBarItems(
                leading: Button("Cancel") {
                    presentationMode.wrappedValue.dismiss()
                },
                trailing: Button(action: {
                    showingScanner = true
                }) {
                    Image(systemName: "camera")
                        .font(.system(size: 18))
                }
            )
            .alert(isPresented: $showAlert) {
                Alert(
                    title: Text("Error"),
                    message: Text(alertMessage),
                    dismissButton: .default(Text("OK"))
                )
            }
        }
    }
    
    private var segmentedTypeSelector: some View {
        HStack(spacing: 0) {
            ForEach(TransactionType.allCases, id: \.self) { type in
                Button(action: {
                    withAnimation(.spring()) {
                        transactionType = type
                        // Reset category when type changes
                        selectedCategory = transactionType == .income ? .salary : .food
                    }
                }) {
                    Text(type.rawValue)
                        .font(.system(size: 16, weight: .medium))
                        .foregroundColor(transactionType == type ? .white : Theme.text.opacity(0.7))
                        .padding(.vertical, 12)
                        .frame(maxWidth: .infinity)
                        .background(
                            transactionType == type ?
                            (type == .income ? Theme.income : Theme.expense) :
                            Color.clear
                        )
                        .cornerRadius(10)
                }
            }
        }
        .padding(4)
        .background(Color(UIColor.secondarySystemGroupedBackground))
        .cornerRadius(12)
    }
    
    private var amountCard: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Amount")
                .font(.system(size: 16, weight: .medium))
                .foregroundColor(Theme.text.opacity(0.8))
            
            HStack(alignment: .center) {
                Text(userManager.currency)
                    .font(.system(size: 30, weight: .bold))
                    .foregroundColor(transactionType == .income ? Theme.income : Theme.expense)
                
                TextField("0", text: $amount)
                    .font(.system(size: 40, weight: .medium))
                    .keyboardType(.decimalPad)
                    .foregroundColor(transactionType == .income ? Theme.income : Theme.expense)
                    .multilineTextAlignment(.trailing)
                    .frame(maxWidth: .infinity)
            }
            .padding()
            .background(Color(UIColor.secondarySystemGroupedBackground))
            .cornerRadius(12)
        }
        .padding()
        .background(Color(UIColor.tertiarySystemGroupedBackground))
        .cornerRadius(16)
    }
    
    private var quickAmountSelector: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Quick Amount")
                .font(.system(size: 16, weight: .medium))
                .foregroundColor(Theme.text.opacity(0.8))
            
            HStack(spacing: 10) {
                ForEach(["100", "500", "1000", "2000"], id: \.self) { value in
                    Button(action: {
                        amount = value
                    }) {
                        Text("₹\(value)")
                            .font(.system(size: 16, weight: .medium))
                            .foregroundColor(amount == value ? .white : Theme.text)
                            .padding(.vertical, 10)
                            .frame(maxWidth: .infinity)
                            .background(amount == value ? Theme.primary : Color(UIColor.secondarySystemGroupedBackground))
                            .cornerRadius(8)
                    }
                }
            }
        }
        .padding()
        .background(Color(UIColor.tertiarySystemGroupedBackground))
        .cornerRadius(16)
    }
    
    private var dateCard: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Date & Time")
                .font(.system(size: 16, weight: .medium))
                .foregroundColor(Theme.text.opacity(0.8))
            
            DatePicker("", selection: $date)
                .datePickerStyle(CompactDatePickerStyle())
                .labelsHidden()
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding()
                .background(Color(UIColor.secondarySystemGroupedBackground))
                .cornerRadius(12)
        }
        .padding()
        .background(Color(UIColor.tertiarySystemGroupedBackground))
        .cornerRadius(16)
    }
    
    private var categoryCard: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Category")
                .font(.system(size: 16, weight: .medium))
                .foregroundColor(Theme.text.opacity(0.8))
            
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 16) {
                    ForEach(categories, id: \.self) { category in
                        VStack(spacing: 8) {
                            ZStack {
                                Circle()
                                    .fill(selectedCategory == category ? Theme.primary : Color(UIColor.secondarySystemGroupedBackground))
                                    .frame(width: 60, height: 60)
                                
                                Image(systemName: category.icon)
                                    .font(.system(size: 24))
                                    .foregroundColor(selectedCategory == category ? .white : Theme.primary)
                            }
                            
                            Text(category.rawValue)
                                .font(.system(size: 14))
                                .foregroundColor(Theme.text)
                                .multilineTextAlignment(.center)
                        }
                        .frame(width: 80)
                        .onTapGesture {
                            withAnimation {
                                selectedCategory = category
                            }
                        }
                    }
                }
                .padding(.vertical, 10)
            }
        }
        .padding()
        .background(Color(UIColor.tertiarySystemGroupedBackground))
        .cornerRadius(16)
    }
    
    private var paymentMethodCard: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Payment Method")
                .font(.system(size: 16, weight: .medium))
                .foregroundColor(Theme.text.opacity(0.8))
            
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 16) {
                    ForEach(PaymentMethod.allCases) { method in
                        VStack(spacing: 8) {
                            ZStack {
                                Circle()
                                    .fill(paymentMethod == method ? Theme.primary : Color(UIColor.secondarySystemGroupedBackground))
                                    .frame(width: 60, height: 60)
                                
                                Image(systemName: method.icon)
                                    .font(.system(size: 24))
                                    .foregroundColor(paymentMethod == method ? .white : Theme.primary)
                            }
                            
                            Text(method.rawValue)
                                .font(.system(size: 14))
                                .foregroundColor(Theme.text)
                                .multilineTextAlignment(.center)
                        }
                        .frame(width: 80)
                        .onTapGesture {
                            withAnimation {
                                paymentMethod = method
                            }
                        }
                    }
                }
                .padding(.vertical, 10)
            }
        }
        .padding()
        .background(Color(UIColor.tertiarySystemGroupedBackground))
        .cornerRadius(16)
    }
    
    private var recurringCard: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Recurring")
                .font(.system(size: 16, weight: .medium))
                .foregroundColor(Theme.text.opacity(0.8))
            
            VStack {
                Picker("Frequency", selection: $recurringFrequency) {
                    ForEach(RecurringFrequency.allCases) { frequency in
                        Text(frequency.rawValue).tag(frequency)
                    }
                }
                .pickerStyle(SegmentedPickerStyle())
            }
            .padding()
            .background(Color(UIColor.secondarySystemGroupedBackground))
            .cornerRadius(12)
        }
        .padding()
        .background(Color(UIColor.tertiarySystemGroupedBackground))
        .cornerRadius(16)
    }
    
    private var detailsCard: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Details")
                .font(.system(size: 16, weight: .medium))
                .foregroundColor(Theme.text.opacity(0.8))
            
            VStack(spacing: 8) {
                // Note field
                VStack(alignment: .leading, spacing: 6) {
                    Text("Note")
                        .font(.system(size: 14))
                        .foregroundColor(Theme.text.opacity(0.6))
                    
                    TextField("Add a note", text: $note)
                        .padding()
                        .background(Color(UIColor.secondarySystemFill))
                        .cornerRadius(10)
                }
                
                // Location field
                VStack(alignment: .leading, spacing: 6) {
                    Text("Location (optional)")
                        .font(.system(size: 14))
                        .foregroundColor(Theme.text.opacity(0.6))
                    
                    HStack {
                        TextField("Add a location", text: $location)
                        
                        Button(action: {
                            // In a real app, we would get current location
                            location = "Current Location"
                        }) {
                            Image(systemName: "location.fill")
                                .foregroundColor(Theme.primary)
                        }
                    }
                    .padding()
                    .background(Color(UIColor.secondarySystemFill))
                    .cornerRadius(10)
                }
            }
            .padding()
            .background(Color(UIColor.secondarySystemGroupedBackground))
            .cornerRadius(12)
        }
        .padding()
        .background(Color(UIColor.tertiarySystemGroupedBackground))
        .cornerRadius(16)
    }
    
    private var scanningOverlay: some View {
        ZStack {
            Color.black.opacity(0.4)
                .ignoresSafeArea()
            
            VStack(spacing: 20) {
                ProgressView()
                    .scaleEffect(1.5)
                    .progressViewStyle(CircularProgressViewStyle(tint: .white))
                
                Text("Scanning Receipt...")
                    .font(.system(size: 16, weight: .medium))
                    .foregroundColor(.white)
            }
            .padding(30)
            .background(Theme.primary.opacity(0.8))
            .cornerRadius(20)
        }
        .transition(.opacity)
    }
    
    private func saveTransaction() {
        guard let amountValue = Double(amount) else {
            alertMessage = "Please enter a valid amount"
            showAlert = true
            return
        }
        
        let transaction = Transaction(
            amount: amountValue,
            type: transactionType,
            category: selectedCategory,
            date: date,
            note: note
        )
        
        transactionManager.addTransaction(transaction)
        transactionManager.saveTransactions()
        
        // If recurring, we could add code to schedule future transactions
        
        presentationMode.wrappedValue.dismiss()
    }
    
    private func handleScannedReceipt(_ result: ReceiptScanResult) {
        // Simulate receipt scanning
        isScanning = true
        
        // Simulate processing delay
        DispatchQueue.main.asyncAfter(deadline: .now() + 2.0) {
            // Update fields with scanned data
            amount = result.amount
            note = result.vendor
            location = result.location
            
            // For demo purposes, guess a category based on the vendor name
            if let guessedCategory = guessCategory(from: result.vendor) {
                selectedCategory = guessedCategory
            }
            
            isScanning = false
        }
    }
    
    private func guessCategory(from vendor: String) -> TransactionCategory? {
        let lowercasedVendor = vendor.lowercased()
        
        // Simple category detection based on keywords
        if lowercasedVendor.contains("restaurant") || lowercasedVendor.contains("cafe") || lowercasedVendor.contains("food") {
            return .food
        } else if lowercasedVendor.contains("uber") || lowercasedVendor.contains("ola") || lowercasedVendor.contains("petrol") {
            return .transportation
        } else if lowercasedVendor.contains("movie") || lowercasedVendor.contains("netflix") || lowercasedVendor.contains("entertainment") {
            return .entertainment
        } else if lowercasedVendor.contains("amazon") || lowercasedVendor.contains("flipkart") || lowercasedVendor.contains("mall") {
            return .shopping
        } else if lowercasedVendor.contains("hospital") || lowercasedVendor.contains("pharmacy") || lowercasedVendor.contains("doctor") {
            return .health
        } else if lowercasedVendor.contains("electricity") || lowercasedVendor.contains("water") || lowercasedVendor.contains("bill") {
            return .bills
        } else if lowercasedVendor.contains("hotel") || lowercasedVendor.contains("flight") || lowercasedVendor.contains("travel") {
            return .travel
        }
        
        // Default to miscellaneous if no match
        return nil
    }
}

// MARK: - Receipt Scanner Simulation
struct ReceiptScannerView: View {
    @Environment(\.presentationMode) var presentationMode
    var onScanComplete: (ReceiptScanResult) -> Void
    
    @State private var isScanning = false
    
    var body: some View {
        NavigationView {
            ZStack {
                // Camera preview simulation
                Color.black
                    .ignoresSafeArea()
                
                // Camera frame guide
                VStack {
                    Spacer()
                    
                    ZStack {
                        RoundedRectangle(cornerRadius: 12)
                            .stroke(Color.white, lineWidth: 2)
                            .frame(width: 280, height: 400)
                        
                        Text("Position Receipt Here")
                            .font(.system(size: 16, weight: .medium))
                            .foregroundColor(.white)
                            .padding(6)
                            .background(Color.black.opacity(0.6))
                            .cornerRadius(8)
                            .offset(y: -180)
                    }
                    
                    Spacer()
                    
                    Button(action: {
                        simulateScan()
                    }) {
                        Circle()
                            .fill(Color.white)
                            .frame(width: 70, height: 70)
                            .overlay(
                                Circle()
                                    .stroke(Color.white.opacity(0.3), lineWidth: 4)
                                    .frame(width: 80, height: 80)
                            )
                    }
                    .padding(.bottom, 30)
                }
                
                // Scanning overlay
                if isScanning {
                    Color.black.opacity(0.6)
                        .ignoresSafeArea()
                        .overlay(
                            VStack {
                                ProgressView()
                                    .progressViewStyle(CircularProgressViewStyle(tint: .white))
                                    .scaleEffect(1.5)
                                
                                Text("Processing Receipt...")
                                    .font(.headline)
                                    .foregroundColor(.white)
                                    .padding(.top, 20)
                            }
                        )
                }
            }
            .navigationTitle("Scan Receipt")
            .navigationBarTitleDisplayMode(.inline)
            .navigationBarItems(leading: Button("Cancel") {
                presentationMode.wrappedValue.dismiss()
            })
        }
    }
    
    private func simulateScan() {
        isScanning = true
        
        // Simulate processing delay
        DispatchQueue.main.asyncAfter(deadline: .now() + 2.0) {
            // Generate random receipt data for demonstration
            let amounts = ["525.75", "1299.00", "845.50", "99.99", "2499.00"]
            let vendors = ["Cafe Coffee Day", "Big Bazaar", "Reliance Fresh", "BookMyShow", "Apollo Pharmacy"]
            let locations = ["MG Road, Bangalore", "HSR Layout", "Koramangala", "Indira Nagar", "Whitefield"]
            
            let result = ReceiptScanResult(
                amount: amounts.randomElement() ?? "525.75",
                vendor: vendors.randomElement() ?? "Cafe Coffee Day",
                date: Date(),
                location: locations.randomElement() ?? "MG Road, Bangalore"
            )
            
            // Pass result back and dismiss
            onScanComplete(result)
            presentationMode.wrappedValue.dismiss()
        }
    }
}

struct ReceiptScanResult {
    let amount: String
    let vendor: String
    let date: Date
    let location: String
} 