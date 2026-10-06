// LaTeXView.swift
import SwiftUI
import WebKit

// MARK: - Smart renderer: LaTeXView routes through WebKit only when math/HTML is present.

struct LaTeXView: View {
    let text: String
    let fontSize: Int
    @State private var height: CGFloat = 44

    init(_ text: String, fontSize: Int = 17) {
        self.text = text
        self.fontSize = fontSize
    }

    /// True when the string contains characters that need KaTeX or HTML rendering.
    private static func needsWebView(_ s: String) -> Bool {
        s.contains("$")
        || s.contains("<")
        || s.range(of: #"\\[a-zA-Z(\[]|\^\{"#, options: .regularExpression) != nil
    }

    var body: some View {
        if Self.needsWebView(text) {
            DynamicHTMLView(html: text, fontSize: fontSize, height: $height)
                .frame(height: height)
        } else {
            Text(text)
                .font(.system(size: CGFloat(fontSize)))
                .fixedSize(horizontal: false, vertical: true)
        }
    }
}

// MARK: - WebView that self-sizes and renders KaTeX math

struct DynamicHTMLView: UIViewRepresentable {
    let html: String
    let fontSize: Int
    @Binding var height: CGFloat

    func makeCoordinator() -> Coordinator { Coordinator(self) }

    func makeUIView(context: Context) -> WKWebView {
        let config = WKWebViewConfiguration()
        let wv = WKWebView(frame: .zero, configuration: config)
        wv.scrollView.isScrollEnabled = false
        wv.isOpaque = false
        wv.backgroundColor = .clear
        wv.scrollView.backgroundColor = .clear
        wv.navigationDelegate = context.coordinator
        return wv
    }

    func updateUIView(_ wv: WKWebView, context: Context) {
        let isDark = UITraitCollection.current.userInterfaceStyle == .dark
        let hasKatex = Bundle.main.path(forResource: "katex.min", ofType: "js") != nil
        let hasLatex = html.contains("$")
            || html.range(of: #"\\[a-zA-Z(\[]|\^\{"#, options: .regularExpression) != nil

        // --- KaTeX head resources ---
        let katexHead = hasLatex && hasKatex ? """
            <link rel='stylesheet' href='katex.min.css'>
            <script src='katex.min.js'></script>
            <script src='katex-auto-render.min.js'></script>
            """ : ""

        // --- KaTeX auto-render: readyState-aware, throwOnError:false so bad LaTeX
        //     degrades gracefully instead of showing raw $...$  ---
        let autoRender = hasLatex && hasKatex ? """
            <script>
            (function() {
                function doRender() {
                    if (typeof renderMathInElement === 'function') {
                        renderMathInElement(document.body, {
                            delimiters: [
                                {left: '$$', right: '$$', display: true},
                                {left: '$',  right: '$',  display: false},
                                {left: '\\\\(', right: '\\\\)', display: false},
                                {left: '\\\\[', right: '\\\\]', display: true}
                            ],
                            throwOnError: false,
                            strict: false,
                            trust: false
                        });
                    }
                }
                if (document.readyState === 'loading') {
                    document.addEventListener('DOMContentLoaded', doRender);
                } else {
                    doRender();
                }
            })();
            </script>
            """ : ""

        let wrapped = """
        <html><head>
        <meta name='viewport' content='width=device-width,initial-scale=1,maximum-scale=1'>
        \(katexHead)
        <style>
          body { font-family: -apple-system, sans-serif; font-size: \(fontSize)px;
                 color: \(isDark ? "#fff" : "#000"); background: transparent;
                 margin: 0; padding: 0; word-wrap: break-word; }
          p { margin: 4px 0; }
          figure { margin: 0; }
          table { border-collapse: collapse; width: 100%; margin: 8px 0; }
          th, td { border: 1px solid \(isDark ? "#555" : "#ccc"); padding: 6px 12px;
                   text-align: center; color: \(isDark ? "#fff" : "#000"); }
          th { background: \(isDark ? "#2a2a2a" : "#f0f0f0"); font-weight: 600; }
          a { color: inherit; text-decoration: none; }
          /* Ensure KaTeX renders inline and doesn't overflow */
          .katex { font-size: 1.05em !important; }
          .katex-display { overflow-x: auto; }
        </style></head>
        <body>\(html)\(autoRender)</body></html>
        """

        wv.loadHTMLString(wrapped, baseURL: Bundle.main.bundleURL)
    }

    // MARK: - Coordinator: retries height measurement so KaTeX has time to render

    final class Coordinator: NSObject, WKNavigationDelegate {
        var parent: DynamicHTMLView
        init(_ parent: DynamicHTMLView) { self.parent = parent }

        func webView(_ wv: WKWebView, didFinish navigation: WKNavigation!) {
            measureHeight(wv, triesLeft: 4, delay: 0.05)
        }

        /// Polls document.body.scrollHeight up to `triesLeft` times with exponential back-off.
        /// This gives KaTeX enough time to finish rendering before we snapshot the height.
        private func measureHeight(_ wv: WKWebView, triesLeft: Int, delay: TimeInterval) {
            DispatchQueue.main.asyncAfter(deadline: .now() + delay) { [weak self, weak wv] in
                guard let self, let wv else { return }
                wv.evaluateJavaScript("document.body.scrollHeight") { result, _ in
                    if let h = result as? CGFloat, h > 8 {
                        self.parent.height = h
                    }
                    if triesLeft > 1 {
                        self.measureHeight(wv, triesLeft: triesLeft - 1, delay: delay * 2)
                    }
                }
            }
        }
    }
}

// MARK: - String helpers

extension String {

