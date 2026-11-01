import SwiftUI

struct SettingsView: View {
    @EnvironmentObject var settings: AppSettings
    @EnvironmentObject var store: SessionStore

    private var appVersion: String {
        let short = Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "2.1"
        let build = Bundle.main.infoDictionary?["CFBundleVersion"] as? String ?? "3"
        return "\(short) (\(build))"
    }

    var body: some View {
        NavigationStack {
            Form {
                Section("系统提示词") {
                    TextEditor(text: $settings.systemPrompt)
                        .frame(minHeight: 88)
                        .font(.body)
                }

                Section("内置本地大模型 (~7B)") {
                    Text("已内置「本地 / 局域网 (7B级)」服务商。推荐在电脑或同一 Wi-Fi 设备上运行：")
                        .font(.footnote)
                    Text("• Ollama：ollama run deepseek-r1:7b 或 qwen2.5:7b\n• 无对齐版本：可从 HuggingFace 搜索 abliterated / uncensored Qwen / DeepSeek 7B 后导入 Ollama\n• 默认地址 http://127.0.0.1:11434/v1（模拟器）或局域网 IP:端口\n• 支持流式输出，API Key 可留空")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                    Text("真机请把 Base URL 改成电脑的局域网 IP，并确保已授权「本地网络」权限。")
                        .font(.caption2)
                        .foregroundStyle(.orange)
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

                Section("权限与联网") {
                    Text("本版本已声明本地网络、麦克风、相机、相册权限，并允许任意网络负载（含 HTTP 局域网）。首次使用本地模型时系统会弹出「本地网络」授权，请点击允许。")
                        .font(.footnote)
                        .foregroundStyle(.secondary)
                }

                Section("关于") {
                    LabeledContent("App", value: "AI 聚合客户端")
                    LabeledContent("版本", value: appVersion)
                    LabeledContent("目标设备", value: "iPhone Air 6.5\" (2736×1260) 及全系自适应")
                    LabeledContent("构建", value: "GitHub Actions macOS Runner")
                    LabeledContent("签名", value: "未签名，需第三方重签安装")
                }
            }
            .navigationTitle("设置")
        }
    }
}
