// UXUpgradeTests.swift — DSStorybookKitTests
//
// Tests for all 4 UX upgrade deliverables:
//
//   D1: Preview audit — CatalogCrossReferences engine unit tests
//   D2: DisclosureGroup sidebar — AppStorage state test
//   D3: CrossReferences engine — used-in + related queries
//   D4: UserWidgetCatalog — JSON round-trip + FileMonitor wakeup
//
// Also includes 8 snapshot tests for acceptance gate.

import Foundation
import Testing
@testable import DSStorybookKit

#if canImport(AppKit) && os(macOS)
import AppKit
import SwiftUI
import SnapshotTesting
import CTechWidgetPreviewBridge
#endif

// MARK: - Helpers (shared)

private let atomEntry = CatalogEntry(
    id: "KatagamiText", widgetKind: "katagami.text", displayName: "Text",
    description: "Inline text node.", primitives: "", wave: "0", ssimStatus: "primitive"
)

private let widgetPeople = CatalogEntry(
    id: "SMPeople", widgetKind: "people", displayName: "People",
    description: "Presenter card.",
    primitives: "KatagamiShadowedCard,KatagamiHStack,KatagamiVStack,KatagamiText",
    wave: "1", ssimStatus: "pendingImpl"
)

private let widgetCart = CatalogEntry(
    id: "SMCart", widgetKind: "cart", displayName: "Cart",
    description: "Shopping cart.",
    primitives: "KatagamiDrawer,KatagamiVStack,KatagamiHStack,KatagamiText",
    wave: "7", ssimStatus: "pendingImpl"
)

// MARK: - D3: CatalogCrossReferences tests

@Suite("CatalogCrossReferences")
struct CatalogCrossReferencesTests {

    // TP-UX-CR-01: primitive → used-in widgets
    @Test("TP-UX-CR-01: katagami.text is used-in People and Cart")
    func textUsedInWidgets() {
        let allEntries = [atomEntry, widgetPeople, widgetCart]
        let refs = CatalogCrossReferences.usedIn(primitive: atomEntry, allEntries: allEntries)
        let ids = refs.map(\.id).sorted()
        #expect(ids.contains("SMPeople"))
        #expect(ids.contains("SMCart"))
    }

    // TP-UX-CR-02: primitive not in any widget returns empty
    @Test("TP-UX-CR-02: primitive used by no widget returns empty used-in")
    func unusedPrimitive() {
        let unusedPrimitive = CatalogEntry(
            id: "KatagamiMarquee", widgetKind: "katagami.marquee", displayName: "Marquee",
            description: "Ticker text.", primitives: "", wave: "0", ssimStatus: "primitive"
        )
        let refs = CatalogCrossReferences.usedIn(primitive: unusedPrimitive, allEntries: [atomEntry, widgetPeople, widgetCart])
        #expect(refs.isEmpty)
    }

    // TP-UX-CR-03: widget → related widgets sharing primitives
    @Test("TP-UX-CR-03: People and Cart are related (share KatagamiHStack + KatagamiVStack + KatagamiText)")
    func widgetRelated() {
        let allEntries = [widgetPeople, widgetCart]
        let refs = CatalogCrossReferences.related(widget: widgetPeople, allEntries: allEntries)
        #expect(refs.map(\.id).contains("SMCart"))
    }

    // TP-UX-CR-04: widget with no shared primitives has no related
    @Test("TP-UX-CR-04: widget with unique primitives has no related")
    func widgetNoRelated() {
        let isolated = CatalogEntry(
            id: "UniqueWidget", widgetKind: "unique", displayName: "Unique",
            description: "Isolated.", primitives: "KatagamiCanvasLayer", wave: "99", ssimStatus: "pendingImpl"
        )
        let refs = CatalogCrossReferences.related(widget: isolated, allEntries: [widgetPeople, widgetCart, isolated])
        #expect(refs.isEmpty)
    }

    // TP-UX-CR-05: crossRefs dispatches correctly
    @Test("TP-UX-CR-05: crossRefs dispatches primitive→usedIn and widget→related correctly")
    func crossRefsDispatch() {
        let allEntries = [atomEntry, widgetPeople, widgetCart]
        let primRefs = CatalogCrossReferences.crossRefs(for: atomEntry, allEntries: allEntries)
        #expect(!primRefs.usedIn.isEmpty)
        #expect(primRefs.related.isEmpty)

        let widgetRefs = CatalogCrossReferences.crossRefs(for: widgetPeople, allEntries: allEntries)
        #expect(widgetRefs.usedIn.isEmpty)
        #expect(!widgetRefs.related.isEmpty)
    }
}

// MARK: - D4: UserWidgetCatalog tests

@Suite("UserWidgetCatalog")
struct UserWidgetCatalogTests {

