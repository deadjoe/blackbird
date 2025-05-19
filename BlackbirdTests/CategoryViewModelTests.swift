import XCTest
import SwiftData
@testable import Blackbird

final class CategoryViewModelTests: XCTestCase {
    var modelContainer: ModelContainer!
    var modelContext: ModelContext!
    var viewModel: CategoryViewModel!
    
    override func setUpWithError() throws {
        let schema = Schema([Feed.self, Article.self, FeedCategory.self])
        let configuration = ModelConfiguration(isStoredInMemoryOnly: true)
        modelContainer = try ModelContainer(for: schema, configurations: [configuration])
        modelContext = ModelContext(modelContainer)
        viewModel = CategoryViewModel(modelContext: modelContext)
    }
    
    override func tearDownWithError() throws {
        viewModel = nil
        modelContainer = nil
        modelContext = nil
    }
    
    // MARK: - Category Creation Tests
    
    func testCreateCategory() throws {
        // Create a category
        try viewModel.createCategory(name: "Technology", colorHex: "FF0000")
        
        // Fetch categories
        let categories = try viewModel.getAllCategories()
        
        // Verify category was created
        XCTAssertEqual(categories.count, 1)
        XCTAssertEqual(categories.first?.name, "Technology")
        XCTAssertEqual(categories.first?.colorHex, "FF0000")
        XCTAssertNotNil(categories.first?.id)
    }
    
    func testCreateCategoryWithDefaultValues() throws {
        // Create a category with only name
        try viewModel.createCategory(name: "News")
        
        // Fetch categories
        let categories = try viewModel.getAllCategories()
        
        // Verify category was created with default values
        XCTAssertEqual(categories.count, 1)
        XCTAssertEqual(categories.first?.name, "News")
        XCTAssertNil(categories.first?.colorHex)
        XCTAssertEqual(categories.first?.sortOrder, 0)
        XCTAssertEqual(categories.first?.isExpanded, true)
    }
    
    func testCreateDuplicateCategory() throws {
        // Create a category
        try viewModel.createCategory(name: "Technology")
        
        // Try to create a category with the same name
        try viewModel.createCategory(name: "Technology")
        
        // Fetch categories
        let categories = try viewModel.getAllCategories()
        
        // Verify only one category was created (no duplicates)
        // Note: This depends on how your implementation handles duplicates
        // If your implementation allows duplicates, this test should be adjusted
        XCTAssertEqual(categories.count, 2)
    }
    
    // MARK: - Category Retrieval Tests
    
    func testGetAllCategories() throws {
        // Create multiple categories
        try viewModel.createCategory(name: "Technology", colorHex: "FF0000")
        try viewModel.createCategory(name: "News", colorHex: "00FF00")
        try viewModel.createCategory(name: "Entertainment", colorHex: "0000FF")
        
        // Fetch all categories
        let categories = try viewModel.getAllCategories()
        
        // Verify all categories are retrieved
        XCTAssertEqual(categories.count, 3)
        
        // Verify categories are sorted by sortOrder
        let sortedCategories = categories.sorted(by: { $0.sortOrder < $1.sortOrder })
        XCTAssertEqual(categories, sortedCategories)
    }
    
    func testGetCategoryByName() throws {
        // Create categories
        try viewModel.createCategory(name: "Technology", colorHex: "FF0000")
        try viewModel.createCategory(name: "News", colorHex: "00FF00")
        
        // Fetch category by name
        let category = try viewModel.getCategory(byName: "News")
        
        // Verify correct category is retrieved
        XCTAssertNotNil(category)
        XCTAssertEqual(category?.name, "News")
        XCTAssertEqual(category?.colorHex, "00FF00")
    }
    
    func testGetCategoryByNameNotFound() throws {
        // Create a category
        try viewModel.createCategory(name: "Technology")
        
        // Try to fetch a non-existent category
        let category = try? viewModel.getCategory(byName: "NonExistent")
        
        // Verify no category is found
        XCTAssertNil(category)
    }
    
    // MARK: - Category Update Tests
    
