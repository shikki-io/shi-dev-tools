// swift-tools-version: 6.0
// kagami-scope: exempt

import PackageDescription

// ds-storybook — local Katagami widget catalog browser.
//
// W5.0 fast-path: Browse mode only (sidebar + detail render).
// Reads a c-tech CatalogManifest JSON (emitted by SMWidgetsKatagamiManifest.emitJSON())
// and renders each widget via .swiftUI(theme:).
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
        .package(
            path: "/Users/jeoffrey/.shikki/workspaces/cliff-tech/projects/sm-widgets-native"
        ),
        // swift-snapshot-testing (Point-Free) — SwiftUI/NSView pixel snapshot tests.
        // Test target only — not linked into production targets.
        .package(
            url: "https://github.com/pointfreeco/swift-snapshot-testing.git",
            from: "1.17.0"
        ),
        // SigmaWidgetPreviewBridge — live sigma catalog render for ds-storybook.
        // 16 WidgetPreviewProvider implementations (9 molecules + 3 layout + 4 surfaces)
        // rendered with KatagamiThemePreset.sigma (sgCrimson / sgGold / sgInk brand palette).
        // Package identity = "sources" (SPM uses directory name for file-system deps).
        // Requires sigma-analytics working tree to be on develop (has correct Package.swift paths).
        .package(
            path: "/Users/jeoffrey/.shikki/workspaces/fj-studio/projects/sigma-analytics/web/app/sources"
        ),
    ],
    targets: [
        // Library: catalog model + SwiftUI browse view + KatagamiPrimitivePreviewProviders.
        .target(
            name: "DSStorybookKit",
            dependencies: [
                .product(name: "KatagamiSwiftUI", package: "Katagami"),
                .product(name: "KatagamiCore", package: "Katagami"),
            ],
            path: "Sources/DSStorybookKit"
        ),
        // CTechWidgetPreviewProviders — live-render WidgetPreviewProvider implementations
        // for all c-tech widgets. Moved from sm-widgets-native/packages/SMWidgets here
        // to break the circular dep (SMWidgets → DSStorybookKit → ds-storybook).
        // Renamed from CTechWidgetPreviewBridge (2026-05-26) — providers use .swiftUI(theme:),
        // no renderer instance management at call-site.
        .target(
            name: "CTechWidgetPreviewProviders",
            dependencies: [
                "DSStorybookKit",
                .product(name: "KatagamiCore", package: "Katagami"),
                .product(name: "KatagamiSwiftUI", package: "Katagami"),
                .product(name: "SMWidgetsKatagami", package: "sm-widgets-native"),
                .product(name: "SMWidgetsCore", package: "sm-widgets-native"),
            ],
            path: "Sources/CTechWidgetPreviewProviders"
        ),
        // Executable: CLI entry point (--catalog flag, arguments parsed manually).
        .executableTarget(
            name: "DSStorybookApp",
            dependencies: [
                "DSStorybookKit",
                "CTechWidgetPreviewProviders",
                .product(name: "KatagamiSwiftUI", package: "Katagami"),
                .product(name: "KatagamiCore", package: "Katagami"),
                // SigmaWidgetPreviewBridge — sigma catalog live renders.
                // Package identity = directory name "sources" (SPM file-system resolution).
                .product(name: "SigmaWidgetPreviewBridge", package: "sources"),
            ],
            path: "Sources/DSStorybookApp"
        ),
        .testTarget(
            name: "DSStorybookKitTests",
            dependencies: [
                "DSStorybookKit",
                .product(name: "SnapshotTesting", package: "swift-snapshot-testing"),
                // Live-render proof: CTechWidgetPreviewProviders.registerAll() in TP-DSS-S06.
                "CTechWidgetPreviewProviders",
            ],
            path: "Tests/DSStorybookKitTests"
        ),
        .testTarget(
            name: "CTechWidgetPreviewProvidersTests",
            dependencies: [
                "CTechWidgetPreviewProviders",
                "DSStorybookKit",
            ],
            path: "Tests/CTechWidgetPreviewProvidersTests"
        ),
    ]
)
