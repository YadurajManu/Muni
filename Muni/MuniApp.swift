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
    
    var body: some Scene {
        WindowGroup {
            if hasCompletedOnboarding {
                MainTabView()
                    .environmentObject(userManager)
            } else {
                OnboardingView()
                    .environmentObject(userManager)
            }
        }
    }
}
