# Blackbird

Blackbird 是一个简洁、高效的 iOS RSS 阅读器应用，使用 SwiftUI 和 SwiftData 构建。它允许用户添加、管理和阅读来自各种网站的 RSS/Atom/JSON Feed 订阅源。

## 功能特点

- 添加、删除和刷新 Feed 订阅源
- 标记/收藏喜爱的 Feed 和文章
- 阅读文章内容，支持 Markdown 渲染
- 在浏览器中打开原始文章链接
- 自动刷新 Feed 内容
- 深色模式支持
- 使用 SwiftData 进行本地数据存储

## 技术栈

- SwiftUI：用于构建用户界面
- SwiftData：用于数据持久化
- MVVM 架构模式
- FeedKit：用于解析 RSS/Atom/JSON Feed
- Swift 并发（async/await）

## 系统要求

- iOS 17.0 或更高版本
- Xcode 15.0 或更高版本

## 开发设置

### 前提条件

- 安装最新版本的 Xcode
- 安装 [XcodeGen](https://github.com/yonaskolb/XcodeGen)（`brew install xcodegen`）

### 构建步骤

1. 克隆仓库：
   ```bash
   git clone https://github.com/deadjoe/blackbird.git
   cd blackbird
   ```

2. 生成 Xcode 项目：
   ```bash
   xcodegen
   ```

3. 打开生成的 Xcode 项目：
   ```bash
   open Blackbird.xcodeproj
   ```

4. 构建并运行应用

## 项目结构

```
Blackbird/
├── Models/          # 数据模型
├── Views/           # SwiftUI 视图
├── ViewModels/      # 视图模型
├── Services/        # 服务层
└── Utils/           # 工具类和扩展
```

## 测试

项目包含单元测试，涵盖了核心功能和数据模型。运行测试：

```bash
xcodegen
open Blackbird.xcodeproj
# 在 Xcode 中按 Cmd+U 运行测试
```

## 贡献

欢迎提交 Pull Request 和 Issue。

## 许可证

MIT
