import SwiftUI

struct MessageRow: View {
    let message: ChatMessage

    var body: some View {
        HStack {
            if message.role == .user { Spacer(minLength: 32) }

            VStack(alignment: message.role == .user ? .trailing : .leading, spacing: 4) {
                if message.role == .assistant {
                    Text("AI").font(.caption2.weight(.semibold)).foregroundStyle(.secondary)
                }
                Text(message.displayText)
                    .textSelection(.enabled)
                    .multilineTextAlignment(message.role == .user ? .trailing : .leading)
                    .padding(10)
                    .background(
                        message.role == .user ? AnyShapeStyle(Color.accentColor) : AnyShapeStyle(Color.secondary.opacity(0.12)),
                        in: RoundedRectangle(cornerRadius: 14)
                    )
                    .foregroundStyle(message.role == .user ? Color.white : Color.primary)
            }
            .frame(maxWidth: .infinity, alignment: message.role == .user ? .trailing : .leading)

            if message.role == .assistant { Spacer(minLength: 32) }
        }
        .padding(.vertical, 2)
    }
}

private extension ChatMessage {
    var displayText: String {
        if isStreaming && content.isEmpty { return "正在输入…" }
        return content
    }
}
