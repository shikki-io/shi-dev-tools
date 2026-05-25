# Shikki Developer Tools

**shi-dev-tools** is the umbrella meta-package for the Shikki Developer Tools product — a suite of Swift frameworks for building tools in the Shikki ecosystem.

## Components

| Package | Purpose | License |
|---------|---------|---------|
| [shi-design](https://github.com/FJ-Studios/shi-design) | Design system (DSKintsugi) + rendering framework (Katagami) | Apache-2.0 |
| [shi-qa](https://github.com/FJ-Studios/shi-qa) | Quality toolchain: test runner, snapshot, lint, Storybook, VisualQC (Kagami) | AGPL-3.0 |
| [shi-image-io](https://github.com/FJ-Studios/shi-image-io) | CGImage load/save — OG image generation, VisualQC input | AGPL-3.0 |

## Installation

### Recommended: import individual packages

For lighter dependency graphs, import the package you actually need:

```swift
// Design system + rendering
.package(url: "https://github.com/FJ-Studios/shi-design.git", from: "1.0.0")

// Quality toolchain
.package(url: "https://github.com/FJ-Studios/shi-qa.git", from: "1.0.0")

// Image I/O
.package(url: "https://github.com/FJ-Studios/shi-image-io.git", from: "1.0.0")
```

### Umbrella: import shi-dev-tools

For rapid prototyping or when you need all three components:

```swift
.package(url: "https://github.com/FJ-Studios/shi-dev-tools.git", from: "1.0.0"),
```

Then depend on the convenience umbrella products:

```swift
// All shi-design products (Katagami* + DSKintsugi*)
.product(name: "ShiDesign", package: "shi-dev-tools"),

// All shi-qa products (Kagami quality toolchain)
.product(name: "ShiQA", package: "shi-dev-tools"),
```

> **Note on AGPL-3.0:** shi-qa and shi-image-io are AGPL-3.0. If you import `ShiQA` or use shi-image-io in your project, AGPL-3.0 terms apply to your work. shi-design is Apache-2.0 (permissive). shi-dev-tools itself is Apache-2.0.

## Brand

**Shikki Developer Tools** is the human-readable product name.  
**Kagami** (鏡 — mirror) is the brand name for the quality toolchain in shi-qa.

## License

Apache-2.0 — see [LICENSE](LICENSE).

Note: shi-qa (Kagami) and shi-image-io dependencies are AGPL-3.0. The umbrella package itself is Apache-2.0; license terms of dependencies apply when consumed.
