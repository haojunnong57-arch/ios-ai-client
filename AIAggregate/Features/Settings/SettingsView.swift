import SwiftUI

struct SettingsView: View {
    @EnvironmentObject var settings: AppSettings
    @EnvironmentObject var store: SessionStore

    private var appVersion: String {
        let short = Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "2.3"
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
                    Text("开启后，发送消息时会先搜索互联网，再把结果交给 AI 整理回答，并在底部显示来源链接。搜索使用免费 DuckDuckGo，无需额外 Key。")
                        .font(.footnote)
                        .foregroundStyle(.secondary)
                }

                Section("数据") {
                    LabeledContent("已保存会话", value: "\(store.sessions.count)")
                    Button(role: .destructive) {
                        store.sessions.removeAll()
                        store.save()
                    } label: {
                        Label("清空全部会话", systemImage: "trash")
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
