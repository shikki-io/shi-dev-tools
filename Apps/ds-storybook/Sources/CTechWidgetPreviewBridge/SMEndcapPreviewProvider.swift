// SMEndcapPreviewProvider.swift — CTechWidgetPreviewBridge
//
// Renders SMEndcapKatagami (W5) through KatagamiSwiftUIRenderer.
// Demo: 3 horizontal slots — covers the horizontal ScrollView path.

import SwiftUI
import KatagamiCore
import KatagamiSwiftUI
import SMWidgetsKatagami
import CTechPlayer
import DSStorybookKit

public struct SMEndcapPreviewProvider: WidgetPreviewProvider {
    public init() {}

    @MainActor
    public func previewView(for entry: CatalogEntry) -> AnyView {
        let demoSlots = [
            makeSlot(position: 0, title: "Casque Bluetooth Pro", price: 149.99, promo: "-25%"),
            makeSlot(position: 1, title: "Chargeur magnétique", price: 39.99, promo: nil),
            makeSlot(position: 2, title: "Enceinte portable", price: 79.99, promo: "NOUVEAU"),
        ]

        let widget = SMEndcapKatagami(
            title: "Nos recommandations",
            displayMode: .horizontal,
            slots: demoSlots
        )

        let renderer = KatagamiSwiftUIRenderer()
        return (try? renderer.render(widget, theme: KatagamiThemePreset.kintsugi))
            ?? AnyView(Text("SMEndcap render failed").foregroundStyle(.orange))
    }

    private func makeSlot(position: Int, title: String, price: Double, promo: String?) -> Slot {
        Slot(
            position: position,
            isSponsored: false,
            title: title,
            description: "",
            imageUrl: "",
            price: price,
            originalPrice: nil,
            currency: "EUR",
            promotionLabel: promo,
            stock: nil,
            isAvailable: true,
            trackingUrl: nil,
            gtin: nil,
            vendor: "CliffTech",
            tags: [],
            metadata: nil,
            options: [],
            variants: []
        )
    }
}