    // -------------------------------------------------------------------------
    // lightClean: normalises LaTeX delimiters and decodes HTML entities but
    // KEEPS $...$ tokens so KaTeX can render them.  Use this for question text
    // and explanations that should be rendered via LaTeXView / KaTeX.
    // -------------------------------------------------------------------------
    var lightClean: String {
        var s = self
        // Decode common HTML entities
        s = s.replacingOccurrences(of: "&nbsp;",  with: " ")
             .replacingOccurrences(of: "&amp;",   with: "&")
             .replacingOccurrences(of: "&lt;",    with: "<")
             .replacingOccurrences(of: "&gt;",    with: ">")
             .replacingOccurrences(of: "&#39;",   with: "'")
             .replacingOccurrences(of: "&rsquo;", with: "\u{2019}")
             .replacingOccurrences(of: "&lsquo;", with: "\u{2018}")
             .replacingOccurrences(of: "&rdquo;", with: "\u{201D}")
             .replacingOccurrences(of: "&ldquo;", with: "\u{201C}")
        // Normalise \(...\) and \[...\] → $...$ so KaTeX auto-render sees them
        s = s.replacingOccurrences(of: "\\(", with: "$")
             .replacingOccurrences(of: "\\)", with: "$")
        s = s.replacingOccurrences(of: "\\[", with: "$$")
             .replacingOccurrences(of: "\\]", with: "$$")
        // Collapse runs of whitespace (but not newlines inside math)
        s = s.replacingOccurrences(of: "[ \t]{2,}", with: " ", options: .regularExpression)
        return s.trimmingCharacters(in: .whitespacesAndNewlines)
    }

    // -------------------------------------------------------------------------
    // strippingLatex: converts LaTeX to readable Unicode plain-text.
    // Use ONLY for short option text or anywhere a native Text() view is used.
    // -------------------------------------------------------------------------
    var strippingLatex: String {
        var s = self
        s = s.replacingOccurrences(of: "\\(", with: "").replacingOccurrences(of: "\\)", with: "")
        s = s.replacingOccurrences(of: "\\[", with: "").replacingOccurrences(of: "\\]", with: "")
        s = s.replacingOccurrences(of: "$", with: "")
        s = s.replacingOccurrences(of: "\\*\\*([^*]+)\\*\\*", with: "$1", options: .regularExpression)
        s = s.replacingOccurrences(of: "\\*([^*]+)\\*",   with: "$1", options: .regularExpression)
        // Flatten exponent braces: x^{12} -> x^12
        s = s.replacingOccurrences(of: "\\^\\{([^}]+)\\}", with: "^$1", options: .regularExpression)
        // Convert \frac{a}{b} -> (a/b)
        if let re = try? NSRegularExpression(pattern: "\\\\frac\\{([^}]*)\\}\\{([^}]*)\\}") {
            s = re.stringByReplacingMatches(in: s, range: NSRange(s.startIndex..., in: s), withTemplate: "($1/$2)")
        }
        let subs: [(String, String)] = [
            ("\\times","×"),("\\div","÷"),("\\geq","≥"),("\\leq","≤"),("\\neq","≠"),("\\ne","≠"),
            ("\\ge","≥"),("\\le","≤"),("\\pm","±"),("\\cdot","·"),("\\pi","π"),("\\infty","∞"),
            ("\\alpha","α"),("\\beta","β"),("\\theta","θ"),("\\angle","∠"),("\\triangle","△"),
            ("\\approx","≈"),("\\circ","°"),("\\sqrt","√"),("\\frac",""),
            ("\\left",""),("\\right",""),("\\overline",""),("\\hline",""),
            ("\\begin{",""),("\\end{",""),("\\text{",""),("{",""),("\\log","log"),
        ]
        for (from, to) in subs { s = s.replacingOccurrences(of: from, with: to) }
        s = s.replacingOccurrences(of: "\\\\[a-zA-Z]+", with: "", options: .regularExpression)
        s = s.replacingOccurrences(of: "\\\\(\\d)", with: "$1", options: .regularExpression)
        s = s.replacingOccurrences(of: "}", with: "")
        // Convert ^n to superscript Unicode
        let supMap: [Character: String] = [
            "0":"⁰","1":"¹","2":"²","3":"³","4":"⁴","5":"⁵","6":"⁶","7":"⁷","8":"⁸","9":"⁹",
            "n":"ⁿ","x":"ˣ","t":"ᵗ","a":"ᵃ","b":"ᵇ","i":"ⁱ","(":"⁽",")":"⁾"
        ]
        if let re = try? NSRegularExpression(pattern: #"\^(\([\w\s+\-*/]+\)|[\w]+)"#) {
            let matches = re.matches(in: s, range: NSRange(s.startIndex..., in: s))
            for m in matches.reversed() {
                guard let r = Range(m.range, in: s), let gr = Range(m.range(at: 1), in: s) else { continue }
                let exp = String(s[gr])
                let sup = exp.compactMap { (c: Character) -> String? in
                    supMap[c] ?? (c == "+" ? "⁺" : c == "-" ? "⁻" : c == "/" ? "/" : nil)
                }
                if sup.count == exp.count { s.replaceSubrange(r, with: sup.joined()) }
            }
        }
        s = s.replacingOccurrences(of: " +", with: " ", options: .regularExpression)
        return s.trimmingCharacters(in: .whitespaces)
    }