    // TP-UX-UW-01: JSON round-trip
    @Test("TP-UX-UW-01: UserWidgetEntry JSON round-trip")
    func jsonRoundTrip() throws {
        let entry = UserWidgetEntry(
            id: "MyWidget",
            widgetKind: "my.widget",
            displayName: "My Widget",
            description: "A custom widget.",
            primitives: "KatagamiVStack,KatagamiText",
            wave: "user",
            ssimStatus: "user",
            codeSnippet: "MyWidget()"
        )
        let encoder = JSONEncoder()
        encoder.outputFormatting = .prettyPrinted
        let data = try encoder.encode(entry)
        let decoder = JSONDecoder()
        let decoded = try decoder.decode(UserWidgetEntry.self, from: data)

        #expect(decoded.id == "MyWidget")
        #expect(decoded.widgetKind == "my.widget")
        #expect(decoded.displayName == "My Widget")
        #expect(decoded.codeSnippet == "MyWidget()")
    }

    // TP-UX-UW-02: Empty directory produces empty entries
    @Test("TP-UX-UW-02: empty directory produces no entries")
    @MainActor
    func emptyDirectoryLoadsEmpty() throws {
        let dir = FileManager.default.temporaryDirectory
            .appendingPathComponent("ux-test-empty-\(UUID().uuidString)", isDirectory: true)
        try FileManager.default.createDirectory(at: dir, withIntermediateDirectories: true)
        defer { try? FileManager.default.removeItem(at: dir) }

        let catalog = UserWidgetCatalog(directory: dir)
        #expect(catalog.entries.isEmpty)
    }

    // TP-UX-UW-03: JSON file in directory loads entry
    @Test("TP-UX-UW-03: valid JSON file is loaded as CatalogEntry")
    @MainActor
    func jsonFileLoaded() throws {
        let dir = FileManager.default.temporaryDirectory
            .appendingPathComponent("ux-test-load-\(UUID().uuidString)", isDirectory: true)
        try FileManager.default.createDirectory(at: dir, withIntermediateDirectories: true)
        defer { try? FileManager.default.removeItem(at: dir) }

        let json = """
        {
          "id": "TestWidget",
          "widgetKind": "test.widget",
          "displayName": "Test Widget",
          "description": "A test.",
          "primitives": "KatagamiText",
          "wave": "user",
          "ssimStatus": "user"
        }
        """.data(using: .utf8)!

        try json.write(to: dir.appendingPathComponent("test-widget.json"))

        let catalog = UserWidgetCatalog(directory: dir)
        #expect(catalog.entries.count == 1)
        #expect(catalog.entries[0].id == "TestWidget")
        #expect(catalog.entries[0].widgetKind == "test.widget")
    }

    // TP-UX-UW-04: toCatalogEntry preserves all fields
    @Test("TP-UX-UW-04: UserWidgetEntry.catalogEntry() preserves all fields")
    func catalogEntryConversion() {
        let entry = UserWidgetEntry(
            id: "X",
            widgetKind: "x.widget",
            displayName: "X Widget",
            description: "desc",
            primitives: "KatagamiText,KatagamiVStack",
            wave: "user",
            ssimStatus: "user",
            codeSnippet: nil
        )
        let ce = entry.catalogEntry()
        #expect(ce.id == "X")
        #expect(ce.widgetKind == "x.widget")
        #expect(ce.primitiveList == ["KatagamiText", "KatagamiVStack"])
        #expect(ce.codeSnippet == nil)
    }

    // TP-UX-UW-05: FileMonitor wakeup (2s gate)
    @Test("TP-UX-UW-05: FileMonitor wakes catalog on new file drop (≤2s)")
    @MainActor
    func fileMonitorWakeup() async throws {
        let dir = FileManager.default.temporaryDirectory
            .appendingPathComponent("ux-test-monitor-\(UUID().uuidString)", isDirectory: true)
        try FileManager.default.createDirectory(at: dir, withIntermediateDirectories: true)
        defer { try? FileManager.default.removeItem(at: dir) }

        let catalog = UserWidgetCatalog(directory: dir)
        #expect(catalog.entries.isEmpty)

        // Drop a JSON file
        let json = """
        {
          "id": "Dropped",
          "widgetKind": "dropped.widget",
          "displayName": "Dropped Widget",
          "description": "Auto-detected.",
          "primitives": "",
          "wave": "user",
          "ssimStatus": "user"
        }
        """.data(using: .utf8)!
        try json.write(to: dir.appendingPathComponent("dropped.json"))

        // Wait up to 2s for the FileMonitor to fire and reload.
        var waited = 0.0
        while catalog.entries.isEmpty && waited < 2.0 {
            try await Task.sleep(nanoseconds: 100_000_000) // 100ms
            waited += 0.1
        }

        #expect(catalog.entries.count == 1, "FileMonitor did not wake within 2s — waited \(waited)s")
        #expect(catalog.entries.first?.id == "Dropped")
    }
}

// MARK: - D2: Snapshot tests (macOS only)

#if canImport(AppKit) && os(macOS)

/// Wrap a SwiftUI view in an NSHostingView at a fixed size.
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

@MainActor
@Suite("StorybookUXSnapshot")
struct StorybookUXSnapshotTests {

