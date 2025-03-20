//
//  ChatView.swift
//  Muni
//
//  Created by Yaduraj Singh on 20/03/25.
//

import SwiftUI

struct ChatView: View {
    @EnvironmentObject private var aiManager: AIManager
    @EnvironmentObject private var transactionManager: TransactionManager
    @EnvironmentObject private var userManager: UserManager
    @State private var messageText = ""
    @FocusState private var isInputFocused: Bool
    
    var body: some View {
        NavigationView {
            VStack(spacing: 0) {
                // Chat messages
                ScrollViewReader { scrollView in
                    ScrollView {
                        LazyVStack(spacing: Theme.paddingMedium) {
                            ForEach(aiManager.messages) { message in
                                MessageBubbleView(message: message)
                            }
                            
                            if aiManager.isLoading {
                                LoadingIndicator()
                                    .padding()
                            }
                        }
                        .padding(.horizontal)
                        .padding(.top, Theme.paddingMedium)
                        .padding(.bottom, Theme.paddingLarge)
                    }
                    .background(Theme.background)
                    .onChange(of: aiManager.messages.count) { _ in
                        if let lastMessage = aiManager.messages.last {
                            withAnimation {
                                scrollView.scrollTo(lastMessage.id, anchor: .bottom)
                            }
                        }
                    }
                }
                
                // Typing indicator
                VStack(spacing: 0) {
                    Divider()
                        .background(Theme.text.opacity(0.1))
                    
                    HStack {
                        TextField("Ask me anything...", text: $messageText)
                            .padding(.horizontal)
                            .frame(height: 52)
                            .focused($isInputFocused)
                        
                        Button(action: {
                            sendMessage()
                        }) {
                            Image(systemName: "arrow.up.circle.fill")
                                .font(.system(size: 30))
                                .foregroundColor(messageText.isEmpty ? .gray : Theme.primary)
                        }
                        .disabled(messageText.isEmpty || aiManager.isLoading)
                        .padding(.trailing)
                    }
                }
                .background(Theme.background)
                .shadow(color: Color.black.opacity(0.05), radius: 5, y: -5)
            }
            .navigationTitle("Financial Assistant")
        }
    }
    
    private func sendMessage() {
        let message = messageText.trimmingCharacters(in: .whitespacesAndNewlines)
        messageText = ""
        
        guard !message.isEmpty else { return }
        
        aiManager.sendMessage(message, transactionManager: transactionManager, userManager: userManager)
    }
}

struct LoadingIndicator: View {
    @State private var isAnimating = false
    
    var body: some View {
        HStack(spacing: 6) {
            Circle()
                .frame(width: 8, height: 8)
                .opacity(isAnimating ? 0.3 : 1)
                .animation(
                    Animation.easeInOut(duration: 0.8)
                        .repeatForever(autoreverses: true)
                        .delay(0)
                , value: isAnimating)
            
            Circle()
                .frame(width: 8, height: 8)
                .opacity(isAnimating ? 0.3 : 1)
                .animation(
                    Animation.easeInOut(duration: 0.8)
                        .repeatForever(autoreverses: true)
                        .delay(0.2)
                , value: isAnimating)
            
            Circle()
                .frame(width: 8, height: 8)
                .opacity(isAnimating ? 0.3 : 1)
                .animation(
                    Animation.easeInOut(duration: 0.8)
                        .repeatForever(autoreverses: true)
                        .delay(0.4)
                , value: isAnimating)
        }
        .foregroundColor(Theme.text.opacity(0.5))
        .padding()
        .onAppear {
            isAnimating = true
        }
    }
} 