import Foundation

struct LLMProvider: Identifiable, Equatable, Codable, Sendable, Hashable {
    var id: String { name }
    let name: String
    let defaultBaseURL: String
    let defaultModel: String
    let placeholderKey: String

    static let builtin: [LLMProvider] = [
        LLMProvider(name: "DeepSeek",
                    defaultBaseURL: "https://api.deepseek.com/v1",
                    defaultModel: "deepseek-flash",
                    placeholderKey: "deepseek_api_key"),
        LLMProvider(name: "OpenAI",
                    defaultBaseURL: "https://api.openai.com/v1",
                    defaultModel: "gpt-4o-mini",
                    placeholderKey: "openai_api_key"),
        LLMProvider(name: "通义千问 Qwen",
                    defaultBaseURL: "https://dashscope.aliyuncs.com/compatible-mode/v1",
                    defaultModel: "qwen-turbo",
                    placeholderKey: "qwen_api_key"),
        LLMProvider(name: "自定义 OpenAI 兼容",
                    defaultBaseURL: "https://moonshot.kk18.chat/v1",
                    defaultModel: "deepseek-v4.1-flash-1017",
                    placeholderKey: "custom_api_key")
    ]
}

struct LLMConfig: Equatable, Codable, Sendable {
    var baseURL: String
    var apiKey: String
    var modelName: String
    var temperature: Double
    var maxTokens: Int
}
