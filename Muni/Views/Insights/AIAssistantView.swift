import SwiftUI
import Combine

struct AIAssistantView: View {
    @EnvironmentObject private var transactionManager: TransactionManager
    @EnvironmentObject private var userManager: UserManager
    @StateObject private var viewModel = AIAssistantViewModel()
    @Environment(\.colorScheme) private var colorScheme
    @Environment(\.dismiss) private var dismiss
    
    var body: some View {
        VStack(spacing: 0) {
            // Header with branding
            assistantHeader
            
            // Chat messages
            messagesView
            
            // Quick action buttons
            if !viewModel.isTyping {
                quickActionButtons
            }
            
            // Input area
            messageInputArea
        }
        .background(Theme.background.ignoresSafeArea())
        .onAppear {
            viewModel.loadConversationHistory()
            if viewModel.messages.isEmpty {
                viewModel.addInitialWelcomeMessage(userName: userManager.name)
            }
            viewModel.initialize(
                transactionManager: transactionManager,
                userManager: userManager
            )
        }
    }
    
    // Assistant header with branding and controls
    private var assistantHeader: some View {
        ZStack {
            // Background with gradient
            LinearGradient(
                gradient: Gradient(colors: [Theme.primary, Theme.primary.opacity(0.8)]),
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
            .ignoresSafeArea(edges: .top)
            
            VStack(spacing: 4) {
                // App branding and assistant title
                HStack {
                    Button(action: { dismiss() }) {
                        Image(systemName: "arrow.left")
                            .font(.system(size: 18, weight: .semibold))
                            .foregroundColor(.white)
                            .padding(8)
                            .background(Color.white.opacity(0.2))
                            .clipShape(Circle())
                    }
                    
                    Spacer()
                    
                    Text("Muni Assistant")
                        .font(.system(size: 20, weight: .bold, design: .rounded))
                        .foregroundColor(.white)
                    
                    Spacer()
                    
                    Button(action: { viewModel.clearConversation() }) {
                        Image(systemName: "arrow.clockwise")
                            .font(.system(size: 18, weight: .semibold))
                            .foregroundColor(.white)
                            .padding(8)
                            .background(Color.white.opacity(0.2))
                            .clipShape(Circle())
                    }
                }
                
                // Status indicator
                HStack {
                    Circle()
                        .fill(Color.green)
                        .frame(width: 8, height: 8)
                    
                    Text(viewModel.isTyping ? "Thinking..." : "Ready to help")
                        .font(.system(size: 14))
                        .foregroundColor(.white.opacity(0.9))
                    
                    Spacer()
                }
            }
            .padding(.horizontal)
            .padding(.top, 8)
            .padding(.bottom, 12)
        }
        .frame(height: 110)
    }
    
    // Messages scrolling view
    private var messagesView: some View {
        ScrollViewReader { scrollView in
            ScrollView {
                LazyVStack(spacing: 16) {
                    ForEach(viewModel.messages) { message in
                        MessageBubble(message: message)
                            .id(message.id)
                    }
                    
                    // Typing indicator
                    if viewModel.isTyping {
                        TypingIndicator()
                            .id("typingIndicator")
                    }
                }
                .padding()
            }
            .onChange(of: viewModel.messages.count) { _ in
                withAnimation {
                    scrollView.scrollTo(viewModel.messages.last?.id ?? "typingIndicator", anchor: .bottom)
                }
            }
            .onChange(of: viewModel.isTyping) { isTyping in
                if isTyping {
                    withAnimation {
                        scrollView.scrollTo("typingIndicator", anchor: .bottom)
                    }
                }
            }
        }
        .background(Theme.background)
    }
    
    // Quick action suggestion buttons
    private var quickActionButtons: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 10) {
                ForEach(viewModel.getQuickActionSuggestions(
                    transactionManager: transactionManager,
                    userManager: userManager
                ), id: \.self) { suggestion in
                    Button(action: {
                        viewModel.sendMessage(content: suggestion)
                    }) {
                        Text(suggestion)
                            .font(.system(size: 14))
                            .foregroundColor(Theme.primary)
                            .padding(.vertical, 8)
                            .padding(.horizontal, 12)
                            .background(
                                RoundedRectangle(cornerRadius: 18)
                                    .stroke(Theme.primary.opacity(0.5), lineWidth: 1)
                                    .background(
                                        RoundedRectangle(cornerRadius: 18)
                                            .fill(colorScheme == .dark ? Color.black.opacity(0.3) : Color.white)
                                    )
                            )
                    }
                }
            }
            .padding(.horizontal)
            .padding(.vertical, 10)
        }
        .background(
            Rectangle()
                .fill(Theme.background)
                .shadow(color: Color.black.opacity(0.05), radius: 5, x: 0, y: -5)
        )
    }
    
    // Message input area
    private var messageInputArea: some View {
        HStack(spacing: 12) {
            // Text input field
            HStack {
                TextField("Ask me about your finances...", text: $viewModel.inputMessage)
                    .padding(.leading, 12)
                    .disabled(viewModel.isTyping)
                
                if !viewModel.inputMessage.isEmpty {
                    Button(action: {
                        viewModel.inputMessage = ""
                    }) {
                        Image(systemName: "xmark.circle.fill")
                            .foregroundColor(.gray)
                    }
                    .padding(.trailing, 8)
                }
            }
            .padding(.vertical, 10)
            .background(
                RoundedRectangle(cornerRadius: 24)
                    .fill(colorScheme == .dark ? Color.black.opacity(0.3) : Color.white)
                    .shadow(color: Color.black.opacity(0.05), radius: 2, x: 0, y: 1)
            )
            
            // Send button
            Button(action: {
                if !viewModel.inputMessage.isEmpty {
                    viewModel.sendMessage(content: viewModel.inputMessage)
                    viewModel.inputMessage = ""
                }
            }) {
                Image(systemName: "arrow.up.circle.fill")
                    .font(.system(size: 38))
                    .foregroundColor(!viewModel.inputMessage.isEmpty && !viewModel.isTyping ? Theme.primary : Color.gray)
            }
            .disabled(viewModel.inputMessage.isEmpty || viewModel.isTyping)
        }
        .padding(.horizontal)
        .padding(.vertical, 10)
        .background(
            Rectangle()
                .fill(colorScheme == .dark ? Color.black.opacity(0.2) : Color.white.opacity(0.9))
                .shadow(color: Color.black.opacity(0.08), radius: 5, x: 0, y: -2)
        )
    }
}

