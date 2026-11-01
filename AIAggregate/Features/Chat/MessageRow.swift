import SwiftUI

struct MessageRow: View {
    let message: ChatMessage
    var onCopy: (() -> Void)? = nil
    var onRegenerate: (() -> Void)? = nil
    var onEdit: ((String) -> Void)? = nil

    @State private var showEdit = false
    @State private var editText = ""

    var body: some View {
        HStack {
            if message.role == .user { Spacer(minLength: 40) }

            VStack(alignment: message.role == .user ? .trailing : .leading, spacing: 6) {
                if message.role == .assistant {
                    Text("AI")
                        .font(.caption2.weight(.semibold))
                        .foregroundStyle(.secondary)
                }

                Text(message.displayText)
                    .textSelection(.enabled)
                    .multilineTextAlignment(message.role == .user ? .trailing : .leading)
                    .padding(12)
                    .background(
                        message.role == .user
                        ? AnyShapeStyle(Color.accentColor.gradient)
                        : AnyShapeStyle(.ultraThinMaterial),
                        in: RoundedRectangle(cornerRadius: 16, style: .continuous)
                    )
                    .foregroundStyle(message.role == .user ? Color.white : Color.primary)
                    .contextMenu {
                        Button { onCopy?() } label: {
                            Label("复制", systemImage: "doc.on.doc")
                        }
                        if message.role == .user {
                            Button {
                                editText = message.content
                                showEdit = true
                            } label: {
                                Label("编辑并重发", systemImage: "pencil")
                            }
                        }
                        if message.role == .assistant {
                            Button { onRegenerate?() } label: {
                                Label("重新生成", systemImage: "arrow.clockwise")
                            }
                        }
                    }

                if message.role == .assistant && !message.isStreaming && !message.content.isEmpty {
                    HStack(spacing: 12) {
                        Button { onCopy?() } label: {
                            Image(systemName: "doc.on.doc")
                                .font(.caption)
                        }
                        Button { onRegenerate?() } label: {
                            Image(systemName: "arrow.clockwise")
                                .font(.caption)
                        }
                    }
                    .foregroundStyle(.secondary)
                    .buttonStyle(.plain)
                }
            }
            .frame(maxWidth: .infinity, alignment: message.role == .user ? .trailing : .leading)

            if message.role == .assistant { Spacer(minLength: 40) }
        }
        .padding(.vertical, 2)
        .sheet(isPresented: $showEdit) {
            NavigationStack {
                TextEditor(text: $editText)
                    .padding()
                    .navigationTitle("编辑消息")
                    .navigationBarTitleDisplayMode(.inline)
                    .toolbar {
                        ToolbarItem(placement: .cancellationAction) {
                            Button("取消") { showEdit = false }
                        }
                        ToolbarItem(placement: .confirmationAction) {
                            Button("发送") {
                                onEdit?(editText)
                                showEdit = false
                            }
                            .disabled(editText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
                        }
                    }
            }
            .presentationDetents([.medium, .large])
        }
    }
}

private extension ChatMessage {
    var displayText: String {
        if isStreaming && content.isEmpty { return "正在输入…" }
        return content
    }
}
