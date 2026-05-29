// KatagamiPrimitivePreviewBridge.swift — DSStorybookKit
// kagami-scope: exempt
//
// Preview providers for all 28 Katagami canonical primitives.
//
// Hop D (2026-05-29): Rewrote to use native SwiftUI only (removed shikki Katagami DSL
// dependency). Previously used KatagamiSwiftUIRenderer.render() with a SwiftUI fallback;
// now uses the fallback view directly everywhere.
//
// For the 8 canonical atoms (hstack/vstack/zstack/grid/text/button/spacer/section),
// PrimitiveCatalog.swiftUIBodies (from KagamiStorybookSwiftUI in shi-design) provides
// the authoritative body provider. These are wired in DSStorybookApp.init() via
// KagamiStorybookSwiftUIBodies.registerAll().
//
// TODO(hop-d-upstream): the 20 extended primitives (heading, paragraph, emphasis, strong,
// code, image, link, textfield, linebreak, inlinegroup, marquee, scrollview, drawer,
// viewport, semantic, swipecontainer, asyncimage, badge, overlaymarker, qrmarker,
// shadowedcard) should be upstreamed to shi-design's KagamiStorybookSwiftUI.
//
// Tiers:
//   Atoms (13):     text, heading, paragraph, emphasis, strong, code,
//                   image, link, button, textfield, linebreak, inlinegroup, marquee
//   Layout (10):    hstack, vstack, zstack, grid, scrollview, spacer,
//                   drawer, viewport, semantic, swipecontainer
//   Components (4): asyncimage, badge, overlaymarker, qrmarker
//   Composite (1):  shadowedcard
//
// Registration: call `KatagamiPrimitivePreviewProviders.registerAll()` in
// DSStorybookApp.init() alongside CTechWidgetPreviewProviders.registerAll().

import SwiftUI

// MARK: - KatagamiPrimitivePreviewProviders

public enum KatagamiPrimitivePreviewProviders {

    /// Register one WidgetPreviewProvider per Katagami primitive widgetKind.
    /// Safe to call multiple times — repeated registration overwrites the
    /// previous provider for the same widgetKind (idempotent).
    public static func registerAll() {
        let r = WidgetPreviewRegistry.shared

        // MARK: Atoms
        r.register(provider: KPPTextProvider(),        for: "katagami.text")
        r.register(provider: KPPHeadingProvider(),     for: "katagami.heading")
        r.register(provider: KPPParagraphProvider(),   for: "katagami.paragraph")
        r.register(provider: KPPEmphasisProvider(),    for: "katagami.emphasis")
        r.register(provider: KPPStrongProvider(),      for: "katagami.strong")
        r.register(provider: KPPCodeProvider(),        for: "katagami.code")
        r.register(provider: KPPImageProvider(),       for: "katagami.image")
        r.register(provider: KPPLinkProvider(),        for: "katagami.link")
        r.register(provider: KPPButtonProvider(),      for: "katagami.button")
        r.register(provider: KPPTextFieldProvider(),   for: "katagami.textfield")
        r.register(provider: KPPLineBreakProvider(),   for: "katagami.linebreak")
        r.register(provider: KPPInlineGroupProvider(), for: "katagami.inlinegroup")
        r.register(provider: KPPMarqueeProvider(),     for: "katagami.marquee")

        // MARK: Layout
        r.register(provider: KPPHStackProvider(),         for: "katagami.hstack")
        r.register(provider: KPPVStackProvider(),         for: "katagami.vstack")
        r.register(provider: KPPZStackProvider(),         for: "katagami.zstack")
        r.register(provider: KPPGridProvider(),           for: "katagami.grid")
        r.register(provider: KPPScrollViewProvider(),     for: "katagami.scrollview")
        r.register(provider: KPPSpacerProvider(),         for: "katagami.spacer")
        r.register(provider: KPPDrawerProvider(),         for: "katagami.drawer")
        r.register(provider: KPPViewportProvider(),       for: "katagami.viewport")
        r.register(provider: KPPSemanticProvider(),       for: "katagami.semantic")
        r.register(provider: KPPSwipeContainerProvider(), for: "katagami.swipecontainer")

        // MARK: Components
        r.register(provider: KPPAsyncImageProvider(),    for: "katagami.asyncimage")
        r.register(provider: KPPBadgeProvider(),         for: "katagami.badge")
        r.register(provider: KPPOverlayMarkerProvider(), for: "katagami.overlaymarker")
        r.register(provider: KPPQRMarkerProvider(),      for: "katagami.qrmarker")

        // MARK: Composite
        r.register(provider: KPPShadowedCardProvider(), for: "katagami.shadowedcard")
    }
}