// Message bubble component
struct MessageBubble: View {
    let message: ChatMessage
    @Environment(\.colorScheme) private var colorScheme
    
    var body: some View {
        HStack {
            if message.isUser {
                Spacer()
            }
            
            VStack(alignment: message.isUser ? .trailing : .leading, spacing: 4) {
                // Message content
                Text(message.content)
                    .font(.system(size: 16))
                    .foregroundColor(message.isUser ? Color.white : Theme.text)
                    .padding(.horizontal, 16)
                    .padding(.vertical, 12)
                    .background(
                        message.isUser
                            ? Theme.primary
                            : (colorScheme == .dark ? Color.gray.opacity(0.3) : Color.gray.opacity(0.1))
                    )
                    .cornerRadius(20)
                    .cornerRadius(message.isUser ? 20 : 20, corners: message.isUser ? [.topLeft, .bottomLeft, .bottomRight] : [.topRight, .bottomLeft, .bottomRight])
                
                // Optional action buttons for assistant messages
                if !message.isUser && !message.actions.isEmpty {
                    HStack(spacing: 8) {
                        ForEach(message.actions, id: \.self) { action in
                            Text(action.title)
                                .font(.system(size: 14))
                                .foregroundColor(Theme.primary)
                                .padding(.vertical, 6)
                                .padding(.horizontal, 12)
                                .background(
                                    RoundedRectangle(cornerRadius: 16)
                                        .stroke(Theme.primary.opacity(0.5), lineWidth: 1)
                                )
                        }
                    }
                    .padding(.top, 4)
                }
                
                // Timestamp
                Text(formatTime(date: message.timestamp))
                    .font(.system(size: 12))
                    .foregroundColor(Theme.text.opacity(0.5))
                    .padding(.horizontal, 4)
            }
            
            if !message.isUser {
                Spacer()
            }
        }
    }
    
    private func formatTime(date: Date) -> String {
        let formatter = DateFormatter()
        formatter.timeStyle = .short
        return formatter.string(from: date)
    }
}

