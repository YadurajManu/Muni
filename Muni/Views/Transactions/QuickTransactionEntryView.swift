import SwiftUI

struct QuickTransactionEntryView: View {
    @Environment(\.presentationMode) private var presentationMode
    @EnvironmentObject private var userManager: UserManager
    
    let transactionType: TransactionType
    let presetCategory: TransactionCategory
    let onSave: (Transaction) -> Void
    
    @State private var amount: String = ""
    @State private var note: String = ""
    @State private var category: TransactionCategory
    @State private var date = Date()
    @State private var showDatePicker = false
    @FocusState private var isAmountFocused: Bool
    
    // Initialize with preset category
    init(transactionType: TransactionType, presetCategory: TransactionCategory, onSave: @escaping (Transaction) -> Void) {
        self.transactionType = transactionType
        self.presetCategory = presetCategory
        self._category = State(initialValue: presetCategory)
        self.onSave = onSave
    }
    
    var body: some View {
        NavigationView {
            Form {
                // Auto-focus on amount field
                Section {
                    HStack {
                        Text(userManager.currency)
                            .font(.title2)
                            .foregroundColor(Theme.text.opacity(0.7))
                        
                        TextField("0", text: $amount)
                            .font(.system(size: 34, weight: .bold))
                            .keyboardType(.decimalPad)
                            .multilineTextAlignment(.leading)
                            .focused($isAmountFocused)
                        
                        Spacer()
                    }
                    .listRowBackground(Color.clear)
                    .listRowInsets(EdgeInsets(top: 10, leading: 16, bottom: 10, trailing: 16))
                }
                
                // Note field
                Section(header: Text("Note")) {
                    TextField("What's this for?", text: $note)
                }
                
                // Category selector
                Section(header: Text("Category")) {
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
                    .pickerStyle(MenuPickerStyle())
                }
                
                // Date picker
                Section(header: Text("Date")) {
                    Button(action: {
                        withAnimation {
                            showDatePicker.toggle()
                        }
                        
                        // Light haptic
                        UIImpactFeedbackGenerator(style: .light).impactOccurred()
                    }) {
                        HStack {
                            Text("Date")
                            Spacer()
                            Text(formattedDate())
                                .foregroundColor(.gray)
                        }
                    }
                    
                    if showDatePicker {
                        DatePicker("", selection: $date, displayedComponents: .date)
                            .datePickerStyle(GraphicalDatePickerStyle())
                            .frame(maxHeight: 400)
                            .onChange(of: date) { _ in
                                // Light haptic on date change
                                UIImpactFeedbackGenerator(style: .light).impactOccurred(intensity: 0.5)
                            }
                    }
                }
                
                // Submission button
                Section {
                    Button(action: saveTransaction) {
                        HStack {
                            Spacer()
                            Text("Save \(transactionType.rawValue)")
                                .font(.headline)
                                .foregroundColor(.white)
                            Spacer()
                        }
                        .padding(.vertical, 10)
                        .background(isValidTransaction ? Theme.primary : Color.gray)
                        .cornerRadius(8)
                    }
                    .disabled(!isValidTransaction)
                    .listRowBackground(Color.clear)
                }
            }
            .navigationTitle("\(presetCategory.rawValue) \(transactionType.rawValue)")
            .navigationBarItems(
                leading: Button("Cancel") {
                    presentationMode.wrappedValue.dismiss()
                }
            )
            .onAppear {
                // Auto focus on amount field when view appears
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                    isAmountFocused = true
                }
            }
        }
    }
    
    private var isValidTransaction: Bool {
        guard let amountValue = Double(amount), amountValue > 0 else { return false }
        return true
    }
    
    private func saveTransaction() {
        guard let amountValue = Double(amount), amountValue > 0 else { return }
        
        let transaction = Transaction(
            id: UUID(),
            type: transactionType,
            category: category,
            amount: amountValue,
            date: date,
            note: note.isEmpty ? "\(category.rawValue)" : note
        )
        
        onSave(transaction)
        
        // Haptic feedback
        UINotificationFeedbackGenerator().notificationOccurred(.success)
        
        presentationMode.wrappedValue.dismiss()
    }
    
    private func formattedDate() -> String {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        formatter.timeStyle = .none
        return formatter.string(from: date)
    }
    
    private func getCategories(for type: TransactionType) -> [TransactionCategory] {
        return TransactionCategory.allCases.filter { $0.transactionType == type }
    }
}

// Extension to provide additional properties for TransactionCategory
extension TransactionCategory {
    var transactionType: TransactionType {
        switch self {
        case .food, .transportation, .shopping, .entertainment, .bills, .healthcare, .education, .miscellaneous:
            return .expense
        case .salary, .business, .investment, .gifts:
            return .income
        }
    }
    
    var iconName: String {
        switch self {
        case .food: return "fork.knife"
        case .transportation: return "car.fill"
        case .shopping: return "bag.fill"
        case .entertainment: return "film.fill"
        case .bills: return "doc.text.fill"
        case .healthcare: return "heart.fill"
        case .education: return "book.fill"
        case .miscellaneous: return "ellipsis.circle.fill"
        case .salary: return "indianrupeesign.circle.fill"
        case .business: return "briefcase.fill"
        case .investment: return "chart.line.uptrend.xyaxis"
        case .gifts: return "gift.fill"
        }
    }
    
    var color: Color {
        switch self {
        case .food: return .orange
        case .transportation: return .blue
        case .shopping: return .purple
        case .entertainment: return .pink
        case .bills: return .gray
        case .healthcare: return .red
        case .education: return .cyan
        case .miscellaneous: return .gray
        case .salary: return .green
        case .business: return .indigo
        case .investment: return .green
        case .gifts: return .orange
        }
    }
} 