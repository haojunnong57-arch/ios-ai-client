import SwiftUI

struct RootView: View {
    @EnvironmentObject var store: SessionStore
    @EnvironmentObject var settings: AppSettings
    @State private var activeTab: RootTab = .chat
    @State private var currentSessionID: UUID?

    enum RootTab: String, CaseIterable {
        case chat, models, settings
    }

    var body: some View {
        TabView(selection: $activeTab) {
            ChatContainerView(
                sessionID: $currentSessionID,
                onGoModels: { activeTab = .models }
            )
            .tabItem { Label("对话", systemImage: "bubble.left.and.bubble.right") }
            .tag(RootTab.chat)

            ModelsView()
                .tabItem { Label("模型", systemImage: "cube.transparent") }
                .tag(RootTab.models)

            SettingsView()
                .tabItem { Label("设置", systemImage: "gearshape") }
                .tag(RootTab.settings)
        }
        .tint(.accentColor)
    }
}
