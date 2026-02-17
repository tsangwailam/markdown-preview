import Cocoa
import Quartz
import CoreMarkdownPreview

final class PreviewViewController: NSViewController, QLPreviewingController {
    private let cache = PreviewCache(capacity: 48)
    private let renderer = MarkdownRenderer()
    private var textView: NSTextView!

    override func loadView() {
        let scrollView = NSTextView.scrollableTextView()
        scrollView.hasVerticalScroller = true
        scrollView.hasHorizontalScroller = false
        scrollView.autohidesScrollers = true
        scrollView.drawsBackground = true
        scrollView.backgroundColor = .textBackgroundColor
        scrollView.translatesAutoresizingMaskIntoConstraints = false

        guard let textView = scrollView.documentView as? NSTextView else {
            self.view = NSView()
            return
        }

        self.textView = textView
        self.textView.isEditable = false
        self.textView.isSelectable = true
        self.textView.drawsBackground = true
        self.textView.backgroundColor = .textBackgroundColor
        self.textView.textContainerInset = NSSize(width: 16, height: 16)
        self.textView.minSize = NSSize(width: 0, height: 0)
        self.textView.maxSize = NSSize(width: CGFloat.greatestFiniteMagnitude, height: CGFloat.greatestFiniteMagnitude)
        self.textView.isVerticallyResizable = true
        self.textView.isHorizontallyResizable = false
        self.textView.autoresizingMask = [.width]
        self.textView.textContainer?.containerSize = NSSize(width: 0, height: CGFloat.greatestFiniteMagnitude)
        self.textView.textContainer?.widthTracksTextView = true

        let container = NSView()
        container.addSubview(scrollView)
        NSLayoutConstraint.activate([
            scrollView.leadingAnchor.constraint(equalTo: container.leadingAnchor),
            scrollView.trailingAnchor.constraint(equalTo: container.trailingAnchor),
            scrollView.topAnchor.constraint(equalTo: container.topAnchor),
            scrollView.bottomAnchor.constraint(equalTo: container.bottomAnchor)
        ])
        self.view = container
    }

    func preparePreviewOfFile(at url: URL, completionHandler handler: @escaping (Error?) -> Void) {
        Task {
            do {
                let key = try Self.cacheKey(for: url)
                if let cached = await cache.value(for: key) {
                    try setHTML(cached)
                    handler(nil)
                    return
                }

                let markdown = try Self.readMarkdown(at: url)
                let isDarkMode = await MainActor.run {
                    view.effectiveAppearance.bestMatch(from: [.darkAqua, .aqua]) == .darkAqua
                }
                let theme = PreviewTheme.fromDarkMode(isDarkMode)

                let html: String
                if key.byteSize > 2_000_000 {
                    let escaped = markdown
                        .replacingOccurrences(of: "&", with: "&amp;")
                        .replacingOccurrences(of: "<", with: "&lt;")
                        .replacingOccurrences(of: ">", with: "&gt;")
                    html = HTMLTemplate.page(body: "<pre><code>\(escaped)</code></pre>", theme: theme)
                } else {
                    html = renderer.render(markdown: markdown, theme: theme)
                }

                await cache.store(html, for: key)
                try setHTML(html)
                handler(nil)
            } catch {
                Task { @MainActor in
                    let message = """
                    Markdown preview failed.

                    \(error.localizedDescription)

                    File: \(url.path)
                    """
                    setPlainText(message)
                    handler(nil)
                }
            }
        }
    }

    private static func readMarkdown(at url: URL) throws -> String {
        let isAccessing = url.startAccessingSecurityScopedResource()
        defer {
            if isAccessing {
                url.stopAccessingSecurityScopedResource()
            }
        }

        var coordinatedError: NSError?
        var readError: Error?
        var data: Data?
        let coordinator = NSFileCoordinator()
        coordinator.coordinate(readingItemAt: url, options: [], error: &coordinatedError) { coordinatedURL in
            do {
                data = try Data(contentsOf: coordinatedURL, options: [.mappedIfSafe])
            } catch {
                readError = error
            }
        }

        if let coordinatedError {
            throw coordinatedError
        }
        if let readError {
            throw readError
        }
        guard let data else {
            throw NSError(
                domain: "MarkdownPreview",
                code: 1002,
                userInfo: [NSLocalizedDescriptionKey: "Unable to read markdown file."]
            )
        }

        if let text = String(data: data, encoding: .utf8) {
            return text
        }
        if let text = String(data: data, encoding: .utf16) {
            return text
        }
        return String(decoding: data, as: UTF8.self)
    }

    private static func cacheKey(for url: URL) throws -> CacheKey {
        let values = try url.resourceValues(forKeys: [.contentModificationDateKey, .fileSizeKey])
        let date = values.contentModificationDate ?? .distantPast
        let size = Int64(values.fileSize ?? 0)
        return CacheKey(path: url.path, modificationTime: date, byteSize: size)
    }

    @MainActor
    private func setHTML(_ html: String) throws {
        let data = Data(html.utf8)
        let attributed = try NSAttributedString(
            data: data,
            options: [
                .documentType: NSAttributedString.DocumentType.html,
                .characterEncoding: String.Encoding.utf8.rawValue
            ],
            documentAttributes: nil
        )
        let mutable = NSMutableAttributedString(attributedString: attributed)
        let fullRange = NSRange(location: 0, length: mutable.length)
        mutable.removeAttribute(.backgroundColor, range: fullRange)
        mutable.addAttribute(.foregroundColor, value: NSColor.labelColor, range: fullRange)
        textView.textStorage?.setAttributedString(mutable)
    }

    @MainActor
    private func setPlainText(_ text: String) {
        textView.string = text
        textView.textColor = .labelColor
    }
}
