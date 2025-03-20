import Foundation
import SwiftUI

// Action button for assistant responses
struct MessageAction: Identifiable, Hashable {
    let id = UUID()
    let title: String
    let action: () -> Void
    
    static func == (lhs: MessageAction, rhs: MessageAction) -> Bool {
        return lhs.id == rhs.id && lhs.title == rhs.title
    }
    
    func hash(into hasher: inout Hasher) {
        hasher.combine(id)
        hasher.combine(title)
    }
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
    
    init(id: UUID = UUID(), content: String, isUser: Bool, timestamp: Date = Date()) {
        self.id = id
        self.content = content
        self.isUser = isUser
        self.timestamp = timestamp
    }
} 