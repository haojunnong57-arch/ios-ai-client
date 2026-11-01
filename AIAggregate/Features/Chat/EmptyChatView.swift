import SwiftUI

struct EmptyChatView: View {
    @EnvironmentObject var settings: AppSettings
    let onStart: () -> Void
    let onGoModels: () -> Void

    private var hasKey: Bool {
        let key = KeychainManager.shared.get(settings.provider.placeholderKey) ?? ""
        return !key.trimmingCharacters(in: .whitespaces).isEmpty
    }

    var body: some View {
        VStack(spacing: 0) {
            Spacer(minLength: 24)

            VStack(spacing: 18) {
                Image(systemName: "sparkles")
                    .font(.system(size: 64, weight: .regular))
                    .symbolRenderingMode(.hierarchical)
                    .foregroundStyle(.tint)

                Text("开始一段新对话")
                    .font(.title2.bold())

                Text("当前模型：\(settings.provider.name) · \(settings.provider.defaultModel)")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)

                if hasKey {
                    Label("API Key 已配置，可直接对话", systemImage: "checkmark.seal.fill")
                        .font(.footnote)
                        .foregroundStyle(.green)
                } else {
                    Label("尚未填写当前服务商的 API Key", systemImage: "exclamationmark.triangle.fill")
                        .font(.footnote)
                        .foregroundStyle(.orange)
                    Text("请到「模型」页填写并保存 Key 后再发送消息")
                        .font(.footnote)
                        .foregroundStyle(.secondary)
                        .multilineTextAlignment(.center)
                }
            }
            .frame(maxWidth: .infinity)
            .padding(.horizontal, 24)

            Spacer(minLength: 20)

            VStack(spacing: 12) {
                Button(action: onStart) {
                    Label("新建对话", systemImage: "plus.circle.fill")
                        .font(.headline)
                        .frame(maxWidth: .infinity)
                }
                .buttonStyle(.borderedProminent)
                .controlSize(.large)

                if !hasKey {
                    Button(action: onGoModels) {
                        Label("去配置 API Key", systemImage: "key.fill")
                            .frame(maxWidth: .infinity)
                    }
                    .buttonStyle(.bordered)
                    .controlSize(.large)
                }
            }
            .padding(.horizontal, 32)
            .padding(.bottom, 24)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
}
