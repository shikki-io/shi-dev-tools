// SMPeoplePreviewProvider.swift — CTechWidgetPreviewProviders
//
// Renders SMPeopleKatagami (W1) via .swiftUI(theme:).
// Stub data: presenter name from CatalogEntry.displayName; role from
// CatalogEntry.description (truncated). Falls back to static strings when
// the entry carries no useful data.

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
        return AnyView(widget.swiftUI(theme: KatagamiThemePreset.kintsugi))
    }
}
