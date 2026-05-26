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

import DSStorybookKit
import Foundation
import SwiftUI

// MARK: - @main App (Swift 6 / ArgumentParser-compatible)

@main
struct DSStorybookSwiftUIApp: App {
    // MARK: - Argument parsing (CommandLine.arguments, no ArgumentParser dep in App)

    static let parsedManifest: CatalogManifest = loadManifestFromArgs()
    static let listOnly: Bool = CommandLine.arguments.contains("--list")

    var body: some Scene {
        WindowGroup("ds-storybook") {
            StorybookBrowserView(manifest: Self.parsedManifest)
        }
        .windowStyle(.automatic)
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