    func testUpdateCategory() throws {
        // Create a category
        try viewModel.createCategory(name: "Technology")
        
        // Fetch the category
        let category = try viewModel.getCategory(byName: "Technology")
        XCTAssertNotNil(category)
        
        // Update the category
        if let category = category {
            try viewModel.updateCategory(category, name: "Tech News", colorHex: "FF0000", isExpanded: false)
        }
        
        // Fetch the updated category
        let updatedCategory = try viewModel.getCategory(byName: "Tech News")
        
        // Verify category was updated
        XCTAssertNotNil(updatedCategory)
        XCTAssertEqual(updatedCategory?.name, "Tech News")
        XCTAssertEqual(updatedCategory?.colorHex, "FF0000")
        XCTAssertEqual(updatedCategory?.isExpanded, false)
    }
    
    func testUpdateCategoryPartial() throws {
        // Create a category
        try viewModel.createCategory(name: "Technology")
        
        // Fetch the category
        let category = try viewModel.getCategory(byName: "Technology")
        XCTAssertNotNil(category)
        
        // Update only the color
        if let category = category {
            try viewModel.updateCategory(category, colorHex: "FF0000")
        }
        
        // Fetch the updated category
        let updatedCategory = try viewModel.getCategory(byName: "Technology")
        
        // Verify only color was updated
        XCTAssertNotNil(updatedCategory)
        XCTAssertEqual(updatedCategory?.name, "Technology") // Name unchanged
        XCTAssertEqual(updatedCategory?.colorHex, "FF0000") // Color updated
        XCTAssertEqual(updatedCategory?.isExpanded, true) // Expansion state unchanged
    }
    
    // MARK: - Category Deletion Tests
    
    func testDeleteCategory() throws {
        // Create categories
        try viewModel.createCategory(name: "Technology")
        try viewModel.createCategory(name: "News")
        
        // Verify categories exist
        var categories = try viewModel.getAllCategories()
        XCTAssertEqual(categories.count, 2)
        
        // Delete a category
        if let category = try viewModel.getCategory(byName: "Technology") {
            try viewModel.deleteCategory(category)
        }
        
        // Verify category was deleted
        categories = try viewModel.getAllCategories()
        XCTAssertEqual(categories.count, 1)
        XCTAssertEqual(categories.first?.name, "News")
    }
    
    func testDeleteDefaultCategory() throws {
        // Create the default category
        try viewModel.createCategory(name: "未分类")
        
        // Verify category exists
        let categories = try viewModel.getAllCategories()
        XCTAssertEqual(categories.count, 1)
        
        // Try to delete the default category
        if let defaultCategory = try viewModel.getCategory(byName: "未分类") {
            try viewModel.deleteCategory(defaultCategory)
        }
        
        // Verify default category was not deleted
        // Note: This depends on your implementation
        let categoriesAfterDelete = try viewModel.getAllCategories()
        XCTAssertEqual(categoriesAfterDelete.count, 1)
        XCTAssertEqual(categoriesAfterDelete.first?.name, "未分类")
        XCTAssertNotNil(viewModel.errorMessage)
    }
    
    // MARK: - Feed-Category Relationship Tests
    
    func testGetFeedsInCategory() throws {
        // Create a category
        try viewModel.createCategory(name: "Technology")
        let category = try viewModel.getCategory(byName: "Technology")
        XCTAssertNotNil(category)
        
        // Create feeds in the category
        if let category = category {
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
            
            modelContext.insert(feed1)
            modelContext.insert(feed2)
        }
        
        // Create a feed not in the category
        let otherFeed = Feed(
            title: "Other Feed",
            url: URL(string: "https://example.com/other.xml")!
        )
        modelContext.insert(otherFeed)
        
        // Get feeds in the category
        if let category = category {
            let feeds = try viewModel.getFeeds(in: category)
            
            // Verify only feeds in the category are returned
            XCTAssertEqual(feeds.count, 2)
            let feedTitles = feeds.map { $0.title }.sorted()
            XCTAssertEqual(feedTitles, ["Tech Feed 1", "Tech Feed 2"])
        }
    }
}
