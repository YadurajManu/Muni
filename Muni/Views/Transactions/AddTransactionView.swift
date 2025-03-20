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
    @State private var showAlert: Bool = false
    @State private var alertMessage: String = ""
    
    private var categories: [TransactionCategory] {
        transactionType == .income ? TransactionCategory.incomeCategories() : TransactionCategory.expenseCategories()
    }
    
    private var isFormValid: Bool {
        !amount.isEmpty && Double(amount) ?? 0 > 0 && !note.isEmpty
    }
    
    var body: some View {
        NavigationView {
            ScrollView {
                VStack(spacing: Theme.paddingLarge) {
                    // Transaction type selector
                    typeSelector
                    
                    // Amount input
                    amountInput
                    
                    // Category selector
                    categorySelector
                    
                    // Date picker
                    datePicker
                    
                    // Note input
                    noteInput
                    
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
                }
                .padding(.vertical)
            }
            .background(Theme.background.ignoresSafeArea())
            .navigationTitle("Add Transaction")
            .navigationBarTitleDisplayMode(.inline)
            .navigationBarItems(trailing: Button("Cancel") {
                presentationMode.wrappedValue.dismiss()
            })
            .alert(isPresented: $showAlert) {
                Alert(
                    title: Text("Error"),
                    message: Text(alertMessage),
                    dismissButton: .default(Text("OK"))
                )
            }
        }
    }
    
    private var typeSelector: some View {
        VStack(alignment: .leading, spacing: Theme.paddingSmall) {
            Text("Transaction Type")
                .font(.system(size: Theme.bodySize, weight: .medium))
                .foregroundColor(Theme.text)
            
            Picker("Transaction Type", selection: $transactionType) {
                ForEach(TransactionType.allCases, id: \.self) { type in
                    Text(type.rawValue).tag(type)
                }
            }
            .pickerStyle(SegmentedPickerStyle())
            .onChange(of: transactionType) { _ in
                // Reset category when type changes
                selectedCategory = transactionType == .income ? .salary : .food
            }
        }
        .padding(.horizontal)
    }
    
    private var amountInput: some View {
        VStack(alignment: .leading, spacing: Theme.paddingSmall) {
            Text("Amount")
                .font(.system(size: Theme.bodySize, weight: .medium))
                .foregroundColor(Theme.text)
            
            HStack {
                Text(userManager.currency)
                    .font(.system(size: Theme.bodySize, weight: .semibold))
                    .foregroundColor(Theme.text)
                
                TextField("0.00", text: $amount)
                    .keyboardType(.decimalPad)
                    .font(.system(size: Theme.subtitleSize))
                    .foregroundColor(Theme.text)
            }
            .padding()
            .background(Theme.secondary.opacity(0.3))
            .cornerRadius(Theme.cornerRadiusMedium)
        }
        .padding(.horizontal)
    }
    
    private var categorySelector: some View {
        VStack(alignment: .leading, spacing: Theme.paddingSmall) {
            Text("Category")
                .font(.system(size: Theme.bodySize, weight: .medium))
                .foregroundColor(Theme.text)
            
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: Theme.paddingMedium) {
                    ForEach(categories, id: \.self) { category in
                        CategoryButton(
                            category: category,
                            isSelected: selectedCategory == category,
                            action: { selectedCategory = category }
                        )
                    }
                }
                .padding(.vertical, 4)
            }
        }
        .padding(.horizontal)
    }
    
    private var datePicker: some View {
        VStack(alignment: .leading, spacing: Theme.paddingSmall) {
            Text("Date")
                .font(.system(size: Theme.bodySize, weight: .medium))
                .foregroundColor(Theme.text)
            
            DatePicker("", selection: $date, displayedComponents: [.date])
                .datePickerStyle(WheelDatePickerStyle())
                .labelsHidden()
                .background(Theme.secondary.opacity(0.3))
                .cornerRadius(Theme.cornerRadiusMedium)
        }
        .padding(.horizontal)
    }
    
    private var noteInput: some View {
        VStack(alignment: .leading, spacing: Theme.paddingSmall) {
            Text("Note")
                .font(.system(size: Theme.bodySize, weight: .medium))
                .foregroundColor(Theme.text)
            
            TextField("Add a note", text: $note)
                .padding()
                .background(Theme.secondary.opacity(0.3))
                .cornerRadius(Theme.cornerRadiusMedium)
        }
        .padding(.horizontal)
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
        presentationMode.wrappedValue.dismiss()
    }
}

struct CategoryButton: View {
    let category: TransactionCategory
    let isSelected: Bool
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            VStack(spacing: 8) {
                Image(systemName: category.icon)
                    .font(.system(size: 24))
                    .foregroundColor(isSelected ? .white : Theme.primary)
                
                Text(category.rawValue)
                    .font(.system(size: Theme.captionSize))
                    .foregroundColor(isSelected ? .white : Theme.text)
                    .lineLimit(1)
                    .fixedSize(horizontal: false, vertical: true)
            }
            .frame(width: 80, height: 80)
            .background(isSelected ? Theme.primary : Theme.secondary.opacity(0.3))
            .cornerRadius(Theme.cornerRadiusMedium)
        }
    }
} 