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
                    LazyVStack(alignment: .leading, spacing: 12) {
                        ForEach(vm.session.messages) { msg in
                            MessageRow(message: msg).id(msg.id)
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
                    .padding()
                    .padding(.bottom, 90)
                }
                .onChange(of: vm.session.messages.last?.content) { _, _ in
                    if let last = vm.session.messages.last {
                        withAnimation { proxy.scrollTo(last.id, anchor: .bottom) }
                    }
                }
            }
            composer
                .padding(.bottom, 72)
        }
        .onAppear { vm.wire(store: store, settings: settings) }
    }

    private var composer: some View {
        VStack(spacing: 8) {
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
            .padding(.horizontal, 4)

            HStack(alignment: .bottom, spacing: 8) {
                TextField("输入消息…", text: $vm.inputText, axis: .vertical)
                    .lineLimit(1...5)
                    .padding(12)
                    .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 20))

                if vm.isGenerating {
                    Button { vm.stop() } label: {
                        Image(systemName: "stop.circle.fill")
                            .font(.title2)
                            .foregroundStyle(.red)
                    }
                } else {
                    Button { vm.send() } label: {
                        Image(systemName: "arrow.up.circle.fill")
                            .font(.title2)
                    }
                    .disabled(vm.inputText.trimmingCharacters(in: .whitespaces).isEmpty)
                }
            }
        }
        .padding()
        .background(.regularMaterial)
    }
}
