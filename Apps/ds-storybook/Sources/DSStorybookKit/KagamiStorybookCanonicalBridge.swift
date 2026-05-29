// KagamiStorybookCanonicalBridge.swift — DSStorybookKit
// kagami-scope: exempt  — adapter bridge; covered by KagamiStorybookSwiftUI tests in shi-design
//
// Hop D (2026-05-29): U-A bridge — registers shi-design's KagamiStorybookSwiftUI
// body providers (the 8 canonical atoms) into ds-storybook's WidgetPreviewRegistry.
//
// PrimitiveCatalog.swiftUIBodies (from KagamiStorybookSwiftUI) provides native
// SwiftUI body factories keyed by component slug (hstack/vstack/zstack/grid/text/
// button/spacer/section). These shadow the providers registered by
// KatagamiPrimitivePreviewProviders.registerAll() for the 8 canonical slugs
// (prefixed with "katagami.").
//
// Usage: call KagamiStorybookCanonicalBridge.registerAll() in DSStorybookApp.init()
// AFTER KatagamiPrimitivePreviewProviders.registerAll() to override the 8 canonical
// slots with shi-design's authoritative bodies.

import Foundation
import KatagamiCore
import KagamiStorybook
import KagamiStorybookSwiftUI
import SwiftUI

// MARK: - KagamiStorybookCanonicalBridge

/// Bridges KagamiStorybookSwiftUI body providers into WidgetPreviewRegistry.
///
/// KagamiStorybook.PrimitiveCatalog.primitives defines the 8 canonical atoms:
/// hstack, vstack, zstack, grid, text, button, spacer, section.
///
/// KagamiStorybookSwiftUI.PrimitiveCatalog.swiftUIBodies maps each slug to a
/// KagamiStorybookBody factory. This bridge adapts each factory to the
/// WidgetPreviewProvider protocol expected by ds-storybook's browser.
public enum KagamiStorybookCanonicalBridge {

    /// Register all 8 canonical atom body providers into WidgetPreviewRegistry.shared.
    ///
    /// Called in DSStorybookApp.init() after KatagamiPrimitivePreviewProviders.registerAll().
    /// For each canonical slug, the shi-design body overrides the fallback native SwiftUI preview.
    public static func registerAll() {
        let r = WidgetPreviewRegistry.shared
        let bodies = KagamiStorybook.PrimitiveCatalog.swiftUIBodies

        // Map slug → widgetKind (ds-storybook uses "katagami.<slug>" convention).
        for (slug, provider) in bodies {
            let widgetKind = "katagami.\(slug)"
            r.register(
                provider: KagamiBodyAdapter(slug: slug, provider: provider),
                for: widgetKind
            )
        }
    }
}

// MARK: - KagamiBodyAdapter

/// Adapts an AnyStorybookBodyProvider to WidgetPreviewProvider.
///
/// ds-storybook's WidgetPreviewProvider receives a CatalogEntry (ds-storybook's
/// JSON-decoded model). KagamiStorybookBody requires a ComponentEntry (shi-design's
/// canonical model). This adapter creates a minimal ComponentEntry from the
/// CatalogEntry's widgetKind/displayName to drive the body factory.
private struct KagamiBodyAdapter: WidgetPreviewProvider, @unchecked Sendable {
    let slug: String
    let provider: AnyStorybookBodyProvider

    @MainActor
    func previewView(for entry: CatalogEntry) -> AnyView {
        // Build a minimal ComponentEntry from the ds-storybook CatalogEntry.
        let componentEntry = ComponentEntry(
            slug: slug,
            title: entry.displayName,
            tier: .atom,
            previewHTML: "",
            code: entry.codeSnippet ?? "",
            props: [],
            usedIn: []
        )
        return provider.body(for: componentEntry, theme: ThemeTokens())
    }
}
