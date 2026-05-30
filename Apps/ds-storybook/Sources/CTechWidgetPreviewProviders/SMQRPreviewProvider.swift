// SMQRPreviewProvider.swift — CTechWidgetPreviewProviders
// kagami-scope: exempt
//
// Renders SMQRKatagami (W4) via SwiftUIRenderer.renderView(_:context:).
// Hop α (2026-05-30): migrated from KatagamiSwiftUIRenderer / KatagamiThemePreset
// to shi-design's SwiftUIRenderer API.
//
// QR rendering note: ViewNode has no native QR bitmap primitive.
// The renderer currently shows ViewNode.badge(text: deeplink) as a capsule label.
// A CoreImage escape-hatch can be wired at the renderer call-site to produce
// an actual bitmap when needed.

import SwiftUI
import KatagamiCore
import KatagamiSwiftUI
import SMWidgetsKatagami
import DSStorybookKit

public struct SMQRPreviewProvider: WidgetPreviewProvider {
    public init() {}

    @MainActor
    public func previewView(for entry: CatalogEntry) -> AnyView {
        let config = KatagamiQRConfig(
            deeplink: "https://shop.clifftechnologies.co/demo?widget=qr",
            sizePoints: 160,
            accessibilityLabel: "Demo QR code — Cliff Technologies shop",
            showCaption: true
        )
        let widget = SMQRKatagami(config: config)
        let renderer = SwiftUIRenderer()
        return renderer.renderView(widget, context: RenderContext(target: .swiftUI))
    }
}
