import Foundation
import FeedKit
import SwiftData
import UIKit

enum FeedError: Error {
    case invalidURL
    case parsingFailed
    case networkError(Error)
    case feedNotFound
    case duplicateFeed
}

@Observable
class FeedService {
    static let shared = FeedService()

    var isLoading = false
    var progress: Double = 0
    var currentTask: String = ""

    private let imageCache = NSCache<NSString, UIImage>()
    private let session: URLSession

    private init() {
        let config = URLSessionConfiguration.default
        config.timeoutIntervalForRequest = 30
        config.requestCachePolicy = .reloadRevalidatingCacheData
        self.session = URLSession(configuration: config)
    }

    // 获取Feed，支持分类
    func fetchFeed(from url: URL, category: FeedCategory? = nil) async throws -> (Feed, [Article]) {
        isLoading = true
        progress = 0
        currentTask = "正在获取 Feed..."

        defer {
            isLoading = false
            progress = 1.0
            currentTask = ""
        }

        return try await withCheckedThrowingContinuation { continuation in
            let parser = FeedParser(URL: url)

            parser.parseAsync { result in
                self.progress = 0.3
                self.currentTask = "正在解析 Feed..."

                switch result {
                case .success(let feed):
                    do {
                        let (feedModel, articles) = try self.processFeed(feed, url: url, category: category)

                        // 尝试获取网站图标
                        Task {
                            await self.fetchFeedIcon(for: feedModel)
                        }

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

    // 处理不同类型的Feed
    private func processFeed(_ feed: FeedKit.Feed, url: URL, category: FeedCategory? = nil) throws -> (Feed, [Article]) {
        switch feed {
        case .atom(let atomFeed):
            return processAtomFeed(atomFeed, url: url, category: category)
        case .rss(let rssFeed):
            return processRSSFeed(rssFeed, url: url, category: category)
        case .json(let jsonFeed):
            return processJSONFeed(jsonFeed, url: url, category: category)
        }
    }

    // 处理RSS Feed
    private func processRSSFeed(_ rssFeed: RSSFeed, url: URL, category: FeedCategory? = nil) -> (Feed, [Article]) {
        self.progress = 0.5
        self.currentTask = "正在处理 RSS Feed..."

        let feed = Feed(
            title: rssFeed.title ?? "Untitled Feed",
            url: url,
            feedDescription: rssFeed.description,
            imageURL: rssFeed.image?.url.flatMap { URL(string: $0) },
            category: category
        )

        let articles = rssFeed.items?.compactMap { item -> Article? in
            guard let title = item.title else { return nil }

            // 尝试获取最完整的内容
            let content: String?
            if let contentEncoded = item.content?.contentEncoded, !contentEncoded.isEmpty {
                content = contentEncoded
            } else if let description = item.description, !description.isEmpty {
                content = description
            } else {
                content = nil
            }

            let article = Article(
                title: title,
                link: item.link.flatMap { URL(string: $0) },
                description: item.description,
                content: content,
                author: item.author,
                pubDate: item.pubDate,
                guid: item.guid?.value
            )

            // 提取图片
            if let mediaContent = item.media?.mediaContents?.first,
               let urlString = mediaContent.attributes?.url,
               let imageURL = URL(string: urlString) {
                article.imageURL = imageURL
            } else {
                article.extractMainImage()
            }

            // 计算阅读时间
            article.calculateReadingTime()

            return article
        } ?? []

        self.progress = 0.8

        return (feed, articles)
    }

    // 处理Atom Feed
    private func processAtomFeed(_ atomFeed: AtomFeed, url: URL, category: FeedCategory? = nil) -> (Feed, [Article]) {
        self.progress = 0.5
        self.currentTask = "正在处理 Atom Feed..."

        let feed = Feed(
            title: atomFeed.title ?? "Untitled Feed",
            url: url,
            feedDescription: atomFeed.subtitle?.value,
            category: category
        )

        let articles = atomFeed.entries?.compactMap { entry -> Article? in
            guard let title = entry.title else { return nil }

            // 尝试获取最完整的内容
            let content: String?
            if let contentValue = entry.content?.value, !contentValue.isEmpty {
                content = contentValue
            } else if let summary = entry.summary?.value, !summary.isEmpty {
                content = summary
            } else {
                content = nil
            }

            let article = Article(
                title: title,
                link: entry.links?.first?.attributes?.href.flatMap { URL(string: $0) },
                description: entry.summary?.value,
                content: content,
                author: entry.authors?.first?.name,
                pubDate: entry.published ?? entry.updated,
                guid: entry.id
            )

            // 提取图片
            article.extractMainImage()

            // 计算阅读时间
            article.calculateReadingTime()

            return article
        } ?? []

        self.progress = 0.8

        return (feed, articles)
    }

    // 处理JSON Feed
    private func processJSONFeed(_ jsonFeed: JSONFeed, url: URL, category: FeedCategory? = nil) -> (Feed, [Article]) {
        self.progress = 0.5
        self.currentTask = "正在处理 JSON Feed..."

        let feed = Feed(
            title: jsonFeed.title ?? "Untitled Feed",
            url: url,
            feedDescription: jsonFeed.description,
            imageURL: jsonFeed.icon.flatMap { URL(string: $0) },
            category: category
        )

        let articles = jsonFeed.items?.compactMap { item -> Article? in
            guard let title = item.title else { return nil }

            // 尝试获取最完整的内容
            let content: String?
            if let contentHtml = item.contentHtml, !contentHtml.isEmpty {
                content = contentHtml
            } else if let contentText = item.contentText, !contentText.isEmpty {
                content = contentText
            } else if let summary = item.summary, !summary.isEmpty {
                content = summary
            } else {
                content = nil
            }

            let article = Article(
                title: title,
                link: item.url.flatMap { URL(string: $0) },
                description: item.summary,
                content: content,
                author: item.author?.name,
                pubDate: item.datePublished ?? item.dateModified,
                guid: item.id
            )

            // 设置图片
            if let imageURL = item.image.flatMap({ URL(string: $0) }) {
                article.imageURL = imageURL
            } else {
                article.extractMainImage()
            }

            // 设置标签
            if let tags = item.tags {
                article.tags = tags
            }

            // 计算阅读时间
            article.calculateReadingTime()

            return article
        } ?? []

        self.progress = 0.8

        return (feed, articles)
    }

    // 获取网站图标
    private func fetchFeedIcon(for feed: Feed) async {
        guard let host = feed.url.host else { return }

        // 尝试获取favicon
        let faviconURL = URL(string: "https://\(host)/favicon.ico")

        if let iconURL = faviconURL {
            do {
                let (data, _) = try await session.data(from: iconURL)
                if UIImage(data: data) != nil {
                    feed.iconData = data
                }
            } catch {
                // 尝试从网站HTML中提取图标
                if let siteURL = URL(string: "https://\(host)") {
                    await extractIconFromHTML(siteURL: siteURL, for: feed)
                }
            }
        }
    }

    // 从HTML中提取图标
    private func extractIconFromHTML(siteURL: URL, for feed: Feed) async {
        do {
            let (data, _) = try await session.data(from: siteURL)
            if let html = String(data: data, encoding: .utf8) {
                // 查找link标签中的图标
                let pattern = #"<link[^>]+rel=["'](?:shortcut )?icon["'][^>]+href=["']([^"']+)["']"#
                if let regex = try? NSRegularExpression(pattern: pattern) {
                    let range = NSRange(html.startIndex..., in: html)
                    if let match = regex.firstMatch(in: html, range: range) {
                        let urlRange = Range(match.range(at: 1), in: html)
                        if let urlRange = urlRange {
                            var iconPath = String(html[urlRange])
                            // 处理相对路径
                            if iconPath.starts(with: "/") {
                                iconPath = "https://\(siteURL.host!)\(iconPath)"
                            } else if !iconPath.starts(with: "http") {
                                iconPath = "https://\(siteURL.host!)/\(iconPath)"
                            }

                            if let iconURL = URL(string: iconPath) {
                                let (iconData, _) = try await session.data(from: iconURL)
                                if let _ = UIImage(data: iconData) {
                                    feed.iconData = iconData
                                }
                            }
                        }
                    }
                }
            }
        } catch {
            // 忽略错误，图标获取失败不是关键功能
        }
    }

    // 发现网站的Feed链接
    func discoverFeeds(from websiteURL: URL) async throws -> [URL] {
        guard let host = websiteURL.host else {
            throw FeedError.invalidURL
        }

        var url = websiteURL
        // 确保URL是网站根目录
        if url.path != "" && !url.path.contains(".") {
            url = URL(string: "https://\(host)")!
        }

        let (data, _) = try await session.data(from: url)
        guard let html = String(data: data, encoding: .utf8) else {
            throw FeedError.parsingFailed
        }

        // 查找所有可能的Feed链接
        let pattern = #"<link[^>]+type=["']application/(?:rss|atom)\+xml["'][^>]+href=["']([^"']+)["']"#
        guard let regex = try? NSRegularExpression(pattern: pattern) else {
            throw FeedError.parsingFailed
        }

        let range = NSRange(html.startIndex..., in: html)
        let matches = regex.matches(in: html, range: range)

        var feedURLs: [URL] = []

        for match in matches {
            let urlRange = Range(match.range(at: 1), in: html)
            if let urlRange = urlRange {
                var feedURLString = String(html[urlRange])
                // 处理相对路径
                if feedURLString.starts(with: "/") {
                    feedURLString = "https://\(host)\(feedURLString)"
                } else if !feedURLString.starts(with: "http") {
                    feedURLString = "https://\(host)/\(feedURLString)"
                }

                if let feedURL = URL(string: feedURLString) {
                    feedURLs.append(feedURL)
                }
            }
        }

        // 如果没有找到Feed，尝试常见的Feed路径
        if feedURLs.isEmpty {
            let commonPaths = ["/feed", "/rss", "/atom.xml", "/feed.xml", "/rss.xml", "/index.xml"]
            for path in commonPaths {
                if let potentialURL = URL(string: "https://\(host)\(path)") {
                    do {
                        let (_, response) = try await session.data(from: potentialURL)
                        if let httpResponse = response as? HTTPURLResponse,
                           httpResponse.statusCode == 200,
                           let contentType = httpResponse.value(forHTTPHeaderField: "Content-Type"),
                           contentType.contains("xml") {
                            feedURLs.append(potentialURL)
                        }
                    } catch {
                        // 忽略错误，继续尝试下一个路径
                    }
                }
            }
        }

        return feedURLs
    }
}
