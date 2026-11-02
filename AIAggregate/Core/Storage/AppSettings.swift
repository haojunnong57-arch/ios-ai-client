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

enum AccentPalette: String, CaseIterable, Identifiable {
    case systemBlue, sky, mint, indigo, purple, pink, orange, graphite
    var id: String { rawValue }
    var title: String {
        switch self {
        case .systemBlue: return "系统蓝"
        case .sky: return "天空蓝"
        case .mint: return "薄荷绿"
        case .indigo: return "靛蓝"
        case .purple: return "薰衣草紫"
        case .pink: return "柔和粉"
        case .orange: return "日落橙"
        case .graphite: return "石墨灰"
        }
    }
    var color: Color {
        switch self {
        case .systemBlue: return .blue
        case .sky: return Color(red: 0.35, green: 0.62, blue: 0.95)
        case .mint: return Color(red: 0.35, green: 0.78, blue: 0.68)
        case .indigo: return Color(red: 0.42, green: 0.45, blue: 0.85)
        case .purple: return Color(red: 0.62, green: 0.48, blue: 0.85)
        case .pink: return Color(red: 0.92, green: 0.48, blue: 0.62)
        case .orange: return Color(red: 0.95, green: 0.55, blue: 0.30)
        case .graphite: return Color(red: 0.45, green: 0.48, blue: 0.52)
        }
    }
}

@MainActor
final class AppSettings: ObservableObject {
    static let shared = AppSettings()

    @Published var selectedProviderIndex: Int { didSet { persist() } }
    @Published var customDisplayName: String { didSet { persist() } }
    @Published var customBaseURL: String { didSet { persist() } }
    @Published var customAPIKey: String { didSet { persist() } }
    @Published var customModelID: String { didSet { persist() } }
    @Published var customProtocol: String { didSet { persist() } }
    @Published var customAPIPath: String { didSet { persist() } }
    @Published var systemPrompt: String { didSet { persist() } }
    @Published var enableWebSearch: Bool { didSet { persist() } }
    @Published var customModelName: String { didSet { persist() } }
    @Published var useCustomEndpoint: Bool { didSet { persist() } }
    @Published var themeMode: AppThemeMode { didSet { persist() } }
    @Published var accentPalette: AccentPalette { didSet { persist() } }

    private let defaults = UserDefaults.standard
    private let key = "app_settings_v6"

    private init() {
        if let data = defaults.dictionary(forKey: key) {
            self.selectedProviderIndex = data["providerIndex"] as? Int ?? 0
            self.customDisplayName = data["displayName"] as? String ?? "My AI"
            self.customBaseURL = data["customBase"] as? String ?? ""
            self.customAPIKey = data["customAPIKey"] as? String ?? ""
            self.customModelID = data["customModelId"] as? String ?? ""
            self.customProtocol = data["customProtocol"] as? String ?? "OpenAI Compatible"
            self.customAPIPath = data["customAPIPath"] as? String ?? ""
            self.systemPrompt = data["sysPrompt"] as? String ?? "你是一个有帮助的中文 AI 助手。回答时如果使用了联网搜索资料，请在末尾列出参考来源。"
            self.enableWebSearch = data["webSearch"] as? Bool ?? false
            self.customModelName = data["customModel"] as? String ?? ""
            self.useCustomEndpoint = data["useCustom"] as? Bool ?? true
            self.themeMode = AppThemeMode(rawValue: data["theme"] as? String ?? "") ?? .system
            self.accentPalette = AccentPalette(rawValue: data["accent"] as? String ?? "") ?? .systemBlue
        } else {
            self.selectedProviderIndex = 0
            self.customDisplayName = "My AI"
            self.customBaseURL = ""
            self.customAPIKey = ""
            self.customModelID = ""
            self.customProtocol = "OpenAI Compatible"
            self.customAPIPath = ""
            self.systemPrompt = "你是一个有帮助的中文 AI 助手。回答时如果使用了联网搜索资料，请在末尾列出参考来源。"
            self.enableWebSearch = false
            self.customModelName = ""
            self.useCustomEndpoint = true
            self.themeMode = .system
            self.accentPalette = .systemBlue
        }
        if selectedProviderIndex >= LLMProvider.builtin.count {
            selectedProviderIndex = 0
        }
        if customModelName.isEmpty, !customModelID.isEmpty {
            customModelName = customModelID
        }
        if customModelID.isEmpty, !customModelName.isEmpty {
            customModelID = customModelName
        }
    }

    private func persist() {
        defaults.set([
            "providerIndex": selectedProviderIndex,
            "displayName": customDisplayName,
            "customBase": customBaseURL,
            "customAPIKey": customAPIKey,
            "customModelId": customModelID,
            "customProtocol": customProtocol,
            "customAPIPath": customAPIPath,
            "sysPrompt": systemPrompt,
            "webSearch": enableWebSearch,
            "customModel": customModelName,
            "useCustom": useCustomEndpoint,
            "theme": themeMode.rawValue,
            "accent": accentPalette.rawValue
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
        let key = customAPIKey.isEmpty ? KeychainManager.shared.get(p.placeholderKey) ?? "" : customAPIKey
        let base = customBaseURL.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
            ? p.defaultBaseURL
            : customBaseURL.trimmingCharacters(in: .whitespacesAndNewlines)
        let modelID = customModelID.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
            ? (customModelName.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty ? p.defaultModel : customModelName)
            : customModelID.trimmingCharacters(in: .whitespacesAndNewlines)
        let displayName = customDisplayName.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty ? "My AI" : customDisplayName

        return LLMConfig(
            displayName: displayName,
            baseURL: base,
            apiKey: key,
            modelName: modelID,
            modelID: modelID,
            protocolType: customProtocol,
            apiPath: customAPIPath.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty ? nil : customAPIPath.trimmingCharacters(in: .whitespacesAndNewlines),
            temperature: 0.7,
            maxTokens: 2048
        )
    }
}
