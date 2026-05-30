// SMPeoplePreviewProvider.swift — CTechWidgetPreviewProviders
// kagami-scope: exempt
//
// Renders SMPeopleKatagami (W1) via SwiftUIRenderer.renderView(_:context:).
// Hop α (2026-05-30): migrated from KatagamiSwiftUIRenderer / KatagamiThemePreset
// to shi-design's SwiftUIRenderer API.
//
// Stub data: presenter name + role hardcoded for storybook preview.

import SwiftUI
import KatagamiCore
import KatagamiSwiftUI
import SMWidgetsKatagami
import DSStorybookKit

public struct SMPeoplePreviewProvider: WidgetPreviewProvider {
    public init() {}

    @MainActor
    public func previewView(for entry: CatalogEntry) -> AnyView {
        let widget = SMPeopleKatagami(
            overlayUUID: "preview-\(entry.id)",
            title: "Jane Dupont",
            descriptionText: "Head of Product & Innovation",
            displaySize: .regular
        )
        let renderer = SwiftUIRenderer()
        return renderer.renderView(widget, context: RenderContext(target: .swiftUI))
    }
}
