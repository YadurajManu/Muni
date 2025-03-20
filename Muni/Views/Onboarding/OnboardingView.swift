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
    @State private var monthlyIncome = ""
    @State private var monthlyBudget = ""
    @State private var selectedFinancialGoal = ""
    @State private var selectedExpenseCategory: TransactionCategory = .food
    @State private var notificationsEnabled = true
    @State private var darkModeEnabled = false
    
    private let pages = [
        "Welcome", 
        "Personal Info", 
        "Financial Goals", 
        "Tracking Habits", 
        "Appearance", 
        "Ready"
    ]
    
    var body: some View {
        GeometryReader { geometry in
            ZStack {
                // Background gradient
                LinearGradient(
                    gradient: Gradient(colors: [Color.black.opacity(0.8), Theme.primary.opacity(0.9)]),
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
                .ignoresSafeArea()
                
                // Content
                VStack(spacing: 0) {
                    // Header
                    OnboardingHeader(
                        currentPage: currentPage,
                        totalPages: pages.count,
                        title: pages[currentPage]
                    )
                    .padding(.top, 20)
                    
                    // Content pages
                    TabView(selection: $currentPage) {
                        WelcomePage()
                            .tag(0)
                        
                        PersonalInfoPage(
                            userName: $userName,
                            monthlyIncome: $monthlyIncome,
                            monthlyBudget: $monthlyBudget
                        )
                            .tag(1)
                        
                        FinancialGoalsPage(
                            selectedGoal: $selectedFinancialGoal
                        )
                            .tag(2)
                        
                        TrackingHabitsPage(
                            selectedCategory: $selectedExpenseCategory
                        )
                            .tag(3)
                        
                        AppearancePage(
                            notificationsEnabled: $notificationsEnabled,
                            darkModeEnabled: $darkModeEnabled
                        )
                            .tag(4)
                        
                        ReadyPage(
                            userName: userName
                        )
                            .tag(5)
                    }
                    .tabViewStyle(PageTabViewStyle(indexDisplayMode: .never))
                    .frame(height: geometry.size.height * 0.75)
                    .animation(.easeInOut, value: currentPage)
                    
                    // Navigation buttons
                    HStack(spacing: 20) {
                        // Back button
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
                                .padding(.vertical, 16)
                                .padding(.horizontal, 20)
                                .background(Color.white.opacity(0.2))
                                .foregroundColor(.white)
                                .cornerRadius(12)
                            }
                            .transition(.opacity)
                        }
                        
                        Spacer()
                        
                        // Continue/Start button
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
                                Text(currentPage == pages.count - 1 ? "Get Started" : "Continue")
                                Image(systemName: "chevron.right")
                            }
                            .padding(.vertical, 16)
                            .padding(.horizontal, 20)
                            .frame(minWidth: 160)
                            .background(isNextButtonDisabled() ? Color.gray.opacity(0.5) : Color.white)
                            .foregroundColor(isNextButtonDisabled() ? Color.white.opacity(0.5) : Theme.primary)
                            .cornerRadius(12)
                            .shadow(color: Color.black.opacity(0.1), radius: 5, x: 0, y: 2)
                        }
                        .disabled(isNextButtonDisabled())
                    }
                    .padding(.horizontal, 30)
                    .padding(.bottom, 30)
                }
            }
        }
    }
    
    private func isNextButtonDisabled() -> Bool {
        switch currentPage {
        case 1: // Personal Info page
            return userName.isEmpty || monthlyIncome.isEmpty
        case 2: // Financial Goals page
            return selectedFinancialGoal.isEmpty
        default:
            return false
        }
    }
    
    private func completeOnboarding() {
        // Update the user manager with all collected data
        userManager.name = userName.isEmpty ? "User" : userName
        userManager.primaryExpenseCategory = selectedExpenseCategory
        userManager.financialGoal = selectedFinancialGoal
        userManager.notificationsEnabled = notificationsEnabled
        userManager.darkModeEnabled = darkModeEnabled
        
        // Set income if valid
        if let income = Double(monthlyIncome) {
            userManager.monthlyIncome = income
        }
        
        // Set budget if valid
        if let budget = Double(monthlyBudget) {
            userManager.monthlyBudget = budget
        } else if let income = Double(monthlyIncome) {
            // Default budget to 70% of income if not specified
            userManager.monthlyBudget = income * 0.7
        }
        
        // Complete the onboarding
        userManager.completeOnboarding()
    }
}

