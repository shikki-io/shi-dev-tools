// DSStorybookApp.swift — ds-storybook executable entry point.
//
// W5.0a: Bootstrap SPM app target — NavigationSplitView on macOS 14 / iPadOS 17.
// W5.0b: --catalog flag — decodes CatalogManifest JSON, dumps entry count.
// W5.0c: Browse mode — passes manifest to StorybookBrowserView.
//
// Usage:
//   swift run --package-path Apps/ds-storybook ds-storybook \
//             --catalog /tmp/c-tech-manifest.json
//
// swift run local only — no bundle-id needed for this slice.

import AppKit
import CTechWidgetPreviewBridge
import DSStorybookKit
import Foundation
import SwiftUI

// MARK: - @main App (Swift 6 / ArgumentParser-compatible)

@main
struct DSStorybookSwiftUIApp: App {
    // MARK: - Argument parsing (CommandLine.arguments, no ArgumentParser dep in App)

    static let parsedManifest: CatalogManifest = loadManifestFromArgs()
    static let listOnly: Bool = CommandLine.arguments.contains("--list")

    // MARK: - Init — register widget preview providers before any view loads.
    //
    // CTechWidgetPreviewBridge.registerAll() wires one WidgetPreviewProvider per
    // c-tech widgetKind ("people", "product", "qr", "endcap", "program_guide",
    // "cart") into WidgetPreviewRegistry.shared. StorybookDetailView queries the
    // registry; providers render KatagamiView widgets via KatagamiSwiftUIRenderer.
    //
    // KatagamiPrimitivePreviewBridge.registerAll() wires one provider per
    // Katagami canonical primitive (28 total — atoms/layout/components/composite).
    // Without this, clicking any primitive in the sidebar shows the orange
    // "No preview registered for widgetKind: katagami.*" fallback.
    init() {
        CTechWidgetPreviewBridge.registerAll()
        KatagamiPrimitivePreviewBridge.registerAll()
    }

    var body: some Scene {
        WindowGroup("ds-storybook") {
            StorybookBrowserView(manifest: Self.parsedManifest)
        }
        .windowStyle(.automatic)
        // macOS 14+: request a comfortable canvas that shows the full widget
        // chrome without clipping. Operator default was ~580×430 which cut
        // off card shadows and avatar overlays.
        .defaultSize(width: 1280, height: 800)
        .commands {
            CommandGroup(after: .windowArrangement) {
                Button("Reset Window Size") {
                    // Cmd+0 — return window to the 1280×800 default.
                    // NSWindow resize is handled by NSApp.keyWindow on macOS 14+.
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
    }

    // MARK: - Argument resolution

    private static func loadManifestFromArgs() -> CatalogManifest {
        let args = CommandLine.arguments

        // Print entry count + names to stdout (W5.0b acceptance).
        // We do this as a side-effect here because App.main() doesn't return.

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

            // W5.0b: dump entry count + names to console.
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
