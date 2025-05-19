import SwiftUI
import SwiftData
import Foundation

struct ArticleListView: View {
    @Environment(\.modelContext) private var modelContext
    var feed: Feed
    @State private var viewModel: ArticleViewModel!

    var body: some View {
        List {
            ForEach(feed.articles.sorted(by: { ($0.pubDate ?? Date.distantPast) > ($1.pubDate ?? Date.distantPast) })) { article in
                NavigationLink(destination: ArticleDetailView(article: article)) {
                    VStack(alignment: .leading, spacing: 4) {
                        Text(article.title)
                            .font(.headline)
                            .foregroundColor(article.isRead ? .secondary : .primary)

                        if let description = article.articleDescription, !description.isEmpty {
                            Text(description.cleanHTMLTags())
                                .font(.caption)
                                .lineLimit(2)
                                .foregroundColor(.secondary)
                        }

                        HStack {
                            if let pubDate = article.pubDate {
                                Text(pubDate.formatted(.relative(presentation: .named)))
                                    .font(.caption2)
                                    .foregroundColor(.secondary)
                            }

                            Spacer()

                            if article.isStarred {
                                Image(systemName: "star.fill")
                                    .foregroundColor(.yellow)
                                    .font(.caption)
                            }
                        }
                    }
                    .padding(.vertical, 4)
                }
                .swipeActions {
                    Button {
                        viewModel.toggleStarred(article)
                    } label: {
                        Label(article.isStarred ? "Unstar" : "Star", systemImage: article.isStarred ? "star.slash" : "star")
                    }
                    .tint(.yellow)

                    if !article.isRead {
                        Button {
                            viewModel.markAsRead(article)
                        } label: {
                            Label("Mark as Read", systemImage: "checkmark")
                        }
                        .tint(.blue)
                    }
                }
            }
        }
        .navigationTitle(feed.title)
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .navigationBarTrailing) {
                Button {
                    Task {
                        await FeedListViewModel(modelContext: modelContext).refreshFeed(feed)
                    }
                } label: {
                    Label("Refresh", systemImage: "arrow.clockwise")
                }
            }
        }
        .onAppear {
            viewModel = ArticleViewModel(modelContext: modelContext)
        }
    }
}

#Preview {
    let config = ModelConfiguration(isStoredInMemoryOnly: true)
    let container = try! ModelContainer(for: Feed.self, Article.self, configurations: config)

    let feed = Feed(title: "Sample Feed", url: URL(string: "https://example.com")!)
    let article1 = Article(title: "Article 1", pubDate: Date())
    let article2 = Article(title: "Article 2", pubDate: Date().addingTimeInterval(-3600))

    feed.articles = [article1, article2]

    return NavigationStack {
        ArticleListView(feed: feed)
    }
    .modelContainer(container)
}