// MARK: - Atom providers

// katagami.text
struct KPPTextProvider: WidgetPreviewProvider {
    @MainActor func previewView(for entry: CatalogEntry) -> AnyView {
        AnyView(
            Text("The quick brown fox jumps over the lazy dog").font(.body)
        )
    }
}

// katagami.heading
struct KPPHeadingProvider: WidgetPreviewProvider {
    @MainActor func previewView(for entry: CatalogEntry) -> AnyView {
        AnyView(Text("Design System Heading").font(.title2.bold()))
    }
}

// katagami.paragraph
struct KPPParagraphProvider: WidgetPreviewProvider {
    @MainActor func previewView(for entry: CatalogEntry) -> AnyView {
        AnyView(Text("A paragraph groups inline content — bold text, emphasis, links, and line breaks.").font(.body))
    }
}

// katagami.emphasis
struct KPPEmphasisProvider: WidgetPreviewProvider {
    @MainActor func previewView(for entry: CatalogEntry) -> AnyView {
        AnyView(Text("Italicised emphasis text").italic())
    }
}

// katagami.strong
struct KPPStrongProvider: WidgetPreviewProvider {
    @MainActor func previewView(for entry: CatalogEntry) -> AnyView {
        AnyView(Text("Bold strong text").bold())
    }
}

// katagami.code
struct KPPCodeProvider: WidgetPreviewProvider {
    @MainActor func previewView(for entry: CatalogEntry) -> AnyView {
        AnyView(
            Text("swift build --product shi")
                .font(.system(.body, design: .monospaced))
                .padding(8)
                .background(Color(red: 0.1, green: 0.1, blue: 0.12))
                .foregroundStyle(.white)
                .clipShape(RoundedRectangle(cornerRadius: 6))
        )
    }
}

// katagami.image
struct KPPImageProvider: WidgetPreviewProvider {
    @MainActor func previewView(for entry: CatalogEntry) -> AnyView {
        AnyView(Image(systemName: "photo").font(.largeTitle))
    }
}

// katagami.link
struct KPPLinkProvider: WidgetPreviewProvider {
    @MainActor func previewView(for entry: CatalogEntry) -> AnyView {
        AnyView(
            Link("shikki.io", destination: URL(string: "https://shikki.io")!)
                .font(.body)
        )
    }
}

// katagami.button
struct KPPButtonProvider: WidgetPreviewProvider {
    @MainActor func previewView(for entry: CatalogEntry) -> AnyView {
        AnyView(
            Button("Click me") { }
                .buttonStyle(.borderedProminent)
        )
    }
}

// katagami.textfield
struct KPPTextFieldProvider: WidgetPreviewProvider {
    @MainActor func previewView(for entry: CatalogEntry) -> AnyView {
        AnyView(
            TextField("Enter text…", text: .constant("Sample input"))
                .textFieldStyle(.roundedBorder)
        )
    }
}

// katagami.linebreak
struct KPPLineBreakProvider: WidgetPreviewProvider {
    @MainActor func previewView(for entry: CatalogEntry) -> AnyView {
        AnyView(
            VStack {
                Text("Line one")
                Divider().frame(width: 60)
                Text("Line two (after line break)")
            }
        )
    }
}

// katagami.inlinegroup
struct KPPInlineGroupProvider: WidgetPreviewProvider {
    @MainActor func previewView(for entry: CatalogEntry) -> AnyView {
        AnyView(
            HStack(spacing: 2) {
                Text("Runs on")
                Text("YOUR").bold()
                Text("machine")
            }
        )
    }
}

