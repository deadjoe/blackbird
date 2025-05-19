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
            description: "Test Description",
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
        XCTAssertEqual(feeds.first?.description, "Test Description")
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
        XCTAssertEqual(articles.first?.description, "Test Description")
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
}
