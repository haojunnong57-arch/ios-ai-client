import SwiftUI

struct ChatContainerView: View {
    @EnvironmentObject var store: SessionStore
    @EnvironmentObject var settings: AppSettings
    @Binding var sessionID: UUID?
    let onGoModels: () -> Void
    @State private var showVoice = false

    var body: some View {
        NavigationStack {
            Group {
                if let sid = sessionID,
                   let idx = store.sessions.firstIndex(where: { $0.id == sid }) {
                    ChatView(session: store.sessions[idx], showVoice: $showVoice)
                } else {
                    EmptyChatView(
                        onStart: startNewChat,
                        onGoModels: onGoModels,
                        onStartVoice: startVoiceChat
                    )
                }
            }
            .navigationTitle("AI 助手")
            .navigationBarTitleDisplayMode(.large)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    HStack(spacing: 12) {
                        Button {
                            startVoiceChat()
                        } label: {
                            Image(systemName: "waveform.circle.fill")
                                .font(.title3)
                        }
                        .accessibilityLabel("语音通话")

                        Menu {
                            Button {
                                if let sid = sessionID { store.delete(sid) }
                                sessionID = nil
                            } label: { Label("删除当前对话", systemImage: "trash") }
                            Button { startNewChat() } label: { Label("新建对话", systemImage: "square.and.pencil") }
                        } label: {
                            Image(systemName: "ellipsis.circle")
                        }
                    }
                }
            }
            .fullScreenCover(isPresented: $showVoice) {
                if let sid = sessionID,
                   let idx = store.sessions.firstIndex(where: { $0.id == sid }) {
                    VoiceCallView(session: store.sessions[idx])
                        .environmentObject(store)
                        .environmentObject(settings)
                }
            }
        }
    }

    private func startNewChat() {
        let s = store.newSession(modelID: settings.provider.defaultModel)
        sessionID = s.id
    }

    private func startVoiceChat() {
        if sessionID == nil {
            startNewChat()
        }
        showVoice = true
    }
}
