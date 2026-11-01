import Foundation

struct LLMProvider: Identifiable, Equatable, Codable, Sendable, Hashable {
    var id: String { name }
    let name: String
    let defaultBaseURL: String
    let defaultModel: String
    let placeholderKey: String
    let isLocal: Bool

    static let builtin: [LLMProvider] = [
        LLMProvider(name: "OpenAI",
                    defaultBaseURL: "https://api.openai.com/v1",
                    defaultModel: "gpt-4o-mini",
                    placeholderKey: "openai_api_key",
                    isLocal: false),
        LLMProvider(name: "DeepSeek",
                    defaultBaseURL: "https://api.deepseek.com/v1",
                    defaultModel: "deepseek-chat",
                    placeholderKey: "deepseek_api_key",
                    isLocal: false),
        LLMProvider(name: "通义千问 Qwen",
                    defaultBaseURL: "https://dashscope.aliyuncs.com/compatible-mode/v1",
                    defaultModel: "qwen-turbo",
                    placeholderKey: "qwen_api_key",
                    isLocal: false),
        // 内置本地 / 局域网支持：优先用于 ~7B 无对齐模型（DeepSeek / Qwen abliterated 等）
        // 用户可在局域网运行 Ollama / LM Studio / vLLM / 本地 DeepSeek-R1-Distill 等 OpenAI 兼容服务
        LLMProvider(name: "本地 / 局域网 (7B级)",
                    defaultBaseURL: "http://127.0.0.1:11434/v1",
                    defaultModel: "deepseek-r1:7b",
                    placeholderKey: "local_api_key",
                    isLocal: true),
        LLMProvider(name: "自定义 OpenAI 兼容",
                    defaultBaseURL: "http://192.168.1.100:8000/v1",
                    defaultModel: "qwen2.5:7b",
                    placeholderKey: "custom_api_key",
                    isLocal: true)
    ]
}

struct LLMConfig: Equatable, Codable, Sendable {
    var baseURL: String
    var apiKey: String
    var modelName: String
    var temperature: Double
    var maxTokens: Int
}
