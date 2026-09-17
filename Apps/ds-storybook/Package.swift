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
        // shi-design: canonical Katagami DSL + SwiftUI renderer + KagamiStorybook products.
        // Hop D (2026-05-29): replaced shikki/packages/Katagami with shi-design local checkout.
        // KatagamiPrimitivePreviewBridge.swift was re-written to pure SwiftUI (no DSL API dep)
        // to resolve the case-insensitive identity conflict (both paths resolved to "katagami").
        // TODO: flip to tag-pin (.package(url: "https://github.com/FJ-Studios/shi-design.git", from: "x.y.z"))
        //       after the first shi-design release lands (PR #11 merged, tag created).
        .package(
            path: "../../../katagami"
        ),
        // Hop α (2026-05-30): re-enabled sm-widgets-native now that SMWidgetsKatagami is
        // migrated to shi-design's ViewNode/ShikkiView API.
        // Note: SMWidgets (not SMWidgetsKatagami) depends on katagami-player; that dep is
        // pulled transitively so ds-storybook does NOT need to declare it directly.
        //
        // 2026-09-14 (session 535acd03): pointed at the sm-widgets-native worktree that
        // carries the KatagamiCanonical import fix (11 SMWidgetsKatagami sources split
        // into "ViewNode/ShikkiView bucket" → import KatagamiCore vs "DSL bucket" →
        // import KatagamiCanonical). The operator's main sm-widgets-native checkout
        // stays on its untouched branch until the fix lands upstream via c-tech PR #51's
        // rebase; until then, this worktree keeps the ds-storybook build green.
        .package(path: "/Users/jeoffrey/.shikki/worktrees/sm-widgets-native-ctech-fix-2026-09-14/packages/SMWidgets"),
        // swift-snapshot-testing (Point-Free) — SwiftUI/NSView pixel snapshot tests.
        // Test target only — not linked into production targets.
        .package(
            url: "https://github.com/pointfreeco/swift-snapshot-testing.git",
            from: "1.17.0"
        ),
        // TODO(hop-e): Re-enable sigma-analytics dep once sigma-analytics Package.swift migrates
        // from shikki/packages/Katagami to shi-design. SigmaServer's KatagamiWeb dep (only in
        // shikki's Katagami) creates a "multiple similar targets" ARC conflict with ds-storybook's
        // shi-design dep that both provide KatagamiCore. Blocked on Hop E / KatagamiWeb landing in shi-design.
        // .package(
        //     path: "/Users/jeoffrey/.shikki/workspaces/fj-studio/projects/sigma-analytics/web/app/sources"
        // ),
    ],
    targets: [
        // Library: catalog model + SwiftUI browse view + KatagamiPrimitivePreviewProviders.
        .target(
            name: "DSStorybookKit",
            dependencies: [
                // U-A: canonical 8-atom catalog + SwiftUI body registry from shi-design.
                .product(name: "KagamiStorybook", package: "katagami"),
                .product(name: "KagamiStorybookSwiftUI", package: "katagami"),
                // KatagamiCore needed for ThemeTokens (used in KagamiStorybookCanonicalBridge).
                .product(name: "KatagamiCore", package: "katagami"),
            ],
            path: "Sources/DSStorybookKit"
        ),
        // Hop α (2026-05-30): re-enabled — SMWidgetsKatagami now uses shi-design ViewNode API.
        // 2026-09-14: re-enabled against the sm-widgets-native-ctech-fix worktree
        // (see note on the SMWidgets dep above).
        .target(
            name: "CTechWidgetPreviewProviders",
            dependencies: [
                "DSStorybookKit",
                .product(name: "KatagamiCore", package: "katagami"),
                .product(name: "KatagamiSwiftUI", package: "katagami"),
                .product(name: "SMWidgetsKatagami", package: "SMWidgets"),
                .product(name: "SMWidgetsCore", package: "SMWidgets"),
            ],
            path: "Sources/CTechWidgetPreviewProviders"
        ),
        // Executable: CLI entry point (--catalog flag, arguments parsed manually).
        .executableTarget(
            name: "DSStorybookApp",
            dependencies: [
                "DSStorybookKit",
                // Hop α (2026-05-30): re-enabled — SMWidgetsKatagami on shi-design ViewNode API.
                // 2026-09-14: re-enabled after fixing sm-widgets-native drift in a worktree.
                "CTechWidgetPreviewProviders",
                // TODO(hop-e): Re-add SigmaWidgetPreviewBridge after sigma-analytics migrates
                // from shikki/packages/Katagami to shi-design (blocked on KatagamiWeb landing there).
                // .product(name: "SigmaWidgetPreviewBridge", package: "sources"),
            ],
            path: "Sources/DSStorybookApp",
            resources: [
                // Two bundled catalogs — loadManifestFromArgs() merges them when no
                // --catalog is provided, so a double-click on ds-storybook.app opens
                // with 28 primitives + 6 c-tech widgets already visible in the
                // sidebar. Any --catalog <path> arg replaces the merge entirely.
                .copy("Resources/default-catalog.json"),
                .copy("Resources/ctech-catalog.json"),
            ]
        ),
        .testTarget(
            name: "DSStorybookKitTests",
            dependencies: [
                "DSStorybookKit",
                .product(name: "SnapshotTesting", package: "swift-snapshot-testing"),
                // Hop α (2026-05-30): CTechWidgetPreviewProviders now available.
                // 2026-09-14: re-enabled after fixing sm-widgets-native drift.
                "CTechWidgetPreviewProviders",
            ],
            path: "Tests/DSStorybookKitTests"
        ),
        // Hop α (2026-05-30): re-enabled — SMWidgetsKatagami migrated to ViewNode API.
        // 2026-09-14: re-enabled after fixing sm-widgets-native drift.
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
