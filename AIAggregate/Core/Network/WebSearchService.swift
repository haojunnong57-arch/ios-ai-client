import Foundation

struct SearchResult: Identifiable, Sendable {
    let id = UUID()
    let title: String
    let url: String
    let snippet: String
}

actor WebSearchService {
    static let shared = WebSearchService()

    /// Free DuckDuckGo HTML search (no API key required).
    func search(query: String, limit: Int = 5) async throws -> [SearchResult] {
        let q = query.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !q.isEmpty else { return [] }

        var components = URLComponents(string: "https://html.duckduckgo.com/html/")!
        components.queryItems = [URLQueryItem(name: "q", value: q)]
        guard let url = components.url else { throw URLError(.badURL) }

        var request = URLRequest(url: url)
        request.setValue("Mozilla/5.0 (iPhone; CPU iPhone OS 17_0 like Mac OS X)", forHTTPHeaderField: "User-Agent")
        request.timeoutInterval = 15

        let (data, response) = try await URLSession.shared.data(for: request)
        guard let http = response as? HTTPURLResponse, (200..<300).contains(http.statusCode) else {
            throw URLError(.badServerResponse)
        }

        let html = String(decoding: data, as: UTF8.self)
        return parseDuckDuckGo(html: html, limit: limit)
    }

    private func parseDuckDuckGo(html: String, limit: Int) -> [SearchResult] {
        var results: [SearchResult] = []
        // Simple regex-style extraction for result blocks
        let parts = html.components(separatedBy: "result__a")
        for part in parts.dropFirst() {
            if results.count >= limit { break }
            guard let hrefRange = part.range(of: "href=\"") else { continue }
            let afterHref = part[hrefRange.upperBound...]
            guard let endQuote = afterHref.firstIndex(of: "\"") else { continue }
            var link = String(afterHref[..<endQuote])
            // DuckDuckGo often wraps links; try to extract uddg=
            if let uddg = link.components(separatedBy: "uddg=").last?.removingPercentEncoding,
               uddg.hasPrefix("http") {
                link = uddg.components(separatedBy: "&").first ?? uddg
            }
            // Title: text between > and </a>
            var title = ""
            if let gt = part.range(of: ">"),
               let close = part.range(of: "</a>") {
                title = String(part[gt.upperBound..<close.lowerBound])
                    .replacingOccurrences(of: "<[^>]+>", with: "", options: .regularExpression)
                    .trimmingCharacters(in: .whitespacesAndNewlines)
            }
            // Snippet
            var snippet = ""
            if let snipStart = part.range(of: "result__snippet") {
                let after = part[snipStart.upperBound...]
                if let gt = after.range(of: ">"),
                   let close = after.range(of: "</") {
                    snippet = String(after[gt.upperBound..<close.lowerBound])
                        .replacingOccurrences(of: "<[^>]+>", with: "", options: .regularExpression)
                        .trimmingCharacters(in: .whitespacesAndNewlines)
                }
            }
            if !title.isEmpty && link.hasPrefix("http") {
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
