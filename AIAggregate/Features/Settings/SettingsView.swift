import SwiftUI

struct SettingsView: View {
    @EnvironmentObject var settings: AppSettings
    @EnvironmentObject var store: SessionStore
    @State private var historyCleared = false

    private var appVersion: String {
        let short = Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "2.7"
        let build = Bundle.main.infoDictionary?["CFBundleVersion"] as? String ?? "1"
        return "\(short) (\(build))"
    }

    var body: some View {
        Form {
            Section("外观与颜色") {
                Picker("主题", selection: $settings.themeMode) {
                    ForEach(AppThemeMode.allCases) { mode in
                        Text(mode.title).tag(mode)
                    }
                }
                Picker("强调色", selection: $settings.accentPalette) {
                    ForEach(AccentPalette.allCases) { p in
                        HStack {
                            Circle().fill(p.color).frame(width: 12, height: 12)
                            Text(p.title)
                        }.tag(p)
                    }
                }
                HStack {
                    Text("预览")
                    Spacer()
                    Capsule()
                        .fill(settings.accentPalette.color.gradient)
                        .frame(width: 72, height: 28)
                    Image(systemName: "bubble.left.and.bubble.right.fill")
                        .foregroundStyle(settings.accentPalette.color)
                }
                Button("恢复默认外观") {
                    settings.themeMode = .system
                    settings.accentPalette = .systemBlue
                }
            }

            Section("系统提示词") {
                TextEditor(text: $settings.systemPrompt)
                    .frame(minHeight: 80)
            }

            Section("联网搜索") {
                Toggle("对话默认开启联网搜索", isOn: $settings.enableWebSearch)
                Text("搜索使用 DuckDuckGo + 维基百科免费接口，无需搜索 Key。失败时会显示明确原因，不返回假结果。")
                    .font(.footnote)
                    .foregroundStyle(.secondary)
            }

            Section("数据与记录") {
                LabeledContent("已保存会话", value: "\(store.sessions.count)")
                Button {
                    UserDefaults.standard.removeObject(forKey: "search_history")
                    historyCleared = true
                    DispatchQueue.main.asyncAfter(deadline: .now() + 2) { historyCleared = false }
                } label: {
                    Label("清空搜索历史", systemImage: "trash")
                }
                if historyCleared {
                    Text("搜索历史已清空").font(.footnote).foregroundStyle(.green)
                }
                Button(role: .destructive) {
                    store.sessions.removeAll()
                    store.save()
                } label: {
                    Label("清空全部对话", systemImage: "trash")
                }
            }

            Section("安全说明") {
                Text("• API Key / GitHub Token 仅存本机 Keychain\n• 不会上传密钥到 GitHub\n• 自定义 HTTP 端点仅用于你主动填写的地址\n• 电脑控制未开放自动执行，无远程控权\n• 若曾在聊天中发送过密钥，建议在服务商处轮换")
                    .font(.footnote)
                    .foregroundStyle(.secondary)
            }

            Section("关于") {
                LabeledContent("App", value: "LocalGPT")
                LabeledContent("版本", value: appVersion)
            }
        }
        .navigationTitle("设置")
    }
}
