//
//  TransactionsView.swift
//  Muni
//
//  Created by Yaduraj Singh on 20/03/25.
//

import SwiftUI

// Define TransactionFilterType enum at the top
enum TransactionFilterType {
    case all
    case income
    case expense
}

struct TransactionsView: View {
    @EnvironmentObject private var transactionManager: TransactionManager
    @EnvironmentObject private var userManager: UserManager
    @State private var searchText = ""
    @State private var filterType: TransactionFilterType = .all
    
    private var filteredTransactions: [Transaction] {
        transactionManager.transactions
            .filter { transaction in
                switch filterType {
                case .all:
                    return true
                case .income:
                    return transaction.type == .income
                case .expense:
                    return transaction.type == .expense
                }
            }
            .filter { transaction in
                if searchText.isEmpty {
                    return true
                } else {
                    return transaction.note.lowercased().contains(searchText.lowercased()) ||
                        transaction.category.rawValue.lowercased().contains(searchText.lowercased())
                }
            }
            .sorted { $0.date > $1.date }
    }
    
    private var groupedTransactions: [String: [Transaction]] {
        Dictionary(grouping: filteredTransactions) { transaction in
            let formatter = DateFormatter()
            formatter.dateFormat = "MMMM yyyy"
            return formatter.string(from: transaction.date)
        }
    }
    
    private var sortedGroupKeys: [String] {
        groupedTransactions.keys.sorted { key1, key2 in
            let formatter = DateFormatter()
            formatter.dateFormat = "MMMM yyyy"
            if let date1 = formatter.date(from: key1), let date2 = formatter.date(from: key2) {
                return date1 > date2
            }
            return key1 > key2
        }
    }
    
    var body: some View {
        NavigationView {
            VStack(spacing: 0) {
                // Search bar
                TransactionSearchBar(searchText: $searchText)
                    .padding(.horizontal)
                    .padding(.top)
                
                // Filter segment
                TypeFilterView(filterType: $filterType)
                    .padding()
                
                if filteredTransactions.isEmpty {
                    emptyStateView
                        .frame(maxHeight: .infinity)
                } else {
                    // Transaction list
                    List {
                        ForEach(sortedGroupKeys, id: \.self) { key in
                            Section(header: Text(key)
                                        .font(.system(size: Theme.subtitleSize, weight: .semibold))
                                        .foregroundColor(Theme.text)
                                        .padding(.vertical, 8)) {
                                ForEach(groupedTransactions[key] ?? []) { transaction in
                                    NavigationLink(destination: TransactionDetailView(transaction: transaction)) {
                                        TransactionView(transaction: transaction, onDelete: {
                                            transactionManager.deleteTransaction(withID: transaction.id)
                                        })
                                    }
                                    .buttonStyle(PlainButtonStyle()) // To prevent NavigationLink styling
                                }
                                .onDelete { indexSet in
                                    deleteTransactions(at: indexSet, inGroup: key)
                                }
                            }
                        }
                    }
                    .listStyle(InsetGroupedListStyle())
                }
            }
            .background(Theme.background.ignoresSafeArea())
            .navigationTitle("Transactions")
            .navigationBarItems(trailing:
                NavigationLink(destination: AddTransactionView()) {
                    Image(systemName: "plus")
                        .foregroundColor(Theme.primary)
                }
            )
        }
    }
    
    private var emptyStateView: some View {
        VStack(spacing: Theme.paddingLarge) {
            Image(systemName: "doc.text.magnifyingglass")
                .resizable()
                .scaledToFit()
                .frame(width: 80, height: 80)
                .foregroundColor(Theme.primary.opacity(0.6))
            
            Text("No transactions found")
                .font(.system(size: Theme.titleSize, weight: .semibold))
                .foregroundColor(Theme.text)
            
            if !searchText.isEmpty || filterType != .all {
                Text("Try changing your search or filter")
                    .font(.system(size: Theme.bodySize))
                    .foregroundColor(Theme.text.opacity(0.7))
                    .multilineTextAlignment(.center)
                    .padding(.horizontal)
            } else {
                Text("Start adding transactions to track your finances")
                    .font(.system(size: Theme.bodySize))
                    .foregroundColor(Theme.text.opacity(0.7))
                    .multilineTextAlignment(.center)
                    .padding(.horizontal)
                
                NavigationLink(destination: AddTransactionView()) {
                    Text("Add Your First Transaction")
                        .primaryButtonStyle()
                        .padding(.horizontal, Theme.paddingLarge)
                }
            }
        }
    }
    
