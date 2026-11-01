import Foundation

struct SearchResult: Identifiable, Sendable {
    let id = UUID()
    let title: String
    let url: String
    let snippet: String
}

enum SearchServiceError: LocalizedError {
    case emptyQuery
    case network(String)
    case noResults
    case blocked

    var errorDescription: String? {
        switch self {
        case .emptyQuery: return "请输入搜索关键词"
        case .network(let s): return "搜索网络错误：\(s)"
        case .noResults: return "未找到相关结果，请换个关键词"
        case .blocked: return "搜索服务暂时不可用或被限制，请稍后重试"
        }
    }
}

actor WebSearchService {
    static let shared = WebSearchService()

    func search(query: String, limit: Int = 8) async throws -> [SearchResult] {
        let q = query.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !q.isEmpty else { throw SearchServiceError.emptyQuery }

        // 1) DuckDuckGo HTML (POST)
        if let ddg = try? await searchDuckDuckGo(query: q, limit: limit), !ddg.isEmpty {
            return ddg
        }

        // 2) Wikipedia OpenSearch (稳定、免费、中英可用)
        if let wiki = try? await searchWikipedia(query: q, limit: limit), !wiki.isEmpty {
            return wiki
        }

        // 3) DuckDuckGo Instant Answer JSON（补充）
        if let instant = try? await searchDuckDuckGoInstant(query: q), !instant.isEmpty {
            return instant
        }

        throw SearchServiceError.noResults
    }

    // MARK: - DuckDuckGo HTML

    private func searchDuckDuckGo(query: String, limit: Int) async throws -> [SearchResult] {
        guard let url = URL(string: "https://html.duckduckgo.com/html/") else {
            throw SearchServiceError.network("无效 URL")
        }
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("Mozilla/5.0 (iPhone; CPU iPhone OS 18_0 like Mac OS X) AppleWebKit/605.1.15 (KHTML, like Gecko) Version/18.0 Mobile/15E148 Safari/604.1", forHTTPHeaderField: "User-Agent")
        request.setValue("application/x-www-form-urlencoded", forHTTPHeaderField: "Content-Type")
        request.setValue("https://html.duckduckgo.com/", forHTTPHeaderField: "Referer")
        request.timeoutInterval = 18

        var allowed = CharacterSet.urlQueryAllowed
        allowed.remove(charactersIn: ":#[]@!$&'()*+,;=")
        let encoded = query.addingPercentEncoding(withAllowedCharacters: allowed) ?? query
        request.httpBody = "q=\(encoded)".data(using: .utf8)

        let (data, response) = try await URLSession.shared.data(for: request)
        guard let http = response as? HTTPURLResponse else {
            throw SearchServiceError.network("无效响应")
        }
        if http.statusCode == 403 || http.statusCode == 429 {
            throw SearchServiceError.blocked
        }
        guard (200..<300).contains(http.statusCode) else {
            throw SearchServiceError.network("HTTP \(http.statusCode)")
        }
        return parseDuckDuckGo(html: String(decoding: data, as: UTF8.self), limit: limit)
    }

    private func parseDuckDuckGo(html: String, limit: Int) -> [SearchResult] {
        var results: [SearchResult] = []
        let parts = html.components(separatedBy: "result__a")
        for part in parts.dropFirst() {
            if results.count >= limit { break }
            guard let hrefRange = part.range(of: "href=\"") else { continue }
            let afterHref = part[hrefRange.upperBound...]
            guard let endQuote = afterHref.firstIndex(of: "\"") else { continue }
            var link = String(afterHref[..<endQuote])

            if let range = link.range(of: "uddg=") {
                let encoded = String(link[range.upperBound...])
                if let decoded = encoded.components(separatedBy: "&").first?.removingPercentEncoding,
                   decoded.hasPrefix("http") {
                    link = decoded
                }
            }

            var title = ""
            if let gt = part.range(of: ">"),
               let close = part.range(of: "</a>") {
                let raw = String(part[gt.upperBound..<close.lowerBound])
                title = raw.replacingOccurrences(of: "<[^>]+>", with: "", options: .regularExpression)
                    .trimmingCharacters(in: .whitespacesAndNewlines)
            }

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

    // MARK: - Wikipedia

    private func searchWikipedia(query: String, limit: Int) async throws -> [SearchResult] {
        var components = URLComponents(string: "https://zh.wikipedia.org/w/api.php")!
        components.queryItems = [
            URLQueryItem(name: "action", value: "opensearch"),
            URLQueryItem(name: "search", value: query),
            URLQueryItem(name: "limit", value: "\(limit)"),
            URLQueryItem(name: "namespace", value: "0"),
            URLQueryItem(name: "format", value: "json")
        ]
        guard let url = components.url else { throw SearchServiceError.network("Wiki URL") }
        var request = URLRequest(url: url)
        request.setValue("LocalGPT/2.7 (iOS; educational)", forHTTPHeaderField: "User-Agent")
        request.timeoutInterval = 15

        let (data, response) = try await URLSession.shared.data(for: request)
        guard let http = response as? HTTPURLResponse, (200..<300).contains(http.statusCode) else {
            // fallback English wiki
            return try await searchWikipediaEN(query: query, limit: limit)
        }

        guard let arr = try JSONSerialization.jsonObject(with: data) as? [Any],
              arr.count >= 4,
              let titles = arr[1] as? [String],
              let descs = arr[2] as? [String],
              let links = arr[3] as? [String] else {
            return try await searchWikipediaEN(query: query, limit: limit)
        }

        var results: [SearchResult] = []
        for i in 0..<min(titles.count, links.count) {
            let snippet = i < descs.count ? descs[i] : ""
            results.append(SearchResult(title: titles[i], url: links[i], snippet: snippet.isEmpty ? "维基百科条目" : snippet))
        }
        return results
    }

    private func searchWikipediaEN(query: String, limit: Int) async throws -> [SearchResult] {
        var components = URLComponents(string: "https://en.wikipedia.org/w/api.php")!
        components.queryItems = [
            URLQueryItem(name: "action", value: "opensearch"),
            URLQueryItem(name: "search", value: query),
            URLQueryItem(name: "limit", value: "\(limit)"),
            URLQueryItem(name: "namespace", value: "0"),
            URLQueryItem(name: "format", value: "json")
        ]
        guard let url = components.url else { return [] }
        var request = URLRequest(url: url)
        request.setValue("LocalGPT/2.7 (iOS; educational)", forHTTPHeaderField: "User-Agent")
        let (data, response) = try await URLSession.shared.data(for: request)
        guard let http = response as? HTTPURLResponse, (200..<300).contains(http.statusCode) else { return [] }
        guard let arr = try JSONSerialization.jsonObject(with: data) as? [Any],
              arr.count >= 4,
              let titles = arr[1] as? [String],
              let descs = arr[2] as? [String],
              let links = arr[3] as? [String] else { return [] }
        var results: [SearchResult] = []
        for i in 0..<min(titles.count, links.count) {
            let snippet = i < descs.count ? descs[i] : ""
            results.append(SearchResult(title: titles[i], url: links[i], snippet: snippet.isEmpty ? "Wikipedia" : snippet))
        }
        return results
    }

    // MARK: - DDG Instant

    private func searchDuckDuckGoInstant(query: String) async throws -> [SearchResult] {
        var components = URLComponents(string: "https://api.duckduckgo.com/")!
        components.queryItems = [
            URLQueryItem(name: "q", value: query),
            URLQueryItem(name: "format", value: "json"),
            URLQueryItem(name: "no_redirect", value: "1"),
            URLQueryItem(name: "no_html", value: "1")
        ]
        guard let url = components.url else { return [] }
        let (data, response) = try await URLSession.shared.data(from: url)
        guard let http = response as? HTTPURLResponse, (200..<300).contains(http.statusCode) else { return [] }
        guard let json = try JSONSerialization.jsonObject(with: data) as? [String: Any] else { return [] }

        var results: [SearchResult] = []
        if let heading = json["Heading"] as? String, !heading.isEmpty,
           let abs = json["AbstractURL"] as? String, abs.hasPrefix("http") {
            let text = (json["AbstractText"] as? String) ?? ""
            results.append(SearchResult(title: heading, url: abs, snippet: text))
        }
        if let related = json["RelatedTopics"] as? [[String: Any]] {
            for item in related.prefix(6) {
                if let text = item["Text"] as? String,
                   let u = item["FirstURL"] as? String, u.hasPrefix("http") {
                    results.append(SearchResult(title: String(text.prefix(80)), url: u, snippet: text))
                }
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
