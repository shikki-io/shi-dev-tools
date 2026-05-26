// SettingsView.swift — DSStorybookKit
//
// Settings scene (macOS Cmd+,) for ds-storybook.
//
// Tabs:
//   1. Projects  — list + add/edit/delete projects; maps to ProjectRegistry.
//   2. Defaults  — window size preference, dark/light preference, auto-reemit.
//   3. Tokens    — default brand for Token Inspector.
//
// Registered as a Settings scene in DSStorybookApp.swift.
// ProjectRegistry is passed in as an @ObservedObject so mutations drive
// the toolbar picker in real time.

import SwiftUI

// MARK: - SettingsView (tab container)

/// Tabbed Settings panel. Opened via Cmd+, on macOS.
public struct SettingsView: View {
    @ObservedObject public var registry: ProjectRegistry

    public init(registry: ProjectRegistry) {
        self.registry = registry
    }

    public var body: some View {
        TabView {
            ProjectsSettingsTab(registry: registry)
                .tabItem { Label("Projects", systemImage: "folder.badge.gearshape") }

            DefaultsSettingsTab()
                .tabItem { Label("Defaults", systemImage: "slider.horizontal.3") }

            TokensSettingsTab(registry: registry)
                .tabItem { Label("Tokens", systemImage: "paintpalette") }
        }
        .frame(minWidth: 600, minHeight: 400)
    }
}

// MARK: - ProjectsSettingsTab

/// Projects tab: list of registered projects with add / edit / delete.
struct ProjectsSettingsTab: View {
    @ObservedObject var registry: ProjectRegistry
    @State private var selectedSlug: String?
    @State private var showingAddSheet = false
    @State private var editingProject: ProjectRecord?

    var body: some View {
        VStack(spacing: 0) {
            // Header
            HStack {
                Text("Registered Projects")
                    .font(.headline)
                Spacer()
                Button {
                    showingAddSheet = true
                } label: {
                    Label("Add Project", systemImage: "plus")
                }
                .buttonStyle(.borderedProminent)
                .controlSize(.small)
            }
            .padding([.horizontal, .top], 16)
            .padding(.bottom, 8)

            Divider()

            // Project list
            List(registry.projects, selection: $selectedSlug) { project in
                ProjectRow(
                    project: project,
                    isActive: project.slug == registry.activeProjectSlug,
                    onEdit: { editingProject = project },
                    onSetActive: { registry.setActive(slug: project.slug) },
                    onDelete: {
                        registry.remove(slug: project.slug)
                        if selectedSlug == project.slug { selectedSlug = nil }
                    }
                )
                .tag(project.slug)
            }
            .listStyle(.inset(alternatesRowBackgrounds: true))

            Divider()

            // Footer hint
            Text("Active project loads on launch and drives the toolbar picker.")
                .font(.caption)
                .foregroundStyle(.secondary)
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding([.horizontal, .vertical], 10)
        }
        .sheet(isPresented: $showingAddSheet) {
            AddProjectSheet(registry: registry, editingProject: nil) {
                showingAddSheet = false
            }
        }
        .sheet(item: $editingProject) { project in
            AddProjectSheet(registry: registry, editingProject: project) {
                editingProject = nil
            }
        }
    }
}

// MARK: - ProjectRow

struct ProjectRow: View {
    let project: ProjectRecord
    let isActive: Bool
    let onEdit: () -> Void
    let onSetActive: () -> Void
    let onDelete: () -> Void

