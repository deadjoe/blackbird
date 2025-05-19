import Foundation
import SwiftData

@Model
final class Feed {
    var title: String
    var url: URL
    var description: String?
    var imageURL: URL?
    var isStarred: Bool
    var lastUpdated: Date?
    @Relationship(deleteRule: .cascade) var articles: [Article] = []
    
    init(title: String, url: URL, description: String? = nil, imageURL: URL? = nil, isStarred: Bool = false) {
        self.title = title
        self.url = url
        self.description = description
        self.imageURL = imageURL
        self.isStarred = isStarred
        self.lastUpdated = Date()
    }
}