// katagami.marquee
struct KPPMarqueeProvider: WidgetPreviewProvider {
    @MainActor func previewView(for entry: CatalogEntry) -> AnyView {
        AnyView(
            Text("Scrolling banner text")
                .font(.body)
                .foregroundStyle(.green)
                .padding(.horizontal, 12)
                .padding(.vertical, 6)
                .background(.green.opacity(0.12), in: Capsule())
        )
    }
}

// MARK: - Layout providers

// katagami.hstack
struct KPPHStackProvider: WidgetPreviewProvider {
    @MainActor func previewView(for entry: CatalogEntry) -> AnyView {
        AnyView(
            HStack(spacing: 12) {
                ForEach(["A", "B", "C"], id: \.self) { label in
                    Text(label)
                        .padding(8)
                        .background(.tint.opacity(0.15), in: RoundedRectangle(cornerRadius: 6))
                }
            }
        )
    }
}

// katagami.vstack
struct KPPVStackProvider: WidgetPreviewProvider {
    @MainActor func previewView(for entry: CatalogEntry) -> AnyView {
        AnyView(
            VStack(alignment: .leading, spacing: 8) {
                ForEach(["Top item", "Middle item", "Bottom item"], id: \.self) { Text($0) }
            }
        )
    }
}

// katagami.zstack
struct KPPZStackProvider: WidgetPreviewProvider {
    @MainActor func previewView(for entry: CatalogEntry) -> AnyView {
        AnyView(
            ZStack {
                Text("Background layer")
                    .foregroundStyle(.secondary)
                Text("Foreground overlay")
                    .padding(4)
                    .background(.tint.opacity(0.15))
            }
        )
    }
}

// katagami.grid
struct KPPGridProvider: WidgetPreviewProvider {
    @MainActor func previewView(for entry: CatalogEntry) -> AnyView {
        AnyView(
            LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible()), GridItem(.flexible())], spacing: 8) {
                ForEach(1...6, id: \.self) { i in
                    Text("\(i)")
                        .frame(maxWidth: .infinity)
                        .padding(8)
                        .background(.tint.opacity(0.15), in: RoundedRectangle(cornerRadius: 6))
                }
            }
        )
    }
}

// katagami.scrollview
struct KPPScrollViewProvider: WidgetPreviewProvider {
    @MainActor func previewView(for entry: CatalogEntry) -> AnyView {
        AnyView(
            ScrollView {
                VStack(spacing: 8) {
                    ForEach(1...5, id: \.self) { i in Text("Scroll item \(i)") }
                }
            }
        )
    }
}

// katagami.spacer
struct KPPSpacerProvider: WidgetPreviewProvider {
    @MainActor func previewView(for entry: CatalogEntry) -> AnyView {
        AnyView(
            HStack {
                Text("Left")
                Spacer()
                Text("Right")
            }
        )
    }
}

