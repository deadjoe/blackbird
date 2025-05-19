import Foundation
import SwiftData
import SwiftUI

@Observable
class FeedListViewModel {
    private let modelContext: ModelContext
    var isLoading = false
    var errorMessage: String?
    
    init(modelContext: ModelContext) {
        self.modelContext = modelContext
    }
    
    func addFeed(urlString: String) async {
        guard let url = URL(string: urlString) else {
            errorMessage = "Invalid URL"
            return
        }
        
        isLoading = true
        errorMessage = nil
        
        do {
            let (feed, articles) = try await FeedService.shared.fetchFeed(from: url)
            
            // Check if feed already exists
            let descriptor = FetchDescriptor<Feed>(predicate: #Predicate { $0.url == url })
            let existingFeeds = try modelContext.fetch(descriptor)
            
            if existingFeeds.isEmpty {
                // Add new feed and articles
                modelContext.insert(feed)
                
                for article in articles {
                    feed.articles.append(article)
                    modelContext.insert(article)
                }
            } else {
                errorMessage = "Feed already exists"
            }
        } catch {
            errorMessage = "Failed to add feed: \(error.localizedDescription)"
        }
        
        isLoading = false
    }
    
    func refreshFeed(_ feed: Feed) async {
        isLoading = true
        errorMessage = nil
        
        do {
            let (_, newArticles) = try await FeedService.shared.fetchFeed(from: feed.url)
            
            // Get existing article URLs to avoid duplicates
            let existingArticleURLs = feed.articles.compactMap { $0.link }
            
            // Add only new articles
            for article in newArticles {
                if let articleURL = article.link, !existingArticleURLs.contains(articleURL) {
                    feed.articles.append(article)
                    modelContext.insert(article)
                }
            }
            
            feed.lastUpdated = Date()
        } catch {
            errorMessage = "Failed to refresh feed: \(error.localizedDescription)"
        }
        
        isLoading = false
    }
    
    func toggleStarred(feed: Feed) {
        feed.isStarred.toggle()
        try? modelContext.save()
    }
    
    func deleteFeed(_ feed: Feed) {
        modelContext.delete(feed)
        try? modelContext.save()
    }
}
