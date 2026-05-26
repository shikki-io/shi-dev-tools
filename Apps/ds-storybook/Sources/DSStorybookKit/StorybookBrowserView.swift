// StorybookBrowserView.swift — DSStorybookKit
//
// W5.0c: Browse mode — NavigationSplitView with sidebar (entry list)
// and detail pane (native widget preview via WidgetPreviewRegistry).
//
// NP-1: Primitives Showcase — new "Primitives" sidebar section above
// the per-client widget catalog. Q1 default: PrimitiveCatalog.all when
// manifest is empty (no --catalog passed).
// NP-3: CodeBlockView embedded in StorybookDetailView below Preview,
// above Description. Renders entry.codeSnippet or auto-derived fallback.
//
// Does not import SMWidgets or any external widget package.
// Preview is delegated to WidgetPreviewRegistry registered providers.

import SwiftUI

// MARK: - StorybookBrowserView

/// Top-level browse view for the ds-storybook app.
///
/// Sidebar sections (in order):
///   1. Primitives — 28 Katagami canonical primitives (always shown; Q1 default when no --catalog)
///   2. Widgets — per-client CatalogEntry list (shown only when --catalog loaded non-empty)
///
/// Detail: registered WidgetPreviewProvider.previewView(for:) result.
/// Defaults to first primitive on launch.
public struct StorybookBrowserView: View {
    public let manifest: CatalogManifest
    @State private var selectedID: String?

    /// The active detail item, resolved from selectedID across both primitive and widget entries.
    private var activeEntry: CatalogEntry? {
        guard let id = selectedID else { return nil }
        // Check primitives first (id is e.g. "KatagamiText")
        if let primitive = PrimitiveCatalog.all.first(where: { $0.id == id }) {
            return primitive.catalogEntry()
        }
        // Then widget catalog
        return manifest.entries.first(where: { $0.id == id })
    }

    public init(manifest: CatalogManifest) {
        self.manifest = manifest
    }

    public var body: some View {
        NavigationSplitView {
            List(selection: $selectedID) {
                // MARK: Primitives Section (NP-1 — always shown above widgets)
                Section("Primitives") {
                    ForEach(PrimitiveCatalog.all) { primitive in
                        PrimitiveSidebarRow(primitive: primitive)
                            .tag(primitive.id)
                    }
                }

                // MARK: Widgets Section (only when catalog loaded)
                if !manifest.entries.isEmpty {
                    Section("Widgets") {
                        ForEach(manifest.entries) { entry in
                            StorybookSidebarRow(entry: entry)
                                .tag(entry.id)
                        }
                    }
                }
            }
            .navigationTitle("ds-storybook")
            .navigationSubtitle(subtitleText)
        } detail: {
            if let entry = activeEntry {
                StorybookDetailView(entry: entry)
            } else {
                ContentUnavailableView(
                    "No catalog loaded",
                    systemImage: "rectangle.stack",
                    description: Text("Pass --catalog <path> to load a widget manifest.")
                )
            }
        }
        .onAppear {
            if selectedID == nil {
                // Q1 default: select first primitive
                selectedID = PrimitiveCatalog.all.first?.id
            }
        }
    }

    private var subtitleText: String {
        let wCount = manifest.entryCount
        let pCount = PrimitiveCatalog.all.count
        if wCount > 0 {
            return "\(pCount) primitives · \(wCount) widget\(wCount == 1 ? "" : "s")"
        }
        return "\(pCount) primitives"
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
