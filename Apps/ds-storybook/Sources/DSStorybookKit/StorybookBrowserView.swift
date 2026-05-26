// StorybookBrowserView.swift — DSStorybookKit
//
// W5.0c: Browse mode — NavigationSplitView with sidebar (entry list)
// and detail pane (native widget preview via WidgetPreviewRegistry).
//
// Does not import SMWidgets or any external widget package.
// Preview is delegated to WidgetPreviewRegistry registered providers.

import SwiftUI

// MARK: - StorybookBrowserView

/// Top-level browse view for the ds-storybook app.
///
/// Sidebar: list of CatalogEntry names.
/// Detail: registered WidgetPreviewProvider.previewView(for:) result.
/// Defaults to first entry on launch.
public struct StorybookBrowserView: View {
    public let manifest: CatalogManifest
    @State private var selectedID: String?

    public init(manifest: CatalogManifest) {
        self.manifest = manifest
    }

    public var body: some View {
        NavigationSplitView {
            List(manifest.entries, selection: $selectedID) { entry in
                StorybookSidebarRow(entry: entry)
                    .tag(entry.id)
            }
            .navigationTitle("ds-storybook")
            .navigationSubtitle("\(manifest.entryCount) widget\(manifest.entryCount == 1 ? "" : "s")")
        } detail: {
            if let id = selectedID,
               let entry = manifest.entries.first(where: { $0.id == id }) {
                StorybookDetailView(entry: entry)
            } else if let first = manifest.entries.first {
                StorybookDetailView(entry: first)
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
                selectedID = manifest.entries.first?.id
            }
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
                        Label("Wave \(entry.wave)", systemImage: "wave.3.right")
                            .font(.caption)
                            .foregroundStyle(.secondary)
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
