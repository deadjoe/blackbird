import SwiftUI
import SwiftData

@main
struct BlackbirdApp: App {
    var body: some Scene {
        WindowGroup {
            ContentView()
        }
        .modelContainer(for: [Feed.self, Article.self])
    }
}
