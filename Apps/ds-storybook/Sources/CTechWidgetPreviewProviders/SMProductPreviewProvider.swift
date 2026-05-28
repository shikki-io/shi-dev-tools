// SMProductPreviewProvider.swift — CTechWidgetPreviewProviders
// kagami-scope: exempt
//
// Renders SMShoppableProductKatagami (W3) via .swiftUI(theme:) — covers widgetKind "product".
// One demo ShoppableProduct line item exercises the full shoppable layout.
// The non-shoppable SMProductKatagami (W2) layout is also valid for this
// widgetKind; we default to the richer shoppable shape for the demo.

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

        let renderer = KatagamiSwiftUIRenderer()
        return (try? renderer.render(widget, theme: KatagamiThemePreset.kintsugi))
            ?? AnyView(Text("SMShoppableProduct render failed").foregroundStyle(.orange))
    }
}
