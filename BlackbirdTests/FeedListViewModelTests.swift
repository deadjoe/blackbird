import XCTest
import SwiftData
import SwiftUI
@testable import Blackbird

final class FeedListViewModelTests: XCTestCase {

    var modelContainer: ModelContainer!
    var modelContext: ModelContext!
    var viewModel: FeedListViewModel!

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

        // 创建视图模型
        viewModel = FeedListViewModel(modelContext: modelContext)
    }

    override func tearDownWithError() throws {
        // 清理测试数据
        try cleanupTestData()

        // 释放资源
        viewModel = nil
        modelContext = nil
        modelContainer = nil
    }

    // MARK: - 测试方法

    func testGetAllFeeds() throws {
        // 测试获取所有 Feed
        let feeds = try viewModel.getAllFeeds()
        XCTAssertEqual(feeds.count, 3, "应该有 3 个 Feed")
    }

    func testGetFeedsInCategory() throws {
        // 获取分类
        let categoryDescriptor = FetchDescriptor<FeedCategory>(predicate: #Predicate<FeedCategory> { $0.name == "技术" })
        let categories = try modelContext.fetch(categoryDescriptor)
        XCTAssertEqual(categories.count, 1, "应该找到一个分类")

        let category = categories.first!

        // 测试获取特定分类的 Feed
        let feeds = try viewModel.getFeedsInCategory(category)
        XCTAssertEqual(feeds.count, 2, "技术分类应该有 2 个 Feed")
    }

    func testGetStarredFeeds() throws {
        // 测试获取收藏的 Feed
        let starredFeeds = try viewModel.getStarredFeeds()
        XCTAssertEqual(starredFeeds.count, 1, "应该有 1 个收藏的 Feed")
        XCTAssertEqual(starredFeeds.first?.title, "SwiftUI 博客", "收藏的 Feed 标题应该是 SwiftUI 博客")
    }

    func testToggleStarred() throws {
        // 获取一个未收藏的 Feed
        let feedDescriptor = FetchDescriptor<Feed>(predicate: #Predicate<Feed> { $0.title == "Swift 新闻" })
        let feeds = try modelContext.fetch(feedDescriptor)
        XCTAssertEqual(feeds.count, 1, "应该找到一个 Feed")

        let feed = feeds.first!
        XCTAssertFalse(feed.isStarred, "Feed 初始应该未收藏")

        // 测试收藏 Feed
        viewModel.toggleStarred(feed: feed)

        // 验证 Feed 已收藏
        let updatedFeeds = try modelContext.fetch(feedDescriptor)
        XCTAssertEqual(updatedFeeds.count, 1, "应该找到一个 Feed")
        XCTAssertTrue(updatedFeeds.first!.isStarred, "Feed 应该已收藏")

        // 测试取消收藏
        viewModel.toggleStarred(feed: updatedFeeds.first!)

        // 验证 Feed 已取消收藏
        let finalFeeds = try modelContext.fetch(feedDescriptor)
        XCTAssertEqual(finalFeeds.count, 1, "应该找到一个 Feed")
        XCTAssertFalse(finalFeeds.first!.isStarred, "Feed 应该已取消收藏")
    }

    func testDeleteFeed() throws {
        // 获取一个 Feed
        let feedDescriptor = FetchDescriptor<Feed>(predicate: #Predicate<Feed> { $0.title == "科技新闻" })
        let feeds = try modelContext.fetch(feedDescriptor)
        XCTAssertEqual(feeds.count, 1, "应该找到一个 Feed")

        let feed = feeds.first!

        // 测试删除 Feed
        viewModel.deleteFeed(feed)

        // 验证 Feed 已删除
        let updatedFeeds = try modelContext.fetch(feedDescriptor)
        XCTAssertEqual(updatedFeeds.count, 0, "Feed 应该已删除")

        // 验证总 Feed 数量减少
        let allFeeds = try viewModel.getAllFeeds()
        XCTAssertEqual(allFeeds.count, 2, "总 Feed 数量应该减少到 2")
    }

    func testRefreshFeed() async throws {
        // 这个测试需要模拟 FeedService，因为我们不想在单元测试中进行实际的网络请求
        // 在这里，我们只测试 refreshFeed 方法是否正确设置了 isLoading 状态

        // 获取一个 Feed
        let feedDescriptor = FetchDescriptor<Feed>(predicate: #Predicate<Feed> { $0.title == "SwiftUI 博客" })
        let feeds = try modelContext.fetch(feedDescriptor)
        XCTAssertEqual(feeds.count, 1, "应该找到一个 Feed")

        let feed = feeds.first!

        // 记录刷新前的状态
        XCTAssertFalse(viewModel.isLoading, "刷新前 isLoading 应该为 false")
        XCTAssertNil(viewModel.errorMessage, "刷新前 errorMessage 应该为 nil")

        // 创建一个任务来测试异步方法
        let task = Task {
            await viewModel.refreshFeed(feed)
        }

        // 等待一小段时间，让异步方法开始执行
        try await Task.sleep(nanoseconds: 100_000_000) // 0.1 秒

        // 验证 isLoading 状态已更新
        XCTAssertTrue(viewModel.isLoading, "刷新过程中 isLoading 应该为 true")

        // 等待任务完成
        _ = await task.value

        // 验证刷新后的状态
        XCTAssertFalse(viewModel.isLoading, "刷新后 isLoading 应该为 false")
        XCTAssertNotNil(viewModel.errorMessage, "刷新后应该有错误消息（因为这是模拟的网络请求）")
    }

    func testRefreshAllFeeds() async throws {
        // 同样，这个测试也只关注状态变化，而不是实际的网络请求

        // 记录刷新前的状态
        XCTAssertFalse(viewModel.isLoading, "刷新前 isLoading 应该为 false")
        XCTAssertNil(viewModel.errorMessage, "刷新前 errorMessage 应该为 nil")

        // 创建一个任务来测试异步方法
        let task = Task {
            await viewModel.refreshAllFeeds()
        }

        // 等待一小段时间，让异步方法开始执行
        try await Task.sleep(nanoseconds: 100_000_000) // 0.1 秒

        // 验证 isLoading 状态已更新
        XCTAssertTrue(viewModel.isLoading, "刷新过程中 isLoading 应该为 true")

        // 等待任务完成
        _ = await task.value

        // 验证刷新后的状态
        XCTAssertFalse(viewModel.isLoading, "刷新后 isLoading 应该为 false")
        XCTAssertNotNil(viewModel.errorMessage, "刷新后应该有错误消息（因为这是模拟的网络请求）")
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
