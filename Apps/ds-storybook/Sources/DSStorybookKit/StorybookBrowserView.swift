// StorybookBrowserView.swift — DSStorybookKit
//
// W5.0c: Browse mode — NavigationSplitView with sidebar (entry list)
// and detail pane (native widget preview via WidgetPreviewRegistry).
//
// NP-1: Primitives Showcase — new "Primitives" sidebar section above
// the per-client widget catalog. Q1 default: PrimitiveCatalog.all when
// manifest is empty (no --catalog passed).
// NP-2: Token Inspector sidebar section below the Widgets section.
// Q4 Option A fast-path: sidebar SECTION, not TabView mode.
// Q3: renders ONLY the catalog's brand (sigma by default).
// NP-3: CodeBlockView embedded in StorybookDetailView below Preview,
// above Description. Renders entry.codeSnippet or auto-derived fallback.
//
// Does not import SMWidgets or any external widget package.
// Preview is delegated to WidgetPreviewRegistry registered providers.

import SwiftUI

// MARK: - SidebarSelection

/// Unified selection type covering primitives, widget entries, and the Token Inspector.
enum SidebarSelection: Hashable {
    case primitive(String)
    case entry(String)
    case tokenInspector
}

// MARK: - StorybookBrowserView

/// Top-level browse view for the ds-storybook app.
///
/// Sidebar sections (in order):
///   1. Primitives — 28 Katagami canonical primitives (always shown; Q1 default when no --catalog)
///   2. Widgets — per-client CatalogEntry list (shown only when --catalog loaded non-empty)
///   3. Design Tokens — DSKintsugi token inspector (Q4 Option A sidebar section)
///
/// Detail: registered WidgetPreviewProvider.previewView(for:) result, or TokenInspectorView.
/// Defaults to first primitive on launch.
public struct StorybookBrowserView: View {
    public let manifest: CatalogManifest
    @State private var selection: SidebarSelection?

    /// Brand resolved from the catalog brand hint (catalog id prefix heuristic).
    private var resolvedBrand: TokenBrand {
        let hint = manifest.entries.first?.widgetKind ?? "sigma"
        return TokenBrand.resolve(from: hint)
    }

    /// The active CatalogEntry (nil when tokenInspector is selected or nothing selected).
    private var activeEntry: CatalogEntry? {
        switch selection {
        case .primitive(let id):
            return PrimitiveCatalog.all.first(where: { $0.id == id })?.catalogEntry()
        case .entry(let id):
            return manifest.entries.first(where: { $0.id == id })
        default:
            return nil
        }
    }

    public init(manifest: CatalogManifest) {
        self.manifest = manifest
    }

    public var body: some View {
        NavigationSplitView {
            List(selection: $selection) {
                // MARK: Primitives Section (NP-1 — always shown above widgets)
                Section("Primitives") {
                    ForEach(PrimitiveCatalog.all) { primitive in
                        PrimitiveSidebarRow(primitive: primitive)
                            .tag(SidebarSelection.primitive(primitive.id))
                    }
                }

                // MARK: Widgets Section (only when catalog loaded)
                if !manifest.entries.isEmpty {
                    Section("Widgets") {
                        ForEach(manifest.entries) { entry in
                            StorybookSidebarRow(entry: entry)
                                .tag(SidebarSelection.entry(entry.id))
                        }
                    }
                }

                // MARK: Token Inspector section (NP-2 Q4)
                Section("Design Tokens") {
                    Label("Token Inspector", systemImage: "paintpalette")
                        .tag(SidebarSelection.tokenInspector)
                }
            }
            .navigationTitle("ds-storybook")
            .navigationSubtitle(subtitleText)
        } detail: {
            detailPane
        }
        .onAppear {
            if selection == nil {
                // Q1 default: select first primitive
                selection = .primitive(PrimitiveCatalog.all.first?.id ?? "")
            }
        }
    }

    private var subtitleText: String {
        let wCount = manifest.entryCount
        let pCount = PrimitiveCatalog.all.count
        if wCount > 0 {
            return "\(pCount) primitives · \(wCount) widget\(wCount == 1 ? "" : "s") · \(resolvedBrand.displayName)"
        }
        return "\(pCount) primitives"
    }

    @ViewBuilder
    private var detailPane: some View {
        switch selection {
        case .primitive(let id):
            if let entry = PrimitiveCatalog.all.first(where: { $0.id == id })?.catalogEntry() {
                StorybookDetailView(entry: entry)
            } else {
                noSelectionView
            }
        case .entry(let id):
            if let entry = manifest.entries.first(where: { $0.id == id }) {
                StorybookDetailView(entry: entry)
            } else {
                noSelectionView
            }
        case .tokenInspector:
            TokenInspectorView(brand: resolvedBrand)
        case nil:
            noSelectionView
        }
    }

