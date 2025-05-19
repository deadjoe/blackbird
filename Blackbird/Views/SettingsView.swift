import SwiftUI
import SwiftData

struct SettingsView: View {
    @AppStorage("refreshInterval") private var refreshInterval = 3600.0 // Default: 1 hour
    @AppStorage("maxArticleAge") private var maxArticleAge = 7.0 // Default: 7 days
    @AppStorage("markReadOnOpen") private var markReadOnOpen = true
    @AppStorage("openLinksInBrowser") private var openLinksInBrowser = false
    @AppStorage("showUnreadOnly") private var showUnreadOnly = false
    
    @Environment(\.modelContext) private var modelContext
    @Query private var feeds: [Feed]
    
    var body: some View {
        NavigationStack {
            Form {
                Section(header: Text("Refresh Settings")) {
                    Picker("Auto Refresh", selection: $refreshInterval) {
                        Text("15 Minutes").tag(900.0)
                        Text("30 Minutes").tag(1800.0)
                        Text("1 Hour").tag(3600.0)
                        Text("2 Hours").tag(7200.0)
                        Text("4 Hours").tag(14400.0)
                        Text("Manual Only").tag(0.0)
                    }
                    
                    Picker("Keep Articles", selection: $maxArticleAge) {
                        Text("1 Day").tag(1.0)
                        Text("3 Days").tag(3.0)
                        Text("1 Week").tag(7.0)
                        Text("2 Weeks").tag(14.0)
                        Text("1 Month").tag(30.0)
                        Text("Forever").tag(0.0)
                    }
                }
                
                Section(header: Text("Reading Preferences")) {
                    Toggle("Mark as Read When Opened", isOn: $markReadOnOpen)
                    Toggle("Open Links in Browser", isOn: $openLinksInBrowser)
                    Toggle("Show Unread Articles Only", isOn: $showUnreadOnly)
                }
                
                Section(header: Text("Data Management")) {
                    Button("Refresh All Feeds") {
                        Task {
                            await refreshAllFeeds()
                        }
                    }
                    
                    Button("Clear All Read Articles") {
                        clearReadArticles()
                    }
                    .foregroundColor(.red)
                }
                
                Section(header: Text("About")) {
                    HStack {
                        Text("Version")
                        Spacer()
                        Text(Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "1.0.0")
                            .foregroundColor(.secondary)
                    }
                    
                    Link("Source Code", destination: URL(string: "https://github.com/deadjoe/blackbird")!)
                }
            }
            .navigationTitle("Settings")
        }
    }
    
    private func refreshAllFeeds() async {
        let viewModel = FeedListViewModel(modelContext: modelContext)
        for feed in feeds {
            await viewModel.refreshFeed(feed)
        }
    }
    
    private func clearReadArticles() {
        let descriptor = FetchDescriptor<Article>(predicate: #Predicate { $0.isRead == true && $0.isStarred == false })
        if let readArticles = try? modelContext.fetch(descriptor) {
            for article in readArticles {
                modelContext.delete(article)
            }
            try? modelContext.save()
        }
    }
}

#Preview {
    SettingsView()
        .modelContainer(for: [Feed.self, Article.self], inMemory: true)
}
