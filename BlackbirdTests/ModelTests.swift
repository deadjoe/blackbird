import XCTest
import SwiftData
@testable import Blackbird

final class ModelTests: XCTestCase {
    var modelContainer: ModelContainer!
    var modelContext: ModelContext!

    override func setUpWithError() throws {
        let schema = Schema([Feed.self, Article.self])
        let configuration = ModelConfiguration(isStoredInMemoryOnly: true)
        modelContainer = try ModelContainer(for: schema, configurations: [configuration])
        modelContext = ModelContext(modelContainer)
    }

    override func tearDownWithError() throws {
        modelContainer = nil
        modelContext = nil
    }

    func testFeedModel() throws {
        // Create a feed
        let feed = Feed(
            title: "Test Feed",
            url: URL(string: "https://example.com/feed.xml")!,
            feedDescription: "Test Description",
            imageURL: URL(string: "https://example.com/image.jpg"),
            isStarred: true
        )

        // Insert into context
        modelContext.insert(feed)

        // Fetch and verify
        let descriptor = FetchDescriptor<Feed>()
        let feeds = try modelContext.fetch(descriptor)

        XCTAssertEqual(feeds.count, 1)
        XCTAssertEqual(feeds.first?.title, "Test Feed")
        XCTAssertEqual(feeds.first?.url, URL(string: "https://example.com/feed.xml")!)
        XCTAssertEqual(feeds.first?.feedDescription, "Test Description")
        XCTAssertEqual(feeds.first?.imageURL, URL(string: "https://example.com/image.jpg"))
        XCTAssertEqual(feeds.first?.isStarred, true)
    }

    func testArticleModel() throws {
        // Create an article
        let article = Article(
            title: "Test Article",
            link: URL(string: "https://example.com/article"),
            description: "Test Description",
            content: "Test Content",
            author: "Test Author",
            pubDate: Date(),
            isRead: false,
            isStarred: true
        )

        // Insert into context
        modelContext.insert(article)

        // Fetch and verify
        let descriptor = FetchDescriptor<Article>()
        let articles = try modelContext.fetch(descriptor)

        XCTAssertEqual(articles.count, 1)
        XCTAssertEqual(articles.first?.title, "Test Article")
        XCTAssertEqual(articles.first?.link, URL(string: "https://example.com/article"))
        XCTAssertEqual(articles.first?.articleDescription, "Test Description")
        XCTAssertEqual(articles.first?.content, "Test Content")
        XCTAssertEqual(articles.first?.author, "Test Author")
        XCTAssertNotNil(articles.first?.pubDate)
        XCTAssertEqual(articles.first?.isRead, false)
        XCTAssertEqual(articles.first?.isStarred, true)
    }

    func testFeedArticleRelationship() throws {
        // Create a feed
        let feed = Feed(
            title: "Test Feed",
            url: URL(string: "https://example.com/feed.xml")!
        )

        // Create articles
        let article1 = Article(title: "Article 1")
        let article2 = Article(title: "Article 2")

        // Add articles to feed
        feed.articles = [article1, article2]

        // Insert into context
        modelContext.insert(feed)
        modelContext.insert(article1)
        modelContext.insert(article2)

        // Fetch and verify
        let descriptor = FetchDescriptor<Feed>()
        let feeds = try modelContext.fetch(descriptor)

        XCTAssertEqual(feeds.count, 1)
        XCTAssertEqual(feeds.first?.articles.count, 2)
        XCTAssertEqual(feeds.first?.articles[0].title, "Article 1")
        XCTAssertEqual(feeds.first?.articles[1].title, "Article 2")
    }

    func testFeedCategoryRelationship() throws {
        // 简化测试，只测试基本的 Feed 和 Category 关系

        // 创建一个 Feed
        let feed = Feed(
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
        let feedDescriptor = FetchDescriptor<Feed>(predicate: #Predicate { $0.title == "Test Feed" })
        let feeds = try modelContext.fetch(feedDescriptor)

        XCTAssertGreaterThanOrEqual(feeds.count, 1, "Should find at least one feed")

        if let retrievedFeed = feeds.first {
            XCTAssertEqual(retrievedFeed.title, "Test Feed", "Feed title should match")
            XCTAssertEqual(retrievedFeed.categoryID, category.id, "Feed should be associated with the category")
        }
    }

    // 辅助方法：清理测试数据
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

        try modelContext.save()
    }

    func testArticleExtendedProperties() throws {
        // Create an article with extended properties
        let article = Article(
            title: "Test Article with Extended Properties",
            link: URL(string: "https://example.com/article"),
            description: "This is a test article with extended properties",
            content: "# Heading\n\nThis is a test article with **bold** and *italic* text that should be long enough to calculate reading time.",
            author: "Test Author",
            pubDate: Date(),
            guid: "unique-guid-123"
        )

        // Add tags
        article.tags = ["technology", "test", "swift"]

        // Set reading position
        article.lastReadPosition = 0.5

        // Calculate reading time
        article.calculateReadingTime()

        // Extract main image (would normally happen automatically)
        article.imageURL = URL(string: "https://example.com/image.jpg")

        // Update searchable content
        article.updateSearchableContent()

        // Insert into context
        modelContext.insert(article)

        // Fetch and verify
        let descriptor = FetchDescriptor<Article>(predicate: #Predicate { $0.guid == "unique-guid-123" })
        let articles = try modelContext.fetch(descriptor)

        XCTAssertEqual(articles.count, 1)
        XCTAssertEqual(articles.first?.title, "Test Article with Extended Properties")
        XCTAssertEqual(articles.first?.tags.count, 3)
        XCTAssertTrue(articles.first?.tags.contains("technology") ?? false)
        XCTAssertEqual(articles.first?.lastReadPosition, 0.5)
        XCTAssertNotNil(articles.first?.estimatedReadingTime)
        XCTAssertEqual(articles.first?.imageURL, URL(string: "https://example.com/image.jpg"))
        XCTAssertNotNil(articles.first?.searchableContent)
        XCTAssertTrue(articles.first?.searchableContent?.contains("Test Article") ?? false)
    }
}
