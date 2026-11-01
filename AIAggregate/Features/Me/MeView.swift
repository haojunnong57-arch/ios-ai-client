import SwiftUI

struct MeView: View {
    var body: some View {
        NavigationStack {
            List {
                Section("账号与模型") {
                    NavigationLink {
                        ModelsView()
                    } label: {
                        Label("API 设置", systemImage: "key.fill")
                    }
                    NavigationLink {
                        SettingsView()
                    } label: {
                        Label("应用设置", systemImage: "gearshape.fill")
                    }
                }

                Section("扩展（规划中）") {
                    NavigationLink {
                        AgentHubView()
                    } label: {
                        Label("AI 工作台 / 电脑控制", systemImage: "desktopcomputer")
                    }
                    NavigationLink {
                        GitHubConnectorView()
                    } label: {
                        Label("GitHub 连接器", systemImage: "chevron.left.forwardslash.chevron.right")
                    }
                }
            }
            .listStyle(.insetGrouped)
            .navigationTitle("我的")
        }
    }
}
