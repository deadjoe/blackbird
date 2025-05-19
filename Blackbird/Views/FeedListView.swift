import SwiftUI
import SwiftData

struct FeedListView: View {
    @Environment(\.modelContext) private var modelContext
    @Query private var feeds: [Feed]
    @StateObject private var viewModel = FeedListViewModel()
    @State private var showingAddFeed = false
    @State private var newFeedURL = ""

    var body: some View {
        NavigationStack {
            List {
                ForEach(feeds) { feed in
                    NavigationLink(destination: ArticleListView(feed: feed)) {
                        HStack {
                            VStack(alignment: .leading) {
                                Text(feed.title)
                                    .font(.headline)

                                if let description = feed.feedDescription, !description.isEmpty {
                                    Text(description)
                                        .font(.caption)
                                        .lineLimit(1)
                                }

                                if let lastUpdated = feed.lastUpdated {
                                    Text("Updated: \(lastUpdated.formatted(.relative(presentation: .named)))")
                                        .font(.caption2)
                                        .foregroundColor(.secondary)
                                }
                            }

                            Spacer()

                            if feed.isStarred {
                                Image(systemName: "star.fill")
                                    .foregroundColor(.yellow)
                            }
                        }
                    }
                    .swipeActions {
                        Button(role: .destructive) {
                            viewModel.deleteFeed(feed)
                        } label: {
                            Label("Delete", systemImage: "trash")
                        }

                        Button {
                            viewModel.toggleStarred(feed: feed)
                        } label: {
                            Label(feed.isStarred ? "Unstar" : "Star", systemImage: feed.isStarred ? "star.slash" : "star")
                        }
                        .tint(.yellow)

                        Button {
                            Task {
                                await viewModel.refreshFeed(feed)
                            }
                        } label: {
                            Label("Refresh", systemImage: "arrow.clockwise")
                        }
                        .tint(.blue)
                    }
                }
            }
            .navigationTitle("Feeds")
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button {
                        showingAddFeed = true
                    } label: {
                        Label("Add Feed", systemImage: "plus")
                    }
                }
            }
            .sheet(isPresented: $showingAddFeed) {
                NavigationStack {
                    Form {
                        Section(header: Text("Feed URL")) {
                            TextField("https://example.com/feed.xml", text: $newFeedURL)
                                .autocapitalization(.none)
                                .keyboardType(.URL)
                        }

                        Section {
                            Button("Add Feed") {
                                Task {
                                    await viewModel.addFeed(urlString: newFeedURL)
                                    if viewModel.errorMessage == nil {
                                        newFeedURL = ""
                                        showingAddFeed = false
                                    }
                                }
                            }
                            .disabled(newFeedURL.isEmpty || viewModel.isLoading)

                            if viewModel.isLoading {
                                HStack {
                                    Spacer()
                                    ProgressView()
                                    Spacer()
                                }
                            }

                            if let errorMessage = viewModel.errorMessage {
                                Text(errorMessage)
                                    .foregroundColor(.red)
                            }
                        }
                    }
                    .navigationTitle("Add New Feed")
                    .navigationBarTitleDisplayMode(.inline)
                    .toolbar {
                        ToolbarItem(placement: .navigationBarLeading) {
                            Button("Cancel") {
                                showingAddFeed = false
                                newFeedURL = ""
                                viewModel.errorMessage = nil
                            }
                        }
                    }
                }
                .presentationDetents([.medium])
            }
        }
        .onAppear {
            viewModel.setModelContext(modelContext)
        }
    }
}

#Preview {
    FeedListView()
        .modelContainer(for: [Feed.self, Article.self], inMemory: true)
}
