import Foundation
import SwiftData
import SwiftUI

// Feed 类定义
@Model
final class Feed {
    var title: String
    var url: URL
    var feedDescription: String?
    var imageURL: URL?
    var isStarred: Bool
    var lastUpdated: Date?
    var unreadCount: Int
    var sortOrder: Int
    var iconData: Data?
    var categoryID: String?

    @Relationship(deleteRule: .cascade) var articles: [Article] = []

    init(title: String, url: URL, feedDescription: String? = nil, imageURL: URL? = nil, isStarred: Bool = false, category: FeedCategory? = nil, sortOrder: Int = 0) {
        self.title = title
        self.url = url
        self.feedDescription = feedDescription
        self.imageURL = imageURL
        self.isStarred = isStarred
        self.lastUpdated = Date()
        self.unreadCount = 0
        self.sortOrder = sortOrder
        self.categoryID = category?.id
    }

    // 辅助方法：更新未读文章计数
    func updateUnreadCount() {
        self.unreadCount = articles.filter { !$0.isRead }.count
    }

    // 辅助方法：获取图标
    func icon() -> Image? {
        guard let data = iconData, let uiImage = UIImage(data: data) else {
            return nil
        }
        return Image(uiImage: uiImage)
    }
}

// FeedCategory 类定义
@Model
final class FeedCategory {
    @Attribute(.unique) var id: String?
    var name: String
    var colorHex: String?
    var sortOrder: Int
    var isExpanded: Bool

    init(name: String, colorHex: String? = nil, sortOrder: Int = 0, isExpanded: Bool = true) {
        self.id = UUID().uuidString
        self.name = name
        self.colorHex = colorHex
        self.sortOrder = sortOrder
        self.isExpanded = isExpanded
    }

    // 辅助方法：获取分类颜色
    func color() -> Color? {
        guard let hex = colorHex else { return nil }
        return Color(hex: hex)
    }
}

// Article 类定义
@Model
final class Article {
    var title: String
    var link: URL?
    var articleDescription: String?
    var content: String?
    var author: String?
    var pubDate: Date?
    var isRead: Bool
    var isStarred: Bool
    var imageURL: URL?
    var estimatedReadingTime: Int?
    var tags: [String] = []
    var lastReadPosition: Double?
    var guid: String?

    // 用于全文搜索的索引
    @Attribute(.spotlight) var searchableContent: String?

    init(title: String, link: URL? = nil, description: String? = nil, content: String? = nil, author: String? = nil, pubDate: Date? = nil, isRead: Bool = false, isStarred: Bool = false, imageURL: URL? = nil, guid: String? = nil) {
        self.title = title
        self.link = link
        self.articleDescription = description
        self.content = content
        self.author = author
        self.pubDate = pubDate
        self.isRead = isRead
        self.isStarred = isStarred
        self.imageURL = imageURL
        self.guid = guid

        // 设置可搜索内容
        updateSearchableContent()

        // 估算阅读时间
        calculateReadingTime()
    }

    // 更新可搜索内容
    func updateSearchableContent() {
        var searchText = title

        if let desc = articleDescription {
            searchText += " " + desc
        }

        if let fullContent = content {
            searchText += " " + fullContent
        }

        if let authorName = author {
            searchText += " " + authorName
        }

        self.searchableContent = searchText
    }

    // 计算估计阅读时间（以分钟为单位）
    func calculateReadingTime() {
        let wordsPerMinute = 200.0

        var totalWords = 0
        if let content = content {
            totalWords += content.split(separator: " ").count
        }

        if let description = articleDescription, content == nil {
            totalWords += description.split(separator: " ").count
        }

        if totalWords > 0 {
            self.estimatedReadingTime = max(1, Int(ceil(Double(totalWords) / wordsPerMinute)))
        } else {
            self.estimatedReadingTime = nil
        }
    }

    // 从内容中提取主要图片URL
    func extractMainImage() {
        if let content = content {
            // 简单的图片URL提取逻辑
            let pattern = #"<img[^>]+src=\"([^\"]+)\""#
            if let regex = try? NSRegularExpression(pattern: pattern) {
                let range = NSRange(content.startIndex..., in: content)
                if let match = regex.firstMatch(in: content, range: range) {
                    let urlRange = Range(match.range(at: 1), in: content)
                    if let urlRange = urlRange, let url = URL(string: String(content[urlRange])) {
                        self.imageURL = url
                    }
                }
            }
        }
    }
}

// 颜色扩展，用于十六进制颜色转换
extension Color {
    init(hex: String) {
        let hex = hex.trimmingCharacters(in: CharacterSet.alphanumerics.inverted)
        var int: UInt64 = 0
        Scanner(string: hex).scanHexInt64(&int)
        let a, r, g, b: UInt64
        switch hex.count {
        case 3: // RGB (12-bit)
            (a, r, g, b) = (255, (int >> 8) * 17, (int >> 4 & 0xF) * 17, (int & 0xF) * 17)
        case 6: // RGB (24-bit)
            (a, r, g, b) = (255, int >> 16, int >> 8 & 0xFF, int & 0xFF)
        case 8: // ARGB (32-bit)
            (a, r, g, b) = (int >> 24, int >> 16 & 0xFF, int >> 8 & 0xFF, int & 0xFF)
        default:
            (a, r, g, b) = (1, 1, 1, 0)
        }
        self.init(
            .sRGB,
            red: Double(r) / 255,
            green: Double(g) / 255,
            blue: Double(b) / 255,
            opacity: Double(a) / 255
        )
    }
}
