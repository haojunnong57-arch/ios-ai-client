import Foundation
import SwiftUI

enum AppThemeMode: String, CaseIterable, Identifiable {
    case system, light, dark
    var id: String { rawValue }
    var title: String {
        switch self {
        case .system: return "跟随系统"
        case .light: return "浅色"
        case .dark: return "深色"
        }
    }
}

@MainActor
final class AppSettings: ObservableObject {
    static let shared = AppSettings()

    @Published var selectedProviderIndex: Int { didSet { persist() } }
    @Published var systemPrompt: String { didSet { persist() } }
    @Published var enableWebSearch: Bool { didSet { persist() } }
    @Published var customBaseURL: String { didSet { persist() } }
    @Published var customModelName: String { didSet { persist() } }
    @Published var useCustomEndpoint: Bool { didSet { persist() } }
    @Published var themeMode: AppThemeMode { didSet { persist() } }

    private let defaults = UserDefaults.standard
    private let key = "app_settings_v4"

    private init() {
        if let data = defaults.dictionary(forKey: key) {
            self.selectedProviderIndex = data["providerIndex"] as? Int ?? 0
            self.systemPrompt = data["sysPrompt"] as? String ?? "你是一个有帮助的中文 AI 助手。回答时如果使用了联网搜索资料，请在末尾列出参考来源。"
            self.enableWebSearch = data["webSearch"] as? Bool ?? false
            self.customBaseURL = data["customBase"] as? String ?? ""
            self.customModelName = data["customModel"] as? String ?? ""
            self.useCustomEndpoint = data["useCustom"] as? Bool ?? false
            if let t = data["theme"] as? String, let mode = AppThemeMode(rawValue: t) {
                self.themeMode = mode
            } else {
                self.themeMode = .system
            }
        } else {
            self.selectedProviderIndex = 0
            self.systemPrompt = "你是一个有帮助的中文 AI 助手。回答时如果使用了联网搜索资料，请在末尾列出参考来源。"
            self.enableWebSearch = false
            self.customBaseURL = ""
            self.customModelName = ""
            self.useCustomEndpoint = false
            self.themeMode = .system
        }
        if selectedProviderIndex >= LLMProvider.builtin.count {
            selectedProviderIndex = 0
        }
    }

    private func persist() {
        defaults.set([
            "providerIndex": selectedProviderIndex,
            "sysPrompt": systemPrompt,
            "webSearch": enableWebSearch,
            "customBase": customBaseURL,
            "customModel": customModelName,
            "useCustom": useCustomEndpoint,
            "theme": themeMode.rawValue
        ], forKey: key)
    }

    var resolvedColorScheme: ColorScheme? {
        switch themeMode {
        case .system: return nil
        case .light: return .light
        case .dark: return .dark
        }
    }

    var provider: LLMProvider {
        let idx = min(max(0, selectedProviderIndex), LLMProvider.builtin.count - 1)
        return LLMProvider.builtin[idx]
    }

    func currentConfig() -> LLMConfig {
        let p = provider
        let key = KeychainManager.shared.get(p.placeholderKey) ?? ""
        let base: String
        let model: String
        if useCustomEndpoint {
            base = customBaseURL.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
                ? p.defaultBaseURL
                : customBaseURL.trimmingCharacters(in: .whitespacesAndNewlines)
            model = customModelName.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
                ? p.defaultModel
                : customModelName.trimmingCharacters(in: .whitespacesAndNewlines)
        } else {
            base = p.defaultBaseURL
            model = p.defaultModel
        }
        return LLMConfig(baseURL: base,
                        apiKey: key,
                        modelName: model,
                        temperature: 0.7,
                        maxTokens: 2048)
    }
}
