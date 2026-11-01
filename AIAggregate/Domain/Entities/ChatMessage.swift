import Foundation

enum MessageRole: String, Codable, Sendable {
    case system, user, assistant
}

struct ChatMessage: Identifiable, Equatable, Codable, Sendable {
    var id: UUID = UUID()
    let role: MessageRole
    var content: String
    let createdAt: Date
    var isStreaming: Bool = false
}

struct ChatSession: Identifiable, Equatable, Codable, Sendable {
    var id: UUID = UUID()
    var title: String
    var modelID: String
    var messages: [ChatMessage]
    var updatedAt: Date
}
