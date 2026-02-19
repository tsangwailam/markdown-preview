import Cocoa
import Quartz
import WebKit
import CoreMarkdownPreview

final class PreviewViewController: NSViewController, QLPreviewingController, WKNavigationDelegate {
    private enum PreviewMode {
        case rendered
        case raw
    }

    private let cache = PreviewCache(capacity: 48)
    private let renderer = MarkdownRenderer()
    private var webView: WKWebView!
    private var toggleButton: NSButton!
    private var fallbackScrollView: NSScrollView!
    private var fallbackTextView: NSTextView!
    private var pendingHandler: ((Error?) -> Void)?
    private var pendingTimeoutWorkItem: DispatchWorkItem?
    private var lastMarkdown: String = ""
    private var lastHTML: String?
    private var attemptedSafeReload = false
    private var currentMode: PreviewMode = .rendered

    override func loadView() {
        let config = WKWebViewConfiguration()
        config.defaultWebpagePreferences.allowsContentJavaScript = true

        let container = NSView(frame: .zero)

        let webView = WKWebView(frame: .zero, configuration: config)
        webView.navigationDelegate = self
        webView.translatesAutoresizingMaskIntoConstraints = false
        self.webView = webView

        let textView = NSTextView(frame: .zero)
        textView.isEditable = false
        textView.isRichText = false
        textView.drawsBackground = true
        textView.backgroundColor = .textBackgroundColor
        textView.font = .monospacedSystemFont(ofSize: 12, weight: .regular)
        textView.isVerticallyResizable = true
        textView.isHorizontallyResizable = false
        textView.autoresizingMask = [.width]
        textView.textContainer?.widthTracksTextView = true
        textView.textContainer?.containerSize = NSSize(width: 0, height: CGFloat.greatestFiniteMagnitude)
        self.fallbackTextView = textView

        let scrollView = NSScrollView(frame: .zero)
        scrollView.translatesAutoresizingMaskIntoConstraints = false
        scrollView.hasVerticalScroller = true
        scrollView.hasHorizontalScroller = false
        scrollView.borderType = .noBorder
        scrollView.documentView = textView
        textView.frame = scrollView.contentView.bounds
        scrollView.isHidden = true
        self.fallbackScrollView = scrollView

        let button = NSButton(title: "Raw", target: self, action: #selector(togglePreviewMode))
        button.translatesAutoresizingMaskIntoConstraints = false
        button.bezelStyle = .rounded
        self.toggleButton = button

        container.addSubview(webView)
        container.addSubview(scrollView)
        container.addSubview(button)

        NSLayoutConstraint.activate([
            webView.topAnchor.constraint(equalTo: container.topAnchor),
            webView.leadingAnchor.constraint(equalTo: container.leadingAnchor),
            webView.trailingAnchor.constraint(equalTo: container.trailingAnchor),
            webView.bottomAnchor.constraint(equalTo: container.bottomAnchor),

            scrollView.topAnchor.constraint(equalTo: container.topAnchor),
            scrollView.leadingAnchor.constraint(equalTo: container.leadingAnchor),
            scrollView.trailingAnchor.constraint(equalTo: container.trailingAnchor),
            scrollView.bottomAnchor.constraint(equalTo: container.bottomAnchor),

            button.topAnchor.constraint(equalTo: container.topAnchor, constant: 10),
            button.trailingAnchor.constraint(equalTo: container.trailingAnchor, constant: -10)
        ])

        self.view = container
    }

    func preparePreviewOfFile(at url: URL, completionHandler handler: @escaping (Error?) -> Void) {
        Task {
            do {
                let markdown = try Self.readMarkdown(at: url)
                let key = try Self.cacheKey(for: url)
                if let cached = await cache.value(for: key) {
                    await MainActor.run {
                        lastMarkdown = markdown
                        loadHTML(cached, completion: handler)
                    }
                    return
                }

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
                await MainActor.run {
                    lastMarkdown = markdown
                    loadHTML(html, completion: handler)
                }
            } catch {
                Task { @MainActor in
                    let message = """
                    Markdown preview failed.

                    \(error.localizedDescription)

                    File: \(url.path)
                    """
                    setErrorHTML(message)
                    finishPending(nil)
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
    private func loadHTML(_ html: String, completion: @escaping (Error?) -> Void) {
        finishPending(nil)
        pendingHandler = completion
        lastHTML = html
        attemptedSafeReload = false
        applyCurrentMode()
        let timeout = DispatchWorkItem { [weak self] in
            Task { @MainActor in
                self?.finishPending(nil)
            }
        }
        pendingTimeoutWorkItem = timeout
        DispatchQueue.main.asyncAfter(deadline: .now() + 2.0, execute: timeout)
        let resourceBundle = Bundle(for: PreviewViewController.self)
        webView.loadHTMLString(html, baseURL: resourceBundle.resourceURL)
    }

    @MainActor
    @objc
    private func togglePreviewMode() {
        currentMode = currentMode == .rendered ? .raw : .rendered
        applyCurrentMode()
    }

    @MainActor
    private func applyCurrentMode() {
        fallbackTextView.string = lastMarkdown
        let showRaw = currentMode == .raw
        webView.isHidden = showRaw
        fallbackScrollView.isHidden = !showRaw
        toggleButton.title = showRaw ? "Render" : "Raw"
    }

    private func strippedFormatterScripts(from html: String) -> String {
        var stripped = html
        stripped = stripped.replacingOccurrences(of: "<script src=\"highlight.min.js\"></script>", with: "")
        stripped = stripped.replacingOccurrences(of: "<script src=\"standalone.js\"></script>", with: "")
        stripped = stripped.replacingOccurrences(of: "<script src=\"parser-babel.js\"></script>", with: "")
        stripped = stripped.replacingOccurrences(of: "<script src=\"parser-estree.js\"></script>", with: "")
        stripped = stripped.replacingOccurrences(of: "<script src=\"parser-html.js\"></script>", with: "")
        stripped = stripped.replacingOccurrences(of: "<script src=\"parser-yaml.js\"></script>", with: "")
        stripped = stripped.replacingOccurrences(
            of: #"<script>\s*\(function\s*\(\)\s*\{[\s\S]*?\}\)\(\);\s*</script>"#,
            with: "",
            options: .regularExpression
        )
        return stripped
    }

    @MainActor
    private func setErrorHTML(_ text: String) {
        let escaped = text
            .replacingOccurrences(of: "&", with: "&amp;")
            .replacingOccurrences(of: "<", with: "&lt;")
            .replacingOccurrences(of: ">", with: "&gt;")
        let html = HTMLTemplate.page(body: "<pre><code>\(escaped)</code></pre>", theme: .light)
        let resourceBundle = Bundle(for: PreviewViewController.self)
        webView.loadHTMLString(html, baseURL: resourceBundle.resourceURL)
    }

    @MainActor
    private func finishPending(_ error: Error?) {
        pendingTimeoutWorkItem?.cancel()
        pendingTimeoutWorkItem = nil
        guard let handler = pendingHandler else {
            return
        }
        pendingHandler = nil
        handler(error)
    }

    func webView(_ webView: WKWebView, didFinish navigation: WKNavigation!) {
        Task { @MainActor in
            finishPending(nil)
        }
    }

    func webView(_ webView: WKWebView, didFail navigation: WKNavigation!, withError error: Error) {
        Task { @MainActor in
            finishPending(error)
        }
    }

    func webView(_ webView: WKWebView, didFailProvisionalNavigation navigation: WKNavigation!, withError error: Error) {
        Task { @MainActor in
            finishPending(error)
        }
    }

    func webViewWebContentProcessDidTerminate(_ webView: WKWebView) {
        Task { @MainActor in
            guard !attemptedSafeReload, let html = lastHTML else {
                currentMode = .raw
                applyCurrentMode()
                finishPending(nil)
                return
            }
            attemptedSafeReload = true
            let safeHTML = strippedFormatterScripts(from: html)
            let resourceBundle = Bundle(for: PreviewViewController.self)
            webView.loadHTMLString(safeHTML, baseURL: resourceBundle.resourceURL)
        }
    }
}
