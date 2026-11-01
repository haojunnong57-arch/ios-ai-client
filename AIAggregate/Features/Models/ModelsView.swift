import SwiftUI

struct ModelsView: View {
    @EnvironmentObject var settings: AppSettings
    @State private var keys: [Int: String] = [:]

    var body: some View {
        NavigationStack {
            Form {
                Section("当前使用") {
                    Picker("服务商", selection: $settings.selectedProviderIndex) {
                        ForEach(Array(LLMProvider.builtin.enumerated()), id: \.offset) { idx, p in
                            Text(p.name).tag(idx)
                        }
                    }
                    let p = settings.provider
                    LabeledContent("Base URL", value: p.defaultBaseURL)
                    LabeledContent("默认模型", value: p.defaultModel)
                }

                Section("API Key（保存在本机 Keychain）") {
                    ForEach(Array(LLMProvider.builtin.enumerated()), id: \.offset) { idx, p in
                        SecureField(p.name + " Key", text: Binding(
                            get: { keys[idx] ?? "" },
                            set: { keys[idx] = $0 }
                        ))
                        .textInputAutocapitalization(.never)
                        .autocorrectionDisabled()
                    }
                    Button("保存 Key") {
                        for (idx, key) in keys where !key.isEmpty {
                            KeychainManager.shared.set(LLMProvider.builtin[idx].placeholderKey,
                                                       value: key.trimmingCharacters(in: .whitespaces))
                        }
                        keys = [:]
                    }
                }

                Section("高级（可选）") {
                    TextField("自定义 Base URL", text: $settings.customBaseURL)
                        .textInputAutocapitalization(.never)
                        .autocorrectionDisabled()
                    TextField("自定义模型名", text: $settings.customModelName)
                        .textInputAutocapitalization(.never)
                    HStack {
                        Text("Temperature")
                        Slider(value: $settings.temperature, in: 0...2)
                        Text(String(format: "%.1f", settings.temperature))
                    }
                }

                Section("说明") {
                    Text("• 三家均为 OpenAI 兼容协议\n• 不内置任何 Key，全部由你本人填写\n• Key 仅存于本机钥匙串，不会上传")
                        .font(.footnote)
                        .foregroundStyle(.secondary)
                }
            }
            .navigationTitle("模型配置")
        }
        .onAppear {
            for (idx, p) in LLMProvider.builtin.enumerated() {
                keys[idx] = KeychainManager.shared.get(p.placeholderKey) ?? ""
            }
        }
    }
}