    private func deleteTransactions(at offsets: IndexSet, inGroup key: String) {
        guard let transactions = groupedTransactions[key] else { return }
        let transactionsToDelete = offsets.map { transactions[$0] }
        
        for transaction in transactionsToDelete {
            transactionManager.deleteTransaction(withID: transaction.id)
        }
    }
}

// TypeFilterView for transaction filtering
struct TypeFilterView: View {
    @Binding var filterType: TransactionFilterType
    
    var body: some View {
        Picker("Filter", selection: $filterType) {
            Text("All").tag(TransactionFilterType.all)
            Text("Income").tag(TransactionFilterType.income)
            Text("Expense").tag(TransactionFilterType.expense)
        }
        .pickerStyle(SegmentedPickerStyle())
        .onChange(of: filterType) { _ in
            // Haptic feedback on filter change
            UIImpactFeedbackGenerator(style: .light).impactOccurred()
        }
    }
}

// TransactionDetailView for viewing transaction details
struct TransactionDetailView: View {
    @Environment(\.presentationMode) private var presentationMode
    @EnvironmentObject private var transactionManager: TransactionManager
    @EnvironmentObject private var userManager: UserManager
    
    let transaction: Transaction
    
    var body: some View {
        ScrollView {
            VStack(spacing: 20) {
                // Header card
                VStack(spacing: 4) {
                    // Category icon
                    ZStack {
                        Circle()
                            .fill(transaction.type == .income ? Color.green.opacity(0.2) : Color.red.opacity(0.2))
                            .frame(width: 70, height: 70)
                        
                        Image(systemName: transaction.category.icon)
                            .font(.system(size: 30))
                            .foregroundColor(transaction.type == .income ? .green : .red)
                    }
                    .padding(.bottom, 8)
                    
                    // Amount
                    Text("\(userManager.currency)\(String(format: "%.2f", transaction.amount))")
                        .font(.system(size: 34, weight: .bold))
                        .foregroundColor(transaction.type == .income ? .green : .red)
                    
                    // Type and category
                    Text("\(transaction.type.rawValue) • \(transaction.category.rawValue)")
                        .font(.headline)
                        .foregroundColor(Theme.text.opacity(0.8))
                        .padding(.bottom, 8)
                    
                    // Date
                    Text(formattedDate(transaction.date))
                        .font(.subheadline)
                        .foregroundColor(Theme.text.opacity(0.6))
                }
                .frame(maxWidth: .infinity)
                .padding()
                .background(Theme.secondary.opacity(0.2))
                .cornerRadius(16)
                
                // Note section
                VStack(alignment: .leading, spacing: 10) {
                    Text("Note")
                        .font(.headline)
                        .foregroundColor(Theme.text)
                    
                    Text(transaction.note)
                        .font(.body)
                        .foregroundColor(Theme.text)
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .padding()
                        .background(Theme.secondary.opacity(0.2))
                        .cornerRadius(12)
                }
                .frame(maxWidth: .infinity, alignment: .leading)
                
                // Action buttons
                HStack(spacing: 20) {
                    Button(action: {
                        // Edit action would go here
                        // For now, just provide haptic feedback
                        UIImpactFeedbackGenerator(style: .medium).impactOccurred()
                    }) {
                        Label("Edit", systemImage: "pencil")
                            .font(.headline)
                            .frame(maxWidth: .infinity)
                            .padding()
                            .background(Theme.secondary.opacity(0.2))
                            .foregroundColor(Theme.primary)
                            .cornerRadius(12)
                    }
                    
                    Button(action: {
                        // Delete action
                        UIImpactFeedbackGenerator(style: .medium).impactOccurred()
                        transactionManager.deleteTransaction(withID: transaction.id)
                        presentationMode.wrappedValue.dismiss()
                    }) {
                        Label("Delete", systemImage: "trash")
                            .font(.headline)
                            .frame(maxWidth: .infinity)
                            .padding()
                            .background(Color.red.opacity(0.1))
                            .foregroundColor(.red)
                            .cornerRadius(12)
                    }
                }
            }
            .padding()
        }
        .navigationTitle("Transaction Details")
        .background(Theme.background.ignoresSafeArea())
    }
    
