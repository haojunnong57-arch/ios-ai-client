import SwiftUI

struct SettingsView: View {
    @EnvironmentObject var settings: AppSettings
    @EnvironmentObject var store: SessionStore

    private var appVersion: String {
        let short = Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "2.0"
        let build = Bundle.main.infoDictionary?["CFBundleVersion"] as? String ?? "2"
        return "\(short) (\(build))"
    }

    var body: some View {
        NavigationStack {
            Form {
                Section("系统提示词") {
                    TextEditor(text: $settings.systemPrompt).frame(minHeight: 88)
                }
                Section("数据") {
                    LabeledContent("已保存会话", value: "\(store.sessions.count)")
                    Button(role: .destructive) {
                        store.sessions.removeAll()
                        store.save()
                    } label: { Label("清空全部会话", systemImage: "trash") }
                }
                Section("关于") {
                    LabeledContent("App", value: "AI 聚合客户端")
                    LabeledContent("版本", value: appVersion)
                    LabeledContent("构建", value: "GitHub Actions macOS Runner")
                    LabeledContent("签名", value: "未签名，需第三方重签安装")
                }
            }
            .navigationTitle("设置")
        }
    }
}
