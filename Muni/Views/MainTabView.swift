//
//  MainTabView.swift
//  Muni
//
//  Created by Yaduraj Singh on 20/03/25.
//

import SwiftUI

struct MainTabView: View {
    @StateObject private var transactionManager = TransactionManager()
    @StateObject private var aiManager = AIManager()
    @EnvironmentObject private var userManager: UserManager
    @State private var selectedTab = 0
    
    var body: some View {
        TabView(selection: $selectedTab) {
            // Dashboard Tab
            DashboardView()
                .environmentObject(transactionManager)
                .environmentObject(userManager)
                .tabItem {
                    Label("Dashboard", systemImage: "chart.pie")
                }
                .tag(0)
            
            // Transactions Tab
            TransactionsView()
                .environmentObject(transactionManager)
                .environmentObject(userManager)
                .tabItem {
                    Label("Transactions", systemImage: "list.bullet")
                }
                .tag(1)
            
            // Add Transaction Tab
            AddTransactionView()
                .environmentObject(transactionManager)
                .environmentObject(userManager)
                .tabItem {
                    Label("Add", systemImage: "plus.circle.fill")
                }
                .tag(2)
            
            // Chat AI Tab
            ChatView()
                .environmentObject(aiManager)
                .environmentObject(transactionManager)
                .environmentObject(userManager)
                .tabItem {
                    Label("Assistant", systemImage: "message")
                }
                .tag(3)
            
            // Profile Tab
            ProfileView()
                .environmentObject(userManager)
                .environmentObject(transactionManager)
                .tabItem {
                    Label("Profile", systemImage: "person")
                }
                .tag(4)
        }
        .accentColor(Theme.primary)
        .onAppear {
            // Configure the tab bar appearance
            let appearance = UITabBarAppearance()
            appearance.configureWithOpaqueBackground()
            
            // Set colors based on light/dark mode
            appearance.backgroundColor = UIColor(Theme.background)
            
            UITabBar.appearance().standardAppearance = appearance
            if #available(iOS 15.0, *) {
                UITabBar.appearance().scrollEdgeAppearance = appearance
            }
        }
    }
} 