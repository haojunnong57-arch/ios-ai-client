import SwiftUI

struct SearchHomeView: View {
    @State private var query = ""
    @State private var results: [SearchResult] = []
    @State private var isLoading = false
    @State private var errorText: String?
    @State private var aiSummary: String = ""
    @State private var isSummarizing = false
    @State private var browserItem: BrowserItem?
    @State private var history: [String] = UserDefaults.standard.stringArray(forKey: "search_history") ?? []

    private let hotKeywords = ["2026 AI 趋势", "DeepSeek 最新模型", "SwiftUI Liquid Glass", "iPhone Air 评测", "开源大模型"]

    var body: some View {
        NavigationStack {
            Group {
                if results.isEmpty && !isLoading {
                    homeContent
                } else {
                    resultsContent
                }
            }
            .navigationTitle("搜索")
            .navigationBarTitleDisplayMode(.inline)
            .sheet(item: $browserItem) { item in
                InAppBrowserView(url: item.url)
            }
        }
    }

    private var homeContent: some View {
        ScrollView {
            VStack(spacing: 24) {
                Spacer(minLength: 32)

                VStack(spacing: 8) {
                    Image(systemName: "magnifyingglass")
                        .font(.system(size: 44, weight: .medium))
                        .foregroundStyle(.primary)
                    Text("LocalGPT Search")
                        .font(.title2.bold())
                    Text("真实网页搜索 · AI 总结")
                        .font(.footnote)
                        .foregroundStyle(.secondary)
                }

                searchField
                    .padding(.horizontal)

                if !history.isEmpty {
                    chipSection(title: "搜索历史", items: Array(history.prefix(8)))
                }

                chipSection(title: "热门搜索", items: hotKeywords)

                Spacer(minLength: 100)
            }
            .padding(.bottom, 80)
        }
    }

    private var resultsContent: some View {
        VStack(spacing: 0) {
            searchField
                .padding()

            if isLoading {
                Spacer()
                ProgressView("正在搜索…")
                Spacer()
            } else {
                List {
                    if isSummarizing || !aiSummary.isEmpty {
                        Section("AI 总结") {
                            if isSummarizing {
                                HStack(spacing: 8) {
                                    ProgressView()
                                    Text("正在生成总结…").font(.footnote)
                                }
                            } else {
                                Text(aiSummary)
                                    .font(.body)
                                    .textSelection(.enabled)
                            }
                        }
                    }

                    if let errorText {
                        Section {
                            Text(errorText)
                                .foregroundStyle(.red)
                                .font(.footnote)
                        }
                    }

                    Section("搜索结果") {
                        ForEach(results) { r in
                            Button {
                                if let u = URL(string: r.url) {
                                    browserItem = BrowserItem(url: u)
                                }
                            } label: {
                                VStack(alignment: .leading, spacing: 4) {
                                    Text(r.title)
                                        .font(.headline)
                                        .foregroundStyle(.primary)
                                        .multilineTextAlignment(.leading)
                                    Text(r.url)
                                        .font(.caption2)
                                        .foregroundStyle(.blue)
                                        .lineLimit(1)
                                    if !r.snippet.isEmpty {
                                        Text(r.snippet)
                                            .font(.footnote)
                                            .foregroundStyle(.secondary)
                                            .lineLimit(3)
                                    }
                                }
                                .padding(.vertical, 4)
                            }
                        }
                    }
                }
                .listStyle(.insetGrouped)
                .padding(.bottom, 70)
            }
        }
    }

    private var searchField: some View {
        HStack(spacing: 10) {
            Image(systemName: "magnifyingglass")
                .foregroundStyle(.secondary)
            TextField("搜索网页…", text: $query)
                .textInputAutocapitalization(.never)
                .autocorrectionDisabled()
                .submitLabel(.search)
                .onSubmit { runSearch() }
            if !query.isEmpty {
                Button {
                    query = ""
                    results = []
                    aiSummary = ""
                    errorText = nil
                } label: {
                    Image(systemName: "xmark.circle.fill")
                        .foregroundStyle(.secondary)
                }
            }
            Button("搜索") { runSearch() }
                .buttonStyle(.borderedProminent)
                .disabled(query.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty || isLoading)
        }
        .padding(12)
        .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 16))
    }

    private func chipSection(title: String, items: [String]) -> some View {
        VStack(alignment: .leading, spacing: 10) {
            Text(title)
                .font(.caption)
                .foregroundStyle(.secondary)
                .padding(.horizontal)

            LazyVGrid(columns: [GridItem(.adaptive(minimum: 100), spacing: 8)], alignment: .leading, spacing: 8) {
                ForEach(items, id: \.self) { item in
                    Button(item) {
                        query = item
                        runSearch()
                    }
                    .buttonStyle(.bordered)
                    .controlSize(.small)
                }
            }
            .padding(.horizontal)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }

    private func runSearch() {
        let q = query.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !q.isEmpty else { return }

        isLoading = true
        errorText = nil
        aiSummary = ""
        results = []

        var h = history.filter { $0 != q }
        h.insert(q, at: 0)
        history = Array(h.prefix(20))
        UserDefaults.standard.set(history, forKey: "search_history")

        Task {
            do {
                let list = try await WebSearchService.shared.search(query: q, limit: 8)
                await MainActor.run {
                    results = list
                    isLoading = false
                    if list.isEmpty {
                        errorText = "未找到相关结果，请换个关键词试试"
                    } else {
                        summarize(query: q, results: list)
                    }
                }
            } catch {
                await MainActor.run {
                    isLoading = false
                    errorText = "搜索失败：\(error.localizedDescription)"
                }
            }
        }
    }

    private func summarize(query: String, results: [SearchResult]) {
        let settings = AppSettings.shared
        let config = settings.currentConfig()
        guard !config.apiKey.isEmpty else {
            aiSummary = "（配置 API Key 后可生成 AI 总结）"
            return
        }
        isSummarizing = true
        Task {
            let context = await WebSearchService.shared.formatForPrompt(results)
            let prompt = "用户搜索：\(query)\n\n\(context)\n\n请用简洁中文总结以上搜索结果的核心信息（不超过200字），并在末尾用一行列出主要来源标题。"
            do {
                let client = OpenAIStreamingClient()
                let messages = [
                    ChatMessage(role: .system, content: "你是搜索结果总结助手。", createdAt: Date()),
                    ChatMessage(role: .user, content: prompt, createdAt: Date())
                ]
                var text = ""
                let stream = try await client.streamChat(messages: messages, config: config)
                for try await part in stream {
                    text += part
                }
                await MainActor.run {
                    aiSummary = text
                    isSummarizing = false
                }
            } catch {
                await MainActor.run {
                    aiSummary = "AI 总结失败，请直接查看下方搜索结果。"
                    isSummarizing = false
                }
            }
        }
    }
}

struct BrowserItem: Identifiable {
    let id = UUID()
    let url: URL
}
