import XCTest
import SwiftData
import SwiftUI
@testable import Blackbird

final class FeedListViewTests: XCTestCase {

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

    func testFeedListViewInitialization() throws {
        // 创建视图
        let view = FeedListView()

        // 验证视图是否正确初始化
        XCTAssertNotNil(view, "FeedListView 应该正确初始化")
    }

    func testFeedListViewModelBinding() throws {
        // 创建视图模型
        let viewModel = FeedListViewModel(modelContext: modelContext)

        // 验证视图模型是否正确绑定
        // 注意：由于 SwiftUI 视图的特性，我们无法直接访问视图的内部属性
        // 所以这里只能验证视图模型是否正确初始化
        XCTAssertNotNil(viewModel, "视图模型应该正确初始化")

        // 验证视图模型中的数据是否正确加载
        let feeds = try viewModel.getAllFeeds()
        XCTAssertEqual(feeds.count, 3, "应该有 3 个 Feed")
    }

    // MARK: - 辅助方法

    private func setupTestData() throws {
        // 创建测试分类
        let category1 = FeedCategory(name: "技术", colorHex: "FF0000")
        let category2 = FeedCategory(name: "新闻", colorHex: "00FF00")

        modelContext.insert(category1)
        modelContext.insert(category2)
        try modelContext.save()

        // 创建测试 Feed
        let feed1 = Feed(
            title: "SwiftUI 博客",
            url: URL(string: "https://example.com/swiftui.xml")!
        )
        feed1.categoryID = category1.id
        feed1.isStarred = true

        let feed2 = Feed(
            title: "Swift 新闻",
            url: URL(string: "https://example.com/swift-news.xml")!
        )
        feed2.categoryID = category1.id

        let feed3 = Feed(
            title: "科技新闻",
            url: URL(string: "https://example.com/tech-news.xml")!
        )
        feed3.categoryID = category2.id

        modelContext.insert(feed1)
        modelContext.insert(feed2)
        modelContext.insert(feed3)
        try modelContext.save()
    }

    private func cleanupTestData() throws {
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

        // 清理所有 Article
        let articleDescriptor = FetchDescriptor<Article>()
        let articles = try modelContext.fetch(articleDescriptor)
        for article in articles {
            modelContext.delete(article)
        }

        try modelContext.save()
    }
}
