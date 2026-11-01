import SwiftUI

struct ModelsView: View {
    @EnvironmentObject var settings: AppSettings
    @State private var keys: [Int: String] = [:]
    @State private var saved: [Int: Bool] = [:]
    @State private var savedHint: String?

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
                    LabeledContent("Key 状态", value: saved[settings.selectedProviderIndex] == true ? "已保存" : "未填写")
                }

                Section("API Key（保存在本机 Keychain，仅本设备可读）") {
                    ForEach(Array(LLMProvider.builtin.enumerated()), id: \.offset) { idx, p in
                        SecureField(p.name + " Key", text: Binding(
                            get: { keys[idx] ?? "" },
                            set: { keys[idx] = $0 }
                        ))
                        .textInputAutocapitalization(.never)
                        .autocorrectionDisabled()
                        LabeledContent("状态", value: saved[idx] == true ? "已保存" : "未填写")
                            .font(.caption)
                    }
                    Button { saveKeys() } label: {
                        Label("保存 Key", systemImage: "square.and.arrow.down")
                    }
                    if let savedHint {
                        Text(savedHint).font(.footnote).foregroundStyle(.green)
                    }
                    Text("填完必须点「保存 Key」；当前服务商为空时对话无法发送。")
                        .font(.footnote)
                        .foregroundStyle(.secondary)
                }

                Section("高级（可选）") {
                    TextField("自定义 Base URL（留空用默认）", text: $settings.customBaseURL)
                        .textInputAutocapitalization(.never)
                        .autocorrectionDisabled()
                    TextField("自定义模型名（留空用默认）", text: $settings.customModelName)
                        .textInputAutocapitalization(.never)
                    HStack {
                        Text("Temperature")
                        Slider(value: $settings.temperature, in: 0...2)
                        Text(String(format: "%.1f", settings.temperature))
                    }
                }

                Section("说明") {
                    Text("• 三家均为 OpenAI 兼容协议（/chat/completions, stream=true）\n• 不内置任何 Key，全部由你本人填写\n• Key 仅存于本机钥匙串，不会上传服务器")
                        .font(.footnote)
                        .foregroundStyle(.secondary)
                }
            }
            .navigationTitle("模型配置")
            .onAppear { loadKeys() }
        }
    }

    private func loadKeys() {
        for (idx, p) in LLMProvider.builtin.enumerated() {
            let k = KeychainManager.shared.get(p.placeholderKey) ?? ""
            keys[idx] = k
            saved[idx] = !k.isEmpty
        }
    }

    private func saveKeys() {
        var count = 0
        for (idx, raw) in keys {
            let trimmed = raw.trimmingCharacters(in: .whitespacesAndNewlines)
            if !trimmed.isEmpty {
                KeychainManager.shared.set(LLMProvider.builtin[idx].placeholderKey, value: trimmed)
                saved[idx] = true
                count += 1
            }
        }
        savedHint = count > 0 ? "已保存 \(count) 个 API Key" : "请先填写至少一个 Key"
        DispatchQueue.main.asyncAfter(deadline: .now() + 3) { savedHint = nil }
    }
}
