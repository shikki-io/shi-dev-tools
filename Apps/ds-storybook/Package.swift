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
        // CTechPlayer (transitive via SMWidgets) declares katagami-player via git URL;
        // SMWidgets re-declares it as a local path. SwiftPM crashes (ARC overflow) when
        // both are visible to the outer consumer unless the outer package also pins to the
        // local path. This entry forces consistent local-path resolution.
        .package(
            path: "/Users/jeoffrey/.shikki/workspaces/obyw-one/projects/katagami-player"
        ),
        // CTechWidgetPreviewBridge — live-render providers for all c-tech widgets.
        // PR #30 merged to sm-widgets-native/develop 2026-05-26.
        // sm-widgets-native has no root Package.swift (packages/ subdir layout),
        // so we reference the SMWidgets sub-package directly via workspace path.
        // TODO: add root Package.swift to sm-widgets-native OR extract SMWidgets as
        // its own repo to enable GitHub URL dep (tracked: shi ws link workspace-resolver).
        .package(
            path: "/Users/jeoffrey/.shikki/workspaces/cliff-tech/projects/sm-widgets-native/packages/SMWidgets"
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
        // Executable: CLI entry point (--catalog flag, arguments parsed manually).
        .executableTarget(
            name: "DSStorybookApp",
            dependencies: [
                "DSStorybookKit",
                .product(name: "KatagamiSwiftUI", package: "Katagami"),
                .product(name: "KatagamiCore", package: "Katagami"),
                .product(name: "CTechWidgetPreviewBridge", package: "SMWidgets"),
            ],
            path: "Sources/DSStorybookApp"
        ),
        .testTarget(
            name: "DSStorybookKitTests",
            dependencies: [
                "DSStorybookKit",
                .product(name: "SnapshotTesting", package: "swift-snapshot-testing"),
                // Live-render proof: CTechWidgetPreviewBridge.registerAll() in TP-DSS-S06.
                .product(name: "CTechWidgetPreviewBridge", package: "SMWidgets"),
            ],
            path: "Tests/DSStorybookKitTests"
        ),
    ]
)
