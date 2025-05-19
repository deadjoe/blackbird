import SwiftUI
import SwiftData

struct ArticleDetailView: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(\.openURL) private var openURL
    var article: Article
    @State private var viewModel: ArticleViewModel!
    
    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 16) {
                Text(article.title)
                    .font(.title)
                    .fontWeight(.bold)
                
                if let author = article.author, !author.isEmpty {
                    Text("By \(author)")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                }
                
                if let pubDate = article.pubDate {
                    Text("Published: \(pubDate.formatted(date: .long, time: .shortened))")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                
                Divider()
                
                if let content = article.content, !content.isEmpty {
                    Text(try! AttributedString(markdown: content))
                } else if let description = article.description, !description.isEmpty {
                    Text(try! AttributedString(markdown: description))
                } else {
                    Text("No content available")
                        .italic()
                        .foregroundColor(.secondary)
                }
                
                if let link = article.link {
                    Button {
                        openURL(link)
                    } label: {
                        Label("Open in Browser", systemImage: "safari")
                    }
                    .buttonStyle(.bordered)
                    .padding(.top)
                }
            }
            .padding()
        }
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .navigationBarTrailing) {
                Button {
                    viewModel.toggleStarred(article)
                } label: {
                    Image(systemName: article.isStarred ? "star.fill" : "star")
                        .foregroundColor(article.isStarred ? .yellow : .primary)
                }
            }
            
            ToolbarItem(placement: .navigationBarTrailing) {
                ShareLink(item: article.link ?? URL(string: "https://example.com")!) {
                    Image(systemName: "square.and.arrow.up")
                }
            }
        }
        .onAppear {
            viewModel = ArticleViewModel(modelContext: modelContext)
            if !article.isRead {
                viewModel.markAsRead(article)
            }
        }
    }
}

#Preview {
    let config = ModelConfiguration(isStoredInMemoryOnly: true)
    let container = try! ModelContainer(for: Article.self, configurations: config)
    
    let article = Article(
        title: "Sample Article with a Long Title That Spans Multiple Lines",
        link: URL(string: "https://example.com"),
        description: "This is a sample article description.",
        content: "# Sample Content\n\nThis is a sample article content with **bold** and *italic* text.\n\n## Section\n\nMore content here.",
        author: "John Doe",
        pubDate: Date()
    )
    
    return NavigationStack {
        ArticleDetailView(article: article)
    }
    .modelContainer(container)
}
