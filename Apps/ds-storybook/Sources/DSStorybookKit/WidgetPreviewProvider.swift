// WidgetPreviewProvider.swift — DSStorybookKit
//
// Protocol + registry: widget packages (e.g. SMWidgets) register a
// WidgetPreviewProvider implementation against a widgetKind string.
// The browser calls previewView(for:) to get a SwiftUI AnyView.
//
// Q-DSA-03 resolution: ds-storybook does NOT import SMWidgets or
// KatagamiSwiftUI directly in the browse view. Instead, SMWidgets
// registers a provider at app start, and the browser calls it.
// This keeps ds-storybook decoupled from any specific widget package.

import SwiftUI

// MARK: - WidgetPreviewProvider

/// A type that can produce a SwiftUI preview for a widget catalog entry.
///
/// Widget packages register concrete implementations for their `widgetKind`
/// values via `WidgetPreviewRegistry.shared.register(provider:for:)`.
public protocol WidgetPreviewProvider: Sendable {
    /// Return a SwiftUI view that previews the widget for the given entry.
    /// - Parameter entry: The catalog entry describing the widget.
    /// - Returns: A native SwiftUI view rendered from the Katagami DSL.
    @MainActor func previewView(for entry: CatalogEntry) -> AnyView
}

// MARK: - WidgetPreviewRegistry

/// Central registry for WidgetPreviewProvider implementations.
///
/// Widget packages call `register(provider:for:)` at app startup (e.g.
/// in the @main App's `init()`) before the browse view renders.
public final class WidgetPreviewRegistry: @unchecked Sendable {
    public static let shared = WidgetPreviewRegistry()

    private var providers: [String: any WidgetPreviewProvider] = [:]

    private init() {}

    /// Register a provider for a widgetKind string.
    public func register(provider: some WidgetPreviewProvider, for widgetKind: String) {
        providers[widgetKind] = provider
    }

    /// Retrieve the registered provider for a widgetKind, or nil if none.
    public func provider(for widgetKind: String) -> (any WidgetPreviewProvider)? {
        providers[widgetKind]
    }

    /// Whether a provider is registered for the given widgetKind.
    public func hasProvider(for widgetKind: String) -> Bool {
        providers[widgetKind] != nil
    }

    /// All registered widgetKind strings.
    public var registeredKinds: [String] { Array(providers.keys.sorted()) }

    /// Remove all registered providers. Use in test teardown to prevent cross-test contamination.
    public func reset() {
        providers.removeAll()
    }
}

// MARK: - FallbackPreviewProvider

/// Used when no provider is registered for a widgetKind.
/// Renders a placeholder card with entry metadata.
struct FallbackPreviewProvider: WidgetPreviewProvider {
    @MainActor func previewView(for entry: CatalogEntry) -> AnyView {
        AnyView(FallbackPreviewView(entry: entry))
    }
}

@MainActor
struct FallbackPreviewView: View {
    let entry: CatalogEntry

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text(entry.displayName)
                .font(.headline)

            Text(entry.description)
                .font(.body)
                .foregroundStyle(.secondary)

            Divider()

            Text("Primitives")
                .font(.caption.bold())
                .foregroundStyle(.secondary)

            FlowLayout(spacing: 4) {
                ForEach(entry.primitiveList, id: \.self) { primitive in
                    Text(primitive)
                        .font(.caption2)
                        .padding(.horizontal, 6)
                        .padding(.vertical, 2)
                        .background(.tint.opacity(0.15), in: RoundedRectangle(cornerRadius: 4))
                }
            }

            Divider()

            HStack {
                Label("Wave \(entry.wave)", systemImage: "wave.3.right")
                Spacer()
                Text(entry.ssimStatus)
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
            .font(.caption)

            Text("No preview registered for widgetKind: \(entry.widgetKind)")
                .font(.caption)
                .foregroundStyle(.orange)
                .padding(.top, 4)
        }
        .padding()
        .background(.background)
    }
}

// MARK: - FlowLayout (simple tag-cloud layout)

/// Minimal flow layout for primitive tags. Wraps items left-to-right.
struct FlowLayout: Layout {
    let spacing: CGFloat

    func sizeThatFits(proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) -> CGSize {
        let maxWidth = proposal.width ?? .infinity
        var x: CGFloat = 0
        var y: CGFloat = 0
        var rowHeight: CGFloat = 0

        for subview in subviews {
            let size = subview.sizeThatFits(.unspecified)
            if x + size.width > maxWidth && x > 0 {
                y += rowHeight + spacing
                x = 0
                rowHeight = 0
            }
            x += size.width + spacing
            rowHeight = max(rowHeight, size.height)
        }

        return CGSize(width: maxWidth, height: y + rowHeight)
    }

    func placeSubviews(in bounds: CGRect, proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) {
        var x: CGFloat = bounds.minX
        var y: CGFloat = bounds.minY
        var rowHeight: CGFloat = 0

        for subview in subviews {
            let size = subview.sizeThatFits(.unspecified)
            if x + size.width > bounds.maxX && x > bounds.minX {
                y += rowHeight + spacing
                x = bounds.minX
                rowHeight = 0
            }
            subview.place(at: CGPoint(x: x, y: y), proposal: ProposedViewSize(size))
            x += size.width + spacing
            rowHeight = max(rowHeight, size.height)
        }
    }
}
