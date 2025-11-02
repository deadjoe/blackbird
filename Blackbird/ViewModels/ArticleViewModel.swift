import Foundation
import SwiftData
import SwiftUI
import Observation

@MainActor
@Observable
class ArticleViewModel: ObservableObject {
    private var modelContext: ModelContext?
    var errorMessage: String?
    var isLoading = false
    var searchText = ""
    var searchResults: [Article] = []

    init() {
        // 默认初始化方法
    }

    init(modelContext: ModelContext) {
        self.modelContext = modelContext
    }

    func setModelContext(_ context: ModelContext) {
        self.modelContext = context
    }

    // 确保ModelContext已设置
    private func getModelContext() -> ModelContext {
        guard let context = modelContext else {
            fatalError("ModelContext not set. Call setModelContext before using this ViewModel.")
        }
        return context
    }

    // 标记文章为已读
    func markAsRead(_ article: Article) {
        let context = getModelContext()
        if !article.isRead {
            article.isRead = true

            // 更新Feed的未读计数
            if let feed = getFeedForArticle(article) {
                feed.updateUnreadCount()
            }

            try? context.save()
        }
    }

    // 标记文章为未读
    func markAsUnread(_ article: Article) {
        let context = getModelContext()
        if article.isRead {
            article.isRead = false

            // 更新Feed的未读计数
            if let feed = getFeedForArticle(article) {
                feed.updateUnreadCount()
            }

            try? context.save()
        }
    }

    // 切换收藏状态
    func toggleStarred(_ article: Article) {
        let context = getModelContext()
        article.isStarred.toggle()
        try? context.save()
    }

    // 保存阅读位置
    func saveReadingPosition(_ article: Article, position: Double) {
        let context = getModelContext()
        article.lastReadPosition = position
        try? context.save()
    }

    // 添加标签
    func addTag(_ article: Article, tag: String) {
        let context = getModelContext()
        if !article.tags.contains(tag) {
            article.tags.append(tag)
            try? context.save()
        }
    }

    // 移除标签
    func removeTag(_ article: Article, tag: String) {
        let context = getModelContext()
        article.tags.removeAll { $0 == tag }
        try? context.save()
    }

    // 获取文章所属的Feed
    func getFeedForArticle(_ article: Article) -> Feed? {
        // 遍历所有Feed查找包含该文章的Feed
        do {
            let context = getModelContext()
            let descriptor = FetchDescriptor<Feed>()
            let feeds = try context.fetch(descriptor)

            for feed in feeds {
                if feed.articles.contains(where: { $0.id == article.id }) {
                    return feed
                }
            }

            return nil
        } catch {
            errorMessage = "查找文章所属Feed失败: \(error.localizedDescription)"
            return nil
        }
    }

    // 获取收藏的文章
    func getStarredArticles() throws -> [Article] {
        let context = getModelContext()
        let descriptor = FetchDescriptor<Article>(
            predicate: #Predicate { $0.isStarred == true },
            sortBy: [SortDescriptor(\.pubDate, order: .reverse)]
        )
        return try context.fetch(descriptor)
    }

    // 获取未读文章
    func getUnreadArticles() throws -> [Article] {
        let context = getModelContext()
        let descriptor = FetchDescriptor<Article>(
            predicate: #Predicate { $0.isRead == false },
            sortBy: [SortDescriptor(\.pubDate, order: .reverse)]
        )
        return try context.fetch(descriptor)
    }

    // 获取最近的文章
    func getRecentArticles(limit: Int = 50) throws -> [Article] {
        let context = getModelContext()
        var descriptor = FetchDescriptor<Article>(
            sortBy: [SortDescriptor(\.pubDate, order: .reverse)]
        )
        descriptor.fetchLimit = limit

        return try context.fetch(descriptor)
    }

