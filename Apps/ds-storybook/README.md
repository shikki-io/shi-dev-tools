# ds-storybook

A native macOS / iPadOS SwiftUI browser for **Katagami** widget catalogs.

It reads a `CatalogManifest` JSON (the same emit the web storybook consumes) and
renders every entry as a real SwiftUI view via `KatagamiView.swiftUI(theme:)` —
so what you see in the sidebar is the shipping widget rendered by the shipping
code, not a preview mock.

- **Frameworks:** SwiftUI, `NavigationSplitView`, Swift 6, macOS 14+ / iPadOS 17+
- **Data:** Katagami `CatalogManifest` JSON (typically emitted by `sm-storybook-emit`)
- **Widget packages currently wired:** Katagami canonical primitives (28), c-tech
  widgets (6 — `SMPeople`, `SMShoppableProduct`, `SMQR`, `SMEndcap`,
  `SMProgramGuide`, `SMCart`), sigma bridge (gated behind `canImport`, off by
  default)

If you want the story about *why* this app exists and how the pieces fit
together, read [`docs/architecture.md`](docs/architecture.md). If you want to
extend it with a new widget kind, jump to
[`docs/adding-a-widget-preview.md`](docs/adding-a-widget-preview.md). If you
want to hand a `.app` bundle to a teammate, see
[`docs/build-and-share.md`](docs/build-and-share.md).

## Quickstart

The `Package.swift` uses a **relative path** (`../../../katagami`) to reach
shi-design. Repo checkouts must sit side by side under a common parent, or you
symlink shi-design in as `katagami` next to `shi-dev-tools`:

```
<parent>/
├── shi-dev-tools/          ← this repo
│   └── Apps/ds-storybook/  ← you are here
├── katagami/               ← shi-design checkout (or symlink)
└── sm-widgets-native/      ← cliff-tech/sm-widgets-native checkout
```

The absolute path to `sm-widgets-native/packages/SMWidgets` is baked into
`Package.swift` (Hop α, 2026-05-30). If your checkout lives elsewhere, edit
that path locally — do not commit the edit.

### Run from source

```sh
# 1. emit a catalog manifest (from a shi-design checkout)
swift run --package-path <shi-design> ds-storybook-emit \
  --contracts contracts --output /tmp/ds-out
# the manifest file appears at /tmp/ds-out/_manifest.json

# 2. run the app
swift run -c release --package-path Apps/ds-storybook ds-storybook \
  --catalog /tmp/ds-out/_manifest.json
```

Flags:

| Flag | What it does |
|---|---|
| `--catalog <path>` | External JSON manifest to load — overrides the bundled default. |
| `--list` | Print the widgetKinds resolved from whichever catalog is active, then exit. |

Without `--catalog`, the app **merges every bundled catalog** —
`Resources/default-catalog.json` (28 Katagami canonical primitives) and
`Resources/ctech-catalog.json` (6 c-tech widgets) — into one manifest, so a
double-click on `ds-storybook.app` opens on a populated sidebar without any
file to point it at. Drop JSON files into
`~/.shikki/storybook/user-widgets/` to add widgets on top of the merged
default (the `UserWidgetCatalog` watcher picks them up within two seconds),
or pass `--catalog <path>` for a project-specific manifest (e.g. one emitted
by `sm-storybook-emit`) that replaces the merge entirely.

### Build a distributable `.app`

See [`docs/build-and-share.md`](docs/build-and-share.md). Short version:
`swift build -c release`, then wrap the binary in a `.app` skeleton around the
existing `DSStorybookApp-Info.plist`. Ad-hoc sign for team review; notarize
only when you're going wider than a handful of reviewers.

## Sources at a glance

```
Sources/
├── DSStorybookApp/                 # @main, argument parsing, provider registration order
├── DSStorybookKit/                 # protocols + models + browser view
│   ├── WidgetPreviewProvider.swift #   → the extension seam
│   ├── CatalogManifest.swift       #   → the JSON schema
│   ├── StorybookBrowserView.swift  #   → sidebar + detail
│   ├── UserWidgetCatalog.swift     #   → ~/.shikki/storybook/user-widgets/ watcher
│   ├── ProjectRegistry.swift       #   → projects.json seed + switcher
│   └── …
└── CTechWidgetPreviewProviders/    # SMPeople/SMProduct/SMQR/SMEndcap/SMProgramGuide/SMCart
```

## Tests

Kagami-only, per fleet convention:

```sh
kagami run --scope DSStorybookKitTests
kagami run --scope CTechWidgetPreviewProvidersTests
```

Snapshot goldens live under `Tests/*/__Snapshots__/`. Regenerate a golden by
deleting it and re-running its test.

## Status & known drift

- **c-tech provider bridge live against a worktree fix (2026-09-14, session
  535acd03).** The v0.1 diagnosis stands: `SMWidgetsKatagami` on the
  `chore/kagami-scopes-yaml-to-override-toml-2026-08-09` branch was mixing
  two shi-design API surfaces — half the widgets on the DSL protocol
  (`KatagamiView` + `KatagamiHStack`, `KatagamiText`, `KatagamiShadowedCard`,
  `KatagamiOverlayMarker`, `KatagamiEmptyView`), half on the ViewNode /
  ShikkiView surface — but every source imported only `KatagamiCore`. Fix:
  add `.product(name: "KatagamiCanonical", package: "katagami")` to
  `SMWidgetsKatagami`'s SPM deps in
  `sm-widgets-native/packages/SMWidgets/Package.swift`; keep the existing
  `KatagamiCore` dep beside it; and move each DSL source (`SMBoot`,
  `SMCallToAction`, `SMSettings`, `SMTimeline`) from `import KatagamiCore`
  to `import KatagamiCanonical`. Applied in the worktree at
  `~/.shikki/worktrees/sm-widgets-native-ctech-fix-2026-09-14`; the
  ds-storybook Package.swift here points at that worktree until the fix
  lands upstream in c-tech PR #51's rebase.
- **project.yml hardcodes absolute paths** to old worktrees
  (`~/.shikki/tmp/wt-fix-dual-singleton-2026-05-26/…`,
  `~/.shikki/workspaces/obyw-one/projects/shikki/packages/Katagami`) that no
  longer exist on most machines. `swift build` uses `Package.swift` and works
  fine; `xcodegen`+`xcodebuild` needs those paths fixed first. See
  [`docs/build-and-share.md`](docs/build-and-share.md#known-issue-projectyml-drift).
- **shi-design import** is still path-based (Hop D placeholder). The TODO in
  `Package.swift` says flip to a tag pin once shi-design cuts its first
  release. Track PR #11 there.
- **Sigma bridge disabled** (`TODO(hop-e)`) — sigma-analytics still consumes
  `shikki/packages/Katagami` instead of shi-design; the two paths resolve to
  two `KatagamiCore` modules and the linker rejects them. Blocked on
  KatagamiWeb landing in shi-design.
