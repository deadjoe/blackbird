import Foundation

extension String {
    /// 从 HTML 字符串中移除 HTML 标签，返回纯文本
    func cleanHTMLTags() -> String {
        // 使用简单的正则表达式移除 HTML 标签
        let htmlTagPattern = "<[^>]+>"
        let htmlTagRegex = try? NSRegularExpression(pattern: htmlTagPattern, options: .caseInsensitive)
        let range = NSRange(location: 0, length: self.count)
        let cleanText = htmlTagRegex?.stringByReplacingMatches(in: self, options: [], range: range, withTemplate: "") ?? self

        // 处理常见的 HTML 实体
        return cleanText
            .replacingOccurrences(of: "&amp;", with: "&")
            .replacingOccurrences(of: "&lt;", with: "<")
            .replacingOccurrences(of: "&gt;", with: ">")
            .replacingOccurrences(of: "&quot;", with: "\"")
            .replacingOccurrences(of: "&apos;", with: "'")
            .replacingOccurrences(of: "&#39;", with: "'")
            .replacingOccurrences(of: "&nbsp;", with: " ")
    }

    /// 将 HTML 内容包装在完整的 HTML 文档中
    func wrapInHTMLDocument() -> String {
        // 检查是否已经是完整的 HTML 文档
        if self.lowercased().contains("<!doctype html") ||
           (self.lowercased().contains("<html") && self.lowercased().contains("</html>")) {
            return self
        }

        // 包装在完整的 HTML 文档中
        return """
        <!DOCTYPE html>
        <html>
        <head>
            <meta charset="UTF-8">
            <meta name="viewport" content="width=device-width, initial-scale=1.0, maximum-scale=5.0, user-scalable=yes">
            <style>
                body {
                    font-family: -apple-system, BlinkMacSystemFont, 'Segoe UI', Roboto, Helvetica, Arial, sans-serif;
                    line-height: 1.6;
                    padding: 12px;
                    margin: 0;
                    font-size: 16px;
                    overflow-y: scroll;
                    -webkit-overflow-scrolling: touch;
                }

                img {
                    max-width: 100%;
                    height: auto;
                }

                a {
                    color: #007AFF;
                    text-decoration: none;
                }

                pre, code {
                    background-color: rgba(0, 0, 0, 0.05);
                    border-radius: 4px;
                    padding: 0.2em 0.4em;
                    overflow-x: auto;
                }

                @media (prefers-color-scheme: dark) {
                    body {
                        color: #FFFFFF;
                        background-color: #000000;
                    }
                    a {
                        color: #0A84FF;
                    }
                    pre, code {
                        background-color: rgba(255, 255, 255, 0.1);
                    }
                }
            </style>
        </head>
        <body>
            \(self)
        </body>
        </html>
        """
    }
}
