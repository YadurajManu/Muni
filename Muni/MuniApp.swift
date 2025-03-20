//
//  MuniApp.swift
//  Muni
//
//  Created by Yaduraj Singh on 20/03/25.
//

import SwiftUI

@main
struct MuniApp: App {
    @AppStorage("hasCompletedOnboarding") private var hasCompletedOnboarding: Bool = false
    @StateObject private var userManager = UserManager()
    @Environment(\.colorScheme) private var colorScheme
    
    var body: some Scene {
        WindowGroup {
            ZStack {
                if hasCompletedOnboarding {
                    MainTabView()
                        .environmentObject(userManager)
                        .preferredColorScheme(userManager.darkModeEnabled ? .dark : nil)
                        .transition(.opacity)
                } else {
                    OnboardingView()
                        .environmentObject(userManager)
                        .preferredColorScheme(.dark) // Onboarding always looks best in dark mode
                        .transition(.opacity)
                }
            }
            .animation(.easeInOut, value: hasCompletedOnboarding)
            .onAppear {
                // Load user data on app launch
                userManager.loadUserData()
            }
        }
    }
}
