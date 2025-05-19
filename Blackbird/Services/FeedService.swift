import Foundation
import FeedKit
import SwiftData

enum FeedError: Error {
    case invalidURL
    case parsingFailed
    case networkError(Error)
}

class FeedService {
    static let shared = FeedService()
    
    private init() {}
    
    func fetchFeed(from url: URL) async throws -> (Feed, [Article]) {
        return try await withCheckedThrowingContinuation { continuation in
            let parser = FeedParser(URL: url)
            
            parser.parseAsync { result in
                switch result {
                case .success(let feed):
                    do {
                        let (feedModel, articles) = try self.processFeed(feed, url: url)
                        continuation.resume(returning: (feedModel, articles))
                    } catch {
                        continuation.resume(throwing: error)
                    }
                case .failure(let error):
                    continuation.resume(throwing: FeedError.networkError(error))
                }
            }
        }
    }
    
    private func processFeed(_ feed: FeedKit.Feed, url: URL) throws -> (Feed, [Article]) {
        switch feed {
        case .atom(let atomFeed):
            return processAtomFeed(atomFeed, url: url)
        case .rss(let rssFeed):
            return processRSSFeed(rssFeed, url: url)
        case .json(let jsonFeed):
            return processJSONFeed(jsonFeed, url: url)
        }
    }
    
    private func processRSSFeed(_ rssFeed: RSSFeed, url: URL) -> (Feed, [Article]) {
        let feed = Feed(
            title: rssFeed.title ?? "Untitled Feed",
            url: url,
            description: rssFeed.description,
            imageURL: rssFeed.image?.url.flatMap { URL(string: $0) }
        )
        
        let articles = rssFeed.items?.compactMap { item -> Article? in
            guard let title = item.title else { return nil }
            
            return Article(
                title: title,
                link: item.link.flatMap { URL(string: $0) },
                description: item.description,
                content: item.content?.encoded,
                author: item.author,
                pubDate: item.pubDate
            )
        } ?? []
        
        return (feed, articles)
    }
    
    private func processAtomFeed(_ atomFeed: AtomFeed, url: URL) -> (Feed, [Article]) {
        let feed = Feed(
            title: atomFeed.title ?? "Untitled Feed",
            url: url,
            description: atomFeed.subtitle?.value
        )
        
        let articles = atomFeed.entries?.compactMap { entry -> Article? in
            guard let title = entry.title else { return nil }
            
            return Article(
                title: title,
                link: entry.links?.first?.href.flatMap { URL(string: $0) },
                description: entry.summary?.value,
                content: entry.content?.value,
                author: entry.authors?.first?.name,
                pubDate: entry.published ?? entry.updated
            )
        } ?? []
        
        return (feed, articles)
    }
    
    private func processJSONFeed(_ jsonFeed: JSONFeed, url: URL) -> (Feed, [Article]) {
        let feed = Feed(
            title: jsonFeed.title ?? "Untitled Feed",
            url: url,
            description: jsonFeed.description,
            imageURL: jsonFeed.icon.flatMap { URL(string: $0) }
        )
        
        let articles = jsonFeed.items?.compactMap { item -> Article? in
            guard let title = item.title else { return nil }
            
            return Article(
                title: title,
                link: item.url.flatMap { URL(string: $0) },
                description: item.summary,
                content: item.contentHtml ?? item.contentText,
                author: item.author?.name,
                pubDate: item.datePublished ?? item.dateModified
            )
        } ?? []
        
        return (feed, articles)
    }
}