// MARK: - Onboarding Header
struct OnboardingHeader: View {
    let currentPage: Int
    let totalPages: Int
    let title: String
    
    var body: some View {
        VStack(spacing: 24) {
            // Progress bar
            HStack(spacing: 8) {
                ForEach(0..<totalPages, id: \.self) { index in
                    Capsule()
                        .fill(currentPage >= index ? Color.white : Color.white.opacity(0.3))
                        .frame(height: 4)
                        .frame(width: index == currentPage ? 24 : 16)
                        .animation(.spring(), value: currentPage)
                }
            }
            .padding(.top)
            
            // Title
            Text(title)
                .font(.system(size: 32, weight: .bold, design: .rounded))
                .foregroundColor(.white)
                .padding(.bottom, 10)
        }
        .padding(.horizontal, 30)
    }
}

// MARK: - Welcome Page
struct WelcomePage: View {
    @State private var isAnimating = false
    
    var body: some View {
        VStack(spacing: 30) {
            // App logo animation
            ZStack {
                Circle()
                    .fill(Color.white)
                    .frame(width: 160, height: 160)
                    .shadow(color: Color.black.opacity(0.1), radius: 10, x: 0, y: 5)
                
                Image(systemName: "indianrupeesign.circle.fill")
                    .resizable()
                    .aspectRatio(contentMode: .fit)
                    .frame(width: 90, height: 90)
                    .foregroundColor(Theme.primary)
                    .scaleEffect(isAnimating ? 1.1 : 1.0)
                    .rotationEffect(Angle(degrees: isAnimating ? 10 : 0))
                    .animation(
                        Animation.easeInOut(duration: 1.2)
                            .repeatForever(autoreverses: true),
                        value: isAnimating
                    )
            }
            .padding(.bottom, 20)
            .onAppear {
                isAnimating = true
            }
            
            // Welcome text
            Text("Welcome to Muni")
                .font(.system(size: 36, weight: .bold, design: .rounded))
                .foregroundColor(.white)
                .multilineTextAlignment(.center)
                .opacity(isAnimating ? 1 : 0)
                .offset(y: isAnimating ? 0 : 20)
                .animation(.easeOut(duration: 0.8).delay(0.3), value: isAnimating)
            
            Text("Your AI-powered personal finance companion")
                .font(.system(size: 20, weight: .medium, design: .rounded))
                .foregroundColor(.white.opacity(0.8))
                .multilineTextAlignment(.center)
                .padding(.bottom, 20)
                .opacity(isAnimating ? 1 : 0)
                .offset(y: isAnimating ? 0 : 20)
                .animation(.easeOut(duration: 0.8).delay(0.5), value: isAnimating)
            
            // Feature highlights with animations
            FeatureRow(icon: "chart.line.uptrend.xyaxis", title: "Smart Tracking", description: "Effortlessly track your daily expenses and income", delay: 0.7)
            
            FeatureRow(icon: "brain.head.profile", title: "AI Insights", description: "Get personalized financial advice", delay: 0.9)
            
            FeatureRow(icon: "chart.pie.fill", title: "Visual Reports", description: "Beautiful charts to visualize your finances", delay: 1.1)
            
            Spacer()
        }
        .padding(.horizontal, 30)
        .padding(.top, 30)
    }
}

struct FeatureRow: View {
    let icon: String
    let title: String
    let description: String
    var delay: Double = 0
    
    @State private var isAnimating = false
    
