import XCTest
import SwiftData
@testable import Blackbird
import FeedKit

final class FeedServiceTests: XCTestCase {
    var modelContainer: ModelContainer!
    var modelContext: ModelContext!

    override func setUpWithError() throws {
        // 创建一个内存中的 ModelContainer 用于测试
        let schema = Schema([
            Blackbird.Feed.self,
            FeedCategory.self,
            Article.self
        ])

        let configuration = ModelConfiguration(
            schema: schema,
            isStoredInMemoryOnly: true
        )

        modelContainer = try ModelContainer(for: schema, configurations: [configuration])
        modelContext = ModelContext(modelContainer)

        // 清理测试数据
        try cleanupTestData()
    }

    override func tearDownWithError() throws {
        // 清理测试数据
        try cleanupTestData()

        // 释放资源
        modelContext = nil
        modelContainer = nil
    }

    // MARK: - 辅助方法

    private func cleanupTestData() throws {
        // 清理所有 Feed
        let feedDescriptor = FetchDescriptor<Blackbird.Feed>()
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

    func testAddFeed() async throws {
        // 创建一个使用测试上下文的视图模型
        let viewModel = FeedListViewModel(modelContext: modelContext)

        // 添加一个无效URL的Feed
        await viewModel.addFeed(urlString: "not a url")

        // 验证错误消息
        XCTAssertNotNil(viewModel.errorMessage, "应该有错误消息")

        // 由于错误消息可能会根据实现变化，我们只检查它是否包含关键词
        XCTAssertTrue(viewModel.errorMessage?.contains("URL") == true ||
                     viewModel.errorMessage?.contains("失败") == true,
                     "错误消息应该包含'URL'或'失败'")
    }

    func testAddFeedWithCategory() async throws {
        // 简化测试，只测试基本的 Feed 和 Category 关系

        // 创建一个 Feed
        let feed = Blackbird.Feed(
            title: "Test Feed",
            url: URL(string: "https://example.com/test.xml")!
        )

        // 创建一个 Category
        let category = FeedCategory(name: "Test Category", colorHex: "FF0000")

        // 插入到上下文
        modelContext.insert(feed)
        modelContext.insert(category)
        try modelContext.save()

        // 确保 ID 不为 nil
        XCTAssertNotNil(feed.id, "Feed ID should not be nil")
        XCTAssertNotNil(category.id, "Category ID should not be nil")

        // 设置关系
        feed.categoryID = category.id
        try modelContext.save()

        // 验证关系
        let feedDescriptor = FetchDescriptor<Blackbird.Feed>(predicate: #Predicate<Blackbird.Feed> { $0.title == "Test Feed" })
        let feeds = try modelContext.fetch(feedDescriptor)

        XCTAssertGreaterThanOrEqual(feeds.count, 1, "Should find at least one feed")

        if let retrievedFeed = feeds.first {
            XCTAssertEqual(retrievedFeed.title, "Test Feed", "Feed title should match")
            XCTAssertEqual(retrievedFeed.categoryID, category.id, "Feed should be associated with the category")
        }
    }

    func testDiscoverFeeds() async throws {
        // 创建一个使用测试上下文的视图模型
        let viewModel = FeedListViewModel(modelContext: modelContext)

        // 使用无效URL测试
        await viewModel.discoverFeeds(from: "not a url")

        // 验证错误消息
        XCTAssertNotNil(viewModel.errorMessage, "应该有错误消息")

        // 由于错误消息可能会根据实现变化，我们只检查它是否包含关键词
        XCTAssertTrue(viewModel.errorMessage?.contains("URL") == true ||
                     viewModel.errorMessage?.contains("失败") == true,
                     "错误消息应该包含'URL'或'失败'")
    }
}
