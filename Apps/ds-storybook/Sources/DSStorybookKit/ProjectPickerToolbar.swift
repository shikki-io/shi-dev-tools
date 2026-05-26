// ProjectPickerToolbar.swift — DSStorybookKit
//
// Top-toolbar "Projects" picker for quick project switching WITHOUT restart.
//
// When the operator picks a project:
//   1. Reads project record from ProjectRegistry.
//   2. Substitutes {output} in manifestCommand → temp path via ManifestEmitter.
//   3. Runs the command via Process (shell out).
//   4. Reads result JSON → decodes CatalogManifest.
//   5. Publishes the new manifest via onManifestLoaded callback.
//   6. Updates activeProjectSlug + lastLoadedAt in ProjectRegistry.
//
// Built-in projects (Katagami Primitives, no catalogPath) skip steps 2-4
// and signal the caller to use PrimitiveCatalog.all directly.

import SwiftUI

// MARK: - ProjectSwitchResult

/// The outcome of switching a project from the toolbar.
public enum ProjectSwitchResult: Sendable {
    /// A manifest was re-emitted; caller should swap to this CatalogManifest.
    case manifest(CatalogManifest)
    /// Built-in project selected; caller should use PrimitiveCatalog.all.
    case builtIn
    /// Emit failed — display the error; previous catalog remains active.
    case failed(String)
}

// MARK: - ProjectPickerToolbar

/// Toolbar item that shows a "Projects" menu for quick switching.
///
/// Usage in StorybookBrowserView toolbar:
///   .toolbar {
///       ToolbarItem(placement: .navigation) {
///           ProjectPickerToolbar(registry: registry) { result in ... }
///       }
///   }
public struct ProjectPickerToolbar: View {
    @ObservedObject public var registry: ProjectRegistry

    /// Called on the MainActor after a switch completes.
    public var onSwitch: @MainActor (ProjectSwitchResult) -> Void

    @State private var isSwitching = false
    @State private var switchError: String?
    @State private var showErrorPopover = false

    public init(
        registry: ProjectRegistry,
        onSwitch: @escaping @MainActor (ProjectSwitchResult) -> Void
    ) {
        self.registry = registry
        self.onSwitch = onSwitch
    }

    public var body: some View {
        HStack(spacing: 4) {
            Menu {
                ForEach(registry.projects) { project in
                    Button {
                        switchProject(to: project)
                    } label: {
                        HStack {
                            if project.slug == registry.activeProjectSlug {
                                Image(systemName: "checkmark")
                            }
                            Text(project.displayName)
                            Spacer()
                            if project.isBuiltIn {
                                Text("built-in")
                                    .foregroundStyle(.secondary)
                            }
                        }
                    }
                }

                Divider()

                Button {
                    // Open Settings to Projects tab.
                    // NSApp.sendAction ensures the Settings window opens correctly on macOS 14+.
                    NSApp.sendAction(Selector(("showSettingsWindow:")), to: nil, from: nil)
                } label: {
                    Label("Manage Projects...", systemImage: "gear")
                }
            } label: {
                HStack(spacing: 4) {
                    Image(systemName: "folder")
                    Text(registry.activeProject.displayName)
                        .lineLimit(1)
                    if isSwitching {
                        ProgressView()
                            .scaleEffect(0.6)
                            .frame(width: 12, height: 12)
                    } else {
                        Image(systemName: "chevron.down")
                            .font(.caption2)
                            .foregroundStyle(.secondary)
                    }
                }
                .font(.callout)
                .padding(.horizontal, 8)
                .padding(.vertical, 4)
                .background(.secondary.opacity(0.1), in: RoundedRectangle(cornerRadius: 6))
            }
            .menuStyle(.borderlessButton)
            .disabled(isSwitching)
            .help("Switch project — re-emits manifest without app restart")

            // Error indicator (tap to see details)
            if switchError != nil {
                Button {
                    showErrorPopover.toggle()
                } label: {
                    Image(systemName: "exclamationmark.triangle.fill")
                        .foregroundStyle(.orange)
                        .font(.callout)
                }
                .buttonStyle(.plain)
                .help("Emit error — tap to see details")
                .popover(isPresented: $showErrorPopover, arrowEdge: .bottom) {
                    ErrorPopover(message: switchError ?? "", onDismiss: {
                        switchError = nil
                        showErrorPopover = false
                    })
                }
            }
        }
    }

    // MARK: - Switch logic

    private func switchProject(to project: ProjectRecord) {
        isSwitching = true
        switchError = nil

        Task { @MainActor in
            defer { isSwitching = false }

            // Update registry immediately so the label reflects the pick.
            registry.setActive(slug: project.slug)

            // Built-in: no emit needed.
            if project.isBuiltIn {
                registry.touchLastLoaded(slug: project.slug)
                onSwitch(.builtIn)
                return
            }

            // External project: run manifest command.
            do {
                let manifest = try await ManifestEmitter.emit(project: project)
                // Write back the output path.
                registry.updateManifestPath(
                    slug: project.slug,
                    path: ManifestEmitter.outputPath(for: project.slug)
                )
                registry.touchLastLoaded(slug: project.slug)
                onSwitch(.manifest(manifest))
            } catch {
                switchError = error.localizedDescription
                showErrorPopover = true
                onSwitch(.failed(error.localizedDescription))
            }
        }
    }
}

// MARK: - ErrorPopover

/// Small popover shown when a manifest emit fails.
struct ErrorPopover: View {
    let message: String
    let onDismiss: () -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Image(systemName: "exclamationmark.triangle.fill")
                    .foregroundStyle(.orange)
                Text("Emit Failed")
                    .font(.headline)
                Spacer()
                Button("Dismiss", action: onDismiss)
                    .buttonStyle(.bordered)
                    .controlSize(.mini)
            }
            Text(message)
                .font(.caption)
                .foregroundStyle(.secondary)
                .textSelection(.enabled)
        }
        .padding(14)
        .frame(width: 340)
    }
}
