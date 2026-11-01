import SwiftUI

struct ChatContainerView: View {
    @EnvironmentObject var store: SessionStore
    @EnvironmentObject var settings: AppSettings
    @Binding var sessionID: UUID?
    let onGoModels: () -> Void

    var body: some View {
        NavigationStack {
            Group {
                if let sid = sessionID,
                   let idx = store.sessions.firstIndex(where: { $0.id == sid }) {
                    ChatView(session: store.sessions[idx])
                } else {
                    EmptyChatView(onStart: startNewChat, onGoModels: onGoModels)
                }
            }
            .navigationTitle("AI 助手")
            .navigationBarTitleDisplayMode(.large)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Menu {
                        Button {
                            if let sid = sessionID { store.delete(sid) }
                            sessionID = nil
                        } label: { Label("删除当前对话", systemImage: "trash") }
                        Button { startNewChat() } label: { Label("新建对话", systemImage: "square.and.pencil") }
                    } label: { Image(systemName: "ellipsis.circle") }
                }
            }
        }
    }

    private func startNewChat() {
        let s = store.newSession(modelID: settings.provider.defaultModel)
        sessionID = s.id
    }
}
