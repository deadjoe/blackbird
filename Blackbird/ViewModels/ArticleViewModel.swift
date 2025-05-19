import Foundation
import SwiftData

@Observable
class ArticleViewModel {
    private let modelContext: ModelContext
    
    init(modelContext: ModelContext) {
        self.modelContext = modelContext
    }
    
    func markAsRead(_ article: Article) {
        article.isRead = true
        try? modelContext.save()
    }
    
    func toggleStarred(_ article: Article) {
        article.isStarred.toggle()
        try? modelContext.save()
    }
    
    func getStarredArticles() throws -> [Article] {
        let descriptor = FetchDescriptor<Article>(predicate: #Predicate { $0.isStarred == true })
        return try modelContext.fetch(descriptor)
    }
}
