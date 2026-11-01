import SwiftUI

/// 电脑控制 / Agent 工作台骨架。
/// 说明：完整 Computer Use 需要本地 Agent 或官方 Computer Use API，
/// 本页先提供状态面板与架构入口，不伪造已连接的云电脑。
struct AgentHubView: View {
    var body: some View {
        List {
            Section("当前状态") {
                LabeledContent("AI 模型") {
                    Text(AppSettings.shared.provider.name)
                }
                LabeledContent("云电脑") {
                    Text("未连接").foregroundStyle(.secondary)
                }
                LabeledContent("本地电脑") {
                    Text("未配对").foregroundStyle(.secondary)
                }
            }

            Section("说明") {
                Text("电脑控制（点击、看屏幕、操作桌面）不能由 iOS App 单独完成，需要：\n\n1. 本地电脑运行受控 Agent 服务（推荐）\n2. 或官方 Computer Use / 云桌面 API（Grok、豆包等通常不向第三方开放完整桌面控制）\n\n当前版本已预留工作台界面与调度架构。你提供可用的本地 Agent 地址或官方 API 后，可继续对接。")
                    .font(.footnote)
                    .foregroundStyle(.secondary)
            }

            Section("安全") {
                Text("不会在未授权情况下访问你的电脑。写入、点击、推送等操作需要明确确认。")
                    .font(.footnote)
                    .foregroundStyle(.secondary)
            }
        }
        .navigationTitle("AI 工作台")
    }
}
