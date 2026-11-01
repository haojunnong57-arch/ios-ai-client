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
                            HStack {
                                Text(p.name)
                                if p.isLocal {
                                    Text("局域网").font(.caption2).padding(2).background(.blue.opacity(0.2)).cornerRadius(4)
                                }
                            }.tag(idx)
                        }
                    }
                    let p = settings.provider
                    LabeledContent("Base URL", value: p.defaultBaseURL)
                    LabeledContent("默认模型", value: p.defaultModel)
                    LabeledContent("Key 状态", value: saved[settings.selectedProviderIndex] == true ? "已保存" : (p.isLocal ? "本地可空" : "未填写"))
                }

                Section("API Key（保存在本机 Keychain，仅本设备可读）") {
                    ForEach(Array(LLMProvider.builtin.enumerated()), id: \.offset) { idx, p in
                        VStack(alignment: .leading, spacing: 4) {
                            SecureField(p.name + (p.isLocal ? " Key（可选）" : " Key"), text: Binding(
                                get: { keys[idx] ?? "" },
                                set: { keys[idx] = $0 }
                            ))
                            .textInputAutocapitalization(.never)
                            .autocorrectionDisabled()
                            LabeledContent("状态", value: saved[idx] == true ? "已保存" : (p.isLocal ? "本地可留空" : "未填写"))
                                .font(.caption)
                        }
                    }
                    Button { saveKeys() } label: {
                        Label("保存 Key", systemImage: "square.and.arrow.down")
                    }
                    if let savedHint {
                        Text(savedHint).font(.footnote).foregroundStyle(.green)
                    }
                    Text("云端服务商填完必须点「保存 Key」。本地/局域网服务商 Key 可留空。当前服务商为空时对话无法发送。")
                        .font(.footnote)
                        .foregroundStyle(.secondary)
                }

                Section("高级（可选，覆盖默认）") {
                    TextField("自定义 Base URL（留空用默认）", text: $settings.customBaseURL)
                        .textInputAutocapitalization(.never)
                        .autocorrectionDisabled()
                        .keyboardType(.URL)
                    TextField("自定义模型名（留空用默认）", text: $settings.customModelName)
                        .textInputAutocapitalization(.never)
                    HStack {
                        Text("Temperature")
                        Slider(value: $settings.temperature, in: 0...2)
                        Text(String(format: "%.1f", settings.temperature))
                    }
                }

                Section("本地 7B 模型说明") {
                    Text("推荐无对齐（uncensored / abliterated）7B 级模型：\n• DeepSeek-R1-Distill-Qwen-7B\n• Qwen2.5-7B-Instruct-Abliterated\n• 在电脑用 Ollama / LM Studio 加载后，把 Base URL 设为 http://你的电脑IP:11434/v1 即可。\n真机与电脑需同一 Wi-Fi，并允许本地网络权限。")
                        .font(.footnote)
                        .foregroundStyle(.secondary)
                }

                Section("说明") {
                    Text("• 所有服务商均为 OpenAI 兼容协议（/chat/completions, stream=true）\n• 不内置任何付费 Key\n• Key 仅存于本机钥匙串\n• 已针对 iPhone Air 6.5\" 屏幕与 Dynamic Island 做自适应布局")
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
        savedHint = count > 0 ? "已保存 \(count) 个 API Key" : "本地服务商可留空 Key"
        DispatchQueue.main.asyncAfter(deadline: .now() + 3) { savedHint = nil }
    }
}
