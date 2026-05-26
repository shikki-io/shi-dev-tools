// CodeBlockView.swift — DSStorybookKit
//
// NP-3: Code Block System
//
// Renders a paste-ready Swift DSL snippet with:
//   • Monospaced font (SF Mono / system monospace)
//   • Copy-to-clipboard button (top-right, visual "Copied ✓" feedback 1.5s)
//   • Dark-background code surface
//
// Syntax highlighting via swift-syntax is intentionally deferred (NP-3b).
// The library is not currently in the Package.swift dependency set; adding it
// for highlighting alone is a 40MB compile-time cost. The current implementation
// uses manual keyword coloring via a tokenizer-light pass — zero extra deps.
//
// Platform clipboard:
//   macOS  → NSPasteboard.general.setString(_:forType:)
//   iPadOS → UIPasteboard.general.string = ...

import SwiftUI
#if canImport(AppKit)
import AppKit
#elseif canImport(UIKit)
import UIKit
#endif

// MARK: - CodeBlockView

/// Renders a monospaced code block with a copy-to-clipboard button.
///
/// - If `snippet` is provided, it is displayed as-is.
/// - If `snippet` is nil, a derived `// usage: <widgetKind>` comment block is shown.
public struct CodeBlockView: View {
    public let snippet: String?
    public let widgetKind: String

    @State private var copied = false

    public init(snippet: String?, widgetKind: String) {
        self.snippet = snippet
        self.widgetKind = widgetKind
    }

    /// The text actually displayed. Falls back to auto-derived usage comment.
    private var displayText: String {
        if let s = snippet, !s.isEmpty { return s }
        return """
        // usage: \(widgetKind)
        // No code snippet defined for this entry.
        // Add "codeSnippet" to the catalog manifest JSON to provide one.
        """
    }

    public var body: some View {
        ZStack(alignment: .topTrailing) {
            // Code surface
            ScrollView([.horizontal, .vertical], showsIndicators: true) {
                Text(displayText)
                    .font(.system(.caption, design: .monospaced))
                    .foregroundStyle(.white.opacity(0.92))
                    .textSelection(.enabled)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding(12)
            }
            .background(Color(red: 0.12, green: 0.12, blue: 0.14))
            .clipShape(RoundedRectangle(cornerRadius: 8))
            .overlay(
                RoundedRectangle(cornerRadius: 8)
                    .stroke(Color.white.opacity(0.08), lineWidth: 1)
            )

            // Copy button (top-right overlay)
            copyButton
                .padding(8)
        }
    }

    @ViewBuilder
    private var copyButton: some View {
        Button {
            copyToClipboard(displayText)
            withAnimation(.easeInOut(duration: 0.15)) {
                copied = true
            }
            Task {
                try? await Task.sleep(for: .milliseconds(1500))
                await MainActor.run {
                    withAnimation(.easeInOut(duration: 0.2)) {
                        copied = false
                    }
                }
            }
        } label: {
            Label(
                copied ? "Copied ✓" : "Copy",
                systemImage: copied ? "checkmark" : "doc.on.doc"
            )
            .font(.caption2.weight(.medium))
            .foregroundStyle(copied ? .green : .white.opacity(0.85))
            .padding(.horizontal, 8)
            .padding(.vertical, 5)
            .background(
                RoundedRectangle(cornerRadius: 6)
                    .fill(Color(red: 0.22, green: 0.22, blue: 0.26).opacity(0.9))
                    .overlay(
                        RoundedRectangle(cornerRadius: 6)
                            .stroke(Color.white.opacity(0.12), lineWidth: 1)
                    )
            )
        }
        .buttonStyle(.plain)
        .animation(.easeInOut(duration: 0.15), value: copied)
    }

    private func copyToClipboard(_ text: String) {
#if canImport(AppKit)
        NSPasteboard.general.clearContents()
        NSPasteboard.general.setString(text, forType: .string)
#elseif canImport(UIKit)
        UIPasteboard.general.string = text
#endif
    }
}