// Custom corner radius extension
extension View {
    func cornerRadius(_ radius: CGFloat, corners: UIRectCorner) -> some View {
        clipShape(RoundedCornerShape(radius: radius, corners: corners))
    }
}

struct RoundedCornerShape: Shape {
    var radius: CGFloat
    var corners: UIRectCorner
    
    func path(in rect: CGRect) -> Path {
        let path = UIBezierPath(
            roundedRect: rect,
            byRoundingCorners: corners,
            cornerRadii: CGSize(width: radius, height: radius)
        )
        return Path(path.cgPath)
    }
}

// Typing indicator
struct TypingIndicator: View {
    @State private var firstDotScale: CGFloat = 1.0
    @State private var secondDotScale: CGFloat = 1.0
    @State private var thirdDotScale: CGFloat = 1.0
    
    var body: some View {
        HStack(spacing: 0) {
            HStack(spacing: 4) {
                Circle()
                    .frame(width: 8, height: 8)
                    .scaleEffect(firstDotScale)
                    .foregroundColor(Theme.text.opacity(0.5))
                
                Circle()
                    .frame(width: 8, height: 8)
                    .scaleEffect(secondDotScale)
                    .foregroundColor(Theme.text.opacity(0.5))
                
                Circle()
                    .frame(width: 8, height: 8)
                    .scaleEffect(thirdDotScale)
                    .foregroundColor(Theme.text.opacity(0.5))
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 12)
            .background(Color.gray.opacity(0.1))
            .cornerRadius(20, corners: [.topRight, .bottomLeft, .bottomRight])
            
            Spacer()
        }
        .onAppear {
            animate()
        }
    }
    
    private func animate() {
        let animation = Animation.easeInOut(duration: 0.4).repeatForever(autoreverses: true)
        
        withAnimation(animation) {
            firstDotScale = 0.6
        }
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.2) {
            withAnimation(animation) {
                secondDotScale = 0.6
            }
        }
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.4) {
            withAnimation(animation) {
                thirdDotScale = 0.6
            }
        }
    }
}

// MARK: - View Model and Data Models

// Action button for assistant responses
struct MessageAction {
    let title: String
    let action: () -> Void
}

// Chat message model
struct ChatMessage: Identifiable, Codable {
    let id: UUID
    let content: String
    let isUser: Bool
    let timestamp: Date
    
    // Actions can't be encoded/decoded directly
    var actions: [MessageAction] = []
    
    // Coding keys for serialization
    enum CodingKeys: String, CodingKey {
        case id, content, isUser, timestamp
    }
}

// View model for AI assistant
class AIAssistantViewModel: ObservableObject {
    @Published var messages: [ChatMessage] = []
    @Published var inputMessage: String = ""
    @Published var isTyping: Bool = false
    
    private var transactionManager: TransactionManager?
    private var userManager: UserManager?
    private var cancellables = Set<AnyCancellable>()
    
    private let savedMessagesKey = "aiAssistantMessages"
    private let maxStoredMessages = 50
    
    func initialize(transactionManager: TransactionManager, userManager: UserManager) {
        self.transactionManager = transactionManager
        self.userManager = userManager
    }
    
    // Load previous conversation history
    func loadConversationHistory() {
        if let savedData = UserDefaults.standard.data(forKey: savedMessagesKey),
           let decodedMessages = try? JSONDecoder().decode([ChatMessage].self, from: savedData) {
            messages = decodedMessages
        }
    }
    
    // Save conversation history
    private func saveConversationHistory() {
        // Only save last maxStoredMessages
        let messagesToSave = messages.suffix(maxStoredMessages)
        if let encodedData = try? JSONEncoder().encode(Array(messagesToSave)) {
            UserDefaults.standard.set(encodedData, forKey: savedMessagesKey)
        }
    }
    
    func addInitialWelcomeMessage(userName: String) {
        let welcomeName = userName.isEmpty ? "there" : userName
        let welcomeMessage = ChatMessage(
            id: UUID(),
            content: "Hi \(welcomeName)! I'm your Muni financial assistant. I can help you understand your spending patterns, provide budget advice, or answer questions about your finances. What can I help you with today?",
            isUser: false,
            timestamp: Date()
        )
        messages.append(welcomeMessage)
        saveConversationHistory()
    }
    