    var body: some View {
        HStack(spacing: 20) {
            Image(systemName: icon)
                .font(.system(size: 28))
                .foregroundColor(.white)
                .frame(width: 50, height: 50)
                .background(Color.white.opacity(0.2))
                .clipShape(Circle())
            
            VStack(alignment: .leading, spacing: 4) {
                Text(title)
                    .font(.system(size: 18, weight: .semibold, design: .rounded))
                    .foregroundColor(.white)
                
                Text(description)
                    .font(.system(size: 15, design: .rounded))
                    .foregroundColor(.white.opacity(0.7))
                    .fixedSize(horizontal: false, vertical: true)
            }
            
            Spacer()
        }
        .padding(.bottom, 10)
        .opacity(isAnimating ? 1 : 0)
        .offset(x: isAnimating ? 0 : -30)
        .onAppear {
            withAnimation(Animation.easeOut(duration: 0.6).delay(delay)) {
                isAnimating = true
            }
        }
    }
}

// MARK: - Personal Info Page
struct PersonalInfoPage: View {
    @Binding var userName: String
    @Binding var monthlyIncome: String
    @Binding var monthlyBudget: String
    
    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 30) {
                Text("Let's personalize your experience")
                    .font(.system(size: 20, weight: .medium, design: .rounded))
                    .foregroundColor(.white.opacity(0.8))
                    .padding(.bottom, 10)
                
                // Name field
                VStack(alignment: .leading, spacing: 10) {
                    Text("What should we call you?")
                        .font(.system(size: 17, weight: .semibold, design: .rounded))
                        .foregroundColor(.white)
                    
                    OnboardingTextField(
                        placeholder: "Your Name",
                        text: $userName,
                        icon: "person.fill"
                    )
                }
                
                // Monthly income field
                VStack(alignment: .leading, spacing: 10) {
                    Text("What's your monthly income?")
                        .font(.system(size: 17, weight: .semibold, design: .rounded))
                        .foregroundColor(.white)
                    
                    OnboardingTextField(
                        placeholder: "50,000",
                        text: $monthlyIncome,
                        icon: "banknote.fill",
                        keyboardType: .numberPad,
                        isCurrency: true
                    )
                    
                    Text("This helps us provide better financial insights")
                        .font(.system(size: 14, design: .rounded))
                        .foregroundColor(.white.opacity(0.6))
                }
                
                // Monthly budget field
                VStack(alignment: .leading, spacing: 10) {
                    Text("Do you have a monthly budget?")
                        .font(.system(size: 17, weight: .semibold, design: .rounded))
                        .foregroundColor(.white)
                    
                    OnboardingTextField(
                        placeholder: "35,000 (optional)",
                        text: $monthlyBudget,
                        icon: "creditcard.fill",
                        keyboardType: .numberPad,
                        isCurrency: true
                    )
                    
                    Text("If left empty, we'll suggest a budget based on your income")
                        .font(.system(size: 14, design: .rounded))
                        .foregroundColor(.white.opacity(0.6))
                }
                
                Spacer()
            }
            .padding(.horizontal, 30)
            .padding(.top, 20)
        }
    }
}

// MARK: - Financial Goals Page
struct FinancialGoalsPage: View {
    @Binding var selectedGoal: String
    
    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 30) {
                Text("What's your primary financial goal?")
                    .font(.system(size: 20, weight: .medium, design: .rounded))
                    .foregroundColor(.white.opacity(0.8))
                    .padding(.bottom, 10)
                
                // Financial goals grid
                LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 15) {
                    ForEach(UserManager.financialGoalOptions(), id: \.self) { goal in
                        GoalCard(
                            goal: goal,
                            isSelected: selectedGoal == goal,
                            action: { selectedGoal = goal }
                        )
                    }
                }
                
                Text("Your goal helps us tailor the app experience to your needs")
                    .font(.system(size: 14, design: .rounded))
                    .foregroundColor(.white.opacity(0.7))
                    .padding(.top, 10)
                
                Spacer()
            }
            .padding(.horizontal, 30)
            .padding(.top, 20)
        }
    }
}

