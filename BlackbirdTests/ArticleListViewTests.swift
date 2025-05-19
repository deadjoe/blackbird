import XCTest
import SwiftData
import SwiftUI
@testable import Blackbird

final class ArticleListViewTests: XCTestCase {

    var modelContainer: ModelContainer!
    var modelContext: ModelContext!

    override func setUpWithError() throws {
        // 创建一个内存中的 ModelContainer 用于测试
        let schema = Schema([
            Feed.self,
            FeedCategory.self,
            Article.self
        ])

        let modelConfiguration = ModelConfiguration(
            schema: schema,
            isStoredInMemoryOnly: true
        )

        modelContainer = try ModelContainer(for: schema, configurations: [modelConfiguration])
        modelContext = ModelContext(modelContainer)

        // 清理测试数据
        try cleanupTestData()

        // 设置测试数据
        try setupTestData()
    }

    override func tearDownWithError() throws {
        // 清理测试数据
        try cleanupTestData()

        // 释放资源
        modelContext = nil
        modelContainer = nil
    }

    // MARK: - 测试方法

    func testArticleListViewInitialization() throws {
        // 获取测试 Feed
        let feedDescriptor = FetchDescriptor<Feed>(predicate: #Predicate<Feed> { $0.title == "SwiftUI 博客" })
        let feeds = try modelContext.fetch(feedDescriptor)
        XCTAssertEqual(feeds.count, 1, "应该找到一个 Feed")

        let feed = feeds.first!

        // 创建视图
        let view = ArticleListView(feed: feed)

        // 验证视图是否正确初始化
        XCTAssertNotNil(view, "ArticleListView 应该正确初始化")
    }

    func testArticleListViewModelBinding() throws {
        // 创建视图模型
        let viewModel = ArticleViewModel(modelContext: modelContext)

        // 获取测试 Feed
        let feedDescriptor = FetchDescriptor<Feed>(predicate: #Predicate<Feed> { $0.title == "SwiftUI 博客" })
        let feeds = try modelContext.fetch(feedDescriptor)
        XCTAssertEqual(feeds.count, 1, "应该找到一个 Feed")

        let feed = feeds.first!

        // 验证视图模型是否正确初始化
        XCTAssertNotNil(viewModel, "视图模型应该正确初始化")

        // 验证 Feed 中的文章数量
        XCTAssertEqual(feed.articles.count, 2, "应该有 2 篇文章")
    }

    // MARK: - 辅助方法

    private func setupTestData() throws {
        // 创建测试分类
        let category = FeedCategory(name: "技术", colorHex: "FF0000")

        modelContext.insert(category)
        try modelContext.save()

        // 创建测试 Feed
        let feed = Feed(
            title: "SwiftUI 博客",
            url: URL(string: "https://example.com/swiftui.xml")!
        )
        feed.categoryID = category.id

        modelContext.insert(feed)
        try modelContext.save()

        // 创建测试文章
        let article1 = Article(
            title: "SwiftUI 入门",
            link: URL(string: "https://example.com/swiftui-intro")!,
            description: "SwiftUI 入门教程",
            pubDate: Date()
        )
        feed.articles.append(article1)

        let article2 = Article(
            title: "SwiftUI 进阶",
            link: URL(string: "https://example.com/swiftui-advanced")!,
            description: "SwiftUI 进阶教程",
            pubDate: Date().addingTimeInterval(-86400) // 昨天
        )
        feed.articles.append(article2)

        modelContext.insert(article1)
        modelContext.insert(article2)
        try modelContext.save()
    }

    private func cleanupTestData() throws {
        // 清理所有 Article
        let articleDescriptor = FetchDescriptor<Article>()
        let articles = try modelContext.fetch(articleDescriptor)
        for article in articles {
            modelContext.delete(article)
        }

        // 清理所有 Feed
        let feedDescriptor = FetchDescriptor<Feed>()
        let feeds = try modelContext.fetch(feedDescriptor)
        for feed in feeds {
            modelContext.delete(feed)
        }

        // 清理所有 FeedCategory
        let categoryDescriptor = FetchDescriptor<FeedCategory>()
        let categories = try modelContext.fetch(categoryDescriptor)
        for category in categories {
            modelContext.delete(category)
        }

        try modelContext.save()
    }
}
