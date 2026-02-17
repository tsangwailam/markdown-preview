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

    func testCodeFenceIncludesLanguageClassForJSON() {
        let renderer = MarkdownRenderer()
        let markdown = """
        ```json
        {"b":1,"a":{"d":4,"c":3}}
        ```
        """

        let html = renderer.render(markdown: markdown, theme: .light)

        XCTAssertTrue(html.contains("<pre><code class=\"language-json\" data-language=\"json\">"))
        XCTAssertTrue(html.contains("{\"b\":1,\"a\":{\"d\":4,\"c\":3}}"))
    }

    func testCodeFenceNormalizesYMLToYAMLClass() {
        let renderer = MarkdownRenderer()
        let markdown = """
        ```yml
        a: 1
        ```
        """

        let html = renderer.render(markdown: markdown, theme: .light)

        XCTAssertTrue(html.contains("class=\"language-yaml\""))
        XCTAssertTrue(html.contains("data-language=\"yaml\""))
    }

    func testSQLCodeFenceIncludesLanguageClass() {
        let renderer = MarkdownRenderer()
        let markdown = """
        ```sql
        select id,name from users where active = 1 order by name
        ```
        """

        let html = renderer.render(markdown: markdown, theme: .light)

        XCTAssertTrue(html.contains("class=\"language-sql\""))
        XCTAssertTrue(html.contains("select id,name from users where active = 1 order by name"))
    }
}
