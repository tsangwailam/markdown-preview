import Foundation

public struct MarkdownRenderer {
    public init() {}

    public func render(markdown: String, theme: PreviewTheme) -> String {
        let body = renderBlocks(markdown)
        return HTMLTemplate.page(body: body, theme: theme)
    }

    private func renderBlocks(_ markdown: String) -> String {
        let normalized = markdown.replacingOccurrences(of: "\r\n", with: "\n")
        let lines = normalized.split(separator: "\n", omittingEmptySubsequences: false).map(String.init)

        var html: [String] = []
        var i = 0

        while i < lines.count {
            let line = lines[i]

            if line.trimmingCharacters(in: .whitespaces).isEmpty {
                i += 1
                continue
            }

            if let hr = renderHorizontalRule(line) {
                html.append(hr)
                i += 1
                continue
            }

            if line.hasPrefix("```") {
                let (block, nextIndex) = renderCodeBlock(lines: lines, start: i)
                html.append(block)
                i = nextIndex
                continue
            }

            if let heading = renderHeading(line) {
                html.append(heading)
                i += 1
                continue
            }

            if line.hasPrefix(">") {
                let (blockquote, nextIndex) = renderBlockquote(lines: lines, start: i)
                html.append(blockquote)
                i = nextIndex
                continue
            }

            if isTableHeader(lines, at: i) {
                let (table, nextIndex) = renderTable(lines: lines, start: i)
                html.append(table)
                i = nextIndex
                continue
            }

            if isOrderedListLine(line) || isUnorderedListLine(line) {
                let (list, nextIndex) = renderList(lines: lines, start: i)
                html.append(list)
                i = nextIndex
                continue
            }

            let (paragraph, nextIndex) = renderParagraph(lines: lines, start: i)
            html.append(paragraph)
            i = nextIndex
        }

        return html.joined(separator: "\n")
    }

    private func renderHorizontalRule(_ line: String) -> String? {
        let trimmed = line.trimmingCharacters(in: .whitespaces)
        if trimmed == "---" || trimmed == "***" || trimmed == "___" {
            return "<hr />"
        }
        return nil
    }

    private func renderHeading(_ line: String) -> String? {
        let hashes = line.prefix { $0 == "#" }.count
        guard hashes > 0 && hashes <= 6 else { return nil }
        let remainder = line.dropFirst(hashes)
        guard remainder.first == " " else { return nil }
        let content = inlineMarkup(String(remainder.dropFirst()))
        return "<h\(hashes)>\(content)</h\(hashes)>"
    }

    private func renderCodeBlock(lines: [String], start: Int) -> (String, Int) {
        let language = fenceLanguage(from: lines[start])
        var i = start + 1
        var codeLines: [String] = []
        while i < lines.count {
            if lines[i].hasPrefix("```") {
                i += 1
                break
            }
            codeLines.append(lines[i])
            i += 1
        }

        let rawCode = codeLines.joined(separator: "\n")
        let code = escapeHTML(rawCode)
        let classAttribute: String
        let dataAttribute: String
        if let language {
            classAttribute = " class=\"language-\(escapeHTML(language))\""
            dataAttribute = " data-language=\"\(escapeHTML(language))\""
        } else {
            classAttribute = ""
            dataAttribute = ""
        }
        return ("<pre><code\(classAttribute)\(dataAttribute)>\(code)</code></pre>", i)
    }

    private func fenceLanguage(from line: String) -> String? {
        guard line.hasPrefix("```") else { return nil }
        let remainder = line.dropFirst(3).trimmingCharacters(in: .whitespaces)
        guard !remainder.isEmpty else { return nil }
        let token = remainder.split(whereSeparator: \.isWhitespace).first.map(String.init) ?? ""
        let normalized = token
            .trimmingCharacters(in: CharacterSet(charactersIn: "{}."))
            .lowercased()
        switch normalized {
        case "yml":
            return "yaml"
        case "py":
            return "python"
        case "js":
            return "javascript"
        case "ts":
            return "typescript"
        default:
            break
        }
        return normalized.isEmpty ? nil : normalized
    }

    private func renderBlockquote(lines: [String], start: Int) -> (String, Int) {
        var i = start
        var content: [String] = []
        while i < lines.count {
            let line = lines[i]
            guard line.hasPrefix(">") else { break }
            var stripped = String(line.dropFirst())
            if stripped.hasPrefix(" ") {
                stripped.removeFirst()
            }
            content.append(stripped)
            i += 1
        }

        let inner = inlineMarkup(content.joined(separator: "<br />"))
        return ("<blockquote><p>\(inner)</p></blockquote>", i)
    }

    private func renderParagraph(lines: [String], start: Int) -> (String, Int) {
        var i = start
        var pieces: [String] = []

        while i < lines.count {
            let line = lines[i]
            let trimmed = line.trimmingCharacters(in: .whitespaces)
            if trimmed.isEmpty ||
                line.hasPrefix("```") ||
                line.hasPrefix(">") ||
                renderHeading(line) != nil ||
                isOrderedListLine(line) ||
                isUnorderedListLine(line) ||
                isTableHeader(lines, at: i) ||
                renderHorizontalRule(line) != nil {
                break
            }
            pieces.append(trimmed)
            i += 1
        }

        let merged = inlineMarkup(pieces.joined(separator: " "))
        return ("<p>\(merged)</p>", i)
    }

