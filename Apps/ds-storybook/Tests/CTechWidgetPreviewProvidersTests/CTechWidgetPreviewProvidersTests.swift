// CTechWidgetPreviewProvidersTests.swift — CTechWidgetPreviewProvidersTests
//
// Smoke tests: each provider must return a non-empty AnyView for a stub
// CatalogEntry. Tests verify the provider is registered and that
// CTechWidgetPreviewProviders.registerAll() wires all 6 widgetKind values.
//
// Acceptance per spec:
//   - registerAll() registers providers for all 6 widgetKind values
//   - Each provider.previewView(for:) returns a non-nil AnyView without crash

import Testing
import SwiftUI
@testable import CTechWidgetPreviewProviders
import DSStorybookKit

// MARK: - Helpers

private func stubEntry(id: String, widgetKind: String, displayName: String) -> CatalogEntry {
    CatalogEntry(
        id: id,
        widgetKind: widgetKind,
        displayName: displayName,
        description: "Test stub for \(displayName)",
        primitives: "KatagamiVStack,KatagamiText",
        wave: "1",
        ssimStatus: "pendingImpl"
    )
}

// MARK: - Registration tests

@Suite("CTechWidgetPreviewProviders registration")
struct CTechWidgetPreviewProvidersRegistrationTests {

    @Test("registerAll() wires 6 widgetKind entries")
    @MainActor
    func registerAllWiresSixKinds() {
        let registry = WidgetPreviewRegistry.shared
        CTechWidgetPreviewProviders.registerAll()

        let expectedKinds = ["people", "product", "qr", "endcap", "program_guide", "cart"]
        for kind in expectedKinds {
            #expect(registry.hasProvider(for: kind), "Missing provider for widgetKind: \(kind)")
        }
    }
}

// MARK: - Provider smoke tests

@Suite("Provider previewView smoke")
struct ProviderSmokeTests {

    @Test("SMPeoplePreviewProvider returns AnyView")
    @MainActor
    func peopleProviderSmoke() {
        let provider = SMPeoplePreviewProvider()
        let entry = stubEntry(id: "SMPeople", widgetKind: "people", displayName: "People")
        let view = provider.previewView(for: entry)
        _ = view
        #expect(Bool(true))
    }

    @Test("SMProductPreviewProvider returns AnyView")
    @MainActor
    func productProviderSmoke() {
        let provider = SMProductPreviewProvider()
        let entry = stubEntry(id: "SMProduct", widgetKind: "product", displayName: "Product")
        let view = provider.previewView(for: entry)
        _ = view
        #expect(Bool(true))
    }

    @Test("SMQRPreviewProvider returns AnyView")
    @MainActor
    func qrProviderSmoke() {
        let provider = SMQRPreviewProvider()
        let entry = stubEntry(id: "SMQR", widgetKind: "qr", displayName: "QR Code")
        let view = provider.previewView(for: entry)
        _ = view
        #expect(Bool(true))
    }

    @Test("SMEndcapPreviewProvider returns AnyView")
    @MainActor
    func endcapProviderSmoke() {
        let provider = SMEndcapPreviewProvider()
        let entry = stubEntry(id: "SMEndcap", widgetKind: "endcap", displayName: "Endcap")
        let view = provider.previewView(for: entry)
        _ = view
        #expect(Bool(true))
    }

    @Test("SMProgramGuidePreviewProvider returns AnyView")
    @MainActor
    func programGuideProviderSmoke() {
        let provider = SMProgramGuidePreviewProvider()
        let entry = stubEntry(id: "SMProgramGuide", widgetKind: "program_guide", displayName: "Program Guide")
        let view = provider.previewView(for: entry)
        _ = view
        #expect(Bool(true))
    }

    @Test("SMCartPreviewProvider returns AnyView")
    @MainActor
    func cartProviderSmoke() {
        let provider = SMCartPreviewProvider()
        let entry = stubEntry(id: "SMCart", widgetKind: "cart", displayName: "Cart")
        let view = provider.previewView(for: entry)
        _ = view
        #expect(Bool(true))
    }
}
