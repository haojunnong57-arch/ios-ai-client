import SwiftUI

struct ChatView: View {
    @StateObject private var vm: ChatViewModel
    @EnvironmentObject var store: SessionStore
    @EnvironmentObject var settings: AppSettings

    init(session: ChatSession) {
        _vm = StateObject(wrappedValue: ChatViewModel(session: session))
    }

    var body: some View {
        VStack(spacing: 0) {
            ScrollViewReader { proxy in
                ScrollView {
                    LazyVStack(alignment: .leading, spacing: 14) {
                        ForEach(vm.session.messages) { msg in
                            MessageRow(
                                message: msg,
                                onCopy: { UIPasteboard.general.string = msg.content },
                                onRegenerate: { vm.regenerate() },
                                onEdit: { text in vm.editAndResend(messageID: msg.id, newText: text) }
                            )
                            .id(msg.id)
                        }
                        if vm.isSearching {
                            HStack(spacing: 8) {
                                ProgressView()
                                Text("正在联网搜索…")
                                    .font(.footnote)
                                    .foregroundStyle(.secondary)
                            }
                            .padding(8)
                        }
                        if let err = vm.errorMessage {
                            Text(err)
                                .font(.footnote)
                                .foregroundStyle(.red)
                                .padding(8)
                        }
                    }
                    .padding(.horizontal, 16)
                    .padding(.vertical, 12)
                }
                .onChange(of: vm.session.messages.last?.content) { _, _ in
                    if let last = vm.session.messages.last {
                        withAnimation { proxy.scrollTo(last.id, anchor: .bottom) }
                    }
                }
            }

            composer
        }
        .onAppear { vm.wire(store: store, settings: settings) }
    }

    private var composer: some View {
        VStack(spacing: 8) {
            Divider().opacity(0.25)
            HStack {
                Toggle(isOn: $settings.enableWebSearch) {
                    Label("联网搜索", systemImage: "globe")
                        .font(.footnote)
                }
                .toggleStyle(.button)
                .tint(settings.enableWebSearch ? .accentColor : .secondary)
                Spacer()
                Text(settings.provider.name)
                    .font(.caption2)
                    .foregroundStyle(.secondary)
            }

            HStack(alignment: .bottom, spacing: 10) {
                TextField("输入消息…", text: $vm.inputText, axis: .vertical)
                    .lineLimit(1...6)
                    .padding(.horizontal, 14)
                    .padding(.vertical, 10)
                    .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 22, style: .continuous))

                if vm.isGenerating {
                    Button { vm.stop() } label: {
                        Image(systemName: "stop.circle.fill")
                            .font(.system(size: 32))
                            .foregroundStyle(.red)
                    }
                } else {
                    Button { vm.send() } label: {
                        Image(systemName: "arrow.up.circle.fill")
                            .font(.system(size: 32))
                    }
                    .disabled(vm.inputText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
                }
            }
        }
        .padding(.horizontal, 14)
        .padding(.top, 8)
        .padding(.bottom, 8)
        .background(.bar)
    }
}
