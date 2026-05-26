// KatagamiPrimitivePreviewBridge.swift — DSStorybookKit
//
// NP-4: Preview providers for all 28 Katagami canonical primitives.
//
// Each provider builds a representative KatagamiView instance and renders it
// via KatagamiSwiftUIRenderer. On render failure the provider falls back to a
// native SwiftUI view so the detail pane never shows the orange "No preview
// registered" warning for any katagami.* widgetKind.
//
// Tiers:
//   Atoms (13):     text, heading, paragraph, emphasis, strong, code,
//                   image, link, button, textfield, linebreak, inlinegroup, marquee
//   Layout (10):    hstack, vstack, zstack, grid, scrollview, spacer,
//                   drawer, viewport, semantic, swipecontainer
//   Components (4): asyncimage, badge, overlaymarker, qrmarker
//   Composite (1):  shadowedcard
//
// Registration: call `KatagamiPrimitivePreviewBridge.registerAll()` in
// DSStorybookApp.init() alongside CTechWidgetPreviewBridge.registerAll().
//
// Import note: DSStorybookKit already declares KatagamiSwiftUI / KatagamiCore
// as target dependencies, so no Package.swift change is required.

import SwiftUI
import KatagamiCore
import KatagamiSwiftUI

// MARK: - KatagamiPrimitivePreviewBridge

public enum KatagamiPrimitivePreviewBridge {

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
        r.register(provider: KPPAsyncImageProvider(),   for: "katagami.asyncimage")
        r.register(provider: KPPBadgeProvider(),        for: "katagami.badge")
        r.register(provider: KPPOverlayMarkerProvider(), for: "katagami.overlaymarker")
        r.register(provider: KPPQRMarkerProvider(),     for: "katagami.qrmarker")

        // MARK: Composite
        r.register(provider: KPPShadowedCardProvider(), for: "katagami.shadowedcard")
    }
}

// MARK: - Render helper

/// Render a KatagamiView or fall back to the provided SwiftUI view.
@MainActor
private func renderOrFallback<V: KatagamiView, F: View>(
    _ widget: V,
    fallback: F
) -> AnyView {
    let renderer = KatagamiSwiftUIRenderer()
    return (try? renderer.render(widget, theme: KatagamiThemePreset.kintsugi))
        ?? AnyView(fallback)
}

// MARK: - Atom providers

// katagami.text
struct KPPTextProvider: WidgetPreviewProvider {
    @MainActor func previewView(for entry: CatalogEntry) -> AnyView {
        let widget = KatagamiText("The quick brown fox jumps over the lazy dog")
        return renderOrFallback(widget, fallback: Text("KatagamiText sample").font(.body))
    }
}

// katagami.heading
struct KPPHeadingProvider: WidgetPreviewProvider {
    @MainActor func previewView(for entry: CatalogEntry) -> AnyView {
        let widget = KatagamiHeading(.h2, "Design System Heading")
        return renderOrFallback(widget, fallback: Text("Design System Heading").font(.title2.bold()))
    }
}

// katagami.paragraph
struct KPPParagraphProvider: WidgetPreviewProvider {
    @MainActor func previewView(for entry: CatalogEntry) -> AnyView {
        let widget = KatagamiParagraph {
            KatagamiText("A paragraph groups inline content — ")
            KatagamiStrong("bold text")
            KatagamiText(", emphasis, links, and line breaks.")
        }
        return renderOrFallback(widget, fallback: Text("Paragraph with inline children").font(.body))
    }
}

// katagami.emphasis
struct KPPEmphasisProvider: WidgetPreviewProvider {
    @MainActor func previewView(for entry: CatalogEntry) -> AnyView {
        let widget = KatagamiEmphasis("Italicised emphasis text")
        return renderOrFallback(widget, fallback: Text("Italicised emphasis text").italic())
    }
}

// katagami.strong
struct KPPStrongProvider: WidgetPreviewProvider {
    @MainActor func previewView(for entry: CatalogEntry) -> AnyView {
        let widget = KatagamiStrong("Bold strong text")
        return renderOrFallback(widget, fallback: Text("Bold strong text").bold())
    }
}

