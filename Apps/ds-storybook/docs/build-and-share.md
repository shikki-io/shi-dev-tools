# Build and share

Two paths: run from source with `swift run`, or produce a `.app` bundle you
hand to a teammate.

## Run from source

The everyday loop. No bundle, no signing.

```sh
cd Apps/ds-storybook
swift run -c release ds-storybook --catalog /path/to/manifest.json
```

Debug builds work too — drop `-c release`. First build downloads and compiles
shi-design + sm-widgets-native transitively; expect 5–10 minutes and a
`.build/` tree of a few GB.

If you plan to iterate a widget, keep the app running and use `--list` or the
toolbar's Projects picker rather than restarting.

## Build a `.app` bundle

Ad-hoc, no notarization — good enough for team review. If you're shipping
wider than that, add a notarization step (out of scope for this doc).

```sh
# 1. Build the release binary.
cd Apps/ds-storybook
swift build -c release --product ds-storybook

# 2. Wrap it in a .app skeleton around DSStorybookApp-Info.plist.
APP_DIR="$(pwd)/dist/ds-storybook.app"
rm -rf "$APP_DIR"
mkdir -p "$APP_DIR/Contents/MacOS" "$APP_DIR/Contents/Resources"

# The Info.plist in this repo uses xcodebuild variables. Substitute them for
# swift-build defaults — the plist below is a hand-authored, self-contained
# copy.
cat > "$APP_DIR/Contents/Info.plist" <<'PLIST'
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
  <key>CFBundleDevelopmentRegion</key><string>en</string>
  <key>CFBundleDisplayName</key><string>ds-storybook</string>
  <key>CFBundleExecutable</key><string>ds-storybook</string>
  <key>CFBundleIdentifier</key><string>eu.fj-studios.shikki.ds-storybook</string>
  <key>CFBundleInfoDictionaryVersion</key><string>6.0</string>
  <key>CFBundleName</key><string>ds-storybook</string>
  <key>CFBundlePackageType</key><string>APPL</string>
  <key>CFBundleShortVersionString</key><string>1.0.0</string>
  <key>CFBundleVersion</key><string>1</string>
  <key>LSApplicationCategoryType</key><string>public.app-category.developer-tools</string>
  <key>LSMinimumSystemVersion</key><string>14.0</string>
  <key>NSHighResolutionCapable</key><true/>
  <key>NSPrincipalClass</key><string>NSApplication</string>
  <key>NSSupportsAutomaticGraphicsSwitching</key><true/>
</dict>
</plist>
PLIST

# 3. Copy the executable + every bundled catalog in.
cp .build/release/ds-storybook "$APP_DIR/Contents/MacOS/ds-storybook"
cp .build/release/ds-storybook_DSStorybookApp.bundle/default-catalog.json \
   "$APP_DIR/Contents/Resources/default-catalog.json"
cp .build/release/ds-storybook_DSStorybookApp.bundle/ctech-catalog.json \
   "$APP_DIR/Contents/Resources/ctech-catalog.json"

# 4. Ad-hoc sign (no Developer ID, no notarization).
codesign --sign - --deep --force --options runtime "$APP_DIR"

# 5. Zip for handoff (macOS-friendly, preserves resource forks).
ditto -c -k --keepParent "$APP_DIR" "$(dirname "$APP_DIR")/ds-storybook.app.zip"

echo "→ $(dirname "$APP_DIR")/ds-storybook.app.zip"
```

The recipient double-clicks the zip, right-clicks `ds-storybook.app` →
**Open**, and dismisses the Gatekeeper warning once. After that the OS
remembers.

If you want it repeatable, put the block above in `scripts/pack-app.sh` and
call it from CI.

### Known issue: `project.yml` drift

`project.yml` currently declares three absolute paths that don't exist on
most machines:

| Package | Path | Status |
|---|---|---|
| `Katagami` | `~/.shikki/workspaces/obyw-one/projects/shikki/packages/Katagami` | Superseded — Hop D collapsed this into shi-design. |
| `ds-storybook` (self-reference) | `~/.shikki/tmp/wt-fix-dual-singleton-2026-05-26/Apps/ds-storybook` | A worktree path from 2026-05. Points at nothing today. |
| `SMWidgets` | `~/.shikki/tmp/wt-ctech-W5-fix-2026-05-26/packages/SMWidgets` | Same — a stale tmp worktree. |

