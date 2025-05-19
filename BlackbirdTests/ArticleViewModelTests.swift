import XCTest
import SwiftData
@testable import Blackbird

final class ArticleViewModelTests: XCTestCase {
    var modelContainer: ModelContainer!
    var modelContext: ModelContext!
    var viewModel: ArticleViewModel!
    
    override func setUpWithError() throws {
        let schema = Schema([Feed.self, Article.self])
        let configuration = ModelConfiguration(isStoredInMemoryOnly: true)
        modelContainer = try ModelContainer(for: schema, configurations: [configuration])
        modelContext = ModelContext(modelContainer)
        viewModel = ArticleViewModel(modelContext: modelContext)
    }
    
    override func tearDownWithError() throws {
        viewModel = nil
        modelContainer = nil
        modelContext = nil
    }
    
    // MARK: - Read/Unread Status Tests
    
    func testMarkAsRead() throws {
        // Create a test article
        let article = Article(
            title: "Test Article",
            isRead: false
        )
        
        // Create a feed and add the article
        let feed = Feed(
            title: "Test Feed",
            url: URL(string: "https://example.com/feed.xml")!
        )
        feed.articles.append(article)
        
        // Insert into context
        modelContext.insert(feed)
        modelContext.insert(article)
        
        // Verify initial state
        XCTAssertFalse(article.isRead)
        XCTAssertEqual(feed.unreadCount, 0) // unreadCount is not updated yet
        
        // Update unread count
        feed.updateUnreadCount()
        XCTAssertEqual(feed.unreadCount, 1)
        
        // Mark as read
        viewModel.markAsRead(article)
        
        // Verify article is marked as read
        XCTAssertTrue(article.isRead)
        
        // Verify feed's unread count is updated
        XCTAssertEqual(feed.unreadCount, 0)
    }
    
    func testMarkAsUnread() throws {
        // Create a test article
        let article = Article(
            title: "Test Article",
            isRead: true
        )
        
        // Create a feed and add the article
        let feed = Feed(
            title: "Test Feed",
            url: URL(string: "https://example.com/feed.xml")!
        )
        feed.articles.append(article)
        
        // Insert into context
        modelContext.insert(feed)
        modelContext.insert(article)
        
        // Verify initial state
        XCTAssertTrue(article.isRead)
        
        // Update unread count
        feed.updateUnreadCount()
        XCTAssertEqual(feed.unreadCount, 0)
        
        // Mark as unread
        viewModel.markAsUnread(article)
        
        // Verify article is marked as unread
        XCTAssertFalse(article.isRead)
        
        // Verify feed's unread count is updated
        XCTAssertEqual(feed.unreadCount, 1)
    }
    
    // MARK: - Star/Unstar Tests
    
    func testToggleStarred() throws {
        // Create a test article
        let article = Article(
            title: "Test Article",
            isStarred: false
        )
        
        // Insert into context
        modelContext.insert(article)
        
        // Verify initial state
        XCTAssertFalse(article.isStarred)
        
        // Toggle starred (star)
        viewModel.toggleStarred(article)
        
        // Verify article is starred
        XCTAssertTrue(article.isStarred)
        
        // Toggle starred again (unstar)
        viewModel.toggleStarred(article)
        
        // Verify article is unstarred
        XCTAssertFalse(article.isStarred)
    }
    
    // MARK: - Reading Position Tests
    
    func testSaveReadingPosition() throws {
        // Create a test article
        let article = Article(
            title: "Test Article"
        )
        
        // Insert into context
        modelContext.insert(article)
        
        // Verify initial state
        XCTAssertNil(article.lastReadPosition)
        
        // Save reading position
        viewModel.saveReadingPosition(article, position: 0.75)
        
        // Verify reading position is saved
        XCTAssertEqual(article.lastReadPosition, 0.75)
    }
    
    // MARK: - Tag Management Tests
    
    func testAddTag() throws {
        // Create a test article
        let article = Article(
            title: "Test Article"
        )
        
        // Insert into context
        modelContext.insert(article)
        
        // Verify initial state
        XCTAssertEqual(article.tags.count, 0)
        
        // Add a tag
        viewModel.addTag(article, tag: "technology")
        
        // Verify tag is added
        XCTAssertEqual(article.tags.count, 1)
        XCTAssertEqual(article.tags.first, "technology")
        
        // Add the same tag again (should not duplicate)
        viewModel.addTag(article, tag: "technology")
        
        // Verify no duplication
        XCTAssertEqual(article.tags.count, 1)
        
        // Add another tag
        viewModel.addTag(article, tag: "swift")
        
        // Verify second tag is added
        XCTAssertEqual(article.tags.count, 2)
        XCTAssertTrue(article.tags.contains("swift"))
    }
    
    func testRemoveTag() throws {
        // Create a test article with tags
        let article = Article(
            title: "Test Article"
        )
        article.tags = ["technology", "swift", "ios"]
        
        // Insert into context
        modelContext.insert(article)
        
        // Verify initial state
        XCTAssertEqual(article.tags.count, 3)
        
        // Remove a tag
        viewModel.removeTag(article, tag: "swift")
        
        // Verify tag is removed
        XCTAssertEqual(article.tags.count, 2)
        XCTAssertFalse(article.tags.contains("swift"))
        XCTAssertTrue(article.tags.contains("technology"))
        XCTAssertTrue(article.tags.contains("ios"))
        
        // Remove a non-existent tag (should not affect tags)
        viewModel.removeTag(article, tag: "nonexistent")
        
        // Verify tags are unchanged
        XCTAssertEqual(article.tags.count, 2)
    }
    
    // MARK: - Article Deletion Test
    
    func testDeleteArticle() throws {
        // Create a test article
        let article = Article(
            title: "Test Article",
            isRead: false
        )
        
        // Create a feed and add the article
        let feed = Feed(
            title: "Test Feed",
            url: URL(string: "https://example.com/feed.xml")!
        )
        feed.articles.append(article)
        
        // Insert into context
        modelContext.insert(feed)
        modelContext.insert(article)
        
        // Update unread count
        feed.updateUnreadCount()
        XCTAssertEqual(feed.unreadCount, 1)
        
        // Delete the article
        viewModel.deleteArticle(article)
        
        // Fetch articles to verify deletion
        let descriptor = FetchDescriptor<Article>()
        let articles = try modelContext.fetch(descriptor)
        
        // Verify article is deleted
        XCTAssertEqual(articles.count, 0)
        
        // Verify feed's unread count is updated
        XCTAssertEqual(feed.unreadCount, 0)
    }
}
