import SwiftUI

struct SettingsView: View {
    @EnvironmentObject var settings: AppSettings
    @EnvironmentObject var store: SessionStore

    var body: some View {
        NavigationStack {
            Form {
                Section("系统提示词") {
                    TextEditor(text: $settings.systemPrompt).frame(minHeight: 80)
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
                    LabeledContent("版本", value: "0.1.0")
                    LabeledContent("构建", value: "GitHub Actions macOS Runner")
                }
            }
            .navigationTitle("设置")
        }
    }
}
