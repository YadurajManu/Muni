//
//  Theme.swift
//  Muni
//
//  Created by Yaduraj Singh on 20/03/25.
//

import SwiftUI

struct Theme {
    // MARK: - Colors
    static let primary = Color("PrimaryColor")
    static let secondary = Color("SecondaryColor")
    static let background = Color("BackgroundColor")
    static let text = Color("TextColor")
    static let accent = Color("AccentColor")
    
    // MARK: - Income/Expense Colors
    static let income = Color("IncomeColor")
    static let expense = Color("ExpenseColor")
    
    // MARK: - Font Sizes
    static let headingSize: CGFloat = 28
    static let titleSize: CGFloat = 22
    static let subtitleSize: CGFloat = 18
    static let bodySize: CGFloat = 16
    static let captionSize: CGFloat = 14
    
    // MARK: - Paddings
    static let paddingSmall: CGFloat = 8
    static let paddingMedium: CGFloat = 16
    static let paddingLarge: CGFloat = 24
    
    // MARK: - Corners
    static let cornerRadiusSmall: CGFloat = 8
    static let cornerRadiusMedium: CGFloat = 12
    static let cornerRadiusLarge: CGFloat = 16
    
    // MARK: - Card Style
    static func cardStyle() -> some ViewModifier {
        return CardModifier()
    }
    
    // MARK: - Button Style
    static func primaryButtonStyle() -> some ViewModifier {
        return PrimaryButtonModifier()
    }
}

// MARK: - View Modifiers
struct CardModifier: ViewModifier {
    func body(content: Content) -> some View {
        content
            .padding(Theme.paddingMedium)
            .background(Theme.background)
            .cornerRadius(Theme.cornerRadiusMedium)
            .shadow(color: Color.black.opacity(0.1), radius: 4, x: 0, y: 2)
    }
}

struct PrimaryButtonModifier: ViewModifier {
    func body(content: Content) -> some View {
        content
            .font(.system(size: Theme.bodySize, weight: .semibold))
            .foregroundColor(.white)
            .padding(.vertical, Theme.paddingMedium)
            .frame(maxWidth: .infinity)
            .background(Theme.primary)
            .cornerRadius(Theme.cornerRadiusMedium)
    }
}

// MARK: - View Extensions
extension View {
    func cardStyle() -> some View {
        self.modifier(Theme.cardStyle())
    }
    
    func primaryButtonStyle() -> some View {
        self.modifier(Theme.primaryButtonStyle())
    }
} 