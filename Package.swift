// swift-tools-version: 6.0

import PackageDescription

// shi-dev-tools — Shikki Developer Tools umbrella meta-package.
//
// Single SPM entry point that re-exports all Shikki Developer Tools components:
//   - shi-design:   design system + rendering framework (Katagami* + DSKintsugi*)
//   - shi-qa:       quality toolchain (Kagami: test runner, snapshot, lint, Storybook)
//   - shi-image-io: CGImage load/save (OG image generation, VisualQC)
//
// License: Apache-2.0
//
// Usage:
//   .package(url: "https://github.com/FJ-Studios/shi-dev-tools.git", from: "1.0.0")
//
// Then depend on products directly from shi-design, shi-qa, or shi-image-io,
// OR use the umbrella products from this package for convenience.

let package = Package(
    name: "shi-dev-tools",
    platforms: [.macOS(.v14), .iOS(.v17)],
    products: [
        // Convenience umbrella: re-exports all public products from shi-design.
        // Prefer importing shi-design directly for lighter builds.
        .library(name: "ShiDesign", targets: ["ShiDesignUmbrella"]),
        // Convenience umbrella: re-exports all public products from shi-qa.
        // Prefer importing shi-qa directly for quality tooling.
        .library(name: "ShiQA", targets: ["ShiQAUmbrella"]),
    ],
    dependencies: [
        .package(url: "https://github.com/FJ-Studios/shi-design.git", branch: "develop"),
        .package(url: "https://github.com/FJ-Studios/shi-qa.git", branch: "develop"),
        .package(url: "https://github.com/FJ-Studios/shi-image-io.git", from: "0.1.0"),
    ],
    targets: [
        // ShiDesign umbrella — thin pass-through to shi-design products.
        .target(
            name: "ShiDesignUmbrella",
            dependencies: [
                .product(name: "KatagamiCore", package: "shi-design"),
                .product(name: "KatagamiTUI", package: "shi-design"),
                .product(name: "KatagamiSwiftUI", package: "shi-design"),
                .product(name: "KatagamiHeadless", package: "shi-design"),
                .product(name: "KatagamiScreens", package: "shi-design"),
                .product(name: "KatagamiAnimator", package: "shi-design"),
                .product(name: "KatagamiRender", package: "shi-design"),
                .product(name: "DSKintsugiCore", package: "shi-design"),
                .product(name: "DSKintsugiTUI", package: "shi-design"),
                .product(name: "DSKintsugi", package: "shi-design"),
            ],
            path: "Sources/ShiDesignUmbrella"
        ),
        // ShiQA umbrella — thin pass-through to shi-qa products.
        .target(
            name: "ShiQAUmbrella",
            dependencies: [
                .product(name: "KagamiQualityGate", package: "shi-qa"),
                .product(name: "KagamiRunner", package: "shi-qa"),
                .product(name: "KagamiStorybook", package: "shi-qa"),
                .product(name: "KagamiSnapshot", package: "shi-qa"),
                .product(name: "KagamiLint", package: "shi-qa"),
            ],
            path: "Sources/ShiQAUmbrella"
        ),
    ]
)
