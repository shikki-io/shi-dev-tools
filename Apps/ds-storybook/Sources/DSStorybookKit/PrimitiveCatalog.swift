// PrimitiveCatalog.swift — DSStorybookKit
//
// NP-1: Static manifest of 28 Katagami primitives derived from
// FJ-Studios/shi-design/Sources/KatagamiCore/Canonical/**
//
// Tiers:
//   Atom       ×13  — leaf nodes with no child primitives
//   Layout     ×10  — structural container nodes
//   Component  × 4  — higher-level composed nodes
//   Composite  × 1  — full feature composites (CopySnippet)
//
// Usage:
//   // No --catalog flag: default to PrimitiveCatalog.all (Q1 default)
//   let manifest = PrimitiveCatalog.manifest

import Foundation

// MARK: - PrimitiveTier

/// Taxonomy tier for a Katagami canonical primitive.
public enum PrimitiveTier: String, Sendable, CaseIterable, Codable {
    case atom      = "Atom"
    case layout    = "Layout"
    case component = "Component"
    case composite = "Composite"

    /// SF Symbol for sidebar decoration.
    public var systemImage: String {
        switch self {
        case .atom:      "circle.fill"
        case .layout:    "rectangle.split.3x1"
        case .component: "square.3.layers.3d"
        case .composite: "cube.fill"
        }
    }
}

// MARK: - PrimitiveEntry

/// A single Katagami primitive shown in the Primitives Showcase sidebar section.
///
/// Mirrors `CatalogEntry` but carries `tier` and `codeSnippet` natively
/// (primitives are statically known; no JSON file needed).
public struct PrimitiveEntry: Sendable, Identifiable {
    public let id: String
    public let displayName: String
    public let widgetKind: String
    public let description: String
    /// Own structural dependencies (child primitive types).
    public let primitives: [String]
    public let tier: PrimitiveTier
    /// Paste-ready Swift DSL invocation.
    public let codeSnippet: String

    public init(
        id: String,
        displayName: String,
        widgetKind: String,
        description: String,
        primitives: [String] = [],
        tier: PrimitiveTier,
        codeSnippet: String
    ) {
        self.id = id
        self.displayName = displayName
        self.widgetKind = widgetKind
        self.description = description
        self.primitives = primitives
        self.tier = tier
        self.codeSnippet = codeSnippet
    }

    /// Convert to a CatalogEntry so the existing browse/detail views work unchanged.
    ///
    /// NP-5 fix: codeSnippet is forwarded so CodeBlockView renders the
    /// paste-ready snippet instead of the "No code snippet defined" fallback.
    public func catalogEntry() -> CatalogEntry {
        CatalogEntry(
            id: id,
            widgetKind: widgetKind,
            displayName: displayName,
            description: description,
            primitives: primitives.joined(separator: ","),
            wave: "0",
            ssimStatus: "primitive",
            codeSnippet: codeSnippet
        )
    }
}

// MARK: - PrimitiveCatalog

/// Static manifest of all 28 Katagami canonical primitives.
public enum PrimitiveCatalog {

    // MARK: Atoms (13)

