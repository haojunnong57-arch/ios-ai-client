import SwiftUI

struct MessageRow: View {
    let message: ChatMessage

    var body: some View {
        HStack {
            if message.role == .user { Spacer(minLength: 40) }
            VStack(alignment: .leading, spacing: 4) {
                if message.role == .assistant {
                    Text("AI").font(.caption2.weight(.semibold)).foregroundStyle(.secondary)
                }
                Text(message.displayText)
                    .textSelection(.enabled)
                    .padding(10)
                    .background(message.role == .user ? AnyShapeStyle(Color.accentColor) : AnyShapeStyle(Color.secondary.opacity(0.12)),
                                in: RoundedRectangle(cornerRadius: 14))
                    .foregroundStyle(message.role == .user ? Color.white : Color.primary)
            }
            if message.role == .assistant { Spacer(minLength: 40) }
        }
    }
}

private extension ChatMessage {
    var displayText: String {
        if isStreaming && content.isEmpty { return "正在输入…" }
        return content
    }
}