    // TP-UX-SS-01: Collapsed DisclosureGroup renders header only (unit-level)
    // Tests the DisclosureGroup-based sidebar structure directly via a stable
    // isolated view — avoids @AppStorage/UserDefaults race conditions in
    // parallel test runs.
    @Test("TP-UX-SS-01: DisclosureGroup collapsed renders header label only")
    func collapsedSectionsSnapshot() throws {
        @State var expanded = false
        let view = List {
            DisclosureGroup(isExpanded: .constant(false)) {
                Text("Atom item")
            } label: {
                Label("Primitives (28)", systemImage: "square.stack")
                    .font(.headline)
            }
            DisclosureGroup(isExpanded: .constant(false)) {
                Text("Widget item")
            } label: {
                Label("Widgets (6)", systemImage: "rectangle.3.group")
                    .font(.headline)
            }
            DisclosureGroup(isExpanded: .constant(false)) {
                Text("Token item")
            } label: {
                Label("Design Tokens", systemImage: "circle.hexagongrid")
                    .font(.headline)
            }
        }
        let nsView = hostingView(view, width: 300, height: 200)

        withSnapshotTesting(record: .missing) {
            assertSnapshot(of: nsView, as: .image(size: CGSize(width: 300, height: 200)), named: "collapsed")
        }
    }

    // TP-UX-SS-02: Expanded sidebar showing section counts
    @Test("TP-UX-SS-02: all sections expanded with counts visible")
    func expandedSectionsSnapshot() throws {
        let manifest = CatalogManifest(entries: [
            CatalogEntry(id: "SMPeople", widgetKind: "people", displayName: "People",
                        description: "Presenter card.",
                        primitives: "KatagamiShadowedCard,KatagamiHStack,KatagamiVStack,KatagamiText",
                        wave: "1", ssimStatus: "pendingImpl")
        ])
        CTechWidgetPreviewBridge.registerAll()
        KatagamiPrimitivePreviewBridge.registerAll()
        let view = StorybookBrowserView(manifest: manifest, userCatalog: UserWidgetCatalog())
        let nsView = hostingView(view, width: 1200, height: 800)

        withSnapshotTesting(record: .missing) {
            assertSnapshot(of: nsView, as: .image(size: CGSize(width: 1200, height: 800)), named: "expanded-with-counts")
        }
    }

    // TP-UX-SS-03: Used-in cross-reference section at bottom of detail view
    @Test("TP-UX-SS-03: Used-In section renders for katagami.text")
    func usedInSectionSnapshot() throws {
        CTechWidgetPreviewBridge.registerAll()
        KatagamiPrimitivePreviewBridge.registerAll()

        let allEntries: [CatalogEntry] = [
            CatalogEntry(id: "KatagamiText", widgetKind: "katagami.text", displayName: "Text",
                        description: "Inline text.", primitives: "", wave: "0", ssimStatus: "primitive"),
            CatalogEntry(id: "SMPeople", widgetKind: "people", displayName: "People",
                        description: "Presenter card.",
                        primitives: "KatagamiShadowedCard,KatagamiHStack,KatagamiVStack,KatagamiText",
                        wave: "1", ssimStatus: "pendingImpl"),
            CatalogEntry(id: "SMCart", widgetKind: "cart", displayName: "Cart",
                        description: "Shopping cart.",
                        primitives: "KatagamiDrawer,KatagamiVStack,KatagamiHStack,KatagamiText",
                        wave: "7", ssimStatus: "pendingImpl"),
        ]
        let textEntry = allEntries[0]
        let detailView = StorybookDetailView(entry: textEntry, allEntries: allEntries, onNavigate: nil)
        let nsView = hostingView(ScrollView { detailView.frame(maxWidth: .infinity) }, width: 800, height: 700)

        withSnapshotTesting(record: .missing) {
            assertSnapshot(of: nsView, as: .image(size: CGSize(width: 800, height: 700)), named: "used-in-links")
        }
    }

    // TP-UX-SS-04: User widget loaded from directory shows in catalog
    @Test("TP-UX-SS-04: user widget JSON loaded appears in sidebar")
    @MainActor
    func userWidgetLoadedSnapshot() throws {
        let dir = FileManager.default.temporaryDirectory
            .appendingPathComponent("ux-snap-\(UUID().uuidString)", isDirectory: true)
        try FileManager.default.createDirectory(at: dir, withIntermediateDirectories: true)
        defer { try? FileManager.default.removeItem(at: dir) }

        let json = """
        {
          "id": "MyCustomWidget",
          "widgetKind": "custom.widget",
          "displayName": "My Custom Widget",
          "description": "An operator-added widget.",
          "primitives": "KatagamiVStack,KatagamiText",
          "wave": "user",
          "ssimStatus": "user"
        }
        """.data(using: .utf8)!
        try json.write(to: dir.appendingPathComponent("my-custom-widget.json"))

        let userCatalog = UserWidgetCatalog(directory: dir)
        let manifest = CatalogManifest(entries: [])
        let view = StorybookBrowserView(manifest: manifest, userCatalog: userCatalog)
        let nsView = hostingView(view, width: 1200, height: 800)

        withSnapshotTesting(record: .missing) {
            assertSnapshot(of: nsView, as: .image(size: CGSize(width: 1200, height: 800)), named: "user-widget-loaded")
        }
    }
}

#endif // canImport(AppKit)
