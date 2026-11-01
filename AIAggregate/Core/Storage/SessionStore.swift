import Foundation

@MainActor
final class SessionStore: ObservableObject {
    @Published var sessions: [ChatSession] = []

    private let fileURL: URL = {
        let dir = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0]
        return dir.appendingPathComponent("sessions.json")
    }()

    init() { load() }

    func load() {
        guard let data = try? Data(contentsOf: fileURL),
              let decoded = try? JSONDecoder().decode([ChatSession].self, from: data) else {
            sessions = []; return
        }
        sessions = decoded
    }

    func save() {
        guard let data = try? JSONEncoder().encode(sessions) else { return }
        try? data.write(to: fileURL, options: .atomic)
    }

    func newSession(modelID: String) -> ChatSession {
        let s = ChatSession(title: "新对话", modelID: modelID, messages: [], updatedAt: Date())
        sessions.insert(s, at: 0)
        save()
        return s
    }

    func delete(_ id: UUID) {
        sessions.removeAll { $0.id == id }
        save()
    }

    func update(_ session: ChatSession) {
        if let i = sessions.firstIndex(where: { $0.id == session.id }) {
            var s = session
            s.updatedAt = Date()
            sessions[i] = s
            save()
        }
    }
}