    public static let atoms: [PrimitiveEntry] = [
        PrimitiveEntry(
            id: "KatagamiText",
            displayName: "Text",
            widgetKind: "katagami.text",
            description: "Inline text node. The leaf-level text primitive; styled by Theme tokens and WSTypeScale.",
            tier: .atom,
            codeSnippet: #"KatagamiText("The quick brown fox jumps over the lazy dog")"#
        ),
        PrimitiveEntry(
            id: "KatagamiHeading",
            displayName: "Heading",
            widgetKind: "katagami.heading",
            description: "Section heading with semantic level (h1–h6). Renders at the scale defined by Theme.typeScale.",
            tier: .atom,
            codeSnippet: #"KatagamiHeading(.h1, "Section Title")"#
        ),
        PrimitiveEntry(
            id: "KatagamiParagraph",
            displayName: "Paragraph",
            widgetKind: "katagami.paragraph",
            description: "Block-level text paragraph. Wraps KatagamiText children with paragraph spacing.",
            primitives: ["KatagamiText"],
            tier: .atom,
            codeSnippet: #"KatagamiParagraph("Long-form body text with multiple lines.")"#
        ),
        PrimitiveEntry(
            id: "KatagamiEmphasis",
            displayName: "Emphasis",
            widgetKind: "katagami.emphasis",
            description: "Inline italic emphasis wrapper. Maps to <em> in web; italic font weight on native.",
            primitives: ["KatagamiText"],
            tier: .atom,
            codeSnippet: #"KatagamiEmphasis("important")"#
        ),
        PrimitiveEntry(
            id: "KatagamiStrong",
            displayName: "Strong",
            widgetKind: "katagami.strong",
            description: "Inline bold emphasis wrapper. Maps to <strong> in web; semibold weight on native.",
            primitives: ["KatagamiText"],
            tier: .atom,
            codeSnippet: #"KatagamiStrong("urgent")"#
        ),
        PrimitiveEntry(
            id: "KatagamiCode",
            displayName: "Code",
            widgetKind: "katagami.code",
            description: "Monospaced inline code snippet. Renders in SF Mono on Apple platforms.",
            tier: .atom,
            codeSnippet: #"KatagamiCode("let x = 42")"#
        ),
        PrimitiveEntry(
            id: "KatagamiImage",
            displayName: "Image",
            widgetKind: "katagami.image",
            description: "Static image node. Accepts asset name or URL string; falls back to placeholder on load failure.",
            tier: .atom,
            codeSnippet: #"KatagamiImage(url: URL(string: "https://...")!)"#
        ),
        PrimitiveEntry(
            id: "KatagamiLink",
            displayName: "Link",
            widgetKind: "katagami.link",
            description: "Tappable link primitive. Triggers navigation or URL open on activation.",
            primitives: ["KatagamiText"],
            tier: .atom,
            codeSnippet: #"KatagamiLink("Read more", url: URL(string: "https://shikki.io")!)"#
        ),
        PrimitiveEntry(
            id: "KatagamiButton",
            displayName: "Button",
            widgetKind: "katagami.button",
            description: "Interactive button primitive. Renders DSKintsugi action tokens; fires action closure on tap.",
            primitives: ["KatagamiText"],
            tier: .atom,
            codeSnippet: """
            KatagamiButton("Click me") { /* action */ }
            """
        ),
        PrimitiveEntry(
            id: "KatagamiTextField",
            displayName: "TextField",
            widgetKind: "katagami.textfield",
            description: "Editable text input primitive. Binds to a string key in the widget's data bag.",
            tier: .atom,
            codeSnippet: #"KatagamiTextField(placeholder: "Enter email", text: $email)"#
        ),
        PrimitiveEntry(
            id: "KatagamiLineBreak",
            displayName: "LineBreak",
            widgetKind: "katagami.linebreak",
            description: "Explicit line-break node. Forces a vertical gap in inline content flow.",
            tier: .atom,
            codeSnippet: "KatagamiLine()"
        ),
        PrimitiveEntry(
            id: "KatagamiInlineGroup",
            displayName: "InlineGroup",
            widgetKind: "katagami.inlinegroup",
            description: "Horizontal inline wrapper for mixed text/emphasis/link content without layout semantics.",
            primitives: ["KatagamiText", "KatagamiEmphasis", "KatagamiLink"],
            tier: .atom,
            codeSnippet: "KatagamiInlineBreak()"
        ),
        PrimitiveEntry(
            id: "KatagamiMarquee",
            displayName: "Marquee",
            widgetKind: "katagami.marquee",
            description: "Horizontally scrolling ticker text. Used for live data labels and alert banners.",
            primitives: ["KatagamiText"],
            tier: .atom,
            codeSnippet: #"KatagamiMarquee("Scrolling banner text")"#
        ),
    ]

    // MARK: Layout (10)

