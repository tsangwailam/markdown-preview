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

        let formatterScript = """
        <script>
        (function () {
          function languageFromCodeElement(code) {
            if (!code) { return null; }
            const classes = Array.from(code.classList || []);
            for (const cls of classes) {
              if (cls.startsWith("language-")) {
                return cls.slice("language-".length).toLowerCase();
              }
            }
            return (code.getAttribute("data-language") || "").toLowerCase() || null;
          }

          function configForLanguage(language) {
            if (!language) { return null; }
            if (language === "json" || language === "jsonc" || language === "json5") {
              return { parser: "json", pluginNames: ["babel", "estree"] };
            }
            if (language === "yaml" || language === "yml") {
              return { parser: "yaml", pluginNames: ["yaml"] };
            }
            if (language === "sql") {
              return { parser: "sql", pluginNames: ["sql", "prettier-plugin-sql"] };
            }
            return null;
          }

          async function formatCodeFences() {
            if (typeof window.prettier === "undefined") { return; }
            if (typeof window.prettier.format !== "function") { return; }
            const pluginRegistry = window.prettierPlugins || {};
            const codeBlocks = Array.from(document.querySelectorAll("pre code"));

            for (const code of codeBlocks) {
              const language = languageFromCodeElement(code);
              const config = configForLanguage(language);
              if (!config) { continue; }

              const plugins = config.pluginNames
                .map(function (name) { return pluginRegistry[name]; })
                .filter(Boolean);

              if (plugins.length === 0) { continue; }

              try {
                const source = code.textContent || "";
                const formatted = await window.prettier.format(source, {
                  parser: config.parser,
                  plugins: plugins,
                  tabWidth: 2,
                  useTabs: false
                });
                if (typeof formatted === "string" && formatted.length > 0) {
                  code.textContent = formatted.replace(/\\n$/, "");
                }
              } catch (_) {
              }
            }
          }

          if (document.readyState === "loading") {
            document.addEventListener("DOMContentLoaded", function () { void formatCodeFences(); });
          } else {
            void formatCodeFences();
          }
        })();
        </script>
        """

        return """
        <!doctype html>
        <html>
        <head>
          <meta charset=\"utf-8\" />
          <meta name=\"viewport\" content=\"width=device-width,initial-scale=1\" />
          <style>\(css)</style>
          <script src=\"standalone.js\"></script>
          <script src=\"parser-babel.js\"></script>
          <script src=\"parser-estree.js\"></script>
          <script src=\"parser-yaml.js\"></script>
          \(formatterScript)
        </head>
        <body>
          \(body)
        </body>
        </html>
        """
    }
}
