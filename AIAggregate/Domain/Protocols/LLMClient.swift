import Foundation

protocol LLMClient: Sendable {
    func streamChat(messages: [ChatMessage],
                    config: LLMConfig) async throws -> AsyncThrowingStream<String, Error>
}
