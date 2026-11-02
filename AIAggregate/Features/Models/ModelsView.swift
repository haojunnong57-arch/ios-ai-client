import Foundation
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
                TextField("名称（显示用）", text: $settings.customDisplayName)
                TextField("API Base URL", text: $settings.customBaseURL)
                    .textInputAutocapitalization(.never)
                    .autocorrectionDisabled()
                    .keyboardType(.URL)
                TextField("Model ID（实际请求用）", text: $settings.customModelID)
                    .textInputAutocapitalization(.never)
                    .autocorrectionDisabled()
                Picker("API 协议", selection: $settings.customProtocol) {
                    Text("OpenAI Compatible").tag("OpenAI Compatible")
                    Text("OpenAI").tag("OpenAI")
                    Text("自定义").tag("Custom")
                }
                TextField("可选 API Path（如 /chat/completions or /v1/chat/completions）", text: $settings.customAPIPath)
                    .textInputAutocapitalization(.never)
                    .autocorrectionDisabled()
            } header: {
                Text("自定义模型配置")
            } footer: {
                Text("名称用于界面显示，Model ID 用于真实请求。Base URL 必须指向模型服务商接口地址。")
                    .font(.footnote)
            }

            Section {
                HStack {
                    if showKey {
                        TextField("sk-... 或自己的 API Key", text: $keyText)
                            .textInputAutocapitalization(.never)
                            .autocorrectionDisabled()
                    } else {
                        SecureField("sk-... 或自己的 API Key", text: $keyText)
                            .textInputAutocapitalization(.never)
                            .autocorrectionDisabled()
                    }
                    Button { showKey.toggle() } label: {
                        Image(systemName: showKey ? "eye.slash" : "eye")
                    }
                    .buttonStyle(.plain)
                }
            } header: {
                Text("API Key")
            } footer: {
                Text("仅保存到本机 Keychain，不会写死在代码中。")
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
        .navigationTitle("模型设置")
        .onAppear { loadKey() }
    }

    private func loadKey() {
        keyText = KeychainManager.shared.get("custom_api_key") ?? settings.customAPIKey
        settings.customAPIKey = keyText
        if settings.customDisplayName.isEmpty { settings.customDisplayName = "My AI" }
        if settings.customModelID.isEmpty { settings.customModelID = settings.customModelName }
    }

    private func saveAndTest() {
        let trimmedKey = keyText.trimmingCharacters(in: .whitespacesAndNewlines)
        let trimmedURL = settings.customBaseURL.trimmingCharacters(in: .whitespacesAndNewlines)
        let trimmedModelID = settings.customModelID.trimmingCharacters(in: .whitespacesAndNewlines)
        let trimmedPath = settings.customAPIPath.trimmingCharacters(in: .whitespacesAndNewlines)

        guard !trimmedKey.isEmpty else {
            status = "请输入 API Key"
            return
        }
        guard !trimmedURL.isEmpty else {
            status = "请输入 Base URL"
            return
        }
        guard !trimmedModelID.isEmpty else {
            status = "请输入 Model ID"
            return
        }
        guard trimmedURL.lowercased().hasPrefix("http://") || trimmedURL.lowercased().hasPrefix("https://") else {
            status = "Base URL 必须以 http:// 或 https:// 开头"
            return
        }

        settings.customAPIKey = trimmedKey
        settings.customModelName = trimmedModelID
        settings.customModelID = trimmedModelID
        if settings.customDisplayName.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
            settings.customDisplayName = "My AI"
        }
        if !trimmedPath.isEmpty {
            settings.customAPIPath = trimmedPath
        }

        KeychainManager.shared.set("custom_api_key", value: trimmedKey)
        isTesting = true
        status = nil

        Task {
            let config = settings.currentConfig()
            do {
                let endpoint = OpenAIStreamingClient.makeEndpointURL(baseURL: config.baseURL, apiPath: config.apiPath)
                guard let url = endpoint else {
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
                    "model": config.modelID,
                    "stream": false,
                    "max_tokens": 8,
                    "messages": [["role": "user", "content": "hello"]]
                ]
                req.httpBody = try JSONSerialization.data(withJSONObject: body)

                let (_, resp) = try await URLSession.shared.data(for: req)
                let code = (resp as? HTTPURLResponse)?.statusCode ?? 0
                await MainActor.run {
                    if (200..<300).contains(code) {
                        status = "连接成功"
                    } else if code == 401 {
                        status = "鉴权失败：Key 或 Model ID 不正确 (401)"
                    } else if code == 402 || code == 403 {
                        status = "余额不足或权限受限 (\(code))"
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
