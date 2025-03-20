//
//  CurrencyFormatter.swift
//  Muni
//
//  Created by Yaduraj Singh on 20/03/25.
//

import Foundation

class CurrencyFormatter {
    static let shared = CurrencyFormatter()
    
    private let numberFormatter: NumberFormatter
    
    private init() {
        numberFormatter = NumberFormatter()
        numberFormatter.numberStyle = .currency
        numberFormatter.locale = Locale(identifier: "en_IN") // Indian locale
        numberFormatter.currencySymbol = "₹"
        numberFormatter.minimumFractionDigits = 0
        numberFormatter.maximumFractionDigits = 2
    }
    
    // Format a number as currency
    func string(from number: Double) -> String {
        return numberFormatter.string(from: NSNumber(value: number)) ?? "₹0"
    }
    
    // Parse a currency string to a number
    func number(from string: String) -> Double? {
        // Remove currency symbol and any non-numeric characters except decimal point
        let cleanString = string.replacingOccurrences(of: "[^0-9.]", with: "", options: .regularExpression)
        return Double(cleanString)
    }
    
    // Format currency input as user types
    func formatForInput(string: String) -> String {
        guard let number = number(from: string) else {
            return ""
        }
        
        // For input fields, we don't want the currency symbol
        let simpleString = String(format: "%.0f", number)
        
        // Add commas for thousands separator
        let formatter = NumberFormatter()
        formatter.numberStyle = .decimal
        formatter.locale = Locale(identifier: "en_IN") // Indian locale for thousands formatting
        
        return formatter.string(from: NSNumber(value: number)) ?? simpleString
    }
    
    // Format a number as a display string (with currency symbol)
    func formatForDisplay(number: Double) -> String {
        return string(from: number)
    }
    
    // Format a number as a display string with specified precision
    func formatForDisplay(number: Double, precision: Int) -> String {
        numberFormatter.minimumFractionDigits = precision
        numberFormatter.maximumFractionDigits = precision
        let result = numberFormatter.string(from: NSNumber(value: number)) ?? "₹0"
        
        // Reset to default precision
        numberFormatter.minimumFractionDigits = 0
        numberFormatter.maximumFractionDigits = 2
        
        return result
    }
} 