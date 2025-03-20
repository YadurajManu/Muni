import SwiftUI

struct RecurringTransactionSetupView: View {
    @Environment(\.presentationMode) private var presentationMode
    @EnvironmentObject private var transactionManager: TransactionManager
    @EnvironmentObject private var userManager: UserManager
    
    @State private var amount: String = ""
    @State private var note: String = ""
    @State private var category: TransactionCategory = .miscellaneous
    @State private var transactionType: TransactionType = .expense
    @State private var frequency: RecurringFrequency = .monthly
    @State private var startDate = Date()
    @State private var hasEndDate = false
    @State private var endDate = Calendar.current.date(byAdding: .year, value: 1, to: Date()) ?? Date()
    
    @FocusState private var isAmountFocused: Bool
    
    var body: some View {
        NavigationView {
            Form {
                // Transaction type selection
                Section {
                    Picker("Transaction Type", selection: $transactionType) {
                        Text("Expense").tag(TransactionType.expense)
                        Text("Income").tag(TransactionType.income)
                    }
                    .pickerStyle(SegmentedPickerStyle())
                    .onChange(of: transactionType) { newValue in
                        // Update category to match transaction type
                        if newValue == .income {
                            category = .salary
                        } else {
                            category = .miscellaneous
                        }
                        
                        // Provide haptic feedback
                        UIImpactFeedbackGenerator(style: .light).impactOccurred()
                    }
                }
                
                // Amount section
                Section {
                    HStack {
                        Text(userManager.currency)
                            .font(.headline)
                            .foregroundColor(Theme.text.opacity(0.7))
                        
                        TextField("0", text: $amount)
                            .keyboardType(.decimalPad)
                            .focused($isAmountFocused)
                    }
                }
                
                // Transaction details
                Section(header: Text("Details")) {
                    TextField("Note", text: $note)
                    
                    Picker("Category", selection: $category) {
                        ForEach(getCategories(for: transactionType), id: \.self) { category in
                            HStack {
                                Image(systemName: category.iconName)
                                    .foregroundColor(category.color)
                                Text(category.rawValue)
                            }
                            .tag(category)
                        }
                    }
                    .onChange(of: category) { _ in
                        // Light haptic feedback
                        UIImpactFeedbackGenerator(style: .light).impactOccurred(intensity: 0.5)
                    }
                }
                
                // Recurring options
                Section(header: Text("Recurrence")) {
                    Picker("Frequency", selection: $frequency) {
                        ForEach(RecurringFrequency.allCases, id: \.self) { freq in
                            Text(freq.displayName)
                                .tag(freq)
                        }
                    }
                    .onChange(of: frequency) { _ in
                        // Light haptic feedback
                        UIImpactFeedbackGenerator(style: .light).impactOccurred(intensity: 0.5)
                    }
                    
                    DatePicker("Start Date", selection: $startDate, displayedComponents: .date)
                    
                    Toggle("End Date", isOn: $hasEndDate)
                        .onChange(of: hasEndDate) { _ in
                            // Light haptic feedback
                            UIImpactFeedbackGenerator(style: .light).impactOccurred(intensity: 0.5)
                        }
                    
                    if hasEndDate {
                        DatePicker("End Date", selection: $endDate, in: startDate..., displayedComponents: .date)
                    }
                }
                
                // Info section
                Section(header: Text("Information"), footer: Text("Recurring transactions will automatically be added to your transaction history based on the frequency you choose.")) {
                    HStack {
                        Image(systemName: "info.circle")
                            .foregroundColor(Theme.primary)
                        
                        VStack(alignment: .leading) {
                            Text("This will create a \(frequency.description.lowercased()) transaction for \(transactionType == .expense ? "payment" : "deposit") of \(userManager.currency)\(amount.isEmpty ? "0" : amount)")
                                .font(.system(size: 14))
                                .foregroundColor(Theme.text)
                            
                            Text(hasEndDate ? "Ends on \(formattedDate(endDate))" : "No end date")
                                .font(.system(size: 12))
                                .foregroundColor(Theme.text.opacity(0.7))
                        }
                    }
                }
                
                // Save button
                Section {
                    Button(action: saveRecurringTransaction) {
                        HStack {
                            Spacer()
                            Text("Save Recurring Transaction")
                                .font(.headline)
                                .foregroundColor(.white)
                            Spacer()
                        }
                        .padding(.vertical, 10)
                        .background(isValid ? Theme.primary : Color.gray)
                        .cornerRadius(8)
                    }
                    .disabled(!isValid)
                    .listRowBackground(Color.clear)
                }
            }
            .navigationTitle("Recurring Transaction")
            .navigationBarItems(
                leading: Button("Cancel") {
                    presentationMode.wrappedValue.dismiss()
                }
            )
            .onAppear {
                // Auto focus on amount field
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                    isAmountFocused = true
                }
            }
        }
    }
    
    // Computed property to check if form is valid
    private var isValid: Bool {
        guard let amountValue = Double(amount), amountValue > 0 else { return false }
        return !note.isEmpty
    }
    
    // Save the recurring transaction
    private func saveRecurringTransaction() {
        guard let amountValue = Double(amount), amountValue > 0 else { return }
        
        // Create base transaction
        let baseTransaction = Transaction(
            id: UUID(),
            amount: amountValue,
            type: transactionType,
            category: category,
            date: startDate,
            note: note
        )
        
        // Add recurring transaction
        transactionManager.addRecurringTransaction(
            baseTransaction,
            frequency: frequency,
            endDate: hasEndDate ? endDate : nil
        )
        
        // Success haptic
        UINotificationFeedbackGenerator().notificationOccurred(.success)
        
        presentationMode.wrappedValue.dismiss()
    }
    
    // Helper to get categories for transaction type
    private func getCategories(for type: TransactionType) -> [TransactionCategory] {
        return TransactionCategory.allCases.filter { $0.transactionType == type }
    }
    
    // Format date for display
    private func formattedDate(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        formatter.timeStyle = .none
        return formatter.string(from: date)
    }
} 