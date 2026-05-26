// SMQRPreviewProvider.swift — CTechWidgetPreviewProviders
//
// Renders SMQRKatagami (W4) via .swiftUI(theme:).
//
// Q-CT2: SMQRKatagami now uses KatagamiQRCode (AnyQRMarker) as its primary
// node. KatagamiSwiftUIRenderer bridges AnyQRMarker to CoreImage on macOS 14+,
// so the actual QR bitmap SHOULD render without an EscapeHatch. The fallback
// prose ("QR code: <deeplink>") renders if the renderer does not yet implement
// the AnyQRMarker bridge for the current target.
//
// Open Q: CoreImage CIFilter("CIQRCodeGenerator") is available on macOS 14+
// (used by the renderer). Verify at demo time; if the bitmap is blank, the
// AnyQRMarker bridge in KatagamiSwiftUIRenderer may need the
// bridgeIfQRCode() path wired — surface to operator.

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
        return AnyView(widget.swiftUI(theme: KatagamiThemePreset.kintsugi))
    }
}
