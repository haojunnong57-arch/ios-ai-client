import Foundation

@MainActor
final class AppSettings: ObservableObject {
    static let shared = AppSettings()

    @Published var selectedProviderIndex: Int { didSet { persist() } }
    @Published var customBaseURL: String { didSet { persist() } }
    @Published var customModelName: String { didSet { persist() } }
    @Published var temperature: Double { didSet { persist() } }
    @Published var systemPrompt: String { didSet { persist() } }

    private let defaults = UserDefaults.standard
    private let key = "app_settings_v1"

    private init() {
        if let data = defaults.dictionary(forKey: key) {
            self.selectedProviderIndex = data["providerIndex"] as? Int ?? 0
            self.customBaseURL = data["customBase"] as? String ?? ""
            self.customModelName = data["customModel"] as? String ?? ""
            self.temperature = data["temp"] as? Double ?? 0.7
            self.systemPrompt = data["sysPrompt"] as? String ?? "你是一个有帮助的中文 AI 助手。"
        } else {
            self.selectedProviderIndex = 0
            self.customBaseURL = ""
            self.customModelName = ""
            self.temperature = 0.7
            self.systemPrompt = "你是一个有帮助的中文 AI 助手。"
        }
    }

    private func persist() {
        defaults.set([
            "providerIndex": selectedProviderIndex,
            "customBase": customBaseURL,
            "customModel": customModelName,
            "temp": temperature,
            "sysPrompt": systemPrompt
        ], forKey: key)
    }

    var provider: LLMProvider { LLMProvider.builtin[selectedProviderIndex] }

    func currentConfig() -> LLMConfig {
        let base = customBaseURL.isEmpty ? provider.defaultBaseURL : customBaseURL
        let model = customModelName.isEmpty ? provider.defaultModel : customModelName
        let key = KeychainManager.shared.get(provider.placeholderKey) ?? ""
        return LLMConfig(baseURL: base,
                        apiKey: key,
                        modelName: model,
                        temperature: temperature,
                        maxTokens: 2048)
    }
}