struct GoalCard: View {
    let goal: String
    let isSelected: Bool
    let action: () -> Void
    
    // Returns an appropriate icon based on the goal
    private var iconName: String {
        switch goal {
        case "Save for an emergency fund":
            return "umbrella.fill"
        case "Pay off debt":
            return "creditcard.fill"
        case "Save for a major purchase":
            return "cart.fill"
        case "Build investment portfolio":
            return "chart.line.uptrend.xyaxis.circle.fill"
        case "Track day-to-day expenses":
            return "list.bullet.clipboard.fill"
        case "Reduce unnecessary spending":
            return "scissors"
        case "Financial independence":
            return "star.fill"
        default:
            return "ellipsis.circle.fill"
        }
    }
    
    @State private var isAnimating = false
    
    var body: some View {
        Button(action: {
            withAnimation(.spring()) {
                action()
                isAnimating = true
                
                // Reset animation after it completes
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                    isAnimating = false
                }
            }
        }) {
            VStack(spacing: 15) {
                Image(systemName: iconName)
                    .font(.system(size: 28))
                    .foregroundColor(isSelected ? Theme.primary : .white)
                    .scaleEffect(isAnimating && isSelected ? 1.3 : 1.0)
                    .animation(.spring(response: 0.3, dampingFraction: 0.6), value: isAnimating)
                
                Text(goal)
                    .font(.system(size: 14, weight: .medium, design: .rounded))
                    .foregroundColor(isSelected ? .black : .white)
                    .multilineTextAlignment(.center)
                    .lineLimit(2)
                    .fixedSize(horizontal: false, vertical: true)
            }
            .frame(height: 120)
            .frame(maxWidth: .infinity)
            .padding(.horizontal, 10)
            .padding(.vertical, 16)
            .background(isSelected ? Color.white : Color.white.opacity(0.1))
            .cornerRadius(16)
            .overlay(
                RoundedRectangle(cornerRadius: 16)
                    .stroke(isSelected ? Color.white : Color.clear, lineWidth: 2)
            )
            .shadow(color: isSelected ? Theme.primary.opacity(0.3) : Color.clear, radius: 8, x: 0, y: 2)
            .scaleEffect(isSelected ? 1.05 : 1.0)
            .animation(.spring(response: 0.3, dampingFraction: 0.6), value: isSelected)
        }
    }
}

// MARK: - Tracking Habits Page
struct TrackingHabitsPage: View {
    @Binding var selectedCategory: TransactionCategory
    
    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 30) {
                Text("What do you spend the most on?")
                    .font(.system(size: 20, weight: .medium, design: .rounded))
                    .foregroundColor(.white.opacity(0.8))
                    .padding(.bottom, 10)
                
                // Categories grid
                LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible()), GridItem(.flexible())], spacing: 15) {
                    ForEach(TransactionCategory.expenseCategories(), id: \.self) { category in
                        CategoryCard(
                            category: category,
                            isSelected: selectedCategory == category,
                            action: { selectedCategory = category }
                        )
                    }
                }
                
                Text("This helps us focus on the categories that matter most to you")
                    .font(.system(size: 14, design: .rounded))
                    .foregroundColor(.white.opacity(0.7))
                    .padding(.top, 10)
                
                Spacer()
            }
            .padding(.horizontal, 30)
            .padding(.top, 20)
        }
    }
}

struct CategoryCard: View {
    let category: TransactionCategory
    let isSelected: Bool
    let action: () -> Void
    @State private var isAnimating = false
    
