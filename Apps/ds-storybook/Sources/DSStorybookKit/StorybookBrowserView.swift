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
// NP-4: KatagamiPrimitivePreviewBridge wired into app init — all 28
// primitives show real content, not orange fallback.
//
// UX Upgrade:
//   D2: DisclosureGroup collapsible sections (Primitives nested by tier)
//       with @AppStorage state persistence.
//   D3: CatalogCrossReferences "Used In" / "Related" section at bottom
//       of detail view with clickable NavigationStack navigation.
//   D4: User Widgets DisclosureGroup — drops from ~/.shikki/storybook/user-widgets/
//       appear within 2s via FileMonitor; FallbackPreviewView + "Register Provider"
//       hint for unregistered widgetKinds.
//
// Does not import SMWidgets or any external widget package.
// Preview is delegated to WidgetPreviewRegistry registered providers.

import SwiftUI

// MARK: - SidebarSelection

/// Unified selection type covering primitives, widget entries, and the Token Inspector.
public enum SidebarSelection: Hashable {
    case primitive(String)
    case entry(String)
    case userWidget(String)
    case tokenInspector
}

// MARK: - StorybookBrowserView

/// Top-level browse view for the ds-storybook app.
///
/// Sidebar sections (in order):
///   1. Primitives — 28 Katagami canonical primitives, collapsible per tier
///   2. Widgets — per-client CatalogEntry list (shown only when --catalog loaded)
///   3. User Widgets — operator-dropped JSONs from ~/.shikki/storybook/user-widgets/
///   4. Design Tokens — DSKintsugi token inspector
///
/// Sections are collapsible (DisclosureGroup) with @AppStorage persistence.
public struct StorybookBrowserView: View {
    public let manifest: CatalogManifest
    @ObservedObject public var userCatalog: UserWidgetCatalog
    @State private var selection: SidebarSelection?

    // MARK: D2: DisclosureGroup expansion state (@AppStorage — survives restart)
    @AppStorage("sb.section.primitives.atoms")      private var atomsExpanded      = true
    @AppStorage("sb.section.primitives.layout")     private var layoutExpanded     = true
    @AppStorage("sb.section.primitives.components") private var componentsExpanded = true
    @AppStorage("sb.section.primitives.composites") private var compositesExpanded = true
    @AppStorage("sb.section.primitives")            private var primitivesExpanded = true
    @AppStorage("sb.section.widgets")               private var widgetsExpanded    = true
    @AppStorage("sb.section.userwidgets")           private var userWidgetsExpanded = true
    @AppStorage("sb.section.tokens")                private var tokensExpanded     = true

    /// Brand resolved from the catalog brand hint (catalog id prefix heuristic).
    private var resolvedBrand: TokenBrand {
        let hint = manifest.entries.first?.widgetKind ?? "sigma"
        return TokenBrand.resolve(from: hint)
    }

    public init(manifest: CatalogManifest, userCatalog: UserWidgetCatalog? = nil) {
        self.manifest = manifest
        self.userCatalog = userCatalog ?? UserWidgetCatalog()
    }

    // Merged allEntries for cross-ref engine: primitives + widgets + user widgets
    private var allEntriesForCrossRef: [CatalogEntry] {
        PrimitiveCatalog.all.map { $0.catalogEntry() } + manifest.entries + userCatalog.entries
    }

