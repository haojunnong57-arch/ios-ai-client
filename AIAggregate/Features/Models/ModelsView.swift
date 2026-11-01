import SwiftUI

struct ModelsView: View {
    @EnvironmentObject var settings: AppSettings
    @State private var keyText: String = ""
    @State private var showKey = false
    @State private var status: String?
    @State private var isTesting = false

    var body: some View {
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
                    if settings.provider.name.contains("自定义") {
                        settings.useCustomEndpoint = true
                        if settings.customBaseURL.isEmpty {
                            settings.customBaseURL = settings.provider.defaultBaseURL
                        }
                        if settings.customModelName.isEmpty {
                            settings.customModelName = settings.provider.defaultModel
                        }
                    }
                }
            } header: {
                Text("选择服务商")
            }

            Section {
                HStack {
                    if showKey {
                        TextField("sk-...", text: $keyText)
                            .textInputAutocapitalization(.never)
                            .autocorrectionDisabled()
                    } else {
                        SecureField("sk-...", text: $keyText)
                            .textInputAutocapitalization(.never)
                            .autocorrectionDisabled()
                    }
                    Button { showKey.toggle() } label: {
                        Image(systemName: showKey ? "eye.slash" : "eye")
                    }
                    .buttonStyle(.plain)
                }
            } header: {
                Text("API Key（密钥）")
            } footer: {
                Text("只填密钥本身，不要填到下面的网址栏。")
                    .font(.footnote)
            }

            Section {
                Toggle("使用自定义接口", isOn: $settings.useCustomEndpoint)
                if settings.useCustomEndpoint {
                    TextField("https://api.example.com/v1", text: $settings.customBaseURL)
                        .textInputAutocapitalization(.never)
                        .autocorrectionDisabled()
                        .keyboardType(.URL)
                    TextField("模型名称，如 deepseek-v4.1-flash-1017", text: $settings.customModelName)
                        .textInputAutocapitalization(.never)
                        .autocorrectionDisabled()
                    Text("第三方示例\nBase URL: https://moonshot.kk18.chat/v1\n模型: deepseek-v4.1-flash-1017")
                        .font(.caption2)
                        .foregroundStyle(.secondary)
                }
            } header: {
                Text("自定义接口")
            } footer: {
                Text("Base URL 必须以 http:// 或 https:// 开头。")
                    .font(.footnote)
            }

            Section {
                Button { saveAndTest() } label: {
                    if isTesting {
                        ProgressView().frame(maxWidth: .infinity)
                    } else {
                        Text("保存并测试连接").frame(maxWidth: .infinity)
                    }
                }
                .disabled(keyText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty || isTesting)

                if let status {
                    Text(status)
                        .font(.footnote)
                        .foregroundStyle(status.contains("成功") ? .green : .red)
                }
            }
        }
        .navigationTitle("API 设置")
        .onAppear { loadKey() }
    }

    private func loadKey() {
        keyText = KeychainManager.shared.get(settings.provider.placeholderKey) ?? ""
    }

    private func saveAndTest() {
        let trimmed = keyText.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return }

        if settings.useCustomEndpoint {
            let base = settings.customBaseURL.trimmingCharacters(in: .whitespacesAndNewlines)
            if base.lowercased().hasPrefix("sk-") {
                status = "填错位置：密钥应写在「API Key」，Base URL 应是 https:// 开头的网址"
                return
            }
            if !base.lowercased().hasPrefix("http://") && !base.lowercased().hasPrefix("https://") {
                status = "Base URL 必须以 https:// 开头"
                return
            }
            if settings.customModelName.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
                status = "请填写模型名称"
                return
            }
        }

        KeychainManager.shared.set(settings.provider.placeholderKey, value: trimmed)
        isTesting = true
        status = nil

        Task {
            let config = settings.currentConfig()
            do {
                var base = config.baseURL.trimmingCharacters(in: .whitespacesAndNewlines)
                while base.hasSuffix("/") { base.removeLast() }
                guard let url = URL(string: base + "/chat/completions"), url.scheme == "http" || url.scheme == "https" else {
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
