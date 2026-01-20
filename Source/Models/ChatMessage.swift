import Foundation

struct ChatMessage: Identifiable, Equatable {
    let id = UUID()
    let role: MessageRole
    var content: String
    let timestamp = Date()
    
    enum MessageRole {
        case user
        case assistant
    }
}
