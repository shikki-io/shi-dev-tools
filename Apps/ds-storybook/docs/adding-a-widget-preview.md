# Adding a widget preview

You want to make a new widget kind show up in the browser. Here's the loop.

## The seam

`DSStorybookKit` exposes one protocol:

```swift
public protocol WidgetPreviewProvider: Sendable {
    @MainActor func previewView(for entry: CatalogEntry) -> AnyView
}
```

You implement one type per widget kind, then register it against a string
identifier (`widgetKind`) that matches what the catalog manifest carries for
those entries.

## Five steps

1. **Pick the `widgetKind`.** It comes from the emit side —
   `SMWidgetsKatagamiManifest.emitJSON()` on the c-tech side, for instance.
   For a new widget package, decide the string, and use the same string in the
   manifest and in the provider registration.

2. **Write the provider.** Put it in a widget-side bridge package (mirror
   `CTechWidgetPreviewProviders`) — not in `DSStorybookKit`. The kit stays
   widget-agnostic; the bridge is where the seam lives.

   ```swift
   import DSStorybookKit
   import SwiftUI
   import SMWidgetsKatagami   // your widget package

   struct SMFooPreviewProvider: WidgetPreviewProvider {
       @MainActor func previewView(for entry: CatalogEntry) -> AnyView {
           // 1. Build the widget's KatagamiView from stub or entry payload.
           let widget = SMFooKatagami(
               title: entry.sampleTitle ?? "Foo",
               // … whatever the widget needs
           )
           // 2. Lower to SwiftUI via the shi-design renderer.
           return AnyView(widget.swiftUI(theme: .clifftech))
       }
   }
   ```

   Keep the provider a `struct` and `Sendable`. Do not hold state — each render
   should build the widget fresh from the `CatalogEntry`.

3. **Register it.** Follow the `CTechWidgetPreviewProviders.registerAll()`
   shape — one `enum` with a static `registerAll()` that writes into the shared
   registry:

   ```swift
   public enum SMFooBridge {
       public static func registerAll() {
           let r = WidgetPreviewRegistry.shared
           r.register(provider: SMFooPreviewProvider(), for: "foo")
       }
   }
   ```

4. **Wire it into the app.** Add the target to `Package.swift`, add the import
   in `DSStorybookApp.swift`, and call your `registerAll()` in `App.init()`.
   Order matters — registration is last-write-wins per `widgetKind`, so put
   your call **after** any registration you want to be able to override, and
   **before** anything you want to override you.

5. **Test it.** Mirror `Tests/CTechWidgetPreviewProvidersTests`:
   - assert `WidgetPreviewRegistry.shared.hasProvider(for: "foo")` after
     `registerAll()`,
   - snapshot the SwiftUI view via `swift-snapshot-testing`.

   Run under kagami:
   ```sh
   kagami run --scope SMFooBridgeTests
   ```

## Common gotchas

- **widgetKind mismatch.** The string on the provider side must equal the
  string in the manifest. A typo means the fallback view fires (orange "no
  preview registered" card). `--list` prints registered kinds — compare
  against a `jq '.entries[].widgetKind'` on the manifest.

- **Two `WidgetPreviewRegistry.shared` instances.** If your provider registers
  fine but the browser never sees it, you likely broke the DSStorybookKit
  singleton pattern — see the "dual singleton" note in
  [`architecture.md`](architecture.md#the-registry-is-a-singleton--and-that-hurt-once).
  Do not depend on `DSStorybookKit` from two places that resolve to different
  module instances (typical trigger: an xcodegen-generated project that
  inlines the sources into the app target while also linking an SPM copy).

- **Rendering from stub data vs. entry data.** Preview providers may render
  from stub data (as SMEndcap does) or from `entry.samplePayload` (as
  SMProduct does). Prefer entry data — it means editing the sample in the
  manifest, without a rebuild, changes the render.

- **Themes.** Widgets take a `KatagamiTheme` at render time. Pass one that
  makes sense for the widget's brand. c-tech providers use
  `KatagamiThemePreset.clifftech`; a hypothetical sigma provider would use
  `.sigma`. The theme picker in settings can override this per session.
