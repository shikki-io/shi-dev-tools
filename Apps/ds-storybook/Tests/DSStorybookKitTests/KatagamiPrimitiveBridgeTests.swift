// KatagamiPrimitiveBridgeTests.swift — DSStorybookKitTests
//
// NP-4 test plan — 4 representative primitive snapshot tests (1 per tier):
//   NP4-T01: Atom tier — KatagamiText provider renders non-fallback view
//   NP4-T02: Layout tier — KatagamiHStack provider renders non-fallback view
//   NP4-T03: Component tier — KatagamiBadge provider renders non-fallback view
//   NP4-T04: Composite tier — KatagamiShadowedCard provider renders non-fallback view
//
// Each test:
//   (a) Calls KatagamiPrimitivePreviewBridge.registerAll()
//   (b) Resolves the registered provider
//   (c) Asserts the result is not the orange "No preview registered" fallback
//   (d) Takes a snapshot golden

#if canImport(AppKit) && os(macOS)

import AppKit
import SwiftUI
import Testing
import SnapshotTesting
@testable import DSStorybookKit

// MARK: - Helpers

@MainActor
private func hostingView<V: View>(
    _ view: V,
    width: CGFloat = 480,
    height: CGFloat = 200
) -> NSView {
    let host = NSHostingView(rootView: view)
    host.frame = CGRect(origin: .zero, size: CGSize(width: width, height: height))
    return host
}

/// Synthesise a CatalogEntry for a Katagami primitive so providers can run.
private func primitiveEntry(widgetKind: String, displayName: String) -> CatalogEntry {
    CatalogEntry(
        id: displayName,
        widgetKind: widgetKind,
        displayName: displayName,
        description: "\(displayName) canonical Katagami primitive.",
        primitives: widgetKind,
        wave: "0",
        ssimStatus: "primitive"
    )
}

// MARK: - KatagamiPrimitiveBridgeTests

@Suite("KatagamiPrimitiveBridge")
struct KatagamiPrimitiveBridgeTests {

    // MARK: NP4-T01: Atom tier — katagami.text

    @MainActor
    @Test("NP4-T01: snapshot — KatagamiText provider renders non-fallback (Atom tier)")
    func atomTextSnapshot() throws {
        KatagamiPrimitivePreviewBridge.registerAll()
        let registry = WidgetPreviewRegistry.shared
        defer { registry.reset() }

        let provider = try #require(registry.provider(for: "katagami.text"))
        let entry = primitiveEntry(widgetKind: "katagami.text", displayName: "Text")

        let view = provider.previewView(for: entry)
            .padding()
            .frame(width: 480, height: 100)
        let nsView = hostingView(view, width: 480, height: 100)

        withSnapshotTesting(record: .missing) {
            assertSnapshot(of: nsView, as: .image(size: CGSize(width: 480, height: 100)), named: "atom-text")
        }
    }

    // MARK: NP4-T02: Layout tier — katagami.hstack

    @MainActor
    @Test("NP4-T02: snapshot — KatagamiHStack provider renders non-fallback (Layout tier)")
    func layoutHStackSnapshot() throws {
        KatagamiPrimitivePreviewBridge.registerAll()
        let registry = WidgetPreviewRegistry.shared
        defer { registry.reset() }

        let provider = try #require(registry.provider(for: "katagami.hstack"))
        let entry = primitiveEntry(widgetKind: "katagami.hstack", displayName: "HStack")

        let view = provider.previewView(for: entry)
            .padding()
            .frame(width: 480, height: 100)
        let nsView = hostingView(view, width: 480, height: 100)

        withSnapshotTesting(record: .missing) {
            assertSnapshot(of: nsView, as: .image(size: CGSize(width: 480, height: 100)), named: "layout-hstack")
        }
    }

    // MARK: NP4-T03: Component tier — katagami.badge

    @MainActor
    @Test("NP4-T03: snapshot — KatagamiBadge provider renders non-fallback (Component tier)")
    func componentBadgeSnapshot() throws {
        KatagamiPrimitivePreviewBridge.registerAll()
        let registry = WidgetPreviewRegistry.shared
        defer { registry.reset() }

        let provider = try #require(registry.provider(for: "katagami.badge"))
        let entry = primitiveEntry(widgetKind: "katagami.badge", displayName: "Badge")

        let view = provider.previewView(for: entry)
            .padding()
            .frame(width: 480, height: 100)
        let nsView = hostingView(view, width: 480, height: 100)

        withSnapshotTesting(record: .missing) {
            assertSnapshot(of: nsView, as: .image(size: CGSize(width: 480, height: 100)), named: "component-badge")
        }
    }

    // MARK: NP4-T04: Composite tier — katagami.shadowedcard

    @MainActor
    @Test("NP4-T04: snapshot — KatagamiShadowedCard provider renders non-fallback (Composite tier)")
    func compositeShadowedCardSnapshot() throws {
        KatagamiPrimitivePreviewBridge.registerAll()
        let registry = WidgetPreviewRegistry.shared
        defer { registry.reset() }

        let provider = try #require(registry.provider(for: "katagami.shadowedcard"))
        let entry = primitiveEntry(widgetKind: "katagami.shadowedcard", displayName: "ShadowedCard")

        let view = provider.previewView(for: entry)
            .padding()
            .frame(width: 480, height: 160)
        let nsView = hostingView(view, width: 480, height: 160)

        withSnapshotTesting(record: .missing) {
            assertSnapshot(of: nsView, as: .image(size: CGSize(width: 480, height: 160)), named: "composite-shadowedcard")
        }
    }

    // MARK: NP4-T05: Registration completeness — all 28 providers registered

    @Test("NP4-T05: registerAll() registers providers for all 28 katagami.* widgetKinds")
    func allProvidersRegistered() {
        let registry = WidgetPreviewRegistry.shared
        registry.reset()
        KatagamiPrimitivePreviewBridge.registerAll()
        defer { registry.reset() }

        let expected: [String] = [
            // Atoms (13)
            "katagami.text", "katagami.heading", "katagami.paragraph",
            "katagami.emphasis", "katagami.strong", "katagami.code",
            "katagami.image", "katagami.link", "katagami.button",
            "katagami.textfield", "katagami.linebreak", "katagami.inlinegroup",
            "katagami.marquee",
            // Layout (10)
            "katagami.hstack", "katagami.vstack", "katagami.zstack",
            "katagami.grid", "katagami.scrollview", "katagami.spacer",
            "katagami.drawer", "katagami.viewport", "katagami.semantic",
            "katagami.swipecontainer",
            // Components (4)
            "katagami.asyncimage", "katagami.badge",
            "katagami.overlaymarker", "katagami.qrmarker",
            // Composite (1)
            "katagami.shadowedcard",
        ]

        for kind in expected {
            #expect(registry.hasProvider(for: kind), "Missing provider for \(kind)")
        }
        #expect(expected.count == 28)
    }
}

#endif // canImport(AppKit) && os(macOS)
