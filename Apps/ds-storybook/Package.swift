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
            ],
            path: "Sources/DSStorybookApp"
        ),
        .testTarget(
            name: "DSStorybookKitTests",
            dependencies: ["DSStorybookKit"],
            path: "Tests/DSStorybookKitTests"
        ),
    ]
)
