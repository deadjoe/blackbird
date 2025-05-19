import SwiftUI

struct ContentView: View {
    @State private var selectedTab = 0
    
    var body: some View {
        TabView(selection: $selectedTab) {
            FeedListView()
                .tabItem {
                    Label("Feeds", systemImage: "list.bullet")
                }
                .tag(0)
            
            StarredArticlesView()
                .tabItem {
                    Label("Starred", systemImage: "star.fill")
                }
                .tag(1)
            
            SettingsView()
                .tabItem {
                    Label("Settings", systemImage: "gear")
                }
                .tag(2)
        }
    }
}

#Preview {
    ContentView()
}
