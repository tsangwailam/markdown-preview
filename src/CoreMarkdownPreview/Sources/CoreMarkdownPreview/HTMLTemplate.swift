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
          function normalizeLanguage(language) {
            if (!language) { return null; }
            const value = language.toLowerCase();
            if (value === "py") { return "python"; }
            if (value === "yml") { return "yaml"; }
            if (value === "js") { return "javascript"; }
            if (value === "ts") { return "typescript"; }
            return value;
          }

          function languageFromCodeElement(code) {
            if (!code) { return null; }
            const classes = Array.from(code.classList || []);
            for (const cls of classes) {
              if (cls.startsWith("language-")) {
                return normalizeLanguage(cls.slice("language-".length));
              }
            }
            const language = (code.getAttribute("data-language") || "").toLowerCase() || null;
            return normalizeLanguage(language);
          }

          function configForLanguage(language) {
            if (!language) { return null; }
            if (language === "json" || language === "jsonc" || language === "json5") {
              return { parser: "json", pluginNames: ["babel", "estree"] };
            }
            if (language === "yaml" || language === "yml") {
              return { parser: "yaml", pluginNames: ["yaml"] };
            }
            if (language === "javascript" || language === "jsx") {
              return { parser: "babel", pluginNames: ["babel", "estree"] };
            }
            if (language === "typescript" || language === "tsx") {
              return { parser: "babel-ts", pluginNames: ["babel", "estree"] };
            }
            if (language === "html" || language === "xml" || language === "svg" || language === "xhtml") {
              return { parser: "html", pluginNames: ["html"] };
            }
            if (language === "sql") {
              return { parser: "sql", pluginNames: ["sql", "prettier-plugin-sql"] };
            }
            return null;
          }

          function ensureCodeToolbar(code) {
            const pre = code && code.parentElement;
            if (!pre || pre.tagName !== "PRE") { return null; }

            const parent = pre.parentElement;
            if (!parent) { return null; }

            if (parent.classList && parent.classList.contains("code-block")) {
              return parent.querySelector(".code-toggle");
            }

            const wrapper = document.createElement("div");
            wrapper.className = "code-block";
            parent.insertBefore(wrapper, pre);

            const toolbar = document.createElement("div");
            toolbar.className = "code-toolbar";
            const button = document.createElement("button");
            button.type = "button";
            button.className = "code-toggle";
            toolbar.appendChild(button);

            wrapper.appendChild(toolbar);
            wrapper.appendChild(pre);
            return button;
          }

          function setCodeView(code, button, view) {
            const source = code.getAttribute("data-source") || "";
            const formatted = code.getAttribute("data-formatted") || source;
            const hasFormatted = formatted !== source;
            const nextView = hasFormatted ? view : "source";
            const text = nextView === "source" ? source : formatted;

            code.textContent = text;
            code.setAttribute("data-view", nextView);

            if (button) {
              button.disabled = !hasFormatted;
              button.textContent = nextView === "source" ? "Show Formatted" : "Show Source";
            }
          }

          function highlightCode(code, language) {
            if (typeof window.hljs === "undefined") { return; }
            const source = code.textContent || "";
            const mappedLanguage = language === "xml" ? "xml" : language;
            try {
              if (mappedLanguage) {
                const result = window.hljs.highlight(source, {
                  language: mappedLanguage,
                  ignoreIllegals: true
                });
                if (result && typeof result.value === "string") {
                  code.classList.add("hljs");
                  code.innerHTML = result.value;
                  return;
                }
              }
            } catch (_) {
            }
            if (language) {
              code.classList.add("language-" + language);
            }
            code.removeAttribute("data-highlighted");
            try {
              window.hljs.highlightElement(code);
            } catch (_) {
            }
          }

          async function formatCodeFences() {
            const canFormat = typeof window.prettier !== "undefined" &&
              typeof window.prettier.format === "function";
            const pluginRegistry = window.prettierPlugins || {};
            const codeBlocks = Array.from(document.querySelectorAll("pre code"));

            for (const code of codeBlocks) {
              const language = languageFromCodeElement(code);
              const config = configForLanguage(language);
              const source = code.textContent || "";
              let formatted = source;

              if (canFormat && config) {
                const plugins = config.pluginNames
                  .map(function (name) { return pluginRegistry[name]; })
                  .filter(Boolean);

                if (plugins.length > 0) {
                  try {
                    formatted = await window.prettier.format(source, {
                      parser: config.parser,
                      plugins: plugins,
                      tabWidth: 2,
                      useTabs: false
                    });
                    if (typeof formatted === "string" && formatted.length > 0) {
                      formatted = formatted.replace(/\\n$/, "");
                    } else {
                      formatted = source;
                    }
                  } catch (_) {
                    formatted = source;
                  }
                }
              }

              code.setAttribute("data-source", source);
              code.setAttribute("data-formatted", formatted);

              const button = ensureCodeToolbar(code);
              const initialView = formatted === source ? "source" : "formatted";
              setCodeView(code, button, initialView);
              highlightCode(code, language);

              if (button) {
                button.addEventListener("click", function () {
                  const current = code.getAttribute("data-view") || "source";
                  const next = current === "source" ? "formatted" : "source";
                  setCodeView(code, button, next);
                  highlightCode(code, language);
                });
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
          <script src=\"highlight.min.js\"></script>
          <script src=\"standalone.js\"></script>
          <script src=\"parser-babel.js\"></script>
          <script src=\"parser-estree.js\"></script>
          <script src=\"parser-html.js\"></script>
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
