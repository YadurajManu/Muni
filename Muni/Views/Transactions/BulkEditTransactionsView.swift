import SwiftUI

struct BulkEditTransactionsView: View {
    @Environment(\.presentationMode) private var presentationMode
    @EnvironmentObject private var transactionManager: TransactionManager
    @EnvironmentObject private var userManager: UserManager
    
    @State private var selectedTransactions: Set<UUID> = []
    @State private var showingCategoryPicker = false
    @State private var selectedTransactionType: TransactionType = .expense
    @State private var searchText = ""
    @State private var showingConfirmation = false
    @State private var selectedCategory: TransactionCategory?
    
    var filteredTransactions: [Transaction] {
        transactionManager.transactions.filter { transaction in
            if !searchText.isEmpty {
                return transaction.note.lowercased().contains(searchText.lowercased()) ||
                      transaction.category.rawValue.lowercased().contains(searchText.lowercased()) ||
                      String(format: "%.2f", transaction.amount).contains(searchText)
            }
            return true
        }.sorted { $0.date > $1.date }
    }
    
    var body: some View {
        NavigationView {
            VStack(spacing: 0) {
                // Search bar
                TransactionSearchBar(searchText: $searchText)
                    .padding(.horizontal)
                    .padding(.top, 8)
                
                // Selection filter
                if !selectedTransactions.isEmpty {
                    HStack {
                        Text("\(selectedTransactions.count) selected")
                            .font(.headline)
                            .foregroundColor(Theme.primary)
                        
                        Spacer()
                        
                        Button("Clear") {
                            // Light haptic feedback
                            UIImpactFeedbackGenerator(style: .light).impactOccurred()
                            selectedTransactions.removeAll()
                        }
                        .foregroundColor(Theme.primary)
                    }
                    .padding(.horizontal)
                    .padding(.vertical, 8)
                    .background(Theme.secondary.opacity(0.2))
                }
                
                // Transaction list
                List {
                    ForEach(filteredTransactions) { transaction in
                        BulkEditTransactionRow(
                            transaction: transaction,
                            isSelected: selectedTransactions.contains(transaction.id),
                            onSelect: {
                                // Toggle selection with haptic feedback
                                UIImpactFeedbackGenerator(style: .light).impactOccurred()
                                
                                if selectedTransactions.contains(transaction.id) {
                                    selectedTransactions.remove(transaction.id)
                                } else {
                                    selectedTransactions.insert(transaction.id)
                                    
                                    // If selecting the first transaction, set the transaction type filter
                                    if selectedTransactions.count == 1 {
                                        selectedTransactionType = transaction.type
                                    }
                                }
                            }
                        )
                        .listRowBackground(selectedTransactions.contains(transaction.id) ? 
                            Theme.primary.opacity(0.1) : Color.clear)
                    }
                }
                .listStyle(PlainListStyle())
                
                // Bottom action bar
                if !selectedTransactions.isEmpty {
                    VStack(spacing: 0) {
                        Divider()
                        
                        HStack(spacing: 15) {
                            // Category button
                            Button(action: {
                                // Medium haptic
                                UIImpactFeedbackGenerator(style: .medium).impactOccurred()
                                showingCategoryPicker = true
                            }) {
                                VStack(spacing: 4) {
                                    Image(systemName: "tag.fill")
                                        .font(.system(size: 20))
                                    Text("Category")
                                        .font(.system(size: 12))
                                }
                                .frame(maxWidth: .infinity)
                                .padding(.vertical, 10)
                            }
                            
                            // Delete button
                            Button(action: {
                                // Medium haptic
                                UIImpactFeedbackGenerator(style: .medium).impactOccurred()
                                showingConfirmation = true
                            }) {
                                VStack(spacing: 4) {
                                    Image(systemName: "trash.fill")
                                        .font(.system(size: 20))
                                        .foregroundColor(.red)
                                    Text("Delete")
                                        .font(.system(size: 12))
                                        .foregroundColor(.red)
                                }
                                .frame(maxWidth: .infinity)
                                .padding(.vertical, 10)
                            }
                        }
                        .padding(.horizontal)
                        .padding(.vertical, 8)
                        .background(Color(UIColor.systemBackground))
                        .shadow(color: Color.black.opacity(0.05), radius: 5, y: -5)
                    }
                }
            }
            .navigationTitle("Bulk Edit")
            .navigationBarItems(
                leading: Button("Cancel") {
                    presentationMode.wrappedValue.dismiss()
                },
                trailing: Button("Done") {
                    presentationMode.wrappedValue.dismiss()
                }
                .disabled(selectedTransactions.isEmpty)
                .opacity(selectedTransactions.isEmpty ? 0.5 : 1)
            )
            .actionSheet(isPresented: $showingCategoryPicker) {
                ActionSheet(
                    title: Text("Select Category"),
                    message: Text("Change category for \(selectedTransactions.count) transaction(s)"),
                    buttons: categoryButtons()
                )
            }
            .alert(isPresented: $showingConfirmation) {
                Alert(
                    title: Text("Delete Transactions?"),
                    message: Text("Are you sure you want to delete \(selectedTransactions.count) transaction(s)? This cannot be undone."),
                    primaryButton: .destructive(Text("Delete")) {
                        deleteSelectedTransactions()
                    },
                    secondaryButton: .cancel()
                )
            }
        }
    }
    
