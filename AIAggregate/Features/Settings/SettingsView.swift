import SwiftUI

struct SettingsView: View {
    @EnvironmentObject var settings: AppSettings
    @EnvironmentObject var store: SessionStore
    @State private var historyCleared = false

    private var appVersion: String {
        let short = Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "2.6"
        let build = Bundle.main.infoDictionary?["CFBundleVersion"] as? String ?? "1"
        return "\(short) (\(build))"
    }

    var body: some View {
        Form {
            Section("外观") {
                Picker("主题", selection: $settings.themeMode) {
                    ForEach(AppThemeMode.allCases) { mode in
                        Text(mode.title).tag(mode)
                    }
                }
            }

            Section("系统提示词") {
                TextEditor(text: $settings.systemPrompt)
                    .frame(minHeight: 80)
            }

            Section("联网搜索") {
                Toggle("默认开启联网搜索", isOn: $settings.enableWebSearch)
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

            Section("关于") {
                LabeledContent("App", value: "LocalGPT")
                LabeledContent("版本", value: appVersion)
                LabeledContent("构建", value: "GitHub Actions")
            }
        }
        .navigationTitle("设置")
    }
}
