//
//  Theme.swift
//  Muni
//
//  Created by Yaduraj Singh on 20/03/25.
//

import SwiftUI

struct Theme {
    // MARK: - Colors
    static let primary = Color.blue
    static let secondary = Color.orange
    static let background = Color(.systemBackground)
    static let text = Color.primary
    static let cardBackground = Color(.secondarySystemBackground)
    static let accent = Color("AccentColor")
    
    // MARK: - Income/Expense Colors
    static let income = Color.green
    static let expense = Color.red
    static let neutral = Color.orange
    static let positive = Color.green
    static let negative = Color.red
    
    // MARK: - Font Sizes
    static let headingSize: CGFloat = 28
    static let titleSize: CGFloat = 24
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
    static let cornerRadiusLarge: CGFloat = 20
    
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

// MARK: - App Appearance Settings
enum AppTheme: String, CaseIterable, Identifiable {
    case light, dark, system
    
    var id: String { self.rawValue }
    
    var name: String {
        switch self {
        case .light: return "Light"
        case .dark: return "Dark"
        case .system: return "System"
        }
    }
    
    var iconName: String {
        switch self {
        case .light: return "sun.max.fill"
        case .dark: return "moon.fill"
        case .system: return "gear"
        }
    }
} 