    var body: some View {
        HStack(spacing: 12) {
            // Active indicator
            Circle()
                .fill(isActive ? Color.green : Color.secondary.opacity(0.3))
                .frame(width: 8, height: 8)

            // Info
            VStack(alignment: .leading, spacing: 2) {
                HStack {
                    Text(project.displayName)
                        .font(.body.bold())
                    if project.isBuiltIn {
                        Text("built-in")
                            .font(.caption2)
                            .foregroundStyle(.secondary)
                            .padding(.horizontal, 5)
                            .padding(.vertical, 1)
                            .background(.secondary.opacity(0.12), in: RoundedRectangle(cornerRadius: 3))
                    }
                    Spacer()
                    brandBadge
                }
                Text(project.description)
                    .font(.caption)
                    .foregroundStyle(.secondary)
                    .lineLimit(1)
                if let path = project.catalogPath {
                    Text(path)
                        .font(.caption2.monospaced())
                        .foregroundStyle(.tertiary)
                        .lineLimit(1)
                        .truncationMode(.middle)
                }
                if let loaded = project.lastLoadedAt {
                    Text("Last loaded: \(loaded)")
                        .font(.caption2)
                        .foregroundStyle(.tertiary)
                }
            }

            // Actions
            if !isActive {
                Button("Set Active") { onSetActive() }
                    .buttonStyle(.bordered)
                    .controlSize(.mini)
            }

            if !project.isBuiltIn {
                Menu {
                    Button("Edit", action: onEdit)
                    Divider()
                    Button("Delete", role: .destructive, action: onDelete)
                } label: {
                    Image(systemName: "ellipsis.circle")
                        .foregroundStyle(.secondary)
                }
                .buttonStyle(.plain)
                .menuStyle(.borderlessButton)
                .fixedSize()
            }
        }
        .padding(.vertical, 4)
    }

    @ViewBuilder
    private var brandBadge: some View {
        Text(project.brandKey)
            .font(.caption2.monospaced())
            .foregroundStyle(.primary.opacity(0.7))
            .padding(.horizontal, 6)
            .padding(.vertical, 2)
            .background(brandColor.opacity(0.15), in: RoundedRectangle(cornerRadius: 4))
    }

    private var brandColor: Color {
        switch project.brandKey {
        case "sigma":    .red
        case "c-tech":   .blue
        case "katagami": .purple
        default:         .secondary
        }
    }
}

// MARK: - AddProjectSheet

/// Modal form for adding or editing a project.
struct AddProjectSheet: View {
    @ObservedObject var registry: ProjectRegistry
    let editingProject: ProjectRecord?
    let onDismiss: () -> Void

    // Form fields
    @State private var slug: String = ""
    @State private var displayName: String = ""
    @State private var description: String = ""
    @State private var catalogPath: String = ""
    @State private var manifestCommand: String = ""
    @State private var brandKey: String = "sigma"

    private var isEditing: Bool { editingProject != nil }

    var body: some View {
        VStack(spacing: 0) {
            // Header
            HStack {
                Text(isEditing ? "Edit Project" : "Add Project")
                    .font(.headline)
                Spacer()
                Button("Cancel") { onDismiss() }
                    .keyboardShortcut(.escape)
                Button(isEditing ? "Save" : "Add") {
                    commit()
                    onDismiss()
                }
                .buttonStyle(.borderedProminent)
                .disabled(slug.isEmpty || displayName.isEmpty)
                .keyboardShortcut(.return, modifiers: .command)
            }
            .padding(16)

            Divider()

            // Form
            Form {
                Section("Identity") {
                    LabeledContent("Slug") {
                        TextField("e.g. c-tech", text: $slug)
                            .disabled(isEditing)
                    }
                    LabeledContent("Display Name") {
                        TextField("e.g. Cliff Tech", text: $displayName)
                    }
                    LabeledContent("Description") {
                        TextField("One-line description", text: $description)
                    }
                }

                Section("Paths") {
                    LabeledContent("Catalog Path") {
                        TextField("/path/to/repo (optional for built-in)", text: $catalogPath)
                            .font(.caption.monospaced())
                    }
                    LabeledContent("Manifest Command") {
                        TextField("emit-tool --target {output}", text: $manifestCommand)
                            .font(.caption.monospaced())
                    }
                }

                Section("Brand") {
                    LabeledContent("Brand Key") {
                        Picker("", selection: $brandKey) {
                            Text("sigma").tag("sigma")
                            Text("c-tech").tag("c-tech")
                            Text("katagami").tag("katagami")
                            Text("obyw").tag("obyw")
                            Text("wabi-sabi").tag("wabi-sabi")
                        }
                        .pickerStyle(.menu)
                        .frame(width: 140)
                    }
                }
            }
            .formStyle(.grouped)
            .padding(.horizontal, 8)
        }
        .frame(width: 520, height: 420)
        .onAppear { populate() }
    }

