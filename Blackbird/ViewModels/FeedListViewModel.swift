import Foundation
import SwiftData
import SwiftUI
import Observation

@MainActor
@Observable
class FeedListViewModel: ObservableObject {
    private var modelContext: ModelContext?
    var isLoading = false
    var errorMessage: String?
    var discoveredFeeds: [URL] = []
    var feedService: FeedService

    init() {
        self.feedService = FeedService.shared
    }

    init(modelContext: ModelContext) {
        self.modelContext = modelContext
        self.feedService = FeedService.shared
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

    // 添加新Feed，支持分类
    func addFeed(urlString: String, category: FeedCategory? = nil) async {
        guard let url = URL(string: urlString) else {
            errorMessage = "无效的URL"
            return
        }

        isLoading = true
        errorMessage = nil

        do {
            let context = getModelContext()

            // 检查Feed是否已存在
            let descriptor = FetchDescriptor<Feed>(predicate: #Predicate { $0.url == url })
            let existingFeeds = try context.fetch(descriptor)

            if existingFeeds.isEmpty {
                // 获取Feed并添加到指定分类
                let (feed, articles) = try await feedService.fetchFeed(from: url, category: category)

                // 如果没有指定分类，尝试获取默认分类
                if category == nil {
                    let categoryVM = CategoryViewModel(modelContext: context)
                    if let defaultCategory = try? categoryVM.getCategory(byName: "未分类") {
                        feed.categoryID = defaultCategory.id
                    }
                }

                // 添加Feed和文章
                context.insert(feed)

                for article in articles {
                    feed.articles.append(article)
                    context.insert(article)
                }

                // 更新未读计数
                feed.updateUnreadCount()

                try context.save()
            } else {
                errorMessage = "Feed已存在"
            }
        } catch {
            errorMessage = "添加Feed失败: \(error.localizedDescription)"
        }

        isLoading = false
    }

    // 刷新Feed
    func refreshFeed(_ feed: Feed) async {
        isLoading = true
        errorMessage = nil

        do {
            let context = getModelContext()

            // 获取分类
            let categoryID = feed.categoryID
            var category: FeedCategory? = nil
            if let categoryID = categoryID {
                let categoryDescriptor = FetchDescriptor<FeedCategory>(
                    predicate: #Predicate { $0.id == categoryID }
                )
                category = try? context.fetch(categoryDescriptor).first
            }

            let (_, newArticles) = try await feedService.fetchFeed(from: feed.url, category: category)

            // 使用GUID和URL避免重复
            let existingGUIDs = Set(feed.articles.compactMap { $0.guid })
            let existingURLs = Set(feed.articles.compactMap { $0.link })

            var addedCount = 0

            // 添加新文章
            for article in newArticles {
                let isNew = (article.guid == nil || !existingGUIDs.contains(article.guid!)) &&
                            (article.link == nil || !existingURLs.contains(article.link!))

                if isNew {
                    feed.articles.append(article)
                    context.insert(article)
                    addedCount += 1
                }
            }

            // 更新Feed信息
            feed.lastUpdated = Date()
            feed.updateUnreadCount()

            try context.save()

            if addedCount > 0 {
                errorMessage = "已添加\(addedCount)篇新文章"
            } else {
                errorMessage = "没有新文章"
            }
        } catch {
            errorMessage = "刷新Feed失败: \(error.localizedDescription)"
        }

        isLoading = false
    }

    // 刷新所有Feed
    func refreshAllFeeds() async {
        isLoading = true
        errorMessage = nil

        do {
            let context = getModelContext()

            let descriptor = FetchDescriptor<Feed>()
            let allFeeds = try context.fetch(descriptor)

            var totalNewArticles = 0
            var failedFeeds: [String] = []

            for feed in allFeeds {
                do {
                    // 获取分类
                    let categoryID = feed.categoryID
                    var category: FeedCategory? = nil
                    if let categoryID = categoryID {
                        let categoryDescriptor = FetchDescriptor<FeedCategory>(
                            predicate: #Predicate { $0.id == categoryID }
                        )
                        category = try context.fetch(categoryDescriptor).first
                    }

                    let (_, newArticles) = try await feedService.fetchFeed(from: feed.url, category: category)

                    // 使用GUID和URL避免重复
                    let existingGUIDs = Set(feed.articles.compactMap { $0.guid })
                    let existingURLs = Set(feed.articles.compactMap { $0.link })

                    var addedCount = 0

                    // 添加新文章
                    for article in newArticles {
                        let isNew = (article.guid == nil || !existingGUIDs.contains(article.guid!)) &&
                                    (article.link == nil || !existingURLs.contains(article.link!))

                        if isNew {
                            feed.articles.append(article)
                            context.insert(article)
                            addedCount += 1
                        }
                    }

                    // 更新Feed信息
                    feed.lastUpdated = Date()
                    feed.updateUnreadCount()

                    totalNewArticles += addedCount
                } catch {
                    failedFeeds.append(feed.title)
                }
            }

            try context.save()

            if totalNewArticles > 0 {
                errorMessage = "已添加\(totalNewArticles)篇新文章"
            } else if failedFeeds.isEmpty {
                errorMessage = "没有新文章"
            }

            if !failedFeeds.isEmpty {
                let failedList = failedFeeds.joined(separator: "、")
                errorMessage = (errorMessage ?? "") + (errorMessage == nil ? "" : "；") + "以下订阅刷新失败：\(failedList)"
            }
        } catch {
            errorMessage = "刷新所有Feed失败: \(error.localizedDescription)"
        }

        isLoading = false
    }

    // 切换收藏状态
    func toggleStarred(feed: Feed) {
        let context = getModelContext()
        feed.isStarred.toggle()
        try? context.save()
    }

    // 删除Feed
    func deleteFeed(_ feed: Feed) {
        let context = getModelContext()
        context.delete(feed)
        try? context.save()
    }

    // 重新排序Feed
    func reorderFeeds(_ feeds: [Feed]) {
        let context = getModelContext()
        for (index, feed) in feeds.enumerated() {
            feed.sortOrder = index
        }

        try? context.save()
    }

    // 发现网站的Feed
    func discoverFeeds(from websiteURL: String) async {
        guard let url = URL(string: websiteURL) else {
            errorMessage = "无效的URL"
            return
        }

        isLoading = true
        errorMessage = nil
        discoveredFeeds = []

        do {
            discoveredFeeds = try await feedService.discoverFeeds(from: url)

            if discoveredFeeds.isEmpty {
                errorMessage = "未找到Feed"
            }
        } catch {
            errorMessage = "发现Feed失败: \(error.localizedDescription)"
        }

        isLoading = false
    }

    // 获取所有Feed，可按分类过滤
    func getAllFeeds(in category: FeedCategory? = nil) throws -> [Feed] {
        let context = getModelContext()
        if let category = category {
            return try getFeedsInCategory(category)
        } else {
            let descriptor = FetchDescriptor<Feed>(sortBy: [
                SortDescriptor(\.sortOrder),
                SortDescriptor(\.title)
            ])
            return try context.fetch(descriptor)
        }
    }

    // 获取分类中的Feed
    func getFeedsInCategory(_ category: FeedCategory) throws -> [Feed] {
        let context = getModelContext()
        let categoryID = category.id

        let descriptor = FetchDescriptor<Feed>(
            predicate: #Predicate { $0.categoryID == categoryID },
            sortBy: [SortDescriptor(\.sortOrder), SortDescriptor(\.title)]
        )
        return try context.fetch(descriptor)
    }

    // 获取收藏的Feed
    func getStarredFeeds() throws -> [Feed] {
        let context = getModelContext()
        let descriptor = FetchDescriptor<Feed>(
            predicate: #Predicate { $0.isStarred == true },
            sortBy: [SortDescriptor(\.title)]
        )
        return try context.fetch(descriptor)
    }
}
