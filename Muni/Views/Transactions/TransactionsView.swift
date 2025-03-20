//
//  TransactionsView.swift
//  Muni
//
//  Created by Yaduraj Singh on 20/03/25.
//

import SwiftUI

struct TransactionsView: View {
    @EnvironmentObject private var transactionManager: TransactionManager
    @EnvironmentObject private var userManager: UserManager
    @State private var searchText = ""
    @State private var filterType: TransactionType? = nil
    
    private var filteredTransactions: [Transaction] {
        transactionManager.transactions
            .filter { transaction in
                if let filterType = filterType {
                    return transaction.type == filterType
                }
                return true
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
                SearchBar(searchText: $searchText)
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
                                        TransactionRow(transaction: transaction)
                                            .padding(.vertical, 4)
                                    }
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
            
            if !searchText.isEmpty || filterType != nil {
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

struct SearchBar: View {
    @Binding var searchText: String
    
    var body: some View {
        HStack {
            Image(systemName: "magnifyingglass")
                .foregroundColor(searchText.isEmpty ? Theme.text.opacity(0.5) : Theme.primary)
            
            TextField("Search transactions", text: $searchText)
                .foregroundColor(Theme.text)
            
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

struct TypeFilterView: View {
    @Binding var filterType: TransactionType?
    
    var body: some View {
        HStack {
            filterButton(type: nil, title: "All")
            filterButton(type: .income, title: "Income")
            filterButton(type: .expense, title: "Expense")
        }
    }
    
    private func filterButton(type: TransactionType?, title: String) -> some View {
        Button(action: {
            withAnimation {
                filterType = type
            }
        }) {
            Text(title)
                .padding(.vertical, 8)
                .padding(.horizontal, 16)
                .background(filterType == type ? Theme.primary : Theme.secondary.opacity(0.3))
                .foregroundColor(filterType == type ? .white : Theme.text)
                .cornerRadius(Theme.cornerRadiusMedium)
        }
    }
}

struct TransactionDetailView: View {
    @EnvironmentObject private var userManager: UserManager
    let transaction: Transaction
    
    private var dateFormatter: DateFormatter {
        let formatter = DateFormatter()
        formatter.dateStyle = .full
        return formatter
    }
    
    var body: some View {
        ScrollView {
            VStack(spacing: Theme.paddingLarge) {
                // Header with category icon
                VStack {
                    Image(systemName: transaction.category.icon)
                        .resizable()
                        .scaledToFit()
                        .frame(width: 60, height: 60)
                        .foregroundColor(.white)
                        .padding(20)
                        .background(
                            Circle()
                                .fill(transaction.type == .income ? Theme.income : Theme.expense)
                        )
                    
                    Text(transaction.category.rawValue)
                        .font(.system(size: Theme.subtitleSize, weight: .semibold))
                        .foregroundColor(Theme.text)
                }
                .padding(.top, Theme.paddingLarge)
                
                // Amount
                Text("\(transaction.type == .income ? "+" : "-")\(userManager.currency)\(transaction.amount, specifier: "%.2f")")
                    .font(.system(size: 32, weight: .bold))
                    .foregroundColor(transaction.type == .income ? Theme.income : Theme.expense)
                
                // Details
                VStack(spacing: Theme.paddingMedium) {
                    detailRow(title: "Type", value: transaction.type.rawValue)
                    divider
                    detailRow(title: "Date", value: dateFormatter.string(from: transaction.date))
                    divider
                    detailRow(title: "Note", value: transaction.note)
                }
                .padding()
                .background(Theme.secondary.opacity(0.3))
                .cornerRadius(Theme.cornerRadiusMedium)
                .padding(.horizontal)
                
                Spacer()
            }
        }
        .background(Theme.background.ignoresSafeArea())
        .navigationTitle("Transaction Details")
        .navigationBarTitleDisplayMode(.inline)
    }
    
    private var divider: some View {
        Divider().background(Theme.text.opacity(0.1))
    }
    
    private func detailRow(title: String, value: String) -> some View {
        HStack(alignment: .top) {
            Text(title)
                .font(.system(size: Theme.bodySize))
                .foregroundColor(Theme.text.opacity(0.7))
                .frame(width: 80, alignment: .leading)
            
            Spacer()
            
            Text(value)
                .font(.system(size: Theme.bodySize))
                .foregroundColor(Theme.text)
                .multilineTextAlignment(.trailing)
        }
    }
} 