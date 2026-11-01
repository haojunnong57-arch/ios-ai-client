import SwiftUI

struct EmptyChatView: View {
    let onStart: () -> Void
    var body: some View {
        VStack(spacing: 20) {
            Image(systemName: "sparkles")
                .font(.system(size: 56))
                .foregroundStyle(.tint)
            Text("开始一段新对话").font(.title2.bold())
            Text("支持 OpenAI · DeepSeek · 通义千问\n在「模型」页填入你的 API Key")
                .multilineTextAlignment(.center)
                .foregroundStyle(.secondary)
            Button(action: onStart) {
                Label("新建对话", systemImage: "plus.circle.fill").font(.headline)
            }
            .buttonStyle(.borderedProminent)
            .controlSize(.large)
        }
        .padding()
    }
}
