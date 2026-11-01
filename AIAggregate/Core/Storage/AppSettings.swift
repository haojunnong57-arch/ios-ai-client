import Foundation

@MainActor
final class AppSettings: ObservableObject {
    static let shared = AppSettings()

    @Published var selectedProviderIndex: Int { didSet { persist() } }
    @Published var systemPrompt: String { didSet { persist() } }
    @Published var enableWebSearch: Bool { didSet { persist() } }

    private let defaults = UserDefaults.standard
    private let key = "app_settings_v2"

    private init() {
        if let data = defaults.dictionary(forKey: key) {
            self.selectedProviderIndex = data["providerIndex"] as? Int ?? 0
            self.systemPrompt = data["sysPrompt"] as? String ?? "你是一个有帮助的中文 AI 助手。回答时如果使用了联网搜索资料，请在末尾列出参考来源。"
            self.enableWebSearch = data["webSearch"] as? Bool ?? false
        } else {
            self.selectedProviderIndex = 0
            self.systemPrompt = "你是一个有帮助的中文 AI 助手。回答时如果使用了联网搜索资料，请在末尾列出参考来源。"
            self.enableWebSearch = false
        }
        // Clamp index in case provider list shrank
        if selectedProviderIndex >= LLMProvider.builtin.count {
            selectedProviderIndex = 0
        }
    }

    private func persist() {
        defaults.set([
            "providerIndex": selectedProviderIndex,
            "sysPrompt": systemPrompt,
            "webSearch": enableWebSearch
        ], forKey: key)
    }

    var provider: LLMProvider {
        let idx = min(max(0, selectedProviderIndex), LLMProvider.builtin.count - 1)
        return LLMProvider.builtin[idx]
    }

    func currentConfig() -> LLMConfig {
        let key = KeychainManager.shared.get(provider.placeholderKey) ?? ""
        return LLMConfig(baseURL: provider.defaultBaseURL,
                        apiKey: key,
                        modelName: provider.defaultModel,
                        temperature: 0.7,
                        maxTokens: 2048)
    }
}
