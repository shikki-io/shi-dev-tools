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
        // TODO(hop-f): Re-enable sm-widgets-native + katagami-player once SMWidgetsKatagami
        // is migrated from shikki/packages/Katagami DSL API (KatagamiView, KatagamiShadowedCard,
        // KatagamiSwiftUIRenderer) to shi-design's ViewNode/ShikkiView API. Until then, c-tech
        // widget previews show the orange "No provider registered" fallback in the sidebar.
        // .package(path: "/Users/jeoffrey/.shikki/workspaces/obyw-one/projects/katagami-player"),
        // .package(path: "/Users/jeoffrey/.shikki/workspaces/cliff-tech/projects/sm-widgets-native"),
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
        // TODO(hop-f): CTechWidgetPreviewProviders re-enabled once sm-widgets-native migrates
        // from shikki's Katagami DSL API to shi-design's ViewNode/ShikkiView API (Hop F).
        // Temporarily removed to unblock Hop D build (shi-design dep is incompatible with
        // the shikki Katagami DSL types used in SMWidgetsKatagami).
        // .target(
        //     name: "CTechWidgetPreviewProviders",
        //     dependencies: [
        //         "DSStorybookKit",
        //         .product(name: "KatagamiCore", package: "katagami"),
        //         .product(name: "KatagamiSwiftUI", package: "katagami"),
        //         .product(name: "SMWidgetsKatagami", package: "sm-widgets-native"),
        //         .product(name: "SMWidgetsCore", package: "sm-widgets-native"),
        //     ],
        //     path: "Sources/CTechWidgetPreviewProviders"
        // ),
        // Executable: CLI entry point (--catalog flag, arguments parsed manually).
        .executableTarget(
            name: "DSStorybookApp",
            dependencies: [
                "DSStorybookKit",
                // TODO(hop-f): Re-add CTechWidgetPreviewProviders after sm-widgets-native migrates
                // from shikki Katagami DSL API (KatagamiView, KatagamiShadowedCard, etc.) to
                // shi-design's ViewNode/ShikkiView API.
                // "CTechWidgetPreviewProviders",
                // TODO(hop-e): Re-add SigmaWidgetPreviewBridge after sigma-analytics migrates
                // from shikki/packages/Katagami to shi-design (blocked on KatagamiWeb landing there).
                // .product(name: "SigmaWidgetPreviewBridge", package: "sources"),
            ],
            path: "Sources/DSStorybookApp"
        ),
        .testTarget(
            name: "DSStorybookKitTests",
            dependencies: [
                "DSStorybookKit",
                .product(name: "SnapshotTesting", package: "swift-snapshot-testing"),
                // TODO(hop-f): Re-add CTechWidgetPreviewProviders once sm-widgets-native migrates.
                // "CTechWidgetPreviewProviders",
            ],
            path: "Tests/DSStorybookKitTests"
        ),
        // TODO(hop-f): Re-enable CTechWidgetPreviewProvidersTests after sm-widgets-native migration.
        // .testTarget(
        //     name: "CTechWidgetPreviewProvidersTests",
        //     dependencies: [
        //         "CTechWidgetPreviewProviders",
        //         "DSStorybookKit",
        //     ],
        //     path: "Tests/CTechWidgetPreviewProvidersTests"
        // ),
    ]
)
