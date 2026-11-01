import SwiftUI
import WebKit

struct InAppBrowserView: View {
    let url: URL
    @Environment(\.dismiss) private var dismiss
    @State private var pageTitle = "加载中…"
    @State private var canGoBack = false
    @State private var canGoForward = false
    @State private var progress: Double = 0
    @State private var webView = WKWebView()

    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                if progress > 0 && progress < 1 {
                    ProgressView(value: progress)
                        .progressViewStyle(.linear)
                }
                WebViewRepresentable(
                    webView: webView,
                    url: url,
                    pageTitle: $pageTitle,
                    canGoBack: $canGoBack,
                    canGoForward: $canGoForward,
                    progress: $progress
                )
            }
            .navigationTitle(pageTitle)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("关闭") { dismiss() }
                }
                ToolbarItemGroup(placement: .bottomBar) {
                    Button { webView.goBack() } label: {
                        Image(systemName: "chevron.backward")
                    }
                    .disabled(!canGoBack)

                    Button { webView.goForward() } label: {
                        Image(systemName: "chevron.forward")
                    }
                    .disabled(!canGoForward)

                    Spacer()

                    Button { webView.reload() } label: {
                        Image(systemName: "arrow.clockwise")
                    }

                    Button {
                        UIApplication.shared.open(url)
                    } label: {
                        Image(systemName: "safari")
                    }
                }
            }
        }
    }
}

struct WebViewRepresentable: UIViewRepresentable {
    let webView: WKWebView
    let url: URL
    @Binding var pageTitle: String
    @Binding var canGoBack: Bool
    @Binding var canGoForward: Bool
    @Binding var progress: Double

    func makeCoordinator() -> Coordinator { Coordinator(self) }

    func makeUIView(context: Context) -> WKWebView {
        webView.navigationDelegate = context.coordinator
        webView.allowsBackForwardNavigationGestures = true
        webView.load(URLRequest(url: url))
        context.coordinator.observe(webView)
        return webView
    }

    func updateUIView(_ uiView: WKWebView, context: Context) {}

    class Coordinator: NSObject, WKNavigationDelegate {
        var parent: WebViewRepresentable
        private var observations: [NSKeyValueObservation] = []

        init(_ parent: WebViewRepresentable) { self.parent = parent }

        func observe(_ webView: WKWebView) {
            observations = [
                webView.observe(\.title) { [weak self] wv, _ in
                    DispatchQueue.main.async { self?.parent.pageTitle = wv.title ?? "" }
                },
                webView.observe(\.canGoBack) { [weak self] wv, _ in
                    DispatchQueue.main.async { self?.parent.canGoBack = wv.canGoBack }
                },
                webView.observe(\.canGoForward) { [weak self] wv, _ in
                    DispatchQueue.main.async { self?.parent.canGoForward = wv.canGoForward }
                },
                webView.observe(\.estimatedProgress) { [weak self] wv, _ in
                    DispatchQueue.main.async { self?.parent.progress = wv.estimatedProgress }
                }
            ]
        }

        func webView(_ webView: WKWebView, didFinish navigation: WKNavigation!) {
            parent.pageTitle = webView.title ?? parent.url.host ?? "网页"
        }
    }
}
