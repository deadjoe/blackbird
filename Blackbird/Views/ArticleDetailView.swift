import SwiftUI
import SwiftData
import WebKit
import Foundation

struct ArticleDetailView: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(\.openURL) private var openURL
    var article: Article
    @StateObject private var viewModel = ArticleViewModel()

    var body: some View {
        VStack(spacing: 0) {
            // 文章标题和元数据 - 使用自适应高度
            ScrollView {
                VStack(alignment: .leading, spacing: 12) {
                    // 添加顶部间距，避免被导航栏遮挡
                    Spacer()
                        .frame(height: 16)

                    Text(article.title)
                        .font(.title)
                        .fontWeight(.bold)
                        .fixedSize(horizontal: false, vertical: true) // 允许垂直方向自动调整大小

                    if let author = article.author, !author.isEmpty {
                        Text("By \(author)")
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                    }

                    if let pubDate = article.pubDate {
                        Text("Published: \(pubDate.formatted(date: .long, time: .shortened))")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }

                    if let estimatedTime = article.estimatedReadingTime {
                        Text("\(estimatedTime) min read")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                }
                .padding()
            }
            .frame(minHeight: 120, maxHeight: 220) // 增加高度，为顶部间距留出空间

            Divider()

            // 文章内容 - 使用WKWebView
            if let content = article.content, !content.isEmpty {
                WebViewWrapper(htmlContent: content.wrapInHTMLDocument(), baseURL: article.link)
                    .ignoresSafeArea(.container, edges: .bottom)
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                    .layoutPriority(1) // 给予更高的布局优先级
            } else if let description = article.articleDescription, !description.isEmpty {
                WebViewWrapper(htmlContent: description.wrapInHTMLDocument(), baseURL: article.link)
                    .ignoresSafeArea(.container, edges: .bottom)
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                    .layoutPriority(1) // 给予更高的布局优先级
            } else {
                ScrollView {
                    Text("No content available")
                        .italic()
                        .foregroundColor(.secondary)
                        .frame(maxWidth: .infinity, maxHeight: .infinity)
                        .padding()
                }
                .layoutPriority(1) // 给予更高的布局优先级
            }
        }
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .navigationBarTrailing) {
                Button {
                    viewModel.toggleStarred(article)
                } label: {
                    Image(systemName: article.isStarred ? "star.fill" : "star")
                        .foregroundColor(article.isStarred ? .yellow : .primary)
                }
            }

            if let link = article.link {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button {
                        openURL(link)
                    } label: {
                        Image(systemName: "safari")
                    }
                }
            }

            ToolbarItem(placement: .navigationBarTrailing) {
                ShareLink(item: article.link ?? URL(string: "https://example.com")!) {
                    Image(systemName: "square.and.arrow.up")
                }
            }
        }
        .onAppear {
            viewModel.setModelContext(modelContext)
            if !article.isRead {
                viewModel.markAsRead(article)
            }
        }
    }
}

// WebViewWrapper 结构体，用于在 SwiftUI 中显示 HTML 内容
struct WebViewWrapper: UIViewRepresentable {
    let htmlContent: String
    var baseURL: URL?

    func makeUIView(context: Context) -> WKWebView {
        // 创建 WKWebView 配置
        let configuration = WKWebViewConfiguration()
        configuration.allowsInlineMediaPlayback = true
        configuration.mediaTypesRequiringUserActionForPlayback = []

        // 创建 WKWebView
        let webView = WKWebView(frame: .zero, configuration: configuration)
        webView.navigationDelegate = context.coordinator
        webView.allowsBackForwardNavigationGestures = true

        // 确保滚动正常工作
        webView.scrollView.isScrollEnabled = true
        webView.scrollView.bounces = true
        webView.scrollView.alwaysBounceVertical = true
        webView.scrollView.showsVerticalScrollIndicator = true
        webView.scrollView.showsHorizontalScrollIndicator = false

        // 设置背景色与应用一致
        webView.backgroundColor = UIColor.systemBackground
        webView.isOpaque = false

        return webView
    }

