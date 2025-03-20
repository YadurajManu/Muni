//
//  AIManager.swift
//  Muni
//
//  Created by Yaduraj Singh on 20/03/25.
//

import Foundation
import SwiftUI

class AIManager: ObservableObject {
    @Published var messages: [ChatMessage] = []
    @Published var isLoading = false
    
    private let apiKey = "AIzaSyD3Xbweiz-suIDVW_qvbCI4jYDwCzOqy1g"
    private let apiBaseURL = "https://generativelanguage.googleapis.com/v1beta/models/gemini-1.5-pro:generateContent"
    
    init() {
        // Add initial greeting message
        messages.append(ChatMessage(
            content: "Hello! I'm your financial assistant. I can help analyze your spending, provide budgeting advice, or answer financial questions.",
            isUser: false
        ))
    }
    
    func sendMessage(_ content: String, transactionManager: TransactionManager, userManager: UserManager) {
        // Add user message
        let userMessage = ChatMessage(content: content, isUser: true)
        messages.append(userMessage)
        
        // Show loading
        isLoading = true
        
        // Prepare context information about the user's finances
        let financialContext = generateFinancialContext(transactionManager: transactionManager, userManager: userManager)
        
        // Send API request
        requestAIResponse(userMessage: content, financialContext: financialContext)
    }
    
    private func generateFinancialContext(transactionManager: TransactionManager, userManager: UserManager) -> String {
        let balance = transactionManager.balance()
        let totalIncome = transactionManager.totalIncome()
        let totalExpense = transactionManager.totalExpense()
        
        // Get current month and year
        let now = Date()
        let calendar = Calendar.current
        let month = calendar.component(.month, from: now)
        let year = calendar.component(.year, from: now)
        
        // Get monthly expenses by category
        let monthlyExpenses = transactionManager.getMonthlyExpensesByCategory(month: month, year: year)
        let categoryInfo = monthlyExpenses.map { category, amount in
            return "- \(category.rawValue): \(userManager.currency)\(amount)"
        }.joined(separator: "\n")
        
        return """
        Financial information:
        - Current balance: \(userManager.currency)\(balance)
        - Total income: \(userManager.currency)\(totalIncome)
        - Total expenses: \(userManager.currency)\(totalExpense)
        - Monthly budget: \(userManager.currency)\(userManager.monthlyBudget)
        
        Current month expenses by category:
        \(categoryInfo)
        
        Please provide helpful financial advice based on this information. 
        Always respond with Indian Rupee (₹) as currency.
        """
    }
    
    private func requestAIResponse(userMessage: String, financialContext: String) {
        // Create URL
        guard let url = URL(string: "\(apiBaseURL)?key=\(apiKey)") else {
            handleError("Invalid URL")
            return
        }
        
        // Create request
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        
        // Create JSON payload
        let prompt = """
        You are a helpful finance assistant for the Muni money management app. 
        Your task is to provide helpful insights, advice, and answers related to personal finance.
        
        User's financial context information:
        \(financialContext)
        
        User's message: \(userMessage)
        """
        
        let payload: [String: Any] = [
            "contents": [
                [
                    "parts": [
                        ["text": prompt]
                    ]
                ]
            ]
        ]
        
        // Convert to JSON data
        guard let jsonData = try? JSONSerialization.data(withJSONObject: payload) else {
            handleError("Failed to serialize JSON")
            return
        }
        
        request.httpBody = jsonData
        
        // Create and start task
        let task = URLSession.shared.dataTask(with: request) { [weak self] data, response, error in
            DispatchQueue.main.async {
                if let error = error {
                    self?.handleError("Network error: \(error.localizedDescription)")
                    return
                }
                
                guard let data = data else {
                    self?.handleError("No data received")
                    return
                }
                
                // Try to parse the response
                do {
                    if let json = try JSONSerialization.jsonObject(with: data) as? [String: Any],
                       let candidates = json["candidates"] as? [[String: Any]],
                       let firstCandidate = candidates.first,
                       let content = firstCandidate["content"] as? [String: Any],
                       let parts = content["parts"] as? [[String: Any]],
                       let firstPart = parts.first,
                       let text = firstPart["text"] as? String {
                        
                        // Add AI response
                        self?.messages.append(ChatMessage(content: text, isUser: false))
                    } else {
                        self?.handleError("Failed to parse response")
                    }
                } catch {
                    self?.handleError("JSON parsing error: \(error.localizedDescription)")
                }
                
                self?.isLoading = false
            }
        }
        
        task.resume()
    }
    
    private func handleError(_ message: String) {
        print("AI Error: \(message)")
        messages.append(ChatMessage(
            content: "Sorry, I'm having trouble processing your request. Please try again later.",
            isUser: false
        ))
        isLoading = false
    }
} 
