// swift-tools-version: 6.0

import PackageDescription

// ds-storybook — local Katagami widget catalog browser.
//
// W5.0 fast-path: Browse mode only (sidebar + detail render).
// Reads a c-tech CatalogManifest JSON (emitted by SMWidgetsKatagamiManifest.emitJSON())
// and renders each widget via KatagamiSwiftUIRenderer.
//
// Usage:
//   swift run --package-path Apps/ds-storybook ds-storybook \
//             --catalog /tmp/c-tech-manifest.json
//
// Platform: macOS 14+, iPadOS 17+ (NavigationSplitView, swift run only)
// Distribution: swift run local — no bundle-id needed for this slice.
// Full distribution (TestFlight, 4 modes) deferred to parent W5 spec.

let package = Package(
    name: "ds-storybook",
    platforms: [
        .macOS(.v14),
        .iOS(.v17),
    ],
    products: [
        .executable(name: "ds-storybook", targets: ["DSStorybookApp"]),
        // DSStorybookKit: library for external consumers and testability.
        .library(name: "DSStorybookKit", targets: ["DSStorybookKit"]),
    ],
    dependencies: [
        // Katagami canonical DSL + SwiftUI renderer.
        .package(
            path: "/Users/jeoffrey/.shikki/workspaces/obyw-one/projects/shikki/packages/Katagami"
        ),
        // katagami-player — explicit local path to override CTechPlayer's git URL dep.
        // sm-widgets-native declares katagami-player as a local path; CTechPlayer (transitive)
        // previously declared it via git URL. Both consumers must pin to the same identity
        // (local path) to avoid SwiftPM ARC overflow. This entry forces consistent resolution.
        .package(
            path: "/Users/jeoffrey/.shikki/workspaces/obyw-one/projects/katagami-player"
        ),
        // sm-widgets-native — local path to repo root (root Package.swift added 2026-05-26 via #32).
        // Uses root products: SMWidgetsCore, SMWidgets, SMWidgetsKatagami.
        // GitHub URL dep (.package(url: "https://github.com/clifftechnologies-co/sm-widgets-native.git", branch: "develop"))
        // will replace this once katagami-player + Katagami have standalone GitHub URL deps
        // (blocked: shi ws link workspace-resolver — tracked as NP-root-pkg follow-up).
        .package(
            path: "/Users/jeoffrey/.shikki/workspaces/cliff-tech/projects/sm-widgets-native"
        ),
        // swift-snapshot-testing (Point-Free) — SwiftUI/NSView pixel snapshot tests.
        // Test target only — not linked into production targets.
        .package(
            url: "https://github.com/pointfreeco/swift-snapshot-testing.git",
            from: "1.17.0"
        ),
    ],
    targets: [
        // Library: catalog model + SwiftUI browse view.
        .target(
            name: "DSStorybookKit",
            dependencies: [
                .product(name: "KatagamiSwiftUI", package: "Katagami"),
                .product(name: "KatagamiCore", package: "Katagami"),
            ],
            path: "Sources/DSStorybookKit"
        ),
        // CTechWidgetPreviewBridge — live-render WidgetPreviewProvider implementations
        // for all c-tech widgets. Moved from sm-widgets-native/packages/SMWidgets here
        // to break the circular dep (SMWidgets → DSStorybookKit → ds-storybook).
        .target(
            name: "CTechWidgetPreviewBridge",
            dependencies: [
                "DSStorybookKit",
                .product(name: "KatagamiCore", package: "Katagami"),
                .product(name: "KatagamiSwiftUI", package: "Katagami"),
                .product(name: "SMWidgetsKatagami", package: "sm-widgets-native"),
                .product(name: "SMWidgetsCore", package: "sm-widgets-native"),
            ],
            path: "Sources/CTechWidgetPreviewBridge"
        ),
        // Executable: CLI entry point (--catalog flag, arguments parsed manually).
        .executableTarget(
            name: "DSStorybookApp",
            dependencies: [
                "DSStorybookKit",
                "CTechWidgetPreviewBridge",
                .product(name: "KatagamiSwiftUI", package: "Katagami"),
                .product(name: "KatagamiCore", package: "Katagami"),
            ],
            path: "Sources/DSStorybookApp"
        ),
        .testTarget(
            name: "DSStorybookKitTests",
            dependencies: [
                "DSStorybookKit",
                .product(name: "SnapshotTesting", package: "swift-snapshot-testing"),
                // Live-render proof: CTechWidgetPreviewBridge.registerAll() in TP-DSS-S06.
                "CTechWidgetPreviewBridge",
            ],
            path: "Tests/DSStorybookKitTests"
        ),
        .testTarget(
            name: "CTechWidgetPreviewBridgeTests",
            dependencies: [
                "CTechWidgetPreviewBridge",
                "DSStorybookKit",
            ],
            path: "Tests/CTechWidgetPreviewBridgeTests"
        ),
    ]
)
