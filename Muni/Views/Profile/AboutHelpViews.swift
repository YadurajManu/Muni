import SwiftUI
import UIKit

struct AboutView: View {
    @Environment(\.openURL) var openURL
    
    var body: some View {
        ScrollView {
            VStack(spacing: 30) {
                // App Logo
                Image(systemName: "indianrupeesign.circle.fill")
                    .resizable()
                    .aspectRatio(contentMode: .fit)
                    .frame(width: 100, height: 100)
                    .foregroundColor(.blue)
                    .padding(.top, 40)
                
                // App Info
                VStack(spacing: 8) {
                    Text("Muni")
                        .font(.system(size: 28, weight: .bold))
                    Text("Version 1.0.0")
                        .font(.subheadline)
                        .foregroundColor(.gray)
                }
                
                // Description
                Text("Your personal finance companion for smart money management")
                    .font(.body)
                    .multilineTextAlignment(.center)
                    .foregroundColor(.primary)
                    .padding(.horizontal)
                
                // Features
                VStack(alignment: .leading, spacing: 20) {
                    Text("Key Features")
                        .font(.headline)
                        .padding(.horizontal)
                    
                    VStack(spacing: 15) {
                        makeFeatureRow(icon: "chart.pie.fill", title: "Expense Tracking", description: "Track all your expenses and income")
                        makeFeatureRow(icon: "chart.bar.fill", title: "Budget Management", description: "Set and monitor your budgets")
                        makeFeatureRow(icon: "brain.head.profile", title: "AI Assistant", description: "Get smart financial insights")
                        makeFeatureRow(icon: "arrow.up.arrow.down", title: "Transaction History", description: "View and analyze your transactions")
                    }
                    .padding(.horizontal)
                }
                .padding(.vertical)
                
                // Links
                VStack(spacing: 15) {
                    makeLinkButton(title: "Rate on App Store", icon: "star.fill") {
                        if let url = URL(string: "itms-apps://itunes.apple.com/app/idYOUR_APP_ID") {
                            openURL(url)
                        }
                    }
                    
                    makeLinkButton(title: "Visit Website", icon: "globe") {
                        if let url = URL(string: "https://www.muniapp.com") {
                            openURL(url)
                        }
                    }
                    
                    makeLinkButton(title: "Follow on Twitter", icon: "bubble.left.fill") {
                        if let url = URL(string: "https://twitter.com/muniapp") {
                            openURL(url)
                        }
                    }
                }
                .padding()
                
                // Legal
                VStack(spacing: 10) {
                    Button("Privacy Policy") {
                        if let url = URL(string: "https://www.muniapp.com/privacy") {
                            openURL(url)
                        }
                    }
                    
                    Button("Terms of Service") {
                        if let url = URL(string: "https://www.muniapp.com/terms") {
                            openURL(url)
                        }
                    }
                }
                .font(.footnote)
                .foregroundColor(.blue)
                
                Text("© 2025 Muni. All rights reserved.")
                    .font(.caption)
                    .foregroundColor(.gray)
                    .padding(.top)
                    .padding(.bottom, 30)
            }
        }
        .background(Color(.systemBackground))
        .navigationTitle("About")
        .navigationBarTitleDisplayMode(.inline)
    }
    
    private func makeFeatureRow(icon: String, title: String, description: String) -> some View {
        HStack(spacing: 15) {
            Image(systemName: icon)
                .font(.title2)
                .foregroundColor(.blue)
                .frame(width: 40)
            
            VStack(alignment: .leading, spacing: 4) {
                Text(title)
                    .font(.system(size: 16, weight: .semibold))
                Text(description)
                    .font(.system(size: 14))
                    .foregroundColor(.gray)
            }
            
            Spacer()
        }
    }
    
    private func makeLinkButton(title: String, icon: String, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            HStack {
                Image(systemName: icon)
                Text(title)
            }
            .font(.system(size: 16, weight: .medium))
            .foregroundColor(.white)
            .frame(maxWidth: .infinity)
            .padding()
            .background(Color.blue)
            .cornerRadius(10)
        }
    }
}

struct HelpCenterView: View {
    @State private var searchText = ""
    @State private var selectedCategory: HelpCategory?
    @State private var expandedQuestions: Set<String> = []
    
    private let helpCategories = HelpCategory.allCategories
    
