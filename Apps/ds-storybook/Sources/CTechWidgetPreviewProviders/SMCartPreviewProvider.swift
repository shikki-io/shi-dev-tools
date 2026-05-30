// SMCartPreviewProvider.swift — CTechWidgetPreviewProviders
// kagami-scope: exempt
//
// Renders SMCartKatagami (W7) via SwiftUIRenderer.renderView(_:context:).
// Hop α (2026-05-30): migrated from KatagamiSwiftUIRenderer / KatagamiThemePreset
// to shi-design's SwiftUIRenderer API.
//
// SMCartKatagami renders ViewNode.box as the cart surface (no KatagamiDrawer).
// isOpen = true so the cart items are always visible in the storybook preview.
//
// Demo: 2 cart items + EUR total.

import SwiftUI
import KatagamiCore
import KatagamiSwiftUI
import SMWidgetsKatagami
import SMWidgetsCore
import DSStorybookKit

public struct SMCartPreviewProvider: WidgetPreviewProvider {
    public init() {}

    @MainActor
    public func previewView(for entry: CatalogEntry) -> AnyView {
        let snapshot = KatagamiCartSnapshot(
            id: "preview-cart",
            items: [
                CartItem(
                    id: "item-1",
                    product: Product(
                        id: "prod-1",
                        title: "Casque Bluetooth Pro",
                        price: 149.99,
                        currency: "EUR"
                    ),
                    variant: Variant(id: "var-1", title: "Noir", price: 149.99),
                    quantity: 1
                ),
                CartItem(
                    id: "item-2",
                    product: Product(
                        id: "prod-2",
                        title: "Chargeur magnétique",
                        price: 39.99,
                        currency: "EUR"
                    ),
                    variant: Variant(id: "var-2", title: "Blanc", price: 39.99),
                    quantity: 2
                ),
            ],
            currency: "EUR"
        )

        let widget = SMCartKatagami(snapshot: snapshot, isOpen: true)
        let renderer = SwiftUIRenderer()
        return renderer.renderView(widget, context: RenderContext(target: .swiftUI))
    }
}