Consequence: `xcodegen` regenerates the `.xcodeproj` with broken package
references, and `xcodebuild -project ShikkiDSStorybook.xcodeproj` fails on
resolve. The Xcode project committed to the repo (`ShikkiDSStorybook.xcodeproj/`)
was generated in the past against those paths, so opening it in Xcode also
fails on the same resolve unless you edit the file references.

**The `swift build` path uses `Package.swift`, which is clean — that's what
this doc uses.** If you need the Xcode project (for Instruments, say, or a
UI test target), the fix is to swap the three broken absolute paths in
`project.yml` for the working relative equivalents:

```yaml
packages:
  katagami:
    path: ../../../katagami
  SMWidgets:
    path: /Users/<you>/.shikki/workspaces/cliff-tech/projects/sm-widgets-native/packages/SMWidgets
  # ds-storybook self-reference — keep it (see architecture.md § singleton)
  ds-storybook:
    path: .
```

Then `xcodegen generate` and `xcodebuild` come back to life.

## Notarization (only when you need to ship wider)

Ad-hoc signing is fine for a handful of reviewers. If you're distributing to
customers or a wider team, you'll want a real notarized build:

1. Sign with a Developer ID: `codesign --sign "Developer ID Application: …"`
2. Notarize: `xcrun notarytool submit ds-storybook.app.zip --keychain-profile <profile> --wait`
3. Staple: `xcrun stapler staple ds-storybook.app`

Out of scope for this doc — team convention lives in
[obyw-one release runbooks](https://github.com/shikki-io/obyw-one).

## Emitting a manifest

The `.app` opens on a populated sidebar even with no arguments — a bundled
`Resources/default-catalog.json` ships the 28 Katagami canonical primitives.
For anything beyond those, hand it a `CatalogManifest` JSON from one of the
emitters:

- **c-tech / sm-widgets-native** — `swift run sm-storybook-emit` — emits
  `CatalogManifest` JSON for the six c-tech widgets.
- **shi-design ds-storybook-emit** — emits the full web storybook including a
  `_manifest.json` you can point ds-storybook at.

Pass a manifest with `--catalog <path>` (it replaces the default) or drop JSON
files into `~/.shikki/storybook/user-widgets/` (they layer on top). The
`UserWidgetCatalog` watcher picks up the folder drops within two seconds.

## Bundled catalogs

Two catalogs ship inside the built product:

- `Sources/DSStorybookApp/Resources/default-catalog.json` — the 28 Katagami
  canonical primitives.
- `Sources/DSStorybookApp/Resources/ctech-catalog.json` — the six c-tech
  widgets (SMPeople, SMShoppableProduct, SMQR, SMEndcap, SMProgramGuide,
  SMCart).

The `resources: [.copy(...)]` block on the `DSStorybookApp` target in
`Package.swift` lists them both. Two runtime locations are searched for
each, in order:

1. **`Bundle.module`** — used by `swift run` (SPM lays the resources next to
   the executable at `.build/release/ds-storybook_DSStorybookApp.bundle/`).
2. **`Bundle.main`** — used by the packaged `.app` (the wrap script copies
   the JSON files to `Contents/Resources/` — the standard macOS location
   and the one `codesign` handles cleanly; the SPM "flat bundle" refuses
   to sign, so we don't ship it inside the `.app`).

When no `--catalog` is passed, `loadManifestFromArgs()` **merges every
catalog it finds** (missing ones are skipped silently) into one manifest
before returning — that's how a fresh install opens on the union of
primitives + c-tech widgets.

To add a third bundled catalog (say `sigma-catalog.json` once the sigma
bridge lands): add the file under `Resources/`, extend `resources:` in
`Package.swift`, add its short name to the `bundledCatalogNames` array in
`loadManifestFromArgs`, and add a matching `cp` line in the wrap script.
