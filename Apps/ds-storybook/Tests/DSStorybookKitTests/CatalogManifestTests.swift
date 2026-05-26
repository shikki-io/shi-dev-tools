// CatalogManifestTests.swift — DSStorybookKitTests
//
// Tests for CatalogManifest decode (W5.0b acceptance criteria).
// Verifies the JSON format emitted by SMWidgetsKatagamiManifest.emitJSON().

import Testing
@testable import DSStorybookKit

// MARK: - CatalogManifest decode tests

@Suite("CatalogManifest")
struct CatalogManifestTests {

    // W5.0b acceptance: decode valid 7-entry c-tech JSON.
    @Test("decodes 7 c-tech entries from JSON array")
    func decodesSevenEntries() throws {
        let json = """
        [
          {"id":"SMPeople","widgetKind":"people","displayName":"People",
           "description":"Presenter card","primitives":"KatagamiHStack,KatagamiText",
           "wave":"1","ssimStatus":"pendingImpl"},
          {"id":"SMProduct","widgetKind":"product","displayName":"Product",
           "description":"Product card","primitives":"KatagamiVStack,KatagamiText",
           "wave":"2","ssimStatus":"pendingImpl"},
          {"id":"SMShoppableProduct","widgetKind":"product","displayName":"Shoppable Product",
           "description":"Shoppable overlay","primitives":"KatagamiVStack,KatagamiHStack",
           "wave":"3","ssimStatus":"pendingImpl"},
          {"id":"SMQR","widgetKind":"qr","displayName":"QR Code",
           "description":"QR deeplink","primitives":"KatagamiZStack,KatagamiText",
           "wave":"4","ssimStatus":"pendingImpl"},
          {"id":"SMEndcap","widgetKind":"endcap","displayName":"Endcap",
           "description":"Shopping endcap","primitives":"KatagamiScrollView,KatagamiHStack",
           "wave":"5","ssimStatus":"pendingImpl"},
          {"id":"SMProgramGuide","widgetKind":"program_guide","displayName":"Program Guide",
           "description":"EPG guide","primitives":"KatagamiVStack,KatagamiText",
           "wave":"6","ssimStatus":"pendingImpl"},
          {"id":"SMCart","widgetKind":"cart","displayName":"Cart",
           "description":"Shopping cart","primitives":"KatagamiDrawer,KatagamiVStack",
           "wave":"7","ssimStatus":"pendingImpl"}
        ]
        """.data(using: .utf8)!

        let manifest = try CatalogManifest.decode(from: json)
        #expect(manifest.entryCount == 7)
        #expect(manifest.entries.map(\.id) == [
            "SMPeople", "SMProduct", "SMShoppableProduct",
            "SMQR", "SMEndcap", "SMProgramGuide", "SMCart"
        ])
        #expect(manifest.entries.map(\.displayName) == [
            "People", "Product", "Shoppable Product",
            "QR Code", "Endcap", "Program Guide", "Cart"
        ])
    }

    @Test("entry primitiveList splits comma-separated string")
    func primitiveListSplits() throws {
        let json = """
        [{"id":"A","widgetKind":"a","displayName":"A","description":"test",
          "primitives":"KatagamiHStack,KatagamiVStack,KatagamiText","wave":"1","ssimStatus":"pendingImpl"}]
        """.data(using: .utf8)!

        let manifest = try CatalogManifest.decode(from: json)
        #expect(manifest.entries[0].primitiveList == ["KatagamiHStack", "KatagamiVStack", "KatagamiText"])
    }

    @Test("entry waveInt parses wave string to Int")
    func waveIntParsing() throws {
        let json = """
        [{"id":"A","widgetKind":"a","displayName":"A","description":"d",
          "primitives":"P","wave":"3","ssimStatus":"pendingImpl"}]
        """.data(using: .utf8)!

        let manifest = try CatalogManifest.decode(from: json)
        #expect(manifest.entries[0].waveInt == 3)
    }

    @Test("throws on malformed JSON")
    func throwsOnMalformedJSON() {
        let bad = "not json at all".data(using: .utf8)!
        #expect(throws: (any Error).self) {
            try CatalogManifest.decode(from: bad)
        }
    }

    @Test("decodes empty array")
    func decodesEmptyArray() throws {
        let json = "[]".data(using: .utf8)!
        let manifest = try CatalogManifest.decode(from: json)
        #expect(manifest.entryCount == 0)
    }
}

// MARK: - WidgetPreviewRegistry tests

@Suite("WidgetPreviewRegistry")
struct WidgetPreviewRegistryTests {

    @Test("shared instance hasProvider returns false for unregistered kind")
    func sharedInstanceMissing() {
        // The shared registry may already have providers registered in production;
        // check a never-registered sentinel kind.
        let registry = WidgetPreviewRegistry.shared
        #expect(!registry.hasProvider(for: "zz-test-sentinel-kind-ds-w5"))
    }
}
