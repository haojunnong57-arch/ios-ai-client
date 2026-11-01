import SwiftUI

struct SettingsView: View {
    @EnvironmentObject var settings: AppSettings
    @EnvironmentObject var store: SessionStore
    @State private var historyCleared = false

    private var appVersion: String {
        let short = Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "2.5"
        let build = Bundle.main.infoDictionary?["CFBundleVersion"] as? String ?? "1"
        return "\(short) (\(build))"
    }

    var body: some View {
        NavigationStack {
            Form {
                Section("系统提示词") {
                    TextEditor(text: $settings.systemPrompt)
                        .frame(minHeight: 80)
                }

                Section("联网搜索") {
                    Toggle("默认开启联网搜索", isOn: $settings.enableWebSearch)
                    Text("开启后，发送消息时会先搜索互联网，再把结果交给 AI 整理回答。")
                        .font(.footnote)
                        .foregroundStyle(.secondary)
                }

                Section("数据与记录") {
                    LabeledContent("已保存会话", value: "\(store.sessions.count)")
                    Button {
                        UserDefaults.standard.removeObject(forKey: "search_history")
                        historyCleared = true
                        DispatchQueue.main.asyncAfter(deadline: .now() + 2) {
                            historyCleared = false
                        }
                    } label: {
                        Label("清空搜索历史", systemImage: "trash")
                    }
                    if historyCleared {
                        Text("搜索历史已清空")
                            .font(.footnote)
                            .foregroundStyle(.green)
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
                    LabeledContent("签名", value: "未签名，需全能签重签")
                }
            }
            .navigationTitle("设置")
        }
    }
}
