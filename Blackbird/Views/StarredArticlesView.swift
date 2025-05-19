import SwiftUI
import SwiftData

struct StarredArticlesView: View {
    @Environment(\.modelContext) private var modelContext
    @Query(filter: #Predicate<Article> { $0.isStarred == true }) private var starredArticles: [Article]
    @State private var viewModel: ArticleViewModel!

    var body: some View {
        NavigationStack {
            Group {
                if starredArticles.isEmpty {
                    ContentUnavailableView {
                        Label("No Starred Articles", systemImage: "star")
                    } description: {
                        Text("Star articles to see them here")
                    }
                } else {
                    List {
                        ForEach(starredArticles.sorted(by: { ($0.pubDate ?? Date.distantPast) > ($1.pubDate ?? Date.distantPast) })) { article in
                            NavigationLink(destination: ArticleDetailView(article: article)) {
                                VStack(alignment: .leading, spacing: 4) {
                                    Text(article.title)
                                        .font(.headline)
                                        .foregroundColor(article.isRead ? .secondary : .primary)

                                    if let description = article.articleDescription, !description.isEmpty {
                                        Text(description)
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
                                    }
                                }
                                .padding(.vertical, 4)
                            }
                            .swipeActions {
                                Button {
                                    viewModel.toggleStarred(article)
                                } label: {
                                    Label("Unstar", systemImage: "star.slash")
                                }
                                .tint(.yellow)
                            }
                        }
                    }
                }
            }
            .navigationTitle("Starred Articles")
        }
        .onAppear {
            viewModel = ArticleViewModel(modelContext: modelContext)
        }
    }
}

#Preview {
    StarredArticlesView()
        .modelContainer(for: [Feed.self, Article.self], inMemory: true)
}