// katagami.code
struct KPPCodeProvider: WidgetPreviewProvider {
    @MainActor func previewView(for entry: CatalogEntry) -> AnyView {
        let widget = KatagamiCode("swift build --product shi", inline: false)
        return renderOrFallback(widget, fallback:
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
        let widget = KatagamiImage(source: .systemSymbol("photo"), terminalFallback: "[image]")
        return renderOrFallback(widget, fallback: Image(systemName: "photo").font(.largeTitle))
    }
}

// katagami.link
struct KPPLinkProvider: WidgetPreviewProvider {
    @MainActor func previewView(for entry: CatalogEntry) -> AnyView {
        let widget = KatagamiLink(href: "https://shikki.io", label: "shikki.io", target: .blank)
        return renderOrFallback(widget, fallback:
            Link("shikki.io", destination: URL(string: "https://shikki.io")!)
                .font(.body)
        )
    }
}

// katagami.button
struct KPPButtonProvider: WidgetPreviewProvider {
    @MainActor func previewView(for entry: CatalogEntry) -> AnyView {
        let widget = KatagamiButton("Click me") { }
        return renderOrFallback(widget, fallback:
            Button("Click me") { }
                .buttonStyle(.borderedProminent)
        )
    }
}

// katagami.textfield
struct KPPTextFieldProvider: WidgetPreviewProvider {
    @MainActor func previewView(for entry: CatalogEntry) -> AnyView {
        // KatagamiTextField requires a KatagamiBinding.
        // For preview purposes provide a read-only constant binding.
        let binding = KatagamiBinding<String>(
            get: { "Sample input" },
            set: { _ in }            // no-op set — preview only
        )
        let widget = KatagamiTextField(placeholder: "Enter text…", text: binding)
        return renderOrFallback(widget, fallback:
            TextField("Enter text…", text: .constant("Sample input"))
                .textFieldStyle(.roundedBorder)
        )
    }
}

// katagami.linebreak
struct KPPLineBreakProvider: WidgetPreviewProvider {
    @MainActor func previewView(for entry: CatalogEntry) -> AnyView {
        // KatagamiLineBreak is most meaningful inline. Show it in context.
        let widget = KatagamiVStack {
            KatagamiText("Line one")
            KatagamiLineBreak()
            KatagamiText("Line two (after line break)")
        }
        return renderOrFallback(widget, fallback:
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
        let widget = KatagamiInlineGroup {
            KatagamiText("Runs on ")
            KatagamiStrong("YOUR")
            KatagamiText(" machine")
        }
        return renderOrFallback(widget, fallback:
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
        let widget = KMarquee(text: "Copied!", durationMs: 1500)
        return renderOrFallback(widget, fallback:
            Text("Copied!")
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
        let widget = KatagamiHStack(spacing: 12) {
            KatagamiText("A")
            KatagamiText("B")
            KatagamiText("C")
        }
        return renderOrFallback(widget, fallback:
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
        let widget = KatagamiVStack(alignment: .leading, spacing: 8) {
            KatagamiText("Top item")
            KatagamiText("Middle item")
            KatagamiText("Bottom item")
        }
        return renderOrFallback(widget, fallback:
            VStack(alignment: .leading, spacing: 8) {
                ForEach(["Top item", "Middle item", "Bottom item"], id: \.self) { Text($0) }
            }
        )
    }
}

// katagami.zstack
struct KPPZStackProvider: WidgetPreviewProvider {
    @MainActor func previewView(for entry: CatalogEntry) -> AnyView {
        let widget = KatagamiZStack {
            KatagamiText("Background layer")
            KatagamiText("  Foreground overlay  ")
        }
        return renderOrFallback(widget, fallback:
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
        let widget = KatagamiGrid(columns: 3, rowSpacing: 8, columnSpacing: 8) {
            KatagamiText("1")
            KatagamiText("2")
            KatagamiText("3")
            KatagamiText("4")
            KatagamiText("5")
            KatagamiText("6")
        }
        return renderOrFallback(widget, fallback:
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
        let widget = KatagamiScrollView(.vertical) {
            KatagamiVStack(spacing: 8) {
                KatagamiText("Scroll item 1")
                KatagamiText("Scroll item 2")
                KatagamiText("Scroll item 3")
                KatagamiText("Scroll item 4")
                KatagamiText("Scroll item 5")
            }
        }
        return renderOrFallback(widget, fallback:
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
        // KatagamiSpacer is meaningful only in context — show it between labels.
        let widget = KatagamiHStack {
            KatagamiText("Left")
            KatagamiSpacer()
            KatagamiText("Right")
        }
        return renderOrFallback(widget, fallback:
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
        // Show the drawer in its open state so the content is visible.
        let widget = KatagamiDrawer(side: .leading, isOpen: true) {
            KatagamiVStack(spacing: 8) {
                KatagamiText("Drawer content")
                KatagamiText("Side: leading, isOpen: true")
            }
        }
        return renderOrFallback(widget, fallback:
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
        let widget = KViewport(content: {
            KatagamiText("Viewport content · fullscreen=false")
        }, fullscreen: false)
        return renderOrFallback(widget, fallback:
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
        let widget = KatagamiSemantic(.section) {
            KatagamiText("KatagamiSemantic(.section) — renders as <section>…</section>")
        }
        return renderOrFallback(widget, fallback:
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
        let slides: [KatagamiAnyView] = [
            KatagamiAnyView(KatagamiText("Slide 1")),
            KatagamiAnyView(KatagamiText("Slide 2")),
            KatagamiAnyView(KatagamiText("Slide 3")),
        ]
        let widget = KSwipeContainer(slides: slides, pagerStyle: .bullets)
        return renderOrFallback(widget, fallback:
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
        let widget = KatagamiAsyncImage(
            url: URL(string: "https://picsum.photos/120/80")!,
            placeholder: "loading…"
        )
        return renderOrFallback(widget, fallback:
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
        let widget = KatagamiBadge(text: "NEW")
        return renderOrFallback(widget, fallback:
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
        let widget = KatagamiOverlayMarker(anchor: .topTrailing, size: 40) {
            KatagamiText("●")
        }
        return renderOrFallback(widget, fallback:
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
        let widget = KatagamiQRCode(
            content: "https://shikki.io",
            sizePoints: 120,
            accessibilityLabel: "QR code for shikki.io"
        )
        return renderOrFallback(widget, fallback:
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
        let widget = KatagamiShadowedCard(cornerRadius: 12, shadowRadius: 6) {
            KatagamiVStack(alignment: .leading, spacing: 6) {
                KatagamiText("ShadowedCard")
                KatagamiText("cornerRadius: 12 · shadowRadius: 6")
            }
        }
        return renderOrFallback(widget, fallback:
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
