import XCTest
@testable import CoreMarkdownPreview

final class MarkdownRendererTests: XCTestCase {
    func testHeadingAndParagraphRender() {
        let renderer = MarkdownRenderer()
        let html = renderer.render(markdown: "# Title\n\nHello **world**", theme: .light)

        XCTAssertTrue(html.contains("<h1>Title</h1>"))
        XCTAssertTrue(html.contains("<p>Hello <strong>world</strong></p>"))
    }

    func testCodeFenceEscapesHtml() {
        let renderer = MarkdownRenderer()
        let markdown = "```\n<script>alert('x')</script>\n```"
        let html = renderer.render(markdown: markdown, theme: .light)

        XCTAssertTrue(html.contains("&lt;script&gt;alert('x')&lt;/script&gt;"))
        XCTAssertFalse(html.contains("<script>alert('x')</script>"))
    }

    func testTableRender() {
        let renderer = MarkdownRenderer()
        let markdown = "| Name | Age |\n| --- | --- |\n| Sam | 30 |"
        let html = renderer.render(markdown: markdown, theme: .light)

        XCTAssertTrue(html.contains("<table>"))
        XCTAssertTrue(html.contains("<th>Name</th>"))
        XCTAssertTrue(html.contains("<td>30</td>"))
    }
}
