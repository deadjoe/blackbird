import Foundation
import SwiftData
import SwiftUI
import Observation

@MainActor
@Observable
class CategoryViewModel {
    private let modelContext: ModelContext
    var errorMessage: String?

    init(modelContext: ModelContext) {
        self.modelContext = modelContext

        // 确保默认分类存在
        Task {
            await ensureDefaultCategoryExists()
        }
    }

    // 获取所有分类，按排序顺序
    func getAllCategories() throws -> [FeedCategory] {
        let descriptor = FetchDescriptor<FeedCategory>(sortBy: [SortDescriptor(\.sortOrder)])
        return try modelContext.fetch(descriptor)
    }

    // 获取特定分类
    func getCategory(byName name: String) throws -> FeedCategory? {
        let descriptor = FetchDescriptor<FeedCategory>(predicate: #Predicate { $0.name == name })
        let categories = try modelContext.fetch(descriptor)
        return categories.first
    }

    // 添加新分类
    func addCategory(name: String, colorHex: String? = nil) async throws -> FeedCategory {
        // 检查是否已存在同名分类
        if let existing = try? getCategory(byName: name) {
            return existing
        }

        // 获取当前最大排序值
        let allCategories = try getAllCategories()
        let maxSortOrder = allCategories.map { $0.sortOrder }.max() ?? 0

        // 创建新分类
        let category = FeedCategory(
            name: name,
            colorHex: colorHex,
            sortOrder: maxSortOrder + 1
        )

        modelContext.insert(category)
        try modelContext.save()

        return category
    }

    // 更新分类
    func updateCategory(_ category: FeedCategory, name: String? = nil, colorHex: String? = nil, isExpanded: Bool? = nil) throws {
        if let name = name {
            category.name = name
        }

        if let colorHex = colorHex {
            category.colorHex = colorHex
        }

        if let isExpanded = isExpanded {
            category.isExpanded = isExpanded
        }

        try modelContext.save()
    }

    // 删除分类
    func deleteCategory(_ category: FeedCategory) throws {
        // 不允许删除默认分类
        if category.name == "未分类" {
            errorMessage = "不能删除默认分类"
            return
        }

        // 将该分类下的所有Feed移动到默认分类
        if let defaultCategory = try getCategory(byName: "未分类") {
            // 获取该分类下的所有Feed
            let feeds = try getFeeds(in: category)

            // 将Feed移动到默认分类
            for feed in feeds {
                feed.categoryID = defaultCategory.id
            }
        }

        modelContext.delete(category)
        try modelContext.save()
    }

    // 重新排序分类
    func reorderCategories(_ categories: [FeedCategory]) throws {
        for (index, category) in categories.enumerated() {
            category.sortOrder = index
        }

        try modelContext.save()
    }

    // 切换分类展开状态
    func toggleExpanded(_ category: FeedCategory) throws {
        category.isExpanded.toggle()
        try modelContext.save()
    }

    // 确保默认分类存在
    func ensureDefaultCategoryExists() async {
        do {
            if try getCategory(byName: "未分类") == nil {
                _ = try await addCategory(name: "未分类", colorHex: "808080")
            }
        } catch {
            errorMessage = "创建默认分类失败: \(error.localizedDescription)"
        }
    }

    // 将Feed移动到指定分类
    func moveFeed(_ feed: Feed, to category: FeedCategory) throws {
        feed.categoryID = category.id
        try modelContext.save()
    }

    // 获取分类下的所有Feed
    func getFeeds(in category: FeedCategory) throws -> [Feed] {
        let categoryID = category.id

        let descriptor = FetchDescriptor<Feed>(
            predicate: #Predicate { $0.categoryID == categoryID },
            sortBy: [SortDescriptor(\.sortOrder), SortDescriptor(\.title)]
        )
        return try modelContext.fetch(descriptor)
    }

    // 获取未分类的Feed
    func getUncategorizedFeeds() throws -> [Feed] {
        let descriptor = FetchDescriptor<Feed>(
            predicate: #Predicate { $0.categoryID == nil },
            sortBy: [SortDescriptor(\.sortOrder), SortDescriptor(\.title)]
        )
        return try modelContext.fetch(descriptor)
    }
}
