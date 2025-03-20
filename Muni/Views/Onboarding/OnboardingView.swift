//
//  OnboardingView.swift
//  Muni
//
//  Created by Yaduraj Singh on 20/03/25.
//

import SwiftUI

struct OnboardingView: View {
    @EnvironmentObject private var userManager: UserManager
    @State private var currentPage = 0
    @State private var userName = ""
    @State private var monthlyBudget = ""
    
    private let pages = ["Welcome", "Setup", "Finish"]
    
    var body: some View {
        ZStack {
            Theme.background
                .ignoresSafeArea()
            
            VStack(spacing: Theme.paddingLarge) {
                // Progress indicator
                HStack {
                    ForEach(0..<pages.count, id: \.self) { index in
                        Capsule()
                            .fill(currentPage >= index ? Theme.primary : Theme.secondary)
                            .frame(height: 4)
                    }
                }
                .padding(.horizontal)
                .padding(.top, Theme.paddingLarge)
                
                // Page title
                Text(getTitle())
                    .font(.system(size: Theme.headingSize, weight: .bold))
                    .foregroundColor(Theme.text)
                    .padding(.top, Theme.paddingMedium)
                
                // Page content
                pageContent
                
                Spacer()
                
                // Navigation buttons
                HStack {
                    if currentPage > 0 {
                        Button(action: {
                            withAnimation {
                                currentPage -= 1
                            }
                        }) {
                            HStack {
                                Image(systemName: "chevron.left")
                                Text("Back")
                            }
                            .padding(.vertical, Theme.paddingMedium)
                            .padding(.horizontal, Theme.paddingLarge)
                            .background(Theme.secondary)
                            .foregroundColor(Theme.text)
                            .cornerRadius(Theme.cornerRadiusMedium)
                        }
                    }
                    
                    Spacer()
                    
                    Button(action: {
                        if currentPage == pages.count - 1 {
                            completeOnboarding()
                        } else {
                            withAnimation {
                                currentPage += 1
                            }
                        }
                    }) {
                        HStack {
                            Text(currentPage == pages.count - 1 ? "Start" : "Next")
                            Image(systemName: "chevron.right")
                        }
                        .padding(.vertical, Theme.paddingMedium)
                        .padding(.horizontal, Theme.paddingLarge)
                        .background(isNextButtonDisabled() ? Color.gray : Theme.primary)
                        .foregroundColor(.white)
                        .cornerRadius(Theme.cornerRadiusMedium)
                    }
                    .disabled(isNextButtonDisabled())
                }
                .padding(.horizontal)
                .padding(.bottom, Theme.paddingLarge)
            }
        }
    }
    
    @ViewBuilder
    private var pageContent: some View {
        switch currentPage {
        case 0:
            welcomePage
        case 1:
            setupPage
        case 2:
            finishPage
        default:
            EmptyView()
        }
    }
    
    private var welcomePage: some View {
        VStack(spacing: Theme.paddingLarge) {
            Image(systemName: "indianrupeesign.circle.fill")
                .resizable()
                .scaledToFit()
                .frame(width: 150, height: 150)
                .foregroundColor(Theme.primary)
                .padding(.vertical, Theme.paddingLarge)
            
            Text("Welcome to Muni")
                .font(.system(size: Theme.titleSize, weight: .bold))
                .foregroundColor(Theme.text)
            
            Text("Your smart money manager designed for Indian finances")
                .font(.system(size: Theme.bodySize))
                .foregroundColor(Theme.text.opacity(0.8))
                .multilineTextAlignment(.center)
                .padding(.horizontal)
            
            Text("Let's get you set up in just a few steps")
                .font(.system(size: Theme.bodySize))
                .foregroundColor(Theme.text.opacity(0.8))
                .multilineTextAlignment(.center)
                .padding(.horizontal)
        }
        .padding()
    }
    
    private var setupPage: some View {
        VStack(alignment: .leading, spacing: Theme.paddingMedium) {
            Text("Tell us about yourself")
                .font(.system(size: Theme.subtitleSize, weight: .semibold))
                .foregroundColor(Theme.text)
                .padding(.top, Theme.paddingLarge)
            
            Text("What should we call you?")
                .font(.system(size: Theme.bodySize))
                .foregroundColor(Theme.text.opacity(0.8))
                .padding(.top, Theme.paddingMedium)
            
            TextField("Your Name", text: $userName)
                .padding()
                .background(Theme.secondary)
                .cornerRadius(Theme.cornerRadiusSmall)
                .onChange(of: userName) { _ in
                    userManager.name = userName
                }
            
            Text("What's your monthly budget?")
                .font(.system(size: Theme.bodySize))
                .foregroundColor(Theme.text.opacity(0.8))
                .padding(.top, Theme.paddingMedium)
            
            HStack {
                Text("₹")
                    .font(.system(size: Theme.bodySize, weight: .semibold))
                    .foregroundColor(Theme.text)
                
                TextField("0", text: $monthlyBudget)
                    .keyboardType(.numberPad)
                    .onChange(of: monthlyBudget) { newValue in
                        if let budget = Double(newValue) {
                            userManager.monthlyBudget = budget
                        }
                    }
            }
            .padding()
            .background(Theme.secondary)
            .cornerRadius(Theme.cornerRadiusSmall)
        }
        .padding()
    }
    
    private var finishPage: some View {
        VStack(spacing: Theme.paddingLarge) {
            Image(systemName: "checkmark.circle.fill")
                .resizable()
                .scaledToFit()
                .frame(width: 100, height: 100)
                .foregroundColor(Theme.income)
                .padding(.vertical, Theme.paddingLarge)
            
            Text("You're all set!")
                .font(.system(size: Theme.titleSize, weight: .bold))
                .foregroundColor(Theme.text)
            
            VStack(alignment: .leading, spacing: Theme.paddingMedium) {
                HStack {
                    Text("Name:")
                        .foregroundColor(Theme.text.opacity(0.8))
                    Spacer()
                    Text(userName.isEmpty ? "User" : userName)
                        .foregroundColor(Theme.text)
                        .fontWeight(.semibold)
                }
                
                HStack {
                    Text("Monthly Budget:")
                        .foregroundColor(Theme.text.opacity(0.8))
                    Spacer()
                    Text("₹\(userManager.monthlyBudget, specifier: "%.2f")")
                        .foregroundColor(Theme.text)
                        .fontWeight(.semibold)
                }
            }
            .padding()
            .background(Theme.secondary)
            .cornerRadius(Theme.cornerRadiusMedium)
            .padding(.horizontal)
            
            Text("Tap 'Start' to begin managing your finances")
                .font(.system(size: Theme.bodySize))
                .foregroundColor(Theme.text.opacity(0.8))
                .multilineTextAlignment(.center)
                .padding(.horizontal)
        }
        .padding()
    }
    
    private func getTitle() -> String {
        return pages[currentPage]
    }
    
    private func isNextButtonDisabled() -> Bool {
        if currentPage == 1 {
            return userName.isEmpty
        }
        return false
    }
    
    private func completeOnboarding() {
        // Set default name if empty
        userManager.name = userName.isEmpty ? "User" : userName
        
        // Set budget if valid
        if let budget = Double(monthlyBudget) {
            userManager.monthlyBudget = budget
        }
        
        // Save user data
        userManager.saveUserData()
        
        // Complete onboarding
        UserDefaults.standard.set(true, forKey: "hasCompletedOnboarding")
    }
}

struct OnboardingView_Previews: PreviewProvider {
    static var previews: some View {
        OnboardingView()
            .environmentObject(UserManager())
    }
} 