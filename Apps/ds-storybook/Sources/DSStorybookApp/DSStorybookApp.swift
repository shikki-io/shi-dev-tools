// DSStorybookApp.swift — ds-storybook executable entry point.
//
// W5.0a: Bootstrap SPM app target — NavigationSplitView on macOS 14 / iPadOS 17.
// W5.0b: --catalog flag — decodes CatalogManifest JSON, dumps entry count.
// W5.0c: Browse mode — passes manifest to StorybookBrowserView.
//
// UX Upgrade:
//   D4: UserWidgetCatalog wired — operator can drop JSON files into
//       ~/.shikki/storybook/user-widgets/ and they appear in sidebar within 2s.
//
// Settings system:
//   S1: ProjectRegistry seeded on first launch (c-tech + sigma + Katagami Primitives).
//   S2: Settings scene (Cmd+,) with Projects / Defaults / Tokens tabs.
//   S3: Toolbar "Projects" picker — switches without restart via ManifestEmitter.
//
// Usage:
//   swift run --package-path Apps/ds-storybook ds-storybook \
//             --catalog /tmp/c-tech-manifest.json
//
// swift run local only — no bundle-id needed for this slice.

import AppKit
import CTechWidgetPreviewProviders
import DSStorybookKit
import Foundation
import SwiftUI
#if canImport(SigmaWidgetPreviewBridge)
import SigmaWidgetPreviewBridge
#endif

// MARK: - @main App (Swift 6 / ArgumentParser-compatible)

@main
struct DSStorybookSwiftUIApp: App {
    // MARK: - Argument parsing (CommandLine.arguments, no ArgumentParser dep in App)

    static let parsedManifest: CatalogManifest = loadManifestFromArgs()
    static let listOnly: Bool = CommandLine.arguments.contains("--list")

    // D4: UserWidgetCatalog — instantiated once; FileMonitor lives here.
    let userCatalog = UserWidgetCatalog()

    // S1: ProjectRegistry — loads/seeds projects.json, drives toolbar picker.
    let projectRegistry = ProjectRegistry()

    // MARK: - Init — register widget preview providers before any view loads.
    //
    // CTechWidgetPreviewProviders.registerAll() wires one WidgetPreviewProvider per
    // c-tech widgetKind ("people", "product", "qr", "endcap", "program_guide",
    // "cart") into WidgetPreviewRegistry.shared. StorybookDetailView queries the
    // registry; providers render KatagamiView widgets via .swiftUI(theme:).
    //
    // KatagamiPrimitivePreviewProviders.registerAll() wires one provider per
    // Katagami canonical primitive (28 total — atoms/layout/components/composite).
    // Without this, clicking any primitive in the sidebar shows the orange
    // "No preview registered for widgetKind: katagami.*" fallback.
    //
    // SigmaWidgetPreviewBridge.registerAll() wires 16 providers for the sigma
    // catalog (9 molecules + 3 layout + 4 surfaces) rendered with
    // KatagamiThemePreset.sigma (sgCrimson / sgGold / sgInk brand palette).
    // Gated behind canImport so ds-storybook builds when sigma is absent.
    init() {
        CTechWidgetPreviewProviders.registerAll()
        KatagamiPrimitivePreviewProviders.registerAll()
        #if canImport(SigmaWidgetPreviewBridge)
        SigmaWidgetPreviewBridge.registerAll()
        #endif
    }

    var body: some Scene {
        // MARK: Main window
        WindowGroup("ds-storybook") {
            RootView(
                initialManifest: Self.parsedManifest,
                userCatalog: userCatalog,
                registry: projectRegistry
            )
        }
        .windowStyle(.automatic)
        .defaultSize(width: 1280, height: 800)
        .commands {
            CommandGroup(after: .windowArrangement) {
                Button("Reset Window Size") {
                    if let window = NSApp.keyWindow {
                        let frame = NSRect(
                            x: window.frame.origin.x,
                            y: window.frame.origin.y,
                            width: 1280,
                            height: 800
                        )
                        window.setFrame(frame, display: true, animate: true)
                    }
                }
                .keyboardShortcut("0", modifiers: .command)
            }
        }

        // MARK: S2: Settings scene (Cmd+,)
        Settings {
            SettingsView(registry: projectRegistry)
        }
    }

    // MARK: - Argument resolution

    private static func loadManifestFromArgs() -> CatalogManifest {
        let args = CommandLine.arguments

        guard let catalogIdx = args.firstIndex(of: "--catalog"),
              catalogIdx + 1 < args.count else {

            if !args.contains("--help") && !args.contains("-h") {
                fputs("ds-storybook: no --catalog provided — opening with empty catalog.\n", stderr)
                fputs("Usage: ds-storybook --catalog <path-to-manifest.json>\n", stderr)
            }

            if args.contains("--list") {
                fputs("ds-storybook: 0 widgets\n", stdout)
                exit(0)
            }

            return CatalogManifest(entries: [])
        }

        let path = args[catalogIdx + 1]

        do {
            let manifest = try loadManifest(at: path)

            print("ds-storybook: loaded \(manifest.entryCount) widget\(manifest.entryCount == 1 ? "" : "s") from \(path)")
            for entry in manifest.entries {
                print("  [\(entry.wave)] \(entry.displayName) (\(entry.widgetKind)) — \(entry.primitiveList.count) primitives")
            }

            if args.contains("--list") {
                exit(0)
            }

            return manifest
        } catch {
            fputs("ds-storybook error: \(error.localizedDescription)\n", stderr)
            exit(1)
        }
    }

    private static func loadManifest(at path: String) throws -> CatalogManifest {
        guard FileManager.default.fileExists(atPath: path) else {
            throw DSStorybookError.catalogNotFound(path: path)
        }

        let data = try Data(contentsOf: URL(fileURLWithPath: path))
        return try CatalogManifest.decode(from: data)
    }
}

// MARK: - RootView (S3 — holds mutable manifest state, owns toolbar)

/// Root container that owns the mutable manifest and the project-switch callback.
/// StorybookBrowserView is reconstructed in-place when the operator switches projects.
struct RootView: View {
    @State private var activeManifest: CatalogManifest
    @ObservedObject var userCatalog: UserWidgetCatalog
    @ObservedObject var registry: ProjectRegistry

    init(
        initialManifest: CatalogManifest,
        userCatalog: UserWidgetCatalog,
        registry: ProjectRegistry
    ) {
        _activeManifest = State(initialValue: initialManifest)
        self.userCatalog = userCatalog
        self.registry = registry
    }

    var body: some View {
        StorybookBrowserView(manifest: activeManifest, userCatalog: userCatalog)
            .toolbar {
                // S3: Project picker in leading navigation area.
                ToolbarItem(placement: .navigation) {
                    ProjectPickerToolbar(registry: registry) { @MainActor result in
                        switch result {
                        case .manifest(let newManifest):
                            activeManifest = newManifest
                        case .builtIn:
                            // Built-in: clear external manifest so PrimitiveCatalog shows.
                            activeManifest = CatalogManifest(entries: [])
                        case .failed:
                            // Error already shown in the picker's popover; keep current manifest.
                            break
                        }
                    }
                }
            }
    }
}

// MARK: - Errors

enum DSStorybookError: Error, LocalizedError {
    case catalogNotFound(path: String)
    case decodeFailed(path: String, underlying: Error)

    var errorDescription: String? {
        switch self {
        case .catalogNotFound(let path):
            return "Catalog file not found: \(path)"
        case .decodeFailed(let path, let err):
            return "Failed to decode catalog at \(path): \(err.localizedDescription)"
        }
    }
}
