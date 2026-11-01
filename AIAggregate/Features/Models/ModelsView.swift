import SwiftUI

struct ModelsView: View {
    @EnvironmentObject var settings: AppSettings
    @State private var keyText: String = ""
    @State private var showKey = false
    @State private var status: String?
    @State private var isTesting = false

    var body: some View {
        NavigationStack {
            Form {
                Section {
                    Picker("AI 服务商", selection: $settings.selectedProviderIndex) {
                        ForEach(Array(LLMProvider.builtin.enumerated()), id: \.offset) { idx, p in
                            Text(p.name).tag(idx)
                        }
                    }
                    .onChange(of: settings.selectedProviderIndex) { _, _ in
                        loadKey()
                        status = nil
                    }
                } header: {
                    Text("选择服务商")
                }

                Section {
                    HStack {
                        if showKey {
                            TextField("API Key", text: $keyText)
                                .textInputAutocapitalization(.never)
                                .autocorrectionDisabled()
                        } else {
                            SecureField("API Key", text: $keyText)
                                .textInputAutocapitalization(.never)
                                .autocorrectionDisabled()
                        }
                        Button {
                            showKey.toggle()
                        } label: {
                            Image(systemName: showKey ? "eye.slash" : "eye")
                        }
                        .buttonStyle(.plain)
                    }
                } header: {
                    Text("API Key")
                } footer: {
                    Text("Key 仅保存在本机 Keychain，不会上传。")
                        .font(.footnote)
                }

                Section {
                    Button {
                        saveAndTest()
                    } label: {
                        if isTesting {
                            ProgressView()
                                .frame(maxWidth: .infinity)
                        } else {
                            Text("保存并测试连接")
                                .frame(maxWidth: .infinity)
                        }
                    }
                    .disabled(keyText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty || isTesting)

                    if let status {
                        Text(status)
                            .font(.footnote)
                            .foregroundStyle(status.contains("成功") ? .green : .red)
                    }
                }

                Section("说明") {
                    Text("当前默认模型：\n• DeepSeek → deepseek-flash\n• OpenAI → gpt-4o-mini\n• 通义千问 → qwen-turbo\n\n无需填写 Base URL 或模型名，程序内部已配置。")
                        .font(.footnote)
                        .foregroundStyle(.secondary)
                }
            }
            .navigationTitle("API 设置")
            .onAppear { loadKey() }
        }
    }

    private func loadKey() {
        keyText = KeychainManager.shared.get(settings.provider.placeholderKey) ?? ""
    }

    private func saveAndTest() {
        let trimmed = keyText.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return }
        KeychainManager.shared.set(settings.provider.placeholderKey, value: trimmed)
        isTesting = true
        status = nil

        Task {
            let config = settings.currentConfig()
            do {
                // Minimal test: send a short non-stream request
                var base = config.baseURL.trimmingCharacters(in: .whitespacesAndNewlines)
                while base.hasSuffix("/") { base.removeLast() }
                guard let url = URL(string: base + "/chat/completions") else {
                    await MainActor.run {
                        status = "URL 无效"
                        isTesting = false
                    }
                    return
                }
                var req = URLRequest(url: url)
                req.httpMethod = "POST"
                req.setValue("application/json", forHTTPHeaderField: "Content-Type")
                req.setValue("Bearer \(config.apiKey)", forHTTPHeaderField: "Authorization")
                req.timeoutInterval = 20
                let body: [String: Any] = [
                    "model": config.modelName,
                    "stream": false,
                    "max_tokens": 8,
                    "messages": [["role": "user", "content": "hi"]]
                ]
                req.httpBody = try JSONSerialization.data(withJSONObject: body)
                let (_, resp) = try await URLSession.shared.data(for: req)
                let code = (resp as? HTTPURLResponse)?.statusCode ?? 0
                await MainActor.run {
                    if (200..<300).contains(code) {
                        status = "连接成功"
                    } else if code == 401 {
                        status = "Key 无效或已过期 (401)"
                    } else {
                        status = "连接失败 (HTTP \(code))"
                    }
                    isTesting = false
                }
            } catch {
                await MainActor.run {
                    status = "网络错误：\(error.localizedDescription)"
                    isTesting = false
                }
            }
        }
    }
}
