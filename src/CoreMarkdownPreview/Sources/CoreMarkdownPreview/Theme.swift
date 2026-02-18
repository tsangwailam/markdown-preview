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
      margin: 0;
    }
    pre code { background: transparent; padding: 0; }
    .code-block { margin: 1em 0; }
    .code-toolbar {
      display: flex;
      justify-content: flex-end;
      margin: 0 0 6px;
    }
    .code-toggle {
      font-size: 12px;
      line-height: 1.2;
      border: 1px solid #d0d7de;
      background: #ffffff;
      color: #24292f;
      border-radius: 999px;
      padding: 4px 10px;
      cursor: pointer;
    }
    .code-toggle[disabled] { opacity: 0.6; cursor: default; }
    .hljs { color: #24292f; background: transparent; }
    .hljs-comment, .hljs-quote { color: #6e7781; }
    .hljs-keyword, .hljs-selector-tag, .hljs-type { color: #cf222e; }
    .hljs-string, .hljs-attr { color: #0a3069; }
    .hljs-number, .hljs-literal { color: #0550ae; }
    .hljs-title, .hljs-section, .hljs-name { color: #8250df; }
    .hljs-variable, .hljs-template-variable { color: #953800; }
    .hljs-built_in, .hljs-builtin-name { color: #953800; }
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
      margin: 0;
    }
    pre code { background: transparent; padding: 0; }
    .code-block { margin: 1em 0; }
    .code-toolbar {
      display: flex;
      justify-content: flex-end;
      margin: 0 0 6px;
    }
    .code-toggle {
      font-size: 12px;
      line-height: 1.2;
      border: 1px solid #30363d;
      background: #0d1117;
      color: #c9d1d9;
      border-radius: 999px;
      padding: 4px 10px;
      cursor: pointer;
    }
    .code-toggle[disabled] { opacity: 0.6; cursor: default; }
    .hljs { color: #c9d1d9; background: transparent; }
    .hljs-comment, .hljs-quote { color: #8b949e; }
    .hljs-keyword, .hljs-selector-tag, .hljs-type { color: #ff7b72; }
    .hljs-string, .hljs-attr { color: #a5d6ff; }
    .hljs-number, .hljs-literal { color: #79c0ff; }
    .hljs-title, .hljs-section, .hljs-name { color: #d2a8ff; }
    .hljs-variable, .hljs-template-variable { color: #ffa657; }
    .hljs-built_in, .hljs-builtin-name { color: #ffa657; }
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
