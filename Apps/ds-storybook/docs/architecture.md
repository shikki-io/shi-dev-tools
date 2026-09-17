# Architecture

ds-storybook is a small native app whose job is one thing: **render a Katagami
widget catalog with the same code the widget ships with, so the browser is
never a mock.** Everything below is in service of that.

## The three targets

```
DSStorybookApp   ← @main. Parses --catalog, sets registration order, opens the scene.
      │
      ▼
DSStorybookKit   ← Protocols, models, SwiftUI browser. Knows nothing about any widget.
      ▲
      │
CTechWidgetPreviewProviders   ← Adapter: c-tech widgets → the WidgetPreviewProvider seam.
```

`DSStorybookKit` is deliberately widget-agnostic. It defines
`WidgetPreviewProvider` and a shared `WidgetPreviewRegistry`. Widget packages
plug themselves in from the outside. That's how a bridge package like
`CTechWidgetPreviewProviders` — or a hypothetical `SigmaWidgetPreviewBridge`
(gated behind `canImport`, currently off) — can teach the app to render new
kinds without the app knowing they exist at compile time.

## The registration seam

```swift
public protocol WidgetPreviewProvider: Sendable {
    @MainActor func previewView(for entry: CatalogEntry) -> AnyView
}

public final class WidgetPreviewRegistry: @unchecked Sendable {
    public static let shared = WidgetPreviewRegistry()
    public func register(provider: some WidgetPreviewProvider, for widgetKind: String)
    public func provider(for widgetKind: String) -> (any WidgetPreviewProvider)?
    …
}
```

Registration happens **once**, in `DSStorybookApp.init()`, before any view
loads. The order is deliberate:

```swift
init() {
    // 1. Native SwiftUI fallbacks for the 28 Katagami canonical primitives.
    KatagamiPrimitivePreviewProviders.registerAll()
    // 2. Overrides the 8 canonical atoms with shi-design's authoritative bodies.
    KagamiStorybookCanonicalBridge.registerAll()
    // 3. Six c-tech widget providers on the ViewNode API (Hop α, 2026-05-30).
    CTechWidgetPreviewProviders.registerAll()
    #if canImport(SigmaWidgetPreviewBridge)
    SigmaWidgetPreviewBridge.registerAll()  // Blocked on Hop E.
    #endif
}
```

Last-write-wins per `widgetKind` — so bridges that come later can override
what earlier ones registered. That's how the sigma bridge (when re-enabled)
gets to replace fallback primitives with its own themed renders.

## The registry is a singleton — and that hurt once

`WidgetPreviewRegistry.shared` is genuinely one instance. The `project.yml`
declares a `ds-storybook` self-referencing SPM path so the app target and
`CTechWidgetPreviewProviders` link the same `DSStorybookKit` module. Before
that fix, xcodegen compiled `Sources/DSStorybookKit` twice — once into the app
target directly, once as an SPM copy inside `CTechWidgetPreviewProviders` —
and each had its own `WidgetPreviewRegistry.shared`. The c-tech bridge
happily registered against its private one and the browser looked at ours.
The whole c-tech section rendered as the orange "no preview registered"
fallback. Comment header in `project.yml` names this the "dual singleton"
issue — the self-reference exists purely to make the two paths resolve to one
module.

If you re-generate the Xcode project, keep that self-reference.

## Data flow

```
sm-storybook-emit (shi-design, or c-tech/sm-widgets-native)
    │
    │  emits
    ▼
CatalogManifest JSON  (schema in DSStorybookKit/CatalogManifest.swift)
    │
    │  --catalog <path>
    ▼
DSStorybookApp.parsedManifest   (decoded once, at init)
    │
    ▼
RootView(initialManifest:)
    │
    ▼
StorybookBrowserView   ← NavigationSplitView. Sidebar lists entries.
    │
    │  on selection
    ▼
StorybookDetailView    ← queries WidgetPreviewRegistry.shared.provider(for:)
    │
    ▼
provider.previewView(for: entry)   ← returns AnyView, rendered from the DSL
```

## Rendering — no mocks

Every c-tech preview provider follows the same pattern:

1. Take a `CatalogEntry` (widgetKind, primitives list, sample payload).
2. Materialise the widget's `KatagamiView` via `SMWidgetsKatagami` (still real
   widget code, still real DSL).
3. Call `.swiftUI(theme:)` — the Katagami-to-SwiftUI renderer in shi-design.

That's the whole point: what you see in the sidebar is what will end up on a
c-tech customer screen, rendered by the shipping code paths, with only the
data faked.

## The other data sources

Beyond `--catalog`, the app pulls entries from two more places:

- **`ProjectRegistry`** (`~/.shikki/storybook/projects.json`) — seeded on
  first launch with c-tech, sigma, and Katagami primitives. Drives the
  toolbar picker; switching projects reloads via `ManifestEmitter`.
- **`UserWidgetCatalog`** (`~/.shikki/storybook/user-widgets/`) — a folder
  watched with `FileMonitor`. Drop a JSON file there and it shows up in the
  sidebar within two seconds. Handy for ad-hoc widgets you're iterating on.

## What lives where

| File | Role |
|---|---|
| `DSStorybookApp/DSStorybookApp.swift` | `@main`, CLI parsing, provider registration, `WindowGroup`. |
| `DSStorybookKit/WidgetPreviewProvider.swift` | The extension seam. Read this before adding a widget. |
| `DSStorybookKit/CatalogManifest.swift` | The JSON schema — `CatalogEntry` shape, decoding. |
| `DSStorybookKit/StorybookBrowserView.swift` | Sidebar + detail split, selection binding. |
| `DSStorybookKit/KatagamiPrimitivePreviewBridge.swift` | Native SwiftUI fallbacks for the 28 primitives. |
| `DSStorybookKit/KagamiStorybookCanonicalBridge.swift` | Overrides the 8 canonical atoms with shi-design's authoritative bodies. |
| `DSStorybookKit/UserWidgetCatalog.swift` | The `~/.shikki/storybook/user-widgets/` watcher. |
| `DSStorybookKit/ProjectRegistry.swift` | `projects.json` seed + toolbar picker state. |
| `DSStorybookKit/SettingsView.swift` | ⌘, — Projects / Defaults / Tokens tabs. |
| `DSStorybookKit/TokenInspectorView.swift` | Live inspector for a widget's theme tokens. |
| `CTechWidgetPreviewProviders/*.swift` | Six providers, one file each, plus the `registerAll()` entry point. |