    public var body: some View {
        NavigationSplitView {
            List(selection: $selection) {
                // MARK: D2: Primitives — collapsible with nested tier groups
                Section {
                    DisclosureGroup(isExpanded: $primitivesExpanded) {

                        DisclosureGroup(isExpanded: $atomsExpanded) {
                            ForEach(PrimitiveCatalog.atoms) { primitive in
                                PrimitiveSidebarRow(primitive: primitive)
                                    .tag(SidebarSelection.primitive(primitive.id))
                            }
                        } label: {
                            Label("Atoms (\(PrimitiveCatalog.atoms.count))", systemImage: "circle.fill")
                                .font(.subheadline)
                                .foregroundStyle(.blue)
                        }

                        DisclosureGroup(isExpanded: $layoutExpanded) {
                            ForEach(PrimitiveCatalog.layouts) { primitive in
                                PrimitiveSidebarRow(primitive: primitive)
                                    .tag(SidebarSelection.primitive(primitive.id))
                            }
                        } label: {
                            Label("Layout (\(PrimitiveCatalog.layouts.count))", systemImage: "rectangle.split.3x1")
                                .font(.subheadline)
                                .foregroundStyle(.green)
                        }

                        DisclosureGroup(isExpanded: $componentsExpanded) {
                            ForEach(PrimitiveCatalog.components) { primitive in
                                PrimitiveSidebarRow(primitive: primitive)
                                    .tag(SidebarSelection.primitive(primitive.id))
                            }
                        } label: {
                            Label("Components (\(PrimitiveCatalog.components.count))", systemImage: "square.3.layers.3d")
                                .font(.subheadline)
                                .foregroundStyle(.orange)
                        }

                        DisclosureGroup(isExpanded: $compositesExpanded) {
                            ForEach(PrimitiveCatalog.composites) { primitive in
                                PrimitiveSidebarRow(primitive: primitive)
                                    .tag(SidebarSelection.primitive(primitive.id))
                            }
                        } label: {
                            Label("Composites (\(PrimitiveCatalog.composites.count))", systemImage: "cube.fill")
                                .font(.subheadline)
                                .foregroundStyle(.purple)
                        }

                    } label: {
                        Label("Primitives (\(PrimitiveCatalog.all.count))", systemImage: "square.stack")
                            .font(.headline)
                    }
                }

                // MARK: D2: Widgets — collapsible (only when catalog loaded)
                if !manifest.entries.isEmpty {
                    Section {
                        DisclosureGroup(isExpanded: $widgetsExpanded) {
                            ForEach(manifest.entries) { entry in
                                StorybookSidebarRow(entry: entry)
                                    .tag(SidebarSelection.entry(entry.id))
                            }
                        } label: {
                            Label("Widgets (\(manifest.entryCount))", systemImage: "rectangle.3.group")
                                .font(.headline)
                        }
                    }
                }

                // MARK: D4: User Widgets — operator-dropped JSONs
                Section {
                    DisclosureGroup(isExpanded: $userWidgetsExpanded) {
                        if userCatalog.entries.isEmpty {
                            Text("Drop JSON files in\n~/.shikki/storybook/user-widgets/")
                                .font(.caption)
                                .foregroundStyle(.secondary)
                                .padding(.vertical, 4)
                        } else {
                            ForEach(userCatalog.entries) { entry in
                                StorybookSidebarRow(entry: entry)
                                    .tag(SidebarSelection.userWidget(entry.id))
                            }
                        }
                    } label: {
                        HStack {
                            Label("User Widgets", systemImage: "person.badge.plus")
                                .font(.headline)
                            if !userCatalog.entries.isEmpty {
                                Text("(\(userCatalog.entries.count))")
                                    .font(.caption)
                                    .foregroundStyle(.secondary)
                            }
                        }
                    }
                }

                // MARK: D2: Design Tokens — collapsible
                Section {
                    DisclosureGroup(isExpanded: $tokensExpanded) {
                        Label("Token Inspector", systemImage: "paintpalette")
                            .tag(SidebarSelection.tokenInspector)
                    } label: {
                        Label("Design Tokens", systemImage: "circle.hexagongrid")
                            .font(.headline)
                    }
                }
            }
            .navigationTitle("ds-storybook")
            .navigationSubtitle(subtitleText)
        } detail: {
            detailPane
        }
        .onAppear {
            if selection == nil {
                selection = .primitive(PrimitiveCatalog.all.first?.id ?? "")
            }
        }
    }

    private var subtitleText: String {
        let wCount = manifest.entryCount
        let uCount = userCatalog.entries.count
        let pCount = PrimitiveCatalog.all.count
        var parts = ["\(pCount) primitives"]
        if wCount > 0 { parts.append("\(wCount) widget\(wCount == 1 ? "" : "s")") }
        if uCount > 0 { parts.append("\(uCount) user") }
        parts.append(resolvedBrand.displayName)
        return parts.joined(separator: " · ")
    }

    @ViewBuilder
    private var detailPane: some View {
        switch selection {
        case .primitive(let id):
            if let entry = PrimitiveCatalog.all.first(where: { $0.id == id })?.catalogEntry() {
                StorybookDetailView(entry: entry, allEntries: allEntriesForCrossRef, onNavigate: { ref in
                    navigateTo(ref: ref)
                })
            } else {
                noSelectionView
            }
        case .entry(let id):
            if let entry = manifest.entries.first(where: { $0.id == id }) {
                StorybookDetailView(entry: entry, allEntries: allEntriesForCrossRef, onNavigate: { ref in
                    navigateTo(ref: ref)
                })
            } else {
                noSelectionView
            }
        case .userWidget(let id):
            if let entry = userCatalog.entries.first(where: { $0.id == id }) {
                StorybookDetailView(entry: entry, allEntries: allEntriesForCrossRef, onNavigate: { ref in
                    navigateTo(ref: ref)
                })
            } else {
                noSelectionView
            }
        case .tokenInspector:
            TokenInspectorView(brand: resolvedBrand)
        case nil:
            noSelectionView
        }
    }

