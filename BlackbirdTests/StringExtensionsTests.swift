import XCTest
@testable import Blackbird

final class StringExtensionsTests: XCTestCase {

    // MARK: - cleanHTMLTags Tests

    func testCleanHTMLTagsWithSimpleHTML() {
        let htmlString = "<p>This is a <b>test</b> paragraph.</p>"
        let cleanedString = htmlString.cleanHTMLTags()

        XCTAssertEqual(cleanedString, "This is a test paragraph.")
    }

    func testCleanHTMLTagsWithComplexHTML() {
        let htmlString = """
        <div class="content">
            <h1>Article Title</h1>
            <p>This is a <strong>bold</strong> and <em>emphasized</em> text.</p>
            <ul>
                <li>Item 1</li>
                <li>Item 2</li>
            </ul>
        </div>
        """

        let cleanedString = htmlString.cleanHTMLTags()
        let expectedString = """

    Article Title
    This is a bold and emphasized text.

        Item 1
        Item 2

"""

        XCTAssertEqual(cleanedString, expectedString)
    }

    func testCleanHTMLTagsWithEntities() {
        let htmlString = "This &amp; that &lt;tag&gt; with &quot;quotes&quot; and &apos;apostrophes&apos; &#39;another apostrophe&#39; and&nbsp;spaces."
        let cleanedString = htmlString.cleanHTMLTags()

        XCTAssertEqual(cleanedString, "This & that <tag> with \"quotes\" and 'apostrophes' 'another apostrophe' and spaces.")
    }

    func testCleanHTMLTagsWithNoHTML() {
        let plainString = "This is just plain text with no HTML."
        let cleanedString = plainString.cleanHTMLTags()

        XCTAssertEqual(cleanedString, plainString)
    }

    // MARK: - wrapInHTMLDocument Tests

    func testWrapInHTMLDocumentWithPlainText() {
        let plainText = "This is plain text."
        let wrappedHTML = plainText.wrapInHTMLDocument()

        XCTAssertTrue(wrappedHTML.contains("<!DOCTYPE html>"))
        XCTAssertTrue(wrappedHTML.contains("<html>"))
        XCTAssertTrue(wrappedHTML.contains("<head>"))
        XCTAssertTrue(wrappedHTML.contains("<body>"))
        XCTAssertTrue(wrappedHTML.contains("This is plain text."))
        XCTAssertTrue(wrappedHTML.contains("</body>"))
        XCTAssertTrue(wrappedHTML.contains("</html>"))
    }

    func testWrapInHTMLDocumentWithHTMLFragment() {
        let htmlFragment = "<p>This is an HTML fragment.</p>"
        let wrappedHTML = htmlFragment.wrapInHTMLDocument()

        XCTAssertTrue(wrappedHTML.contains("<!DOCTYPE html>"))
        XCTAssertTrue(wrappedHTML.contains("<p>This is an HTML fragment.</p>"))
    }

    func testWrapInHTMLDocumentWithCompleteHTML() {
        let completeHTML = """
        <!DOCTYPE html>
        <html>
        <head>
            <title>Test</title>
        </head>
        <body>
            <p>This is already a complete HTML document.</p>
        </body>
        </html>
        """

        let wrappedHTML = completeHTML.wrapInHTMLDocument()

        // Should return the original HTML unchanged
        XCTAssertEqual(wrappedHTML, completeHTML)
    }

    func testWrapInHTMLDocumentWithHTMLWithoutDoctype() {
        let htmlWithoutDoctype = """
        <html>
        <head>
            <title>Test</title>
        </head>
        <body>
            <p>This HTML has no doctype but is otherwise complete.</p>
        </body>
        </html>
        """

        let wrappedHTML = htmlWithoutDoctype.wrapInHTMLDocument()

        // Should return the original HTML unchanged
        XCTAssertEqual(wrappedHTML, htmlWithoutDoctype)
    }
}