    var strippingHTML: String {
        var s = self
        if let re = try? NSRegularExpression(pattern: "<(style|script)[^>]*>.*?</(style|script)>",
                                              options: [.caseInsensitive, .dotMatchesLineSeparators]) {
            s = re.stringByReplacingMatches(in: s, range: NSRange(s.startIndex..., in: s), withTemplate: "")
        }
        if let re = try? NSRegularExpression(pattern: "<math[^>]*alttext=\"([^\"]*)\"[^>]*>.*?</math>",
                                              options: [.caseInsensitive, .dotMatchesLineSeparators]) {
            let matches = re.matches(in: s, range: NSRange(s.startIndex..., in: s))
            for m in matches.reversed() {
                guard let r = Range(m.range, in: s), let ar = Range(m.range(at: 1), in: s) else { continue }
                s.replaceSubrange(r, with: cleanAlttext(String(s[ar])))
            }
        }
        s = s.replacingOccurrences(of: "<[^>]*>", with: "", options: .regularExpression)
        s = s.replacingOccurrences(of: "&nbsp;",  with: " ")
            .replacingOccurrences(of: "&amp;",    with: "&")
            .replacingOccurrences(of: "&lt;",     with: "<")
            .replacingOccurrences(of: "&gt;",     with: ">")
            .replacingOccurrences(of: "&rsquo;",  with: "'")
            .replacingOccurrences(of: "&#[^;]+;", with: "", options: .regularExpression)
        return s.replacingOccurrences(of: " +", with: " ", options: .regularExpression)
            .trimmingCharacters(in: .whitespacesAndNewlines)
    }

    private func cleanAlttext(_ s: String) -> String {
        var t = s
        let subs: [(String, String)] = [
            ("StartFraction ", ""), (" EndFraction", ""), (" Over ", "/"),
            ("StartRoot ", "√("), (" EndRoot", ")"),
            ("left parenthesis", "("), ("right parenthesis", ")"),
            ("left bracket", "["), ("right bracket", "]"),
            (" comma ", ", "),
            (" Superscript ", "^"), (" Baseline", ""),
            (" squared", "²"), (" cubed", "³"),
            ("negative ", "-"),
            (" equals ", " = "), (" plus ", " + "), (" minus ", " - "),
            (" times ", " × "), (" divided by ", " / "),
            (" greater than or equal to ", " ≥ "), (" less than or equal to ", " ≤ "),
            (" greater than ", " > "), (" less than ", " < "),
            ("upper ", ""), ("lower ", ""),
        ]
        for (from, to) in subs { t = t.replacingOccurrences(of: from, with: to) }
        return t.replacingOccurrences(of: " +", with: " ", options: .regularExpression)
            .trimmingCharacters(in: .whitespaces)
    }
}