    private func formattedDate(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateStyle = .long
        formatter.timeStyle = .short
        return formatter.string(from: date)
    }
}

// TransactionView for showing individual transactions with gestures
struct TransactionView: View {
    let transaction: Transaction
    let onDelete: () -> Void
    
    @State private var offset: CGFloat = 0
    @State private var isSwiped = false
    
    var body: some View {
        ZStack {
            // Delete button background
            HStack {
                Spacer()
                
                Button(action: {
                    // Medium haptic feedback
                    UIImpactFeedbackGenerator(style: .medium).impactOccurred()
                    onDelete()
                }) {
                    Image(systemName: "trash.fill")
                        .font(.title2)
                        .foregroundColor(.white)
                        .frame(width: 90)
                }
                .background(Color.red)
            }
            
            // Transaction card
            HStack(spacing: 16) {
                // Category icon
                ZStack {
                    Circle()
                        .fill(transaction.type == .income ? Color.green.opacity(0.2) : Color.red.opacity(0.2))
                        .frame(width: 40, height: 40)
                    
                    Image(systemName: transaction.category.icon)
                        .font(.system(size: 16))
                        .foregroundColor(transaction.type == .income ? .green : .red)
                }
                
                VStack(alignment: .leading, spacing: 4) {
                    Text(transaction.note)
                        .font(.system(size: 17, weight: .medium))
                        .foregroundColor(Theme.text)
                    
                    Text(transaction.category.rawValue)
                        .font(.system(size: 14))
                        .foregroundColor(Theme.text.opacity(0.7))
                }
                
                Spacer()
                
                VStack(alignment: .trailing, spacing: 4) {
                    Text(transaction.type == .income ? "+\(String(format: "%.2f", transaction.amount))" : "-\(String(format: "%.2f", transaction.amount))")
                        .font(.system(size: 17, weight: .semibold))
                        .foregroundColor(transaction.type == .income ? .green : .red)
                    
                    Text(formattedDate(transaction.date))
                        .font(.system(size: 14))
                        .foregroundColor(Theme.text.opacity(0.7))
                }
            }
            .padding()
            .background(Theme.secondary.opacity(0.2))
            .cornerRadius(12)
            .offset(x: offset)
            .gesture(
                DragGesture()
                    .onChanged { gesture in
                        if gesture.translation.width < 0 {
                            // Only allow left swipe (negative direction)
                            self.offset = gesture.translation.width
                            
                            // Light haptic on first significant swipe
                            if !isSwiped && gesture.translation.width < -20 {
                                UIImpactFeedbackGenerator(style: .light).impactOccurred()
                                isSwiped = true
                            }
                        }
                    }
                    .onEnded { gesture in
                        if gesture.translation.width < -50 {
                            // Swipe far enough to reveal delete button
                            withAnimation(.spring()) {
                                self.offset = -90
                            }
                            
                            // Medium haptic when fully revealing delete button
                            UIImpactFeedbackGenerator(style: .medium).impactOccurred()
                        } else {
                            // Reset position with spring animation
                            withAnimation(.spring()) {
                                self.offset = 0
                                self.isSwiped = false
                            }
                        }
                    }
            )
        }
    }
    
    private func formattedDate(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        formatter.timeStyle = .none
        return formatter.string(from: date)
    }
}