    var body: some View {
        ScrollView {
            VStack(spacing: 20) {
                // Search bar
                makeSearchBar(text: $searchText)
                    .padding(.horizontal)
                
                // Categories
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 12) {
                        ForEach(helpCategories) { category in
                            makeCategoryButton(
                                category: category,
                                isSelected: category == selectedCategory,
                                action: { selectedCategory = category }
                            )
                        }
                    }
                    .padding(.horizontal)
                }
                
                // FAQ section
                VStack(alignment: .leading, spacing: 20) {
                    Text("Frequently Asked Questions")
                        .font(.headline)
                        .padding(.horizontal)
                    
                    VStack(spacing: 0) {
                        ForEach(filteredQuestions) { question in
                            makeFAQRow(
                                question: question,
                                isExpanded: expandedQuestions.contains(question.id),
                                toggleAction: { toggleQuestion(question.id) }
                            )
                        }
                    }
                    .background(Color(UIColor.secondarySystemBackground))
                    .cornerRadius(12)
                    .padding(.horizontal)
                }
                
                // Contact support
                VStack(spacing: 15) {
                    Text("Need more help?")
                        .font(.headline)
                    
                    Button(action: {
                        if let url = URL(string: "mailto:support@muniapp.com") {
                            UIApplication.shared.open(url)
                        }
                    }) {
                        Text("Contact Support")
                            .font(.body)
                            .foregroundColor(.white)
                            .frame(maxWidth: .infinity)
                            .padding()
                            .background(Color.blue)
                            .cornerRadius(10)
                    }
                }
                .padding()
            }
            .padding(.vertical)
        }
        .background(Color(.systemBackground))
        .navigationTitle("Help Center")
    }
    
    private var filteredQuestions: [FAQQuestion] {
        let questions = selectedCategory?.questions ?? FAQQuestion.allQuestions
        if searchText.isEmpty {
            return questions
        }
        return questions.filter { $0.question.lowercased().contains(searchText.lowercased()) }
    }
    
    private func toggleQuestion(_ id: String) {
        if expandedQuestions.contains(id) {
            expandedQuestions.remove(id)
        } else {
            expandedQuestions.insert(id)
        }
    }
    
    private func makeSearchBar(text: Binding<String>) -> some View {
        HStack {
            Image(systemName: "magnifyingglass")
                .foregroundColor(.gray)
            
            TextField("Search help articles", text: text)
                .textFieldStyle(PlainTextFieldStyle())
            
            if !text.wrappedValue.isEmpty {
                Button(action: { text.wrappedValue = "" }) {
                    Image(systemName: "xmark.circle.fill")
                        .foregroundColor(.gray)
                }
            }
        }
        .padding()
        .background(Color(UIColor.secondarySystemBackground))
        .cornerRadius(10)
    }
    
    private func makeCategoryButton(category: HelpCategory, isSelected: Bool, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            HStack {
                Image(systemName: category.icon)
                Text(category.name)
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 8)
            .background(isSelected ? Color.blue : Color(UIColor.secondarySystemBackground))
            .foregroundColor(isSelected ? .white : .primary)
            .cornerRadius(20)
        }
    }
    
    private func makeFAQRow(question: FAQQuestion, isExpanded: Bool, toggleAction: @escaping () -> Void) -> some View {
        VStack(alignment: .leading, spacing: 0) {
            Button(action: toggleAction) {
                HStack {
                    Text(question.question)
                        .font(.system(size: 16, weight: .medium))
                        .foregroundColor(.primary)
                        .multilineTextAlignment(.leading)
                    
                    Spacer()
                    
                    Image(systemName: "chevron.right")
                        .foregroundColor(.gray)
                        .rotationEffect(.degrees(isExpanded ? 90 : 0))
                }
                .padding()
            }
            
            if isExpanded {
                Text(question.answer)
                    .font(.system(size: 14))
                    .foregroundColor(.gray)
                    .padding(.horizontal)
                    .padding(.bottom)
            }
            
            Divider()
        }
    }
}

// Models
struct HelpCategory: Identifiable, Equatable {
    let id = UUID()
    let name: String
    let icon: String
    let questions: [FAQQuestion]
    
    static func == (lhs: HelpCategory, rhs: HelpCategory) -> Bool {
        lhs.id == rhs.id
    }
    
    static let allCategories = [
        HelpCategory(name: "Getting Started", icon: "star.fill", questions: [
            FAQQuestion(question: "How do I add my first transaction?", answer: "Tap the '+' button at the bottom of the screen and select 'Add Transaction'. Fill in the details and tap 'Save'."),
            FAQQuestion(question: "How do I set up my budget?", answer: "Go to the Budget tab and tap 'Set Budget'. You can set overall and category-specific budgets.")
        ]),
        HelpCategory(name: "Transactions", icon: "arrow.left.arrow.right", questions: [
            FAQQuestion(question: "How do I edit a transaction?", answer: "Find the transaction you want to edit, swipe left, and tap 'Edit'."),
            FAQQuestion(question: "Can I set up recurring transactions?", answer: "Yes! When adding a transaction, toggle 'Make Recurring' and set the frequency.")
        ]),
        HelpCategory(name: "Reports", icon: "chart.bar.fill", questions: [
            FAQQuestion(question: "How do I view my spending reports?", answer: "Go to the Insights tab to view detailed reports and analytics of your spending patterns."),
            FAQQuestion(question: "Can I export my data?", answer: "Yes, go to Profile > Export Data and choose your preferred format (PDF, CSV, or Excel).")
        ])
    ]
}

struct FAQQuestion: Identifiable {
    let id: String
    let question: String
    let answer: String
    
    init(question: String, answer: String) {
        self.id = UUID().uuidString.prefix(8).description
        self.question = question
        self.answer = answer
    }
    
    static var allQuestions: [FAQQuestion] {
        HelpCategory.allCategories.flatMap { $0.questions }
    }
}
