// CTechWidgetPreviewProviders.swift
//
// Top-level registration entry point.
//
// Call `CTechWidgetPreviewProviders.registerAll()` in ds-storybook's App.init()
// before any view loads. Each provider materialises a canonical KatagamiView
// from stub data and renders it via .swiftUI(theme:) to produce a SwiftUI
// view — wiring live render into the WidgetPreviewRegistry for every
// widgetKind in the c-tech catalog.
//
// widgetKind mapping (must match SMWidgetsKatagamiManifest.emitJSON output):
//   "people"        → SMPeoplePreviewProvider
//   "product"       → SMProductPreviewProvider  (also covers SMShoppableProduct)
//   "qr"            → SMQRPreviewProvider
//   "endcap"        → SMEndcapPreviewProvider
//   "program_guide" → SMProgramGuidePreviewProvider
//   "cart"          → SMCartPreviewProvider
//
// Note: SMProduct and SMShoppableProduct share widgetKind "product". The
// registered provider renders SMShoppableProductKatagami with one demo line
// item so the shoppable layout is exercised. The plain-product card appears
// because ShoppableLayout falls through to NonShoppableLayout when products
// list is empty — verified by the test target.

import DSStorybookKit

public enum CTechWidgetPreviewProviders {
    /// Register all c-tech widget preview providers into the shared registry.
    /// Safe to call multiple times — repeated registration overwrites the
    /// previous provider for the same widgetKind (idempotent).
    public static func registerAll() {
        let r = WidgetPreviewRegistry.shared
        r.register(provider: SMPeoplePreviewProvider(),       for: "people")
        r.register(provider: SMProductPreviewProvider(),      for: "product")
        r.register(provider: SMQRPreviewProvider(),           for: "qr")
        r.register(provider: SMEndcapPreviewProvider(),       for: "endcap")
        r.register(provider: SMProgramGuidePreviewProvider(), for: "program_guide")
        r.register(provider: SMCartPreviewProvider(),         for: "cart")
    }
}
