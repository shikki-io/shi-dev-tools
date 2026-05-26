// CatalogCrossReferences.swift — DSStorybookKit
//
// D3: Cross-reference engine — computes "Used In" and "Related" links
// from the full set of primitives + widget entries in the catalog.
//
// For each primitive entry (widgetKind starts with "katagami."):
//   - Scans all catalog entries whose primitiveList contains the
//     primitive's display name or type name (e.g. "KatagamiText" in "text").
//   - Returns CatalogRef items pointing to each widget that uses it.
//
// For each widget entry (c-tech / user):
//   - Produces related widgets by finding other widgets that share
//     at least one primitive with this widget.
//
// Result types are all Sendable + Hashable so they can live in @State.
// Engine is a pure static function — no stored state; call per-entry.

import Foundation

// MARK: - CatalogRef

/// A lightweight cross-reference to another catalog entry.
/// Used in the "Used In" / "Related" side-panel in StorybookDetailView.
public struct CatalogRef: Sendable, Identifiable, Hashable {
    public let id: String       // CatalogEntry.id
    public let displayName: String
    public let widgetKind: String
    public let refKind: RefKind

    public enum RefKind: String, Sendable {
        case usedIn  = "Used In"
        case related = "Related"
    }
}

// MARK: - CatalogCrossReferences

public enum CatalogCrossReferences {

    // MARK: Used-In (primitive → widgets that use it)

    /// For a primitive entry: return all catalog entries (across
    /// primitives + widgets) that reference this primitive in their
    /// `primitiveList`.
    ///
    /// Match logic:
    ///   - Primitive's widgetKind "katagami.text" → normalise to "KatagamiText"
    ///   - Check if any token in candidate.primitiveList contains that string
    ///     (case-insensitive substring so partial matches work)
    public static func usedIn(
        primitive: CatalogEntry,
        allEntries: [CatalogEntry]
    ) -> [CatalogRef] {
        let normalised = normalisePrimitiveName(primitive.widgetKind)
        return allEntries
            .filter { candidate in
                guard candidate.id != primitive.id else { return false }
                return candidate.primitiveList.contains { prim in
                    prim.localizedCaseInsensitiveContains(normalised)
                }
            }
            .map { CatalogRef(id: $0.id, displayName: $0.displayName, widgetKind: $0.widgetKind, refKind: .usedIn) }
    }

    // MARK: Related (widget → widgets sharing primitives)

    /// For a widget entry: return other widgets that share at least one
    /// primitive.  Sorted by shared-primitive count descending.
    public static func related(
        widget: CatalogEntry,
        allEntries: [CatalogEntry]
    ) -> [CatalogRef] {
        let myPrims = Set(widget.primitiveList.map { $0.lowercased() })
        guard !myPrims.isEmpty else { return [] }

        return allEntries
            .filter { candidate in
                guard candidate.id != widget.id else { return false }
                let candidatePrims = Set(candidate.primitiveList.map { $0.lowercased() })
                return !myPrims.intersection(candidatePrims).isEmpty
            }
            .sorted { a, b in
                let aShared = Set(a.primitiveList.map { $0.lowercased() }).intersection(myPrims).count
                let bShared = Set(b.primitiveList.map { $0.lowercased() }).intersection(myPrims).count
                return aShared > bShared
            }
            .map { CatalogRef(id: $0.id, displayName: $0.displayName, widgetKind: $0.widgetKind, refKind: .related) }
    }

    // MARK: Both sections for detail view

    /// Returns (usedIn: [...], related: [...]) cross-refs for a given entry.
    /// Entry is treated as primitive if widgetKind starts with "katagami.".
    public static func crossRefs(
        for entry: CatalogEntry,
        allEntries: [CatalogEntry]
    ) -> (usedIn: [CatalogRef], related: [CatalogRef]) {
        if entry.widgetKind.hasPrefix("katagami.") {
            return (usedIn: usedIn(primitive: entry, allEntries: allEntries), related: [])
        } else {
            return (usedIn: [], related: related(widget: entry, allEntries: allEntries))
        }
    }

    // MARK: - Private helpers

    /// "katagami.text" → "KatagamiText", "katagami.hstack" → "KatagamiHStack"
    private static func normalisePrimitiveName(_ widgetKind: String) -> String {
        guard widgetKind.hasPrefix("katagami.") else { return widgetKind }
        let suffix = widgetKind.dropFirst("katagami.".count)
        return "Katagami" + suffix.capitalized
    }
}
