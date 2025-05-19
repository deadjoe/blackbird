import SwiftUI
import SwiftData
import OSLog

@main
struct BlackbirdApp: App {
    // 创建应用程序日志
    private let logger = Logger(subsystem: "com.deadjoe.blackbird", category: "app")

    // 创建 SwiftData 容器
    private var modelContainer: ModelContainer

    // 初始化
    init() {
        do {
            // 配置持久化选项
            let modelConfiguration = ModelConfiguration(
                isStoredInMemoryOnly: false,
                allowsSave: true
            )

            // 创建模型容器
            modelContainer = try ModelContainer(
                for: Feed.self, Article.self, FeedCategory.self,
                configurations: modelConfiguration
            )

            // 记录初始化成功
            logger.info("SwiftData 模型容器初始化成功")
        } catch {
            // 记录错误并使用内存模式作为备份
            logger.error("SwiftData 模型容器初始化失败: \(error.localizedDescription)")

            // 创建内存模式的模型容器作为备份
            do {
                let backupConfiguration = ModelConfiguration(isStoredInMemoryOnly: true)
                modelContainer = try ModelContainer(
                    for: Feed.self, Article.self, FeedCategory.self,
                    configurations: backupConfiguration
                )
            } catch {
                fatalError("无法创建备份模型容器: \(error.localizedDescription)")
            }
        }
    }

    var body: some Scene {
        WindowGroup {
            ContentView()
                .onAppear {
                    // 记录应用启动
                    logger.info("Blackbird 应用启动")

                    // 确保默认分类存在
                    Task {
                        let context = modelContainer.mainContext
                        let categoryVM = CategoryViewModel(modelContext: context)
                        try? await categoryVM.ensureDefaultCategoryExists()
                    }
                }
        }
        .modelContainer(modelContainer)

        // 设置 App 的生命周期事件处理
        #if os(iOS)
        .onChange(of: UIApplication.shared.applicationState) { _, newState in
            if newState == .background {
                // 应用进入后台时保存数据
                try? modelContainer.mainContext.save()
                logger.info("应用进入后台，数据已保存")
            }
        }
        #endif
    }
}