// katagami.drawer
struct KPPDrawerProvider: WidgetPreviewProvider {
    @MainActor func previewView(for entry: CatalogEntry) -> AnyView {
        AnyView(
            VStack(alignment: .leading, spacing: 4) {
                Label("Drawer (open, leading)", systemImage: "sidebar.left")
                    .font(.body)
                Text("Side: leading · isOpen: true")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
            .padding()
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(.secondary.opacity(0.08), in: RoundedRectangle(cornerRadius: 8))
        )
    }
}

// katagami.viewport
struct KPPViewportProvider: WidgetPreviewProvider {
    @MainActor func previewView(for entry: CatalogEntry) -> AnyView {
        AnyView(
            VStack {
                Label("KViewport container", systemImage: "rectangle.expand.diagonal")
                Text("fullscreen: false · safeAreaInset: true")
                    .font(.caption).foregroundStyle(.secondary)
            }
            .padding()
            .frame(maxWidth: .infinity)
            .background(.secondary.opacity(0.08), in: RoundedRectangle(cornerRadius: 8))
        )
    }
}

// katagami.semantic
struct KPPSemanticProvider: WidgetPreviewProvider {
    @MainActor func previewView(for entry: CatalogEntry) -> AnyView {
        AnyView(
            VStack(alignment: .leading, spacing: 4) {
                Label("<section>", systemImage: "doc.text")
                    .font(.body.monospaced())
                Text("Semantic HTML5 wrapper — transparent on non-web renderers")
                    .font(.caption).foregroundStyle(.secondary)
            }
            .padding()
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(.secondary.opacity(0.08), in: RoundedRectangle(cornerRadius: 8))
        )
    }
}

// katagami.swipecontainer
struct KPPSwipeContainerProvider: WidgetPreviewProvider {
    @MainActor func previewView(for entry: CatalogEntry) -> AnyView {
        AnyView(
            VStack(spacing: 8) {
                HStack(spacing: 4) {
                    ForEach(1...3, id: \.self) { i in
                        Text("Slide \(i)")
                            .padding(.horizontal, 16).padding(.vertical, 8)
                            .background(.tint.opacity(i == 1 ? 0.25 : 0.08), in: RoundedRectangle(cornerRadius: 8))
                    }
                }
                HStack(spacing: 4) {
                    ForEach(1...3, id: \.self) { i in
                        Circle()
                            .fill(i == 1 ? Color.accentColor : Color.secondary.opacity(0.4))
                            .frame(width: 6, height: 6)
                    }
                }
            }
        )
    }
}

// MARK: - Component providers

// katagami.asyncimage
struct KPPAsyncImageProvider: WidgetPreviewProvider {
    @MainActor func previewView(for entry: CatalogEntry) -> AnyView {
        AnyView(
            AsyncImage(url: URL(string: "https://picsum.photos/120/80")) { phase in
                switch phase {
                case .success(let img):
                    img.resizable().scaledToFit().frame(maxWidth: 120, maxHeight: 80)
                default:
                    Label("loading…", systemImage: "photo").foregroundStyle(.secondary)
                }
            }
        )
    }
}

// katagami.badge
struct KPPBadgeProvider: WidgetPreviewProvider {
    @MainActor func previewView(for entry: CatalogEntry) -> AnyView {
        AnyView(
            Text("NEW")
                .font(.caption.bold())
                .padding(.horizontal, 8).padding(.vertical, 4)
                .background(.red.opacity(0.15), in: Capsule())
                .foregroundStyle(.red)
        )
    }
}

// katagami.overlaymarker
struct KPPOverlayMarkerProvider: WidgetPreviewProvider {
    @MainActor func previewView(for entry: CatalogEntry) -> AnyView {
        AnyView(
            ZStack(alignment: .topTrailing) {
                RoundedRectangle(cornerRadius: 8)
                    .fill(Color.secondary.opacity(0.1))
                    .frame(width: 80, height: 80)
                Circle()
                    .fill(Color.accentColor)
                    .frame(width: 16, height: 16)
                    .offset(x: 4, y: -4)
            }
        )
    }
}

// katagami.qrmarker
struct KPPQRMarkerProvider: WidgetPreviewProvider {
    @MainActor func previewView(for entry: CatalogEntry) -> AnyView {
        AnyView(
            VStack(spacing: 6) {
                Image(systemName: "qrcode")
                    .font(.system(size: 60))
                    .foregroundStyle(.secondary)
                Text("https://shikki.io")
                    .font(.caption.monospaced())
                    .foregroundStyle(.secondary)
            }
        )
    }
}

// MARK: - Composite provider

// katagami.shadowedcard
struct KPPShadowedCardProvider: WidgetPreviewProvider {
    @MainActor func previewView(for entry: CatalogEntry) -> AnyView {
        AnyView(
            VStack(alignment: .leading, spacing: 6) {
                Text("ShadowedCard")
                    .font(.headline)
                Text("cornerRadius: 12 · shadowRadius: 6")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
            .padding(16)
            .background(Color(NSColor.windowBackgroundColor))
            .clipShape(RoundedRectangle(cornerRadius: 12))
            .shadow(radius: 6)
        )
    }
}
