import Foundation

@MainActor
final class ChatViewModel: ObservableObject {
    @Published var session: ChatSession
    @Published var inputText: String = ""
    @Published var isGenerating = false
    @Published var isSearching = false
    @Published var errorMessage: String?
    @Published var lastSearchSources: [SearchResult] = []

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

        let config = settings.currentConfig()
        if config.apiKey.trimmingCharacters(in: .whitespaces).isEmpty {
            errorMessage = "请先到「模型」页填写并保存 API Key"
            return
        }

        inputText = ""
        errorMessage = nil
        lastSearchSources = []

        var msgs = session.messages
        msgs.append(ChatMessage(role: .user, content: text, createdAt: Date()))
        if !settings.systemPrompt.isEmpty,
           !msgs.contains(where: { $0.role == .system }) {
            msgs.insert(ChatMessage(role: .system, content: settings.systemPrompt, createdAt: Date()), at: 0)
        }
        msgs.append(ChatMessage(role: .assistant, content: "", createdAt: Date(), isStreaming: true))
        session.messages = msgs
        isGenerating = true

        let useSearch = settings.enableWebSearch
        let finalConfig = config

        generateTask = Task {
            var messagesForModel = msgs

            if useSearch {
                isSearching = true
                do {
                    let results = try await WebSearchService.shared.search(query: text, limit: 5)
                    lastSearchSources = results
                    if !results.isEmpty {
                        let searchContext = await WebSearchService.shared.formatForPrompt(results)
                        // Inject search context as a system message before the last user message
                        if let lastUserIdx = messagesForModel.lastIndex(where: { $0.role == .user }) {
                            messagesForModel.insert(
                                ChatMessage(role: .system, content: searchContext, createdAt: Date()),
                                at: lastUserIdx
                            )
                        }
                    }
                } catch {
                    // Search failure should not block the answer
                    errorMessage = "搜索失败（仍尝试直接回答）：\(error.localizedDescription)"
                }
                isSearching = false
            }

            do {
                let stream = try await client.streamChat(messages: messagesForModel, config: finalConfig)
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
                // Append sources if any
                if !lastSearchSources.isEmpty {
                    var sourceText = "\n\n参考来源：\n"
                    for (idx, s) in lastSearchSources.enumerated() {
                        sourceText += "\(idx+1). \(s.title)\n   \(s.url)\n"
                    }
                    session.messages[i].content += sourceText
                }
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
        isSearching = false
        if let i = session.messages.lastIndex(where: { $0.isStreaming }) {
            session.messages[i].isStreaming = false
        }
    }

    func regenerate() {
        guard !isGenerating else { return }
        if let lastIdx = session.messages.lastIndex(where: { $0.role == .assistant }) {
            session.messages.remove(at: lastIdx)
        }
        if let lastUser = session.messages.last(where: { $0.role == .user }) {
            inputText = lastUser.content
            session.messages.removeAll(where: { $0.id == lastUser.id })
            send()
        }
    }
}