    public static let layouts: [PrimitiveEntry] = [
        PrimitiveEntry(
            id: "KatagamiHStack",
            displayName: "HStack",
            widgetKind: "katagami.hstack",
            description: "Horizontal stack layout. Aligns children side-by-side with configurable spacing and alignment.",
            tier: .layout,
            codeSnippet: """
            KatagamiHStack(spacing: 12) {
                KatagamiText("A")
                KatagamiText("B")
                KatagamiText("C")
            }
            """
        ),
        PrimitiveEntry(
            id: "KatagamiVStack",
            displayName: "VStack",
            widgetKind: "katagami.vstack",
            description: "Vertical stack layout. Stacks children top-to-bottom with configurable spacing.",
            tier: .layout,
            codeSnippet: """
            KatagamiVStack(spacing: 8) {
                KatagamiText("Top")
                KatagamiText("Bottom")
            }
            """
        ),
        PrimitiveEntry(
            id: "KatagamiZStack",
            displayName: "ZStack",
            widgetKind: "katagami.zstack",
            description: "Z-axis (depth) stack layout. Overlays children in painter's order (first = bottom).",
            tier: .layout,
            codeSnippet: """
            KatagamiZStack {
                KatagamiText("Layer 1")
                KatagamiText("Layer 2")
            }
            """
        ),
        PrimitiveEntry(
            id: "KatagamiGrid",
            displayName: "Grid",
            widgetKind: "katagami.grid",
            description: "Adaptive 2-D grid layout. Column count resolves from viewport width and minItemWidth.",
            tier: .layout,
            codeSnippet: """
            KatagamiGrid(columns: 3, spacing: 8) {
                ForEach(1...6, id: \\.self) { KatagamiText("\\($0)") }
            }
            """
        ),
        PrimitiveEntry(
            id: "KatagamiScrollView",
            displayName: "ScrollView",
            widgetKind: "katagami.scrollview",
            description: "Scrollable container. Supports horizontal, vertical, and both-axis scroll directions.",
            tier: .layout,
            codeSnippet: """
            KatagamiScrollView(.horizontal) {
                KatagamiHStack {
                    ForEach(0..<10, id: \\.self) { ... }
                }
            }
            """
        ),
        PrimitiveEntry(
            id: "KatagamiSpacer",
            displayName: "Spacer",
            widgetKind: "katagami.spacer",
            description: "Flexible fill spacer. Expands to fill remaining space in a stack, pushing siblings apart.",
            tier: .layout,
            codeSnippet: """
            KatagamiHStack {
                KatagamiText("Left")
                KatagamiSpacer()
                KatagamiText("Right")
            }
            """
        ),
        PrimitiveEntry(
            id: "KatagamiDrawer",
            displayName: "Drawer",
            widgetKind: "katagami.drawer",
            description: "Modal drawer container. Slides in from bottom (iOS) or side (macOS); overlays content.",
            tier: .layout,
            codeSnippet: """
            KatagamiDrawer(side: .trailing, isOpen: $isOpen) {
                // content
            }
            """
        ),
        PrimitiveEntry(
            id: "KatagamiViewport",
            displayName: "Viewport",
            widgetKind: "katagami.viewport",
            description: "Root viewport node. Sets the coordinate space and safe-area insets for a widget subtree.",
            tier: .layout,
            codeSnippet: """
            KatagamiViewport(width: 375, height: 812, safeArea: .all) {
                KatagamiVStack { /* widget content */ }
            }
            """
        ),
        PrimitiveEntry(
            id: "KatagamiSemantic",
            displayName: "Semantic",
            widgetKind: "katagami.semantic",
            description: "Semantic container with ARIA-equivalent role hints. Used by a11y and screen readers.",
            tier: .layout,
            codeSnippet: """
            KatagamiSemantic(role: .navigation, label: "Main nav") {
                KatagamiHStack { /* nav items */ }
            }
            """
        ),
        PrimitiveEntry(
            id: "KatagamiSwipeContainer",
            displayName: "SwipeContainer",
            widgetKind: "katagami.swipecontainer",
            description: "Swipe-gesture host. Wraps a child and exposes leading/trailing swipe action slots.",
            tier: .layout,
            codeSnippet: """
            KatagamiSwipeContainer {
                KatagamiText("Swipe me")
            } trailingActions: {
                KatagamiButton(action: "delete") { KatagamiText("Delete") }
            }
            """
        ),
    ]

    // MARK: Components (4)

    public static let components: [PrimitiveEntry] = [
        PrimitiveEntry(
            id: "KatagamiAsyncImage",
            displayName: "AsyncImage",
            widgetKind: "katagami.asyncimage",
            description: "URL-sourced image with async loading, placeholder, and failure states.",
            tier: .component,
            codeSnippet: #"KatagamiAsyncImage(url: URL(string: "https://example.com/img.jpg")!)"#
        ),
        PrimitiveEntry(
            id: "KatagamiBadge",
            displayName: "Badge",
            widgetKind: "katagami.badge",
            description: "Pill-shaped text badge. Renders DSKintsugi semantic color tokens for status/tier indication.",
            primitives: ["KatagamiText"],
            tier: .component,
            codeSnippet: #"KatagamiBadge(text: "NEW", style: .accent)"#
        ),
        PrimitiveEntry(
            id: "KatagamiOverlayMarker",
            displayName: "OverlayMarker",
            widgetKind: "katagami.overlaymarker",
            description: "Positioned overlay chip for labelling images and cards (e.g. 'SALE', 'NEW'). Anchored via alignment.",
            primitives: ["KatagamiText"],
            tier: .component,
            codeSnippet: "KatagamiOverlayMarker(size: 48, color: .accentColor)"
        ),
        PrimitiveEntry(
            id: "KatagamiQRMarker",
            displayName: "QRMarker",
            widgetKind: "katagami.qrmarker",
            description: "QR code renderer. Encodes a URL string to a scannable QR image with configurable size.",
            tier: .component,
            codeSnippet: #"KatagamiQRCode(payload: "https://example.com/deep-link")"#
        ),
    ]

    // MARK: Composites (1)

    public static let composites: [PrimitiveEntry] = [
        PrimitiveEntry(
            id: "KatagamiShadowedCard",
            displayName: "ShadowedCard",
            widgetKind: "katagami.shadowedcard",
            description: "Elevated content card with DSKintsugi shadow tokens. The canonical container for widget cards across all brands.",
            primitives: ["KatagamiVStack", "KatagamiHStack"],
            tier: .composite,
            codeSnippet: """
            KatagamiShadowedCard(elevation: .medium) {
                KatagamiVStack(spacing: 8) {
                    KatagamiHeading(.h3, "Card Title")
                    KatagamiText("Card body text.")
                }
            }
            """
        ),
    ]

    // MARK: All

    /// All 28 primitives in tier order: Atom → Layout → Component → Composite.
    public static let all: [PrimitiveEntry] = atoms + layouts + components + composites

    /// CatalogManifest built from all 28 primitives. Used as Q1 default when --catalog not passed.
    public static let manifest: CatalogManifest = CatalogManifest(
        entries: all.map { $0.catalogEntry() }
    )
}