    private func navigateTo(ref: CatalogRef) {
        // Resolve ref.id → SidebarSelection
        if PrimitiveCatalog.all.contains(where: { $0.id == ref.id }) {
            selection = .primitive(ref.id)
        } else if manifest.entries.contains(where: { $0.id == ref.id }) {
            selection = .entry(ref.id)
        } else if userCatalog.entries.contains(where: { $0.id == ref.id }) {
            selection = .userWidget(ref.id)
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
                Text(entry.wave == "user" ? "User" : "W\(entry.wave)")
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
    let allEntries: [CatalogEntry]
    var onNavigate: ((CatalogRef) -> Void)?

    init(entry: CatalogEntry, allEntries: [CatalogEntry] = [], onNavigate: ((CatalogRef) -> Void)? = nil) {
        self.entry = entry
        self.allEntries = allEntries
        self.onNavigate = onNavigate
    }

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
                        } else if entry.ssimStatus == "user" {
                            Label("User Widget", systemImage: "person.badge.plus")
                                .font(.caption)
                                .foregroundStyle(.teal)
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

                // D4: Register Provider hint for user widgets with no provider
                if entry.ssimStatus == "user" && !WidgetPreviewRegistry.shared.hasProvider(for: entry.widgetKind) {
                    RegisterProviderHint(widgetKind: entry.widgetKind)
                }

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

                if entry.primitiveList.isEmpty {
                    Text("—")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                } else {
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

                // MARK: D3: Cross-references section
                let refs = CatalogCrossReferences.crossRefs(for: entry, allEntries: allEntries)
                if !refs.usedIn.isEmpty || !refs.related.isEmpty {
                    Divider()
                    CrossReferencesView(
                        usedIn: refs.usedIn,
                        related: refs.related,
                        onNavigate: onNavigate
                    )
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

// MARK: - RegisterProviderHint (D4)

/// Shown below the fallback preview when a user widget has no registered provider.
struct RegisterProviderHint: View {
    let widgetKind: String

    var body: some View {
        HStack(spacing: 8) {
            Image(systemName: "info.circle")
                .foregroundStyle(.orange)
            VStack(alignment: .leading, spacing: 2) {
                Text("No preview provider registered for \"\(widgetKind)\"")
                    .font(.caption.bold())
                    .foregroundStyle(.orange)
                Text("Implement WidgetPreviewProvider and call\nWidgetPreviewRegistry.shared.register(provider: …, for: \"\(widgetKind)\") in App.init().")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
            Spacer()
        }
        .padding(10)
        .background(.orange.opacity(0.08), in: RoundedRectangle(cornerRadius: 8))
        .overlay(RoundedRectangle(cornerRadius: 8).stroke(.orange.opacity(0.2), lineWidth: 1))
    }
}

// MARK: - CrossReferencesView (D3)

/// "Used In" / "Related" section rendered at the bottom of StorybookDetailView.
/// Each ref card is tappable — calls onNavigate to drive sidebar selection.
struct CrossReferencesView: View {
    let usedIn: [CatalogRef]
    let related: [CatalogRef]
    var onNavigate: ((CatalogRef) -> Void)?

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            if !usedIn.isEmpty {
                Text("Used In")
                    .font(.headline)

                LazyVGrid(
                    columns: [GridItem(.adaptive(minimum: 140, maximum: 220), spacing: 12)],
                    alignment: .leading,
                    spacing: 12
                ) {
                    ForEach(usedIn) { ref in
                        CrossRefCard(ref: ref) {
                            onNavigate?(ref)
                        }
                    }
                }
            }

            if !related.isEmpty {
                Text("Related")
                    .font(.headline)

                LazyVGrid(
                    columns: [GridItem(.adaptive(minimum: 140, maximum: 220), spacing: 12)],
                    alignment: .leading,
                    spacing: 12
                ) {
                    ForEach(related) { ref in
                        CrossRefCard(ref: ref) {
                            onNavigate?(ref)
                        }
                    }
                }
            }
        }
    }
}

// MARK: - CrossRefCard (D3)

/// A single cross-reference card. Tappable — navigates to the referenced entry.
struct CrossRefCard: View {
    let ref: CatalogRef
    let onTap: () -> Void

    var body: some View {
        Button(action: onTap) {
            VStack(alignment: .leading, spacing: 4) {
                HStack {
                    Image(systemName: ref.widgetKind.hasPrefix("katagami.") ? "circle.fill" : "rectangle.3.group")
                        .font(.caption2)
                        .foregroundStyle(ref.refKind == .usedIn ? Color.blue : Color.teal)
                    Text(ref.displayName)
                        .font(.caption.bold())
                        .lineLimit(1)
                    Spacer()
                }
                Text(ref.widgetKind)
                    .font(.caption2.monospaced())
                    .foregroundStyle(.secondary)
                    .lineLimit(1)
            }
            .padding(.horizontal, 10)
            .padding(.vertical, 8)
            .background(.secondary.opacity(0.08), in: RoundedRectangle(cornerRadius: 8))
            .overlay(
                RoundedRectangle(cornerRadius: 8)
                    .stroke(.secondary.opacity(0.15), lineWidth: 1)
            )
        }
        .buttonStyle(.plain)
        .contentShape(RoundedRectangle(cornerRadius: 8))
    }
}

// FlowLayout is defined in WidgetPreviewProvider.swift (shared within DSStorybookKit).