    var body: some View {
        Button(action: {
            withAnimation(.spring()) {
                action()
                isAnimating = true
                
                // Reset animation after it completes
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                    isAnimating = false
                }
            }
        }) {
            VStack(spacing: 10) {
                Image(systemName: category.icon)
                    .font(.system(size: 28))
                    .foregroundColor(isSelected ? Theme.primary : .white)
                    .scaleEffect(isAnimating && isSelected ? 1.3 : 1.0)
                    .animation(.spring(response: 0.3, dampingFraction: 0.6), value: isAnimating)
                
                Text(category.rawValue)
                    .font(.system(size: 13, weight: .medium, design: .rounded))
                    .foregroundColor(isSelected ? .black : .white)
                    .lineLimit(1)
            }
            .frame(height: 90)
            .frame(maxWidth: .infinity)
            .padding(.horizontal, 5)
            .padding(.vertical, 12)
            .background(isSelected ? Color.white : Color.white.opacity(0.1))
            .cornerRadius(12)
            .overlay(
                RoundedRectangle(cornerRadius: 12)
                    .stroke(isSelected ? Color.white : Color.clear, lineWidth: 2)
            )
            .shadow(color: isSelected ? Theme.primary.opacity(0.3) : Color.clear, radius: 8, x: 0, y: 2)
            .scaleEffect(isSelected ? 1.05 : 1.0)
            .animation(.spring(response: 0.3, dampingFraction: 0.6), value: isSelected)
        }
    }
}

// MARK: - Appearance Page
struct AppearancePage: View {
    @Binding var notificationsEnabled: Bool
    @Binding var darkModeEnabled: Bool
    
    var body: some View {
        VStack(alignment: .leading, spacing: 40) {
            Text("Customize your app experience")
                .font(.system(size: 20, weight: .medium, design: .rounded))
                .foregroundColor(.white.opacity(0.8))
                .padding(.bottom, 10)
            
            // Notifications toggle
            Toggle(isOn: $notificationsEnabled) {
                HStack {
                    Image(systemName: "bell.fill")
                        .font(.system(size: 22))
                        .foregroundColor(.white)
                        .frame(width: 40)
                    
                    VStack(alignment: .leading, spacing: 4) {
                        Text("Notifications")
                            .font(.system(size: 18, weight: .semibold, design: .rounded))
                            .foregroundColor(.white)
                        
                        Text("Get reminders and insights")
                            .font(.system(size: 14, design: .rounded))
                            .foregroundColor(.white.opacity(0.7))
                    }
                }
            }
            .toggleStyle(SwitchToggleStyle(tint: Theme.income))
            
            // Dark mode toggle
            Toggle(isOn: $darkModeEnabled) {
                HStack {
                    Image(systemName: "moon.fill")
                        .font(.system(size: 22))
                        .foregroundColor(.white)
                        .frame(width: 40)
                    
                    VStack(alignment: .leading, spacing: 4) {
                        Text("Dark Mode")
                            .font(.system(size: 18, weight: .semibold, design: .rounded))
                            .foregroundColor(.white)
                        
                        Text("Easier on the eyes at night")
                            .font(.system(size: 14, design: .rounded))
                            .foregroundColor(.white.opacity(0.7))
                    }
                }
            }
            .toggleStyle(SwitchToggleStyle(tint: Theme.income))
            
            // Security info
            HStack(spacing: 20) {
                Image(systemName: "lock.fill")
                    .font(.system(size: 28))
                    .foregroundColor(.white)
                    .frame(width: 50, height: 50)
                    .background(Color.white.opacity(0.2))
                    .clipShape(Circle())
                
                VStack(alignment: .leading, spacing: 4) {
                    Text("Your data is secure")
                        .font(.system(size: 18, weight: .semibold, design: .rounded))
                        .foregroundColor(.white)
                    
                    Text("All your financial data is stored locally on your device")
                        .font(.system(size: 14, design: .rounded))
                        .foregroundColor(.white.opacity(0.7))
                        .fixedSize(horizontal: false, vertical: true)
                }
            }
            .padding(.top, 20)
            
            Spacer()
        }
        .padding(.horizontal, 30)
        .padding(.top, 20)
    }
}

