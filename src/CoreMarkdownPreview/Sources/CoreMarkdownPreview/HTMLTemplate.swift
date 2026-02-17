import Foundation

public struct HTMLTemplate {
    public static func page(body: String, theme: PreviewTheme) -> String {
        let css: String
        switch theme {
        case .light:
            css = ThemeCSS.light
        case .dark:
            css = ThemeCSS.dark
        case .auto:
            css = ThemeCSS.light
        }

        return """
        <!doctype html>
        <html>
        <head>
          <meta charset=\"utf-8\" />
          <meta name=\"viewport\" content=\"width=device-width,initial-scale=1\" />
          <style>\(css)</style>
        </head>
        <body>
          \(body)
        </body>
        </html>
        """
    }
}
