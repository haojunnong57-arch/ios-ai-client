import SwiftUI

/// GitHub 连接器骨架。完整 OAuth 需要你在 GitHub 创建 OAuth App 并提供 Client ID。
struct GitHubConnectorView: View {
    @State private var token = ""
    @State private var status = "未连接"

    var body: some View {
        Form {
            Section("连接方式") {
                Text("推荐使用 GitHub Personal Access Token（只读 public_repo / repo 视需求）。Token 仅存本机 Keychain。")
                    .font(.footnote)
                    .foregroundStyle(.secondary)
                SecureField("ghp_... 或 github_pat_...", text: $token)
                    .textInputAutocapitalization(.never)
                    .autocorrectionDisabled()
                Button("保存 Token") {
                    let t = token.trimmingCharacters(in: .whitespacesAndNewlines)
                    guard !t.isEmpty else { return }
                    KeychainManager.shared.set("github_token", value: t)
                    status = "已保存到本机"
                }
                LabeledContent("状态", value: status)
            }

            Section("能力规划") {
                Text("已规划：仓库列表、目录浏览、README、Issues/PR 只读分析。\n写入（提交/推送）将要求二次确认，并使用最小权限。")
                    .font(.footnote)
                    .foregroundStyle(.secondary)
            }
        }
        .navigationTitle("GitHub")
        .onAppear {
            if let t = KeychainManager.shared.get("github_token"), !t.isEmpty {
                status = "本机已有 Token"
                token = t
            }
        }
    }
}
