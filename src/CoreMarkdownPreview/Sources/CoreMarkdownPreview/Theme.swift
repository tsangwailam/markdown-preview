import Foundation

public enum PreviewTheme: Sendable {
    case light
    case dark
    case auto

    public static func fromDarkMode(_ isDarkMode: Bool) -> PreviewTheme {
        isDarkMode ? .dark : .light
    }
}

public enum ThemeCSS {
    public static let light = """
    :root { color-scheme: light; }
    body {
      font-family: -apple-system, BlinkMacSystemFont, "Segoe UI", sans-serif;
      line-height: 1.55;
      color: #1f2328;
      background: #ffffff;
      margin: 0;
      padding: 24px;
    }
    h1,h2,h3,h4,h5,h6 { margin: 1em 0 0.4em; line-height: 1.25; }
    p { margin: 0.7em 0; }
    a { color: #0969da; text-decoration: none; }
    a:hover { text-decoration: underline; }
    code {
      font-family: ui-monospace, SFMono-Regular, Menlo, Monaco, Consolas, monospace;
      background: #f6f8fa;
      border-radius: 6px;
      padding: 0.15em 0.35em;
      font-size: 0.92em;
    }
    pre {
      background: #f6f8fa;
      border-radius: 10px;
      padding: 14px;
      overflow-x: auto;
    }
    pre code { background: transparent; padding: 0; }
    blockquote {
      margin: 1em 0;
      padding: 0.1em 1em;
      border-left: 4px solid #d0d7de;
      color: #57606a;
    }
    table {
      border-collapse: collapse;
      width: 100%;
      margin: 1em 0;
      font-size: 0.95em;
    }
    th, td {
      border: 1px solid #d0d7de;
      padding: 0.45em 0.6em;
      text-align: left;
    }
    th { background: #f6f8fa; }
    ul, ol { margin: 0.6em 0 0.6em 1.3em; }
    hr { border: 0; border-top: 1px solid #d0d7de; margin: 1.2em 0; }
    """

    public static let dark = """
    :root { color-scheme: dark; }
    body {
      font-family: -apple-system, BlinkMacSystemFont, "Segoe UI", sans-serif;
      line-height: 1.55;
      color: #e6edf3;
      background: #0d1117;
      margin: 0;
      padding: 24px;
    }
    h1,h2,h3,h4,h5,h6 { margin: 1em 0 0.4em; line-height: 1.25; }
    p { margin: 0.7em 0; }
    a { color: #58a6ff; text-decoration: none; }
    a:hover { text-decoration: underline; }
    code {
      font-family: ui-monospace, SFMono-Regular, Menlo, Monaco, Consolas, monospace;
      background: #161b22;
      border-radius: 6px;
      padding: 0.15em 0.35em;
      font-size: 0.92em;
    }
    pre {
      background: #161b22;
      border-radius: 10px;
      padding: 14px;
      overflow-x: auto;
    }
    pre code { background: transparent; padding: 0; }
    blockquote {
      margin: 1em 0;
      padding: 0.1em 1em;
      border-left: 4px solid #30363d;
      color: #8b949e;
    }
    table {
      border-collapse: collapse;
      width: 100%;
      margin: 1em 0;
      font-size: 0.95em;
    }
    th, td {
      border: 1px solid #30363d;
      padding: 0.45em 0.6em;
      text-align: left;
    }
    th { background: #161b22; }
    ul, ol { margin: 0.6em 0 0.6em 1.3em; }
    hr { border: 0; border-top: 1px solid #30363d; margin: 1.2em 0; }
    """
}
