import Foundation

@MainActor
final class ChatViewModel: ObservableObject {
    @Published var session: ChatSession
    @Published var inputText: String = ""
    @Published var isGenerating = false
    @Published var errorMessage: String?

    private let client: LLMClient
    private var settings: AppSettings?
    private var store: SessionStore?
    private var generateTask: Task<Void, Never>?

    init(session: ChatSession, client: LLMClient = OpenAIStreamingClient()) {
        self.session = session
        self.client = client
    }

    func wire(store: SessionStore, settings: AppSettings) {
        self.store = store
        self.settings = settings
    }

    func send() {
        guard let settings, let store else { return }
        let text = inputText.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !text.isEmpty, !isGenerating else { return }
        inputText = ""
        errorMessage = nil

        var msgs = session.messages
        msgs.append(ChatMessage(role: .user, content: text, createdAt: Date()))
        if !settings.systemPrompt.isEmpty,
           !msgs.contains(where: { $0.role == .system }) {
            msgs.insert(ChatMessage(role: .system, content: settings.systemPrompt, createdAt: Date()), at: 0)
        }
        msgs.append(ChatMessage(role: .assistant, content: "", createdAt: Date(), isStreaming: true))
        session.messages = msgs
        isGenerating = true

        let config = settings.currentConfig()
        generateTask = Task {
            do {
                let stream = try await client.streamChat(messages: msgs, config: config)
                for try await partial in stream {
                    if Task.isCancelled { break }
                    if let i = session.messages.lastIndex(where: { $0.role == .assistant && $0.isStreaming }) {
                        session.messages[i].content += partial
                    }
                }
            } catch let e as AppError {
                errorMessage = e.localizedDescription
            } catch {
                errorMessage = error.localizedDescription
            }
            if let i = session.messages.lastIndex(where: { $0.isStreaming }) {
                session.messages[i].isStreaming = false
            }
            isGenerating = false
            if session.title == "新对话",
               let firstUser = session.messages.first(where: { $0.role == .user }) {
                session.title = String(firstUser.content.prefix(20))
            }
            store.update(session)
        }
    }

    func stop() {
        generateTask?.cancel()
        generateTask = nil
        isGenerating = false
        if let i = session.messages.lastIndex(where: { $0.isStreaming }) {
            session.messages[i].isStreaming = false
        }
    }

    func regenerate() {
        guard !isGenerating else { return }
        session.messages.removeAll(where: { $0.role == .assistant && !$0.content.isEmpty })
        send()
    }
}
