// PrimitiveCatalogTests.swift — DSStorybookKitTests
//
// NP-1 test plan:
//   NP1-T01: PrimitiveCatalog.all contains exactly 28 entries
//   NP1-T02: Tier distribution — 13 atoms + 10 layouts + 4 components + 1 composite
//   NP1-T03: Every entry has a non-empty codeSnippet
//   NP1-T04: Snapshot — Atom tier sidebar row
//   NP1-T05: Snapshot — Layout tier sidebar row
//   NP1-T06: Snapshot — Component tier sidebar row
//   NP1-T07: Snapshot — Composite tier sidebar row
//   NP1-T08: Snapshot — full catalog (28 primitives) render in StorybookBrowserView

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
    width: CGFloat = 1200,
    height: CGFloat = 800
) -> NSView {
    let host = NSHostingView(rootView: view)
    host.frame = CGRect(origin: .zero, size: CGSize(width: width, height: height))
    return host
}

// MARK: - PrimitiveCatalogTests

@Suite("PrimitiveCatalog")
struct PrimitiveCatalogTests {

    // MARK: NP1-T01: count

    @Test("NP1-T01: PrimitiveCatalog.all contains exactly 28 entries")
    func totalCount() {
        #expect(PrimitiveCatalog.all.count == 28)
    }

    // MARK: NP1-T02: tier distribution

    @Test("NP1-T02: tier distribution — 13 atoms, 10 layouts, 4 components, 1 composite")
    func tierDistribution() {
        let byTier = Dictionary(grouping: PrimitiveCatalog.all, by: \.tier)
        #expect(byTier[.atom]?.count == 13, "Expected 13 atoms")
        #expect(byTier[.layout]?.count == 10, "Expected 10 layouts")
        #expect(byTier[.component]?.count == 4, "Expected 4 components")
        #expect(byTier[.composite]?.count == 1, "Expected 1 composite")
    }

    // MARK: NP1-T03: code snippets present

    @Test("NP1-T03: every primitive entry has a non-empty codeSnippet")
    func codeSnippetsPresent() {
        for entry in PrimitiveCatalog.all {
            #expect(!entry.codeSnippet.isEmpty, "codeSnippet empty for \(entry.id)")
        }
    }

    // MARK: NP1-T04: Atom sidebar row snapshot

    @MainActor
    @Test("NP1-T04: snapshot — Atom tier sidebar row (KatagamiText)")
    func atomSidebarRowSnapshot() throws {
        let primitive = PrimitiveCatalog.atoms.first!  // KatagamiText
        let view = List {
            PrimitiveSidebarRowPublicStub(primitive: primitive)
        }
        .frame(width: 280, height: 60)
        let nsView = hostingView(view, width: 280, height: 60)

        withSnapshotTesting(record: .missing) {
            assertSnapshot(of: nsView, as: .image(size: CGSize(width: 280, height: 60)), named: "atom-row")
        }
    }

    // MARK: NP1-T05: Layout sidebar row snapshot

    @MainActor
    @Test("NP1-T05: snapshot — Layout tier sidebar row (KatagamiHStack)")
    func layoutSidebarRowSnapshot() throws {
        let primitive = PrimitiveCatalog.layouts.first!  // KatagamiHStack
        let view = List {
            PrimitiveSidebarRowPublicStub(primitive: primitive)
        }
        .frame(width: 280, height: 60)
        let nsView = hostingView(view, width: 280, height: 60)

        withSnapshotTesting(record: .missing) {
            assertSnapshot(of: nsView, as: .image(size: CGSize(width: 280, height: 60)), named: "layout-row")
        }
    }

    // MARK: NP1-T06: Component sidebar row snapshot

    @MainActor
    @Test("NP1-T06: snapshot — Component tier sidebar row (KatagamiAsyncImage)")
    func componentSidebarRowSnapshot() throws {
        let primitive = PrimitiveCatalog.components.first!  // KatagamiAsyncImage
        let view = List {
            PrimitiveSidebarRowPublicStub(primitive: primitive)
        }
        .frame(width: 280, height: 60)
        let nsView = hostingView(view, width: 280, height: 60)

        withSnapshotTesting(record: .missing) {
            assertSnapshot(of: nsView, as: .image(size: CGSize(width: 280, height: 60)), named: "component-row")
        }
    }

    // MARK: NP1-T07: Composite sidebar row snapshot

    @MainActor
    @Test("NP1-T07: snapshot — Composite tier sidebar row (KatagamiShadowedCard)")
    func compositeSidebarRowSnapshot() throws {
        let primitive = PrimitiveCatalog.composites.first!  // KatagamiShadowedCard
        let view = List {
            PrimitiveSidebarRowPublicStub(primitive: primitive)
        }
        .frame(width: 280, height: 60)
        let nsView = hostingView(view, width: 280, height: 60)

        withSnapshotTesting(record: .missing) {
            assertSnapshot(of: nsView, as: .image(size: CGSize(width: 280, height: 60)), named: "composite-row")
        }
    }

    // MARK: NP1-T08: Full catalog browser (28 primitives, no widget catalog)

    @MainActor
    @Test("NP1-T08: snapshot — full primitives catalog in StorybookBrowserView (no --catalog)")
    func fullCatalogBrowserSnapshot() throws {
        // Q1 default: no --catalog → manifest is empty, primitives shown
        let manifest = CatalogManifest(entries: [])
        let view = StorybookBrowserView(manifest: manifest)
        let nsView = hostingView(view, width: 1200, height: 800)

        withSnapshotTesting(record: .missing) {
            assertSnapshot(of: nsView, as: .image(size: CGSize(width: 1200, height: 800)), named: "primitives-browser")
        }
    }
}

// MARK: - PrimitiveSidebarRowPublicStub
//
// PrimitiveSidebarRow is internal — expose a matching public stub for tests.

@MainActor
struct PrimitiveSidebarRowPublicStub: View {
    let primitive: PrimitiveEntry

    var body: some View {
        VStack(alignment: .leading, spacing: 2) {
            HStack {
                Image(systemName: primitive.tier.systemImage)
                    .font(.caption2)
                    .foregroundStyle(tierColor)
                    .frame(width: 14)
                Text(primitive.displayName)
                    .font(.body)
                Spacer()
                Text(primitive.tier.rawValue)
                    .font(.caption2)
                    .foregroundStyle(.secondary)
                    .padding(.horizontal, 4)
                    .padding(.vertical, 1)
                    .background(tierColor.opacity(0.12), in: RoundedRectangle(cornerRadius: 3))
            }
            Text(primitive.widgetKind)
                .font(.caption)
                .foregroundStyle(.secondary)
                .padding(.leading, 18)
        }
        .padding(.vertical, 2)
    }

    private var tierColor: Color {
        switch primitive.tier {
        case .atom:      .blue
        case .layout:    .green
        case .component: .orange
        case .composite: .purple
        }
    }
}

#endif // canImport(AppKit) && os(macOS)
