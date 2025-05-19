import XCTest
import SwiftData
import SwiftUI
import WebKit
@testable import Blackbird

final class ArticleDetailViewTests: XCTestCase {
    var modelContainer: ModelContainer!
    var modelContext: ModelContext!
    var viewModel: ArticleViewModel!
    var testArticle: Article!

    override func setUpWithError() throws {
        let schema = Schema([Feed.self, Article.self, FeedCategory.self])
        let configuration = ModelConfiguration(isStoredInMemoryOnly: true)
        modelContainer = try ModelContainer(for: schema, configurations: [configuration])
        modelContext = ModelContext(modelContainer)
        viewModel = ArticleViewModel(modelContext: modelContext)

        // 创建测试文章
        testArticle = Article(
            title: "Test Article",
            link: URL(string: "https://example.com/article"),
            description: "This is a test article description",
            content: "<p>This is the full content of the test article.</p>",
            author: "Test Author",
            pubDate: Date(),
            isRead: false,
            isStarred: false,
            imageURL: nil,
            guid: "test-article-guid"
        )

        modelContext.insert(testArticle)
        try modelContext.save()
    }

    override func tearDownWithError() throws {
        viewModel = nil
        modelContainer = nil
        modelContext = nil
        testArticle = nil
    }

    // MARK: - ArticleDetailView Tests

    func testArticleDetailViewCreation() {
        // 创建视图
        let view = ArticleDetailView(article: testArticle)

        // 验证视图已正确创建
        XCTAssertNotNil(view)
        XCTAssertEqual(view.article.title, "Test Article")
        XCTAssertEqual(view.article.author, "Test Author")
    }

    func testArticleToggleStarred() {
        // 创建视图模型
        let viewModel = ArticleViewModel(modelContext: modelContext)

        // 验证文章初始状态为未收藏
        XCTAssertFalse(testArticle.isStarred)

        // 切换收藏状态
        viewModel.toggleStarred(testArticle)

        // 验证文章状态已更改为已收藏
        XCTAssertTrue(testArticle.isStarred)

        // 再次切换收藏状态
        viewModel.toggleStarred(testArticle)

        // 验证文章状态已更改回未收藏
        XCTAssertFalse(testArticle.isStarred)
    }

    func testMarkArticleAsRead() {
        // 创建视图模型
        let viewModel = ArticleViewModel(modelContext: modelContext)

        // 验证文章初始状态为未读
        XCTAssertFalse(testArticle.isRead)

        // 标记为已读
        viewModel.markAsRead(testArticle)

        // 验证文章状态已更改为已读
        XCTAssertTrue(testArticle.isRead)
    }

    // MARK: - WebViewWrapper Tests

    func testWebViewWrapperCreation() {
        // 创建 HTML 内容
        let htmlContent = "<html><body><h1>Test Content</h1></body></html>"

        // 创建 WebViewWrapper
        let webViewWrapper = WebViewWrapper(htmlContent: htmlContent, baseURL: testArticle.link)

        // 验证 WebViewWrapper 已正确创建
        XCTAssertNotNil(webViewWrapper)
        XCTAssertEqual(webViewWrapper.htmlContent, htmlContent)
        XCTAssertEqual(webViewWrapper.baseURL, testArticle.link)
    }

    func testWebViewWrapperCoordinator() {
        // 创建 HTML 内容
        let htmlContent = "<html><body><h1>Test Content</h1></body></html>"

        // 创建 WebViewWrapper
        let webViewWrapper = WebViewWrapper(htmlContent: htmlContent, baseURL: testArticle.link)

        // 创建 Coordinator
        let coordinator = webViewWrapper.makeCoordinator()

        // 验证 Coordinator 已正确创建
        XCTAssertNotNil(coordinator)

        // 由于 WebViewWrapper 不符合 Equatable 协议，我们不能直接比较对象
        // 而是验证 coordinator.parent 的 htmlContent 和 baseURL 与 webViewWrapper 的相同
        XCTAssertEqual(coordinator.parent.htmlContent, webViewWrapper.htmlContent)
        XCTAssertEqual(coordinator.parent.baseURL, webViewWrapper.baseURL)
    }

    func testWebViewWrapperNavigationAction() {
        // 创建 HTML 内容
        let htmlContent = "<html><body><h1>Test Content</h1></body></html>"

        // 创建 WebViewWrapper
        let webViewWrapper = WebViewWrapper(htmlContent: htmlContent, baseURL: testArticle.link)

        // 创建 Coordinator
        let coordinator = webViewWrapper.makeCoordinator()

        // 创建模拟的 WKNavigationAction
        let mockWebView = WKWebView()
        let mockNavigationAction = MockWKNavigationAction(url: URL(string: "https://example.com/external")!)

        // 测试决策策略
        let expectation = XCTestExpectation(description: "Decision handler called")

        coordinator.webView(mockWebView, decidePolicyFor: mockNavigationAction) { policy in
            // 验证策略是取消的（因为链接会在外部浏览器中打开）
            XCTAssertEqual(policy, .cancel)
            expectation.fulfill()
        }

        wait(for: [expectation], timeout: 1.0)
    }

    func testStringHTMLExtension() {
        // 测试 wrapInHTMLDocument 方法
        let htmlContent = "<p>Test content</p>"
        let wrappedHTML = htmlContent.wrapInHTMLDocument()

        // 验证 HTML 已正确包装
        XCTAssertTrue(wrappedHTML.contains("<!DOCTYPE html>"))
        XCTAssertTrue(wrappedHTML.contains("<html>"))
        XCTAssertTrue(wrappedHTML.contains("</html>"))
        XCTAssertTrue(wrappedHTML.contains(htmlContent))

        // 测试已经是完整 HTML 文档的情况
        let completeHTML = "<!DOCTYPE html><html><body>Test</body></html>"
        let wrappedCompleteHTML = completeHTML.wrapInHTMLDocument()

        // 验证已经是完整 HTML 文档的内容不会被再次包装
        XCTAssertEqual(wrappedCompleteHTML, completeHTML)
    }

    func testCleanHTMLTags() {
        // 测试 cleanHTMLTags 方法
        let htmlContent = "<p>This is <strong>bold</strong> and <em>italic</em> text.</p>"
        let cleanedText = htmlContent.cleanHTMLTags()

        // 验证 HTML 标签已被移除
        XCTAssertEqual(cleanedText, "This is bold and italic text.")

        // 测试 HTML 实体
        let htmlWithEntities = "This &amp; that &lt;tag&gt; &quot;quoted&quot;"
        let cleanedEntities = htmlWithEntities.cleanHTMLTags()

        // 验证 HTML 实体已被转换
        XCTAssertEqual(cleanedEntities, "This & that <tag> \"quoted\"")
    }
}

// 模拟 WKNavigationAction 用于测试
class MockWKNavigationAction: WKNavigationAction {
    private let mockURL: URL

    init(url: URL) {
        self.mockURL = url
        super.init()
    }

    override var request: URLRequest {
        return URLRequest(url: mockURL)
    }

    override var navigationType: WKNavigationType {
        return .linkActivated
    }
}
