import Foundation

struct SearchResult: Identifiable, Sendable {
    let id = UUID()
    let title: String
    let url: String
    let snippet: String
}

actor WebSearchService {
    static let shared = WebSearchService()

    /// Free DuckDuckGo HTML search via POST (no API key).
    func search(query: String, limit: Int = 5) async throws -> [SearchResult] {
        let q = query.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !q.isEmpty else { return [] }

        guard let url = URL(string: "https://html.duckduckgo.com/html/") else {
            throw URLError(.badURL)
        }

        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("Mozilla/5.0 (iPhone; CPU iPhone OS 17_0 like Mac OS X) AppleWebKit/605.1.15", forHTTPHeaderField: "User-Agent")
        request.setValue("application/x-www-form-urlencoded", forHTTPHeaderField: "Content-Type")
        request.timeoutInterval = 20

        let body = "q=\(q.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) ?? q)"
        request.httpBody = body.data(using: .utf8)

        let (data, response) = try await URLSession.shared.data(for: request)
        guard let http = response as? HTTPURLResponse, (200..<300).contains(http.statusCode) else {
            throw URLError(.badServerResponse)
        }

        let html = String(decoding: data, as: UTF8.self)
        return parseDuckDuckGo(html: html, limit: limit)
    }

    private func parseDuckDuckGo(html: String, limit: Int) -> [SearchResult] {
        var results: [SearchResult] = []
        let parts = html.components(separatedBy: "result__a")
        for part in parts.dropFirst() {
            if results.count >= limit { break }

            // href
            guard let hrefRange = part.range(of: "href=\"") else { continue }
            let afterHref = part[hrefRange.upperBound...]
            guard let endQuote = afterHref.firstIndex(of: "\"") else { continue }
            var link = String(afterHref[..<endQuote])

            // unwrap duckduckgo redirect if present
            if let range = link.range(of: "uddg=") {
                let encoded = String(link[range.upperBound...])
                if let decoded = encoded.components(separatedBy: "&").first?.removingPercentEncoding,
                   decoded.hasPrefix("http") {
                    link = decoded
                }
            }

            // title text until </a>
            var title = ""
            if let gt = part.range(of: ">"),
               let close = part.range(of: "</a>") {
                let raw = String(part[gt.upperBound..<close.lowerBound])
                title = raw.replacingOccurrences(of: "<[^>]+>", with: "", options: .regularExpression)
                    .trimmingCharacters(in: .whitespacesAndNewlines)
            }

            // snippet
            var snippet = ""
            if let snip = part.range(of: "result__snippet") {
                let after = part[snip.upperBound...]
                if let gt = after.range(of: ">") {
                    let rest = after[gt.upperBound...]
                    if let end = rest.range(of: "</") {
                        let raw = String(rest[..<end.lowerBound])
                        snippet = raw.replacingOccurrences(of: "<[^>]+>", with: "", options: .regularExpression)
                            .trimmingCharacters(in: .whitespacesAndNewlines)
                    }
                }
            }

            if !title.isEmpty && (link.hasPrefix("http") || link.hasPrefix("//")) {
                if link.hasPrefix("//") { link = "https:" + link }
                results.append(SearchResult(title: title, url: link, snippet: snippet))
            }
        }
        return results
    }

    func formatForPrompt(_ results: [SearchResult]) -> String {
        guard !results.isEmpty else { return "" }
        var lines = ["以下是联网搜索结果，请基于这些资料回答用户问题，并在回答末尾列出参考来源：\n"]
        for (i, r) in results.enumerated() {
            lines.append("\(i+1). \(r.title)\n   链接: \(r.url)\n   摘要: \(r.snippet)\n")
        }
        return lines.joined(separator: "\n")
    }
}
