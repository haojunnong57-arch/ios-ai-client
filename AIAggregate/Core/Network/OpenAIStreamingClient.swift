import Foundation

struct OpenAIStreamingClient: LLMClient, Sendable {
    let session: URLSession

    init(session: URLSession = .shared) {
        self.session = session
    }

    func streamChat(messages: [ChatMessage],
                    config: LLMConfig) async throws -> AsyncThrowingStream<String, Error> {
        var base = config.baseURL.trimmingCharacters(in: .whitespacesAndNewlines)
        while base.hasSuffix("/") { base.removeLast() }
        guard let url = URL(string: base + "/chat/completions") else {
            throw AppError.invalidURL
        }
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        if !config.apiKey.isEmpty {
            request.setValue("Bearer \(config.apiKey)", forHTTPHeaderField: "Authorization")
        }
        request.timeoutInterval = 60

        let payload: [String: Any] = [
            "model": config.modelName,
            "stream": true,
            "temperature": config.temperature,
            "max_tokens": config.maxTokens,
            "messages": messages.map { ["role": $0.role.rawValue, "content": $0.content] }
        ]
        request.httpBody = try JSONSerialization.data(withJSONObject: payload)

        let (bytes, response): (URLSession.AsyncBytes, URLResponse)
        do {
            (bytes, response) = try await session.bytes(for: request)
        } catch {
            throw AppError.network(underlying: error.localizedDescription)
        }

        guard let http = response as? HTTPURLResponse else {
            throw AppError.unknown("无效响应")
        }
        guard (200..<300).contains(http.statusCode) else {
            var bodyData = Data()
            do {
                for try await byte in bytes { bodyData.append(byte) }
            } catch {}
            let body = String(decoding: bodyData, as: UTF8.self)
            throw AppError.httpStatus(http.statusCode, String(body.prefix(500)))
        }

        return AsyncThrowingStream { continuation in
            let task = Task {
                do {
                    for try await line in bytes.lines {
                        if Task.isCancelled {
                            continuation.finish(throwing: AppError.streamCancelled)
                            return
                        }
                        guard line.hasPrefix("data: ") else { continue }
                        let dataStr = String(line.dropFirst(6))
                        if dataStr.trimmingCharacters(in: .whitespaces) == "[DONE]" { break }
                        guard let data = dataStr.data(using: .utf8),
                              let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
                              let choices = json["choices"] as? [[String: Any]],
                              let first = choices.first,
                              let delta = first["delta"] as? [String: Any],
                              let content = delta["content"] as? String else { continue }
                        if !content.isEmpty { continuation.yield(content) }
                    }
                    continuation.finish()
                } catch is CancellationError {
                    continuation.finish(throwing: AppError.streamCancelled)
                } catch {
                    continuation.finish(throwing: AppError.network(underlying: error.localizedDescription))
                }
            }
            continuation.onTermination = { _ in task.cancel() }
        }
    }
}
