import Foundation
import SwiftData

@Model
final class Article {
    var title: String
    var link: URL?
    var description: String?
    var content: String?
    var author: String?
    var pubDate: Date?
    var isRead: Bool
    var isStarred: Bool
    
    init(title: String, link: URL? = nil, description: String? = nil, content: String? = nil, author: String? = nil, pubDate: Date? = nil, isRead: Bool = false, isStarred: Bool = false) {
        self.title = title
        self.link = link
        self.description = description
        self.content = content
        self.author = author
        self.pubDate = pubDate
        self.isRead = isRead
        self.isStarred = isStarred
    }
}