    func clearConversation() {
        messages.removeAll()
        addInitialWelcomeMessage(userName: userManager?.name ?? "")
    }
    
    func sendMessage(content: String) {
        // Add user message
        let userMessage = ChatMessage(
            id: UUID(),
            content: content,
            isUser: true,
            timestamp: Date()
        )
        
        messages.append(userMessage)
        saveConversationHistory()
        
        // Simulate AI typing
        isTyping = true
        
        // Generate response
        DispatchQueue.main.asyncAfter(deadline: .now() + Double.random(in: 1.0...2.5)) {
            self.generateResponse(to: content)
            self.isTyping = false
        }
    }
    
    private func generateResponse(to message: String) {
        guard let tm = transactionManager, let um = userManager else {
            let errorMessage = ChatMessage(
                id: UUID(),
                content: "I'm having trouble accessing your financial data. Please try again later.",
                isUser: false,
                timestamp: Date()
            )
            messages.append(errorMessage)
            saveConversationHistory()
            return
        }
        
        // Process the message content to determine the appropriate response
        let lowerMessage = message.lowercased()
        var responseContent = ""
        var actions: [MessageAction] = []
        
        // Budget-related questions
        if lowerMessage.contains("budget") {
            if um.monthlyBudget <= 0 {
                responseContent = "You haven't set a monthly budget yet. Would you like to set one now?"
                actions.append(MessageAction(title: "Set Budget", action: {}))
            } else {
                let currentExpenses = tm.getMonthlyExpenses(for: Calendar.current.component(.month, from: Date()),
                                                         year: Calendar.current.component(.year, from: Date()))
                let percentage = min(100, Int((currentExpenses / um.monthlyBudget) * 100))
                responseContent = "You've spent \(um.currency)\(String(format: "%.2f", currentExpenses)) of your \(um.currency)\(String(format: "%.2f", um.monthlyBudget)) monthly budget (\(percentage)%). You have \(um.currency)\(String(format: "%.2f", max(0, um.monthlyBudget - currentExpenses))) remaining."
            }
        }
        // Spending analysis questions
        else if lowerMessage.contains("spend") || lowerMessage.contains("spending") {
            let (category, amount) = tm.getTopExpenseCategory()
            let categoryName = category?.rawValue ?? "unknown"
            
            responseContent = "Your highest spending category is \(categoryName) at \(um.currency)\(String(format: "%.2f", amount)). Would you like me to analyze your spending patterns in more detail?"
            actions.append(MessageAction(title: "Analyze Spending", action: {}))
        }
        // Savings questions
        else if lowerMessage.contains("save") || lowerMessage.contains("saving") {
            let totalIncome = tm.totalIncome()
            let totalExpense = tm.totalExpense()
            let savings = totalIncome - totalExpense
            let savingsRate = totalIncome > 0 ? (savings / totalIncome) * 100 : 0
            
            responseContent = "You've saved \(um.currency)\(String(format: "%.2f", max(0, savings))) (\(String(format: "%.1f", savingsRate))% of income). Financial experts recommend saving 20% of your income. I can help you create a savings plan."
            actions.append(MessageAction(title: "Create Savings Plan", action: {}))
        }
        // Financial goals
        else if lowerMessage.contains("goal") {
            if um.financialGoal.isEmpty {
                responseContent = "You haven't set a financial goal yet. Setting clear goals can help you stay motivated and track your progress. Would you like to set a financial goal now?"
                actions.append(MessageAction(title: "Set Goal", action: {}))
            } else {
                let progress = FinancialAnalyticsService.shared.calculateGoalProgress(
                    transactions: tm.transactions,
                    goal: um.financialGoal,
                    monthlyIncome: um.monthlyIncome
                )
                responseContent = "Your goal is: \(um.financialGoal). You're \(Int(progress * 100))% of the way there! Keep going!"
            }
        }
        // Investment and future planning
        else if lowerMessage.contains("invest") || lowerMessage.contains("investment") {
            responseContent = "Based on your current savings rate and spending patterns, I recommend exploring investment options like mutual funds or index funds. Would you like some personalized investment advice?"
            actions.append(MessageAction(title: "Investment Advice", action: {}))
        }
        // Income analysis
        else if lowerMessage.contains("income") || lowerMessage.contains("earn") {
            responseContent = "Your monthly income is \(um.currency)\(String(format: "%.2f", um.monthlyIncome)). Your total recorded income transactions amount to \(um.currency)\(String(format: "%.2f", tm.totalIncome())). Is there anything specific about your income you'd like to analyze?"
        }
        // Balance inquiry
        else if lowerMessage.contains("balance") || lowerMessage.contains("account") {
            let balance = tm.balance()
            responseContent = "Your current balance is \(um.currency)\(String(format: "%.2f", balance)). This is calculated from your total income of \(um.currency)\(String(format: "%.2f", tm.totalIncome())) minus your total expenses of \(um.currency)\(String(format: "%.2f", tm.totalExpense()))."
        }
        // Help or general questions
        else if lowerMessage.contains("help") || lowerMessage.contains("can you") || lowerMessage.contains("what") {
            responseContent = "I can help you with budget planning, spending analysis, financial goals, saving strategies, and investment recommendations. I can also answer questions about your transactions and account balance. What would you like to know about?"
        }
        // Financial tips
        else if lowerMessage.contains("tip") || lowerMessage.contains("advice") {
            let tips = [
                "Automating your savings by setting up recurring transfers can help you save without thinking about it.",
                "The 50/30/20 rule suggests spending 50% on needs, 30% on wants, and 20% on savings and debt repayment.",
                "Building an emergency fund covering 3-6 months of expenses is a financial safety net worth having.",
                "Review your subscriptions regularly to ensure you're using what you pay for.",
                "Consider using the 24-hour rule before making non-essential purchases to avoid impulse buying."
            ]
            responseContent = "Here's a financial tip: \(tips.randomElement()!)\n\nWould you like another tip?"
            actions.append(MessageAction(title: "Another Tip", action: {}))
        }
        // Greeting
        else if lowerMessage.contains("hi") || lowerMessage.contains("hello") || lowerMessage.contains("hey") {
            let name = um.name.isEmpty ? "" : ", \(um.name)"
            responseContent = "Hello\(name)! How can I help with your finances today? You can ask about your spending, budget, savings, or financial goals."
        }
        // Fallback for unrecognized queries
        else {
            responseContent = "I'm not sure I understand that. I can help with your budget, spending analysis, savings strategies, financial goals, or investment recommendations. What would you like to know about?"
        }
        
        // Add the response message
        let responseMessage = ChatMessage(
            id: UUID(),
            content: responseContent,
            isUser: false,
            timestamp: Date()
        )
        
        // Add any actions
        var messageWithActions = responseMessage
        messageWithActions.actions = actions
        
        // Add the message to the conversation
        messages.append(messageWithActions)
        saveConversationHistory()
    }
    
