import SwiftUI

struct HistoryView: View {
    @EnvironmentObject var store: SessionStore
    @Binding var sessionID: UUID?
    let onSelectChat: () -> Void

    var body: some View {
        NavigationStack {
            Group {
                if store.sessions.isEmpty {
                    ContentUnavailableView("暂无历史对话", systemImage: "clock", description: Text("开始新对话后会显示在这里"))
                } else {
                    List {
                        ForEach(store.sessions) { session in
                            Button {
                                sessionID = session.id
                                onSelectChat()
                            } label: {
                                VStack(alignment: .leading, spacing: 4) {
                                    Text(session.title)
                                        .font(.headline)
                                        .foregroundStyle(.primary)
                                    Text(session.updatedAt.formatted(date: .abbreviated, time: .shortened))
                                        .font(.caption)
                                        .foregroundStyle(.secondary)
                                }
                                .padding(.vertical, 4)
                            }
                        }
                        .onDelete { indexSet in
                            for i in indexSet {
                                store.delete(store.sessions[i].id)
                            }
                            if let sid = sessionID, !store.sessions.contains(where: { $0.id == sid }) {
                                sessionID = nil
                            }
                        }
                    }
                    .listStyle(.insetGrouped)
                }
            }
            .navigationTitle("历史记录")
        }
    }
}