// MARK: - Ready Page
struct ReadyPage: View {
    let userName: String
    
    var body: some View {
        VStack(spacing: 40) {
            // Success animation
            ZStack {
                Circle()
                    .fill(Color.white.opacity(0.1))
                    .frame(width: 160, height: 160)
                
                Circle()
                    .fill(Color.white)
                    .frame(width: 150, height: 150)
                
                Image(systemName: "checkmark")
                    .resizable()
                    .aspectRatio(contentMode: .fit)
                    .frame(width: 70, height: 70)
                    .foregroundColor(Theme.primary)
            }
            .padding(.top, 20)
            
            // Welcome text
            Text("You're all set, \(userName.isEmpty ? "there" : userName)!")
                .font(.system(size: 28, weight: .bold, design: .rounded))
                .foregroundColor(.white)
                .multilineTextAlignment(.center)
            
            VStack(spacing: 24) {
                ReadyFeatureItem(icon: "indianrupeesign.circle.fill", text: "Track your daily expenses")
                ReadyFeatureItem(icon: "chart.pie.fill", text: "Monitor spending patterns")
                ReadyFeatureItem(icon: "brain.head.profile", text: "Get AI financial advice")
                ReadyFeatureItem(icon: "bolt.fill", text: "Achieve your financial goals")
            }
            .padding(.horizontal, 20)
            
            Text("Let's start your financial journey")
                .font(.system(size: 18, weight: .medium, design: .rounded))
                .foregroundColor(.white.opacity(0.8))
                .padding(.top, 20)
            
            Spacer()
        }
        .padding(.horizontal, 30)
        .padding(.top, 10)
    }
}

struct ReadyFeatureItem: View {
    let icon: String
    let text: String
    
    var body: some View {
        HStack(spacing: 16) {
            Image(systemName: icon)
                .font(.system(size: 22))
                .foregroundColor(.white)
                .frame(width: 36, height: 36)
                .background(Color.white.opacity(0.2))
                .clipShape(Circle())
            
            Text(text)
                .font(.system(size: 17, weight: .medium, design: .rounded))
                .foregroundColor(.white)
            
            Spacer()
            
            Image(systemName: "checkmark.circle.fill")
                .foregroundColor(Theme.income)
                .font(.system(size: 22))
        }
    }
}

// MARK: - Helper Views
struct OnboardingTextField: View {
    let placeholder: String
    @Binding var text: String
    let icon: String
    var keyboardType: UIKeyboardType = .default
    var isCurrency: Bool = false
    
    var body: some View {
        HStack {
            Image(systemName: icon)
                .foregroundColor(.white)
                .frame(width: 24)
            
            if isCurrency {
                HStack(spacing: 4) {
                    Text("₹")
                        .foregroundColor(.white)
                        .font(.system(size: 17, design: .rounded))
                    
                    TextField(placeholder.replacingOccurrences(of: "₹", with: ""), text: $text)
                        .foregroundColor(.white)
                        .font(.system(size: 17, design: .rounded))
                        .keyboardType(.numberPad)
                        .onChange(of: text) { newValue in
                            if let number = CurrencyFormatter.shared.number(from: newValue) {
                                text = CurrencyFormatter.shared.formatForInput(string: newValue)
                            }
                        }
                }
            } else {
                TextField(placeholder, text: $text)
                    .foregroundColor(.white)
                    .font(.system(size: 17, design: .rounded))
                    .keyboardType(keyboardType)
            }
            
            if !text.isEmpty {
                Button(action: { text = "" }) {
                    Image(systemName: "xmark.circle.fill")
                        .foregroundColor(.white.opacity(0.6))
                }
            }
        }
        .padding()
        .background(Color.white.opacity(0.2))
        .cornerRadius(12)
    }
}

struct OnboardingView_Previews: PreviewProvider {
    static var previews: some View {
        OnboardingView()
            .environmentObject(UserManager())
            .preferredColorScheme(.dark)
    }
} 