    // Generate contextual quick action suggestions
    func getQuickActionSuggestions(transactionManager: TransactionManager, userManager: UserManager) -> [String] {
        var suggestions: [String] = []
        
        // Always provide basic help options
        suggestions.append("How am I doing financially?")
        
        // Budget-related suggestions
        if userManager.monthlyBudget <= 0 {
            suggestions.append("How do I set a budget?")
        } else {
            suggestions.append("How much of my budget is left?")
        }
        
        // If user has transactions, offer analysis
        if !transactionManager.transactions.isEmpty {
            suggestions.append("Where am I spending the most?")
            
            // If there are enough transactions for meaningful analysis
            if transactionManager.transactions.count > 5 {
                suggestions.append("Analyze my spending trends")
            }
            
            // If user is spending a lot in one category
            if let (category, _) = transactionManager.getTopExpenseCategory(), 
               let categoryName = category?.rawValue.lowercased() {
                suggestions.append("How can I reduce \(categoryName) spending?")
            }
        }
        
        // Goal-related suggestions
        if userManager.financialGoal.isEmpty {
            suggestions.append("Suggest a financial goal")
        } else {
            suggestions.append("How's my progress on my goal?")
        }
        
        // Savings and investment suggestions
        suggestions.append("How much should I be saving?")
        suggestions.append("Investment recommendations")
        
        // Return a random selection of at most 5 suggestions
        return Array(suggestions.shuffled().prefix(5))
    }
}

struct AIAssistantView_Previews: PreviewProvider {
    static var previews: some View {
        AIAssistantView()
            .environmentObject(TransactionManager())
            .environmentObject(UserManager())
    }
} 