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
                        if let err = vm.errorMessage {
                            Text(err)
                                .font(.footnote)
                                .foregroundStyle(.red)
                                .padding(8)
                        }
                    }
                    .padding()
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
        HStack(alignment: .bottom, spacing: 8) {
            TextField("输入消息…", text: $vm.inputText, axis: .vertical)
                .lineLimit(1...5)
                .padding(10)
                .background(.regularMaterial, in: RoundedRectangle(cornerRadius: 18))

            if vm.isGenerating {
                Button { vm.stop() } label: {
                    Image(systemName: "stop.circle.fill").font(.title2).foregroundStyle(.red)
                }
            } else {
                Button { vm.send() } label: {
                    Image(systemName: "arrow.up.circle.fill").font(.title2)
                }
                .disabled(vm.inputText.trimmingCharacters(in: .whitespaces).isEmpty)
            }
        }
        .padding()
        .background(.ultraThinMaterial)
    }
}