    @ViewBuilder
    private var noSelectionView: some View {
        ContentUnavailableView(
            "No catalog loaded",
            systemImage: "rectangle.stack",
            description: Text("Pass --catalog <path> to load a widget manifest.")
        )
    }
}

// MARK: - PrimitiveSidebarRow

struct PrimitiveSidebarRow: View {
    let primitive: PrimitiveEntry

    var body: some View {
        VStack(alignment: .leading, spacing: 2) {
            HStack {
                Image(systemName: primitive.tier.systemImage)
                    .font(.caption2)
                    .foregroundStyle(tierColor)
                    .frame(width: 14)
                Text(primitive.displayName)
                    .font(.body)
                Spacer()
                Text(primitive.tier.rawValue)
                    .font(.caption2)
                    .foregroundStyle(.secondary)
                    .padding(.horizontal, 4)
                    .padding(.vertical, 1)
                    .background(tierColor.opacity(0.12), in: RoundedRectangle(cornerRadius: 3))
            }
            Text(primitive.widgetKind)
                .font(.caption)
                .foregroundStyle(.secondary)
                .padding(.leading, 18)
        }
        .padding(.vertical, 2)
    }

    private var tierColor: Color {
        switch primitive.tier {
        case .atom:      .blue
        case .layout:    .green
        case .component: .orange
        case .composite: .purple
        }
    }
}

// MARK: - StorybookSidebarRow

struct StorybookSidebarRow: View {
    let entry: CatalogEntry

    var body: some View {
        VStack(alignment: .leading, spacing: 2) {
            HStack {
                Text(entry.displayName)
                    .font(.body)
                Spacer()
                Text("W\(entry.wave)")
                    .font(.caption2)
                    .foregroundStyle(.secondary)
                    .padding(.horizontal, 4)
                    .padding(.vertical, 1)
                    .background(.secondary.opacity(0.15), in: RoundedRectangle(cornerRadius: 3))
            }
            Text(entry.widgetKind)
                .font(.caption)
                .foregroundStyle(.secondary)
        }
        .padding(.vertical, 2)
    }
}

// MARK: - StorybookDetailView

struct StorybookDetailView: View {
    let entry: CatalogEntry

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 20) {
                // Header
                VStack(alignment: .leading, spacing: 4) {
                    Text(entry.displayName)
                        .font(.largeTitle.bold())
                    HStack(spacing: 8) {
                        Label(entry.widgetKind, systemImage: "rectangle.3.group")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                        if entry.ssimStatus == "primitive" {
                            Label("Primitive", systemImage: "circle.fill")
                                .font(.caption)
                                .foregroundStyle(.blue)
                        } else {
                            Label("Wave \(entry.wave)", systemImage: "wave.3.right")
                                .font(.caption)
                                .foregroundStyle(.secondary)
                        }
                    }
                }

                Divider()

                // Live preview
                Text("Preview")
                    .font(.headline)

                previewContent
                    .frame(maxWidth: .infinity, minHeight: 120, alignment: .topLeading)
                    .background(.secondary.opacity(0.06), in: RoundedRectangle(cornerRadius: 12))
                    .overlay(
                        RoundedRectangle(cornerRadius: 12)
                            .stroke(.secondary.opacity(0.2), lineWidth: 1)
                    )

                Divider()

                // NP-3: Code Block — paste-ready Swift DSL snippet
                Text("Swift DSL")
                    .font(.headline)

                CodeBlockView(snippet: entry.codeSnippet, widgetKind: entry.widgetKind)
                    .frame(minHeight: 80)

                Divider()

                // Description
                Text("Description")
                    .font(.headline)
                Text(entry.description)
                    .font(.body)
                    .foregroundStyle(.secondary)

                Divider()

                // Primitives
                Text("Katagami Primitives")
                    .font(.headline)

                FlowLayout(spacing: 6) {
                    ForEach(entry.primitiveList, id: \.self) { primitive in
                        Text(primitive)
                            .font(.caption.monospaced())
                            .padding(.horizontal, 8)
                            .padding(.vertical, 3)
                            .background(.tint.opacity(0.12), in: RoundedRectangle(cornerRadius: 5))
                    }
                }
            }
            .padding(24)
        }
        .navigationTitle(entry.displayName)
    }

    @MainActor
    @ViewBuilder
    private var previewContent: some View {
        let registry = WidgetPreviewRegistry.shared
        if let provider = registry.provider(for: entry.widgetKind) {
            provider.previewView(for: entry)
                .padding()
        } else {
            FallbackPreviewProvider().previewView(for: entry)
        }
    }
}

// FlowLayout is defined in WidgetPreviewProvider.swift (shared within DSStorybookKit).
