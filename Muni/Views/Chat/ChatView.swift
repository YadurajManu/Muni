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
                                MessageBubble(message: message)
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
                        TextField("Ask me anything about finances...", text: $messageText)
                            .padding()
                            .background(Theme.secondary.opacity(0.3))
                            .cornerRadius(Theme.cornerRadiusMedium)
                            .focused($isInputFocused)
                        
                        Button(action: sendMessage) {
                            Image(systemName: "arrow.up.circle.fill")
                                .resizable()
                                .frame(width: 32, height: 32)
                                .foregroundColor(messageText.isEmpty ? Color.gray : Theme.primary)
                        }
                        .disabled(messageText.isEmpty || aiManager.isLoading)
                    }
                    .padding()
                    .background(Theme.background)
                }
            }
            .navigationTitle("Financial Assistant")
        }
    }
    
    private func sendMessage() {
        guard !messageText.isEmpty else { return }
        
        let message = messageText
        messageText = ""
        
        aiManager.sendMessage(message, transactionManager: transactionManager, userManager: userManager)
    }
}

struct MessageBubble: View {
    let message: ChatMessage
    
    var body: some View {
        HStack {
            if message.isUser {
                Spacer()
            }
            
            Text(message.content)
                .padding()
                .background(message.isUser ? Theme.primary : Theme.secondary.opacity(0.5))
                .foregroundColor(message.isUser ? .white : Theme.text)
                .cornerRadius(Theme.cornerRadiusMedium)
                .frame(maxWidth: 300, alignment: message.isUser ? .trailing : .leading)
            
            if !message.isUser {
                Spacer()
            }
        }
    }
}

struct LoadingIndicator: View {
    @State private var isAnimating = false
    
    var body: some View {
        HStack {
            Circle()
                .fill(Theme.primary.opacity(0.5))
                .frame(width: 10, height: 10)
                .scaleEffect(isAnimating ? 1 : 0.5)
                .animation(Animation.easeInOut(duration: 0.4).repeatForever().delay(0), value: isAnimating)
            
            Circle()
                .fill(Theme.primary.opacity(0.5))
                .frame(width: 10, height: 10)
                .scaleEffect(isAnimating ? 1 : 0.5)
                .animation(Animation.easeInOut(duration: 0.4).repeatForever().delay(0.2), value: isAnimating)
            
            Circle()
                .fill(Theme.primary.opacity(0.5))
                .frame(width: 10, height: 10)
                .scaleEffect(isAnimating ? 1 : 0.5)
                .animation(Animation.easeInOut(duration: 0.4).repeatForever().delay(0.4), value: isAnimating)
        }
        .padding(.vertical, 8)
        .padding(.horizontal, 12)
        .background(Theme.secondary.opacity(0.5))
        .cornerRadius(Theme.cornerRadiusMedium)
        .onAppear {
            isAnimating = true
        }
    }
} 