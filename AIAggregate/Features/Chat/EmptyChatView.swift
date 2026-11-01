import SwiftUI

struct EmptyChatView: View {
    @EnvironmentObject var settings: AppSettings
    let onStart: () -> Void
    let onGoModels: () -> Void
    let onStartVoice: () -> Void

    private var hasKey: Bool {
        let key = KeychainManager.shared.get(settings.provider.placeholderKey) ?? ""
        return !key.trimmingCharacters(in: .whitespaces).isEmpty
    }

    var body: some View {
        VStack(spacing: 0) {
            Spacer(minLength: 16)

            VStack(spacing: 16) {
                Image(systemName: "sparkles")
                    .font(.system(size: 56, weight: .regular))
                    .symbolRenderingMode(.hierarchical)
                    .foregroundStyle(.tint)

                Text("开始一段新对话")
                    .font(.title2.bold())

                Text("当前模型：\(settings.provider.name) · \(settings.provider.defaultModel)")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                    .multilineTextAlignment(.center)

                if hasKey {
                    Label("API Key 已配置，可直接对话", systemImage: "checkmark.seal.fill")
                        .font(.footnote)
                        .foregroundStyle(.green)
                } else {
                    Label("尚未填写当前服务商的 API Key", systemImage: "exclamationmark.triangle.fill")
                        .font(.footnote)
                        .foregroundStyle(.orange)
                    Text("请到「我的 → API 设置」填写并保存 Key")
                        .font(.footnote)
                        .foregroundStyle(.secondary)
                        .multilineTextAlignment(.center)
                }
            }
            .padding(.horizontal, 28)

            Spacer(minLength: 16)

            VStack(spacing: 12) {
                Button(action: onStart) {
                    Label("新建对话", systemImage: "plus.circle.fill")
                        .font(.headline)
                        .frame(maxWidth: .infinity)
                }
                .buttonStyle(.borderedProminent)
                .controlSize(.large)

                Button(action: onStartVoice) {
                    Label("语音通话", systemImage: "waveform.circle.fill")
                        .font(.headline)
                        .frame(maxWidth: .infinity)
                }
                .buttonStyle(.bordered)
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
            .padding(.horizontal, 28)
            .padding(.bottom, 16)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
}
