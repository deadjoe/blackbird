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
        // Create a category with a known ID
        let category = FeedCategory(name: "Technology", colorHex: "FF0000")
        category.id = "test-category-id"

        // Insert category into context
        modelContext.insert(category)
        try modelContext.save()

        // Create feeds with the category
        let feed1 = Feed(
            title: "Tech Feed 1",
            url: URL(string: "https://example.com/tech1.xml")!
        )
        feed1.categoryID = category.id

        let feed2 = Feed(
            title: "Tech Feed 2",
            url: URL(string: "https://example.com/tech2.xml")!
        )
        feed2.categoryID = category.id

        // Insert feeds into context
        modelContext.insert(feed1)
        modelContext.insert(feed2)
        try modelContext.save()

        // Verify the category exists
        let categoryDescriptor = FetchDescriptor<FeedCategory>(predicate: #Predicate { $0.id == "test-category-id" })
        let categories = try modelContext.fetch(categoryDescriptor)

        XCTAssertEqual(categories.count, 1, "Should find exactly one category")
        XCTAssertEqual(categories.first?.name, "Technology", "Category name should match")
        XCTAssertEqual(categories.first?.colorHex, "FF0000", "Category color should match")

        // Verify feeds with category ID
        let feedDescriptor = FetchDescriptor<Feed>(predicate: #Predicate { $0.categoryID == "test-category-id" })
        let feeds = try modelContext.fetch(feedDescriptor)

        XCTAssertEqual(feeds.count, 2, "Should find exactly two feeds")

        // Sort feeds by title for consistent testing
        let sortedFeeds = feeds.sorted(by: { $0.title < $1.title })
        XCTAssertEqual(sortedFeeds.count, 2, "Should have two feeds after sorting")

        if sortedFeeds.count >= 2 {
            XCTAssertEqual(sortedFeeds[0].title, "Tech Feed 1", "First feed title should match")
            XCTAssertEqual(sortedFeeds[1].title, "Tech Feed 2", "Second feed title should match")
        }
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