    private func renderList(lines: [String], start: Int) -> (String, Int) {
        let ordered = isOrderedListLine(lines[start])
        var i = start
        var items: [String] = []

        while i < lines.count {
            let line = lines[i]
            if ordered && !isOrderedListLine(line) { break }
            if !ordered && !isUnorderedListLine(line) { break }

            let content: String
            if ordered {
                guard let range = line.range(of: #"^\s*\d+\.\s+"#, options: .regularExpression) else {
                    break
                }
                content = String(line[range.upperBound...])
            } else {
                guard let range = line.range(of: #"^\s*[-*+]\s+"#, options: .regularExpression) else {
                    break
                }
                content = String(line[range.upperBound...])
            }

            items.append("<li>\(inlineMarkup(content.trimmingCharacters(in: .whitespaces)))</li>")
            i += 1
        }

        let tag = ordered ? "ol" : "ul"
        return ("<\(tag)>\(items.joined())</\(tag)>", i)
    }

    private func isOrderedListLine(_ line: String) -> Bool {
        line.range(of: #"^\s*\d+\.\s+"#, options: .regularExpression) != nil
    }

    private func isUnorderedListLine(_ line: String) -> Bool {
        line.range(of: #"^\s*[-*+]\s+"#, options: .regularExpression) != nil
    }

    private func isTableHeader(_ lines: [String], at index: Int) -> Bool {
        guard index + 1 < lines.count else { return false }
        let header = lines[index]
        let separator = lines[index + 1].trimmingCharacters(in: .whitespaces)
        guard header.contains("|") else { return false }
        return separator.range(of: #"^\|?\s*:?-{3,}:?\s*(\|\s*:?-{3,}:?\s*)+\|?$"#, options: .regularExpression) != nil
    }

    private func renderTable(lines: [String], start: Int) -> (String, Int) {
        let headers = splitTableRow(lines[start]).map(inlineMarkup)
        var i = start + 2
        var rows: [[String]] = []

        while i < lines.count {
            let line = lines[i].trimmingCharacters(in: .whitespaces)
            if line.isEmpty || !line.contains("|") {
                break
            }
            rows.append(splitTableRow(line).map(inlineMarkup))
            i += 1
        }

        let thead = "<thead><tr>" + headers.map { "<th>\($0)</th>" }.joined() + "</tr></thead>"
        let tbodyRows = rows.map { row in
            "<tr>" + row.map { "<td>\($0)</td>" }.joined() + "</tr>"
        }.joined()

        let tbody = "<tbody>\(tbodyRows)</tbody>"
        return ("<table>\(thead)\(tbody)</table>", i)
    }

    private func splitTableRow(_ row: String) -> [String] {
        var trimmed = row.trimmingCharacters(in: .whitespaces)
        if trimmed.hasPrefix("|") { trimmed.removeFirst() }
        if trimmed.hasSuffix("|") { trimmed.removeLast() }
        return trimmed.split(separator: "|").map { $0.trimmingCharacters(in: .whitespaces) }
    }

    private func inlineMarkup(_ text: String) -> String {
        var out = escapeHTML(text)

        out = out.replacingOccurrences(
            of: #"`([^`]+)`"#,
            with: "<code>$1</code>",
            options: .regularExpression
        )

        out = out.replacingOccurrences(
            of: #"\*\*([^*]+)\*\*"#,
            with: "<strong>$1</strong>",
            options: .regularExpression
        )

        out = out.replacingOccurrences(
            of: #"\*([^*]+)\*"#,
            with: "<em>$1</em>",
            options: .regularExpression
        )

        out = regexReplace(
            pattern: #"\[([^\]]+)\]\(([^)]+)\)"#,
            in: out
        ) { groups in
            guard groups.count == 2 else { return groups.first ?? "" }
            let linkText = groups[0]
            let url = sanitizeURL(groups[1])
            return #"<a href="\#(url)">\#(linkText)</a>"#
        }

        return out
    }

    private func regexReplace(
        pattern: String,
        in input: String,
        transform: ([String]) -> String
    ) -> String {
        guard let regex = try? NSRegularExpression(pattern: pattern) else {
            return input
        }

        let nsRange = NSRange(input.startIndex..<input.endIndex, in: input)
        let matches = regex.matches(in: input, range: nsRange)
        if matches.isEmpty {
            return input
        }

        var result = input
        for match in matches.reversed() {
            var groups: [String] = []
            for index in 1..<match.numberOfRanges {
                guard let range = Range(match.range(at: index), in: result) else { continue }
                groups.append(String(result[range]))
            }
            guard let fullRange = Range(match.range(at: 0), in: result) else { continue }
            result.replaceSubrange(fullRange, with: transform(groups))
        }
        return result
    }

    private func sanitizeURL(_ raw: String) -> String {
        let candidate = raw.trimmingCharacters(in: .whitespacesAndNewlines)
        guard let components = URLComponents(string: candidate),
              let scheme = components.scheme?.lowercased(),
              ["http", "https", "mailto"].contains(scheme)
        else {
            return "#"
        }
        return escapeAttribute(candidate)
    }

    private func escapeHTML(_ value: String) -> String {
        value
            .replacingOccurrences(of: "&", with: "&amp;")
            .replacingOccurrences(of: "<", with: "&lt;")
            .replacingOccurrences(of: ">", with: "&gt;")
    }

    private func escapeAttribute(_ value: String) -> String {
        escapeHTML(value).replacingOccurrences(of: "\"", with: "&quot;")
    }
}
