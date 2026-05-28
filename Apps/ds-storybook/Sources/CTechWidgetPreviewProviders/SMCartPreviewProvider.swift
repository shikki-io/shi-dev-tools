// SMCartPreviewProvider.swift — CTechWidgetPreviewProviders
// kagami-scope: exempt
//
// Renders SMCartKatagami (W7) via .swiftUI(theme:).
//
// KatagamiDrawer: when isOpen = true the renderer renders the inner content
// directly (the drawer chrome — sheet/overlay — is the host's responsibility
// per KatagamiSwiftUIRenderer.bridgeIfDrawer comment). We set isOpen = true
// so the cart items are always visible in the storybook preview.
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
        let renderer = KatagamiSwiftUIRenderer()
        return (try? renderer.render(widget, theme: KatagamiThemePreset.kintsugi))
            ?? AnyView(Text("SMCart render failed").foregroundStyle(.orange))
    }
}