    private func populate() {
        guard let p = editingProject else { return }
        slug = p.slug
        displayName = p.displayName
        description = p.description
        catalogPath = p.catalogPath ?? ""
        manifestCommand = p.manifestCommand ?? ""
        brandKey = p.brandKey
    }

    private func commit() {
        let record = ProjectRecord(
            slug: slug,
            displayName: displayName,
            description: description,
            catalogPath: catalogPath.isEmpty ? nil : catalogPath,
            manifestCommand: manifestCommand.isEmpty ? nil : manifestCommand,
            manifestPath: editingProject?.manifestPath,
            lastLoadedAt: editingProject?.lastLoadedAt,
            brandKey: brandKey
        )
        registry.add(project: record)
    }
}

// MARK: - DefaultsSettingsTab

/// Defaults tab: window size, appearance, auto-reemit.
struct DefaultsSettingsTab: View {
    @AppStorage("sb.defaults.windowWidth")     private var windowWidth: Double = 1280
    @AppStorage("sb.defaults.windowHeight")    private var windowHeight: Double = 800
    @AppStorage("sb.defaults.autoReemitOnLaunch") private var autoReemit: Bool = false
    @AppStorage("sb.defaults.preferredAppearance") private var appearance: String = "system"

    var body: some View {
        Form {
            Section("Window") {
                LabeledContent("Default Width") {
                    HStack {
                        Slider(value: $windowWidth, in: 800...2560, step: 80)
                            .frame(width: 180)
                        Text("\(Int(windowWidth)) pt")
                            .monospacedDigit()
                            .frame(width: 56, alignment: .trailing)
                    }
                }
                LabeledContent("Default Height") {
                    HStack {
                        Slider(value: $windowHeight, in: 600...1600, step: 60)
                            .frame(width: 180)
                        Text("\(Int(windowHeight)) pt")
                            .monospacedDigit()
                            .frame(width: 56, alignment: .trailing)
                    }
                }
            }

            Section("Appearance") {
                Picker("Preferred Appearance", selection: $appearance) {
                    Text("System").tag("system")
                    Text("Light").tag("light")
                    Text("Dark").tag("dark")
                }
                .pickerStyle(.segmented)
            }

            Section("Catalog") {
                Toggle("Auto re-emit manifest on launch", isOn: $autoReemit)
                Text("When enabled, the active project's manifest command runs automatically each time the app starts.")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
        }
        .formStyle(.grouped)
        .padding(8)
    }
}

// MARK: - TokensSettingsTab

/// Tokens tab: which brand renders by default in the Token Inspector.
struct TokensSettingsTab: View {
    @ObservedObject var registry: ProjectRegistry
    @AppStorage("sb.tokens.defaultBrand") private var defaultBrand: String = "sigma"

    var body: some View {
        Form {
            Section("Default Brand") {
                Picker("Token Inspector Brand", selection: $defaultBrand) {
                    ForEach(TokenBrand.allCases) { brand in
                        Text(brand.displayName).tag(brand.rawValue)
                    }
                }
                .pickerStyle(.radioGroup)

                Text("This brand is shown in the Token Inspector when no catalog is loaded, or when the active project's brand key does not match a known brand.")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }

            Section("Active Project Brand") {
                LabeledContent("Current Active Project") {
                    Text(registry.activeProject.displayName)
                        .foregroundStyle(.primary)
                }
                LabeledContent("Brand Key") {
                    Text(registry.activeProject.brandKey)
                        .font(.caption.monospaced())
                        .foregroundStyle(.secondary)
                }
            }
        }
        .formStyle(.grouped)
        .padding(8)
    }
}
