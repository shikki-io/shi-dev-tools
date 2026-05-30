// SMProductPreviewProvider.swift — CTechWidgetPreviewProviders
// kagami-scope: exempt
//
// Renders SMShoppableProductKatagami (W3) via SwiftUIRenderer.renderView(_:context:).
// Hop α (2026-05-30): migrated from KatagamiSwiftUIRenderer / KatagamiThemePreset
// to shi-design's SwiftUIRenderer API.
//
// One demo ShoppableProduct line item exercises the full shoppable layout.
// The non-shoppable SMProductKatagami (W2) falls through when products is empty.

import SwiftUI
import KatagamiCore
import KatagamiSwiftUI
import SMWidgetsKatagami
import CTechPlayer
import DSStorybookKit

public struct SMProductPreviewProvider: WidgetPreviewProvider {
    public init() {}

    @MainActor
    public func previewView(for entry: CatalogEntry) -> AnyView {
        let demoProduct = ShoppableProduct(
            campaignContentUuid: "demo-prod-1",
            title: "Casque Bluetooth Pro",
            price: 149.99,
            compareAtPrice: 199.99,
            currency: "EUR",
            imageUrl: nil,
            isAvailable: true,
            options: ["Couleur"],
            variants: [],
            vaultRef: nil
        )

        let widget = SMShoppableProductKatagami(
            overlayUUID: "preview-\(entry.id)",
            title: "Casque audio premium",
            products: [demoProduct],
            fallbackPrice: "EUR 149.99",
            displaySize: .regular
        )

        let renderer = SwiftUIRenderer()
        return renderer.renderView(widget, context: RenderContext(target: .swiftUI))
    }
}
