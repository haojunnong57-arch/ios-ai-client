import Testing
import Foundation
@testable import AIAggregate

struct CoreLogicTests {
    @Test func providerListNotEmpty() {
        #expect(LLMProvider.builtin.count == 3)
        #expect(LLMProvider.builtin.map(\.name).contains("DeepSeek"))
    }

    @Test func messageRoundTrip() throws {
        let m = ChatMessage(role: .user, content: "hello", createdAt: Date())
        let data = try JSONEncoder().encode(m)
        let back = try JSONDecoder().decode(ChatMessage.self, from: data)
        #expect(back.content == "hello")
        #expect(back.role == .user)
    }

    @Test func configBuildsFromDefaults() {
        let cfg = LLMConfig(baseURL: "https://api.example.com/v1",
                           apiKey: "sk-test",
                           modelName: "gpt-4o-mini",
                           temperature: 0.7,
                           maxTokens: 2048)
        #expect(cfg.baseURL.hasSuffix("/v1"))
        #expect(cfg.maxTokens == 2048)
    }

    @Test func errorDescriptions() {
        #expect(AppError.invalidAPIKey.errorDescription?.isEmpty == false)
        #expect(AppError.httpStatus(429, "").errorDescription?.contains("429") == true)
    }
}