    func updateUIView(_ webView: WKWebView, context: Context) {
        // 检查内容是否已经是完整的HTML文档
        let isCompleteHTML = htmlContent.lowercased().contains("<!doctype html") ||
                            (htmlContent.lowercased().contains("<html") &&
                             htmlContent.lowercased().contains("</html>"))

        if isCompleteHTML {
            // 如果已经是完整的HTML文档，直接加载
            webView.loadHTMLString(htmlContent, baseURL: baseURL)
        } else {
            // 添加基本的样式
            let styledHTML = """
            <!DOCTYPE html>
            <html>
            <head>
                <meta charset="UTF-8">
                <meta name="viewport" content="width=device-width, initial-scale=1.0, maximum-scale=5.0, user-scalable=yes">
                <style>
                    :root {
                        color-scheme: light dark;
                    }

                    body {
                        font-family: -apple-system, BlinkMacSystemFont, 'Segoe UI', Roboto, Helvetica, Arial, sans-serif;
                        line-height: 1.6;
                        padding: 12px;
                        margin: 0;
                        font-size: 16px;
                    }

                    @media (prefers-color-scheme: dark) {
                        body {
                            color: #FFFFFF;
                            background-color: #000000;
                        }
                        a {
                            color: #0A84FF;
                        }
                    }

                    @media (prefers-color-scheme: light) {
                        body {
                            color: #000000;
                            background-color: #FFFFFF;
                        }
                        a {
                            color: #007AFF;
                        }
                    }

                    img {
                        max-width: 100%;
                        height: auto;
                        display: block;
                        margin: 1em 0;
                    }

                    pre, code {
                        background-color: rgba(0, 0, 0, 0.05);
                        border-radius: 4px;
                        padding: 0.2em 0.4em;
                        overflow-x: auto;
                    }

                    blockquote {
                        border-left: 4px solid #ddd;
                        padding-left: 1em;
                        margin-left: 0;
                        color: #666;
                    }

                    h1, h2, h3, h4, h5, h6 {
                        line-height: 1.3;
                    }

                    table {
                        border-collapse: collapse;
                        width: 100%;
                        margin: 1em 0;
                    }

                    th, td {
                        border: 1px solid #ddd;
                        padding: 8px;
                        text-align: left;
                    }

                    th {
                        background-color: rgba(0, 0, 0, 0.05);
                    }
                </style>
            </head>
            <body>
                \(htmlContent)
            </body>
            </html>
            """

            webView.loadHTMLString(styledHTML, baseURL: baseURL)
        }
    }

    func makeCoordinator() -> Coordinator {
        Coordinator(self)
    }

    class Coordinator: NSObject, WKNavigationDelegate {
        var parent: WebViewWrapper

        init(_ parent: WebViewWrapper) {
            self.parent = parent
        }

        // 处理链接点击，在外部浏览器中打开
        func webView(_ webView: WKWebView, decidePolicyFor navigationAction: WKNavigationAction, decisionHandler: @escaping (WKNavigationActionPolicy) -> Void) {
            // 如果是用户点击链接
            if navigationAction.navigationType == .linkActivated {
                // 如果有URL，在外部浏览器中打开
                if let url = navigationAction.request.url {
                    UIApplication.shared.open(url)
                    decisionHandler(.cancel)
                    return
                }
            }

            // 允许其他导航
            decisionHandler(.allow)
        }
    }
}

#Preview {
    let config = ModelConfiguration(isStoredInMemoryOnly: true)
    let container = try! ModelContainer(for: Article.self, configurations: config)

    let article = Article(
        title: "Sample Article with a Long Title That Spans Multiple Lines",
        link: URL(string: "https://example.com"),
        description: "This is a sample article description.",
        content: "# Sample Content\n\nThis is a sample article content with **bold** and *italic* text.\n\n## Section\n\nMore content here.",
        author: "John Doe",
        pubDate: Date()
    )

    return NavigationStack {
        ArticleDetailView(article: article)
    }
    .modelContainer(container)
}