    private func categoryButtons() -> [ActionSheet.Button] {
        let categoryType = selectedTransactionType
        var buttons: [ActionSheet.Button] = []
        
        // Add all categories of the selected type
        for category in TransactionCategory.allCases.filter({ $0.transactionType == categoryType }) {
            buttons.append(.default(Text(category.rawValue)) {
                selectedCategory = category
                updateCategoryForSelectedTransactions()
            })
        }
        
        // Add cancel button
        buttons.append(.cancel())
        
        return buttons
    }
    
    private func updateCategoryForSelectedTransactions() {
        guard let newCategory = selectedCategory else { return }
        
        // Iterate through all transactions
        for uuid in selectedTransactions {
            // Find the transaction in the manager
            if let index = transactionManager.transactions.firstIndex(where: { $0.id == uuid }) {
                // Create an updated transaction with the new category
                var updatedTransaction = transactionManager.transactions[index]
                updatedTransaction.category = newCategory
                
                // Update the transaction in the manager
                transactionManager.updateTransaction(updatedTransaction)
            }
        }
        
        // Provide success feedback
        UINotificationFeedbackGenerator().notificationOccurred(.success)
        
        // Clear selection
        selectedTransactions.removeAll()
    }
    
    private func deleteSelectedTransactions() {
        // Delete all selected transactions
        for uuid in selectedTransactions {
            transactionManager.removeTransaction(withID: uuid)
        }
        
        // Provide feedback
        UINotificationFeedbackGenerator().notificationOccurred(.success)
        
        // Clear selection
        selectedTransactions.removeAll()
    }
}

// TransactionSearchBar for bulk edit view
struct TransactionSearchBar: View {
    @Binding var searchText: String
    
    var body: some View {
        HStack {
            Image(systemName: "magnifyingglass")
                .foregroundColor(searchText.isEmpty ? Theme.text.opacity(0.5) : Theme.primary)
            
            TextField("Search transactions", text: $searchText)
                .foregroundColor(Theme.text)
                .disableAutocorrection(true)
            
            if !searchText.isEmpty {
                Button(action: {
                    searchText = ""
                }) {
                    Image(systemName: "xmark.circle.fill")
                        .foregroundColor(Theme.text.opacity(0.5))
                }
            }
        }
        .padding()
        .background(Theme.secondary.opacity(0.3))
        .cornerRadius(10)
    }
}

// TransactionRow for bulk edit view
struct BulkEditTransactionRow: View {
    let transaction: Transaction
    let isSelected: Bool
    let onSelect: () -> Void
    
    var body: some View {
        Button(action: onSelect) {
            HStack {
                // Selection indicator
                Image(systemName: isSelected ? "checkmark.circle.fill" : "circle")
                    .foregroundColor(isSelected ? Theme.primary : Color.gray)
                    .font(.system(size: 22))
                    .frame(width: 24, height: 24)
                
                // Category icon
                ZStack {
                    Circle()
                        .fill(transaction.category.icon.contains("indianrupeesign") ? Color.green.opacity(0.2) : Color.red.opacity(0.2))
                        .frame(width: 36, height: 36)
                    
                    Image(systemName: transaction.category.icon)
                        .font(.system(size: 16))
                        .foregroundColor(transaction.category.icon.contains("indianrupeesign") ? .green : .red)
                }
                
                // Transaction details
                VStack(alignment: .leading, spacing: 4) {
                    Text(transaction.note)
                        .font(.system(size: 16))
                        .foregroundColor(Theme.text)
                        .lineLimit(1)
                    
                    Text(transaction.category.rawValue)
                        .font(.system(size: 13))
                        .foregroundColor(Theme.text.opacity(0.6))
                }
                .padding(.leading, 4)
                
                Spacer()
                
                // Amount and date
                VStack(alignment: .trailing, spacing: 4) {
                    Text("\(transaction.type == .income ? "+" : "-")\(formatAmount(transaction.amount))")
                        .font(.system(size: 16, weight: .semibold))
                        .foregroundColor(transaction.type == .income ? .green : .red)
                    
                    Text(formatDate(transaction.date))
                        .font(.system(size: 13))
                        .foregroundColor(Theme.text.opacity(0.6))
                }
            }
            .padding(.vertical, 6)
        }
        .buttonStyle(PlainButtonStyle())
    }
    
    private func formatAmount(_ amount: Double) -> String {
        return String(format: "%.2f", amount)
    }
    
    private func formatDate(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        formatter.timeStyle = .none
        return formatter.string(from: date)
    }
}