    // 按标签获取文章
    func getArticlesByTag(_ tag: String) throws -> [Article] {
        let context = getModelContext()
        let descriptor = FetchDescriptor<Article>(
            predicate: #Predicate { $0.tags.contains(tag) },
            sortBy: [SortDescriptor(\.pubDate, order: .reverse)]
        )
        return try context.fetch(descriptor)
    }

    // 搜索文章
    func searchArticles(query: String) {
        guard !query.isEmpty else {
            searchResults = []
            return
        }

        isLoading = true
        searchText = query

        // 创建搜索谓词
        let lowercaseQuery = query.lowercased()
        let descriptor = FetchDescriptor<Article>(
            predicate: #Predicate { article in
                article.title.localizedStandardContains(lowercaseQuery) ||
                article.articleDescription?.localizedStandardContains(lowercaseQuery) == true ||
                article.content?.localizedStandardContains(lowercaseQuery) == true ||
                article.author?.localizedStandardContains(lowercaseQuery) == true
            },
            sortBy: [SortDescriptor(\.pubDate, order: .reverse)]
        )

        do {
            let context = getModelContext()
            searchResults = try context.fetch(descriptor)
        } catch {
            errorMessage = "搜索失败: \(error.localizedDescription)"
            searchResults = []
        }

        isLoading = false
    }

    // 清除搜索
    func clearSearch() {
        searchText = ""
        searchResults = []
    }

    // 批量操作：标记多篇文章为已读
    func markAsRead(_ articles: [Article]) {
        let context = getModelContext()
        for article in articles {
            article.isRead = true
        }

        // 更新相关Feed的未读计数
        updateUnreadCountsForFeeds()

        try? context.save()
    }

    // 批量操作：标记多篇文章为未读
    func markAsUnread(_ articles: [Article]) {
        let context = getModelContext()
        for article in articles {
            article.isRead = false
        }

        // 更新相关Feed的未读计数
        updateUnreadCountsForFeeds()

        try? context.save()
    }

    // 更新所有Feed的未读计数
    private func updateUnreadCountsForFeeds() {
        do {
            let context = getModelContext()
            let descriptor = FetchDescriptor<Feed>()
            let feeds = try context.fetch(descriptor)

            for feed in feeds {
                feed.updateUnreadCount()
            }
        } catch {
            errorMessage = "更新未读计数失败: \(error.localizedDescription)"
        }
    }

    // 删除文章
    func deleteArticle(_ article: Article) {
        let context = getModelContext()
        context.delete(article)

        // 更新相关Feed的未读计数
        if let feed = getFeedForArticle(article) {
            feed.updateUnreadCount()
        }

        try? context.save()
    }

    // 获取相关文章（基于标题和内容的相似性）
    func getRelatedArticles(to article: Article, limit: Int = 5) throws -> [Article] {
        guard let feed = getFeedForArticle(article) else {
            return []
        }

        // 从同一Feed中获取其他文章
        let otherArticles = feed.articles.filter { $0.id != article.id }

        // 如果文章很少，直接返回
        if otherArticles.count <= limit {
            return Array(otherArticles)
        }

        // 简单的相关性评分：标题和标签匹配
        let scoredArticles = otherArticles.map { otherArticle -> (Article, Double) in
            var score = 0.0

            // 标题相似性
            let words = article.title.lowercased().split(separator: " ")
            for word in words where word.count > 3 {
                if otherArticle.title.lowercased().contains(word) {
                    score += 1.0
                }
            }

            // 标签匹配
            for tag in article.tags {
                if otherArticle.tags.contains(tag) {
                    score += 2.0
                }
            }

            // 时间接近性
            if let pubDate1 = article.pubDate, let pubDate2 = otherArticle.pubDate {
                let timeInterval = abs(pubDate1.timeIntervalSince(pubDate2))
                if timeInterval < 86400 { // 一天内
                    score += 0.5
                }
            }

            return (otherArticle, score)
        }

        // 按分数排序并返回前N个
        let sortedArticles = scoredArticles.sorted { $0.1 > $1.1 }.prefix(limit).map { $0.0 }
        return Array(sortedArticles)
    }
}
