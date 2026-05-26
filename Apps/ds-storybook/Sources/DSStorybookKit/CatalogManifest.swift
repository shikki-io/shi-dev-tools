// CatalogManifest.swift — DSStorybookKit
//
// Codable model matching the JSON emitted by
// SMWidgetsKatagamiManifest.emitJSON() in the c-tech package.
//
// W5.0b: --catalog flag decodes this; dumps count + names to console.
// W5.0c: Browse mode uses CatalogEntry to drive NavigationSplitView.

import Foundation

// MARK: - CatalogManifest

/// Top-level catalog container. Wraps one or more CatalogEntry values
/// decoded from a JSON file produced by SMWidgetsKatagamiManifest.emitJSON().
///
/// The c-tech emitter produces a flat JSON array of dicts, each with fields:
///   id, widgetKind, displayName, description, primitives, wave, ssimStatus
///
/// ds-storybook wraps the array in this type for convenience.
public struct CatalogManifest: Sendable, Codable, Equatable {
    public let entries: [CatalogEntry]

    public init(entries: [CatalogEntry]) {
        self.entries = entries
    }

    /// Decode from the raw JSON array format emitted by SMWidgetsKatagamiManifest.emitJSON().
    public static func decode(from data: Data) throws -> CatalogManifest {
        let decoder = JSONDecoder()
        let entries = try decoder.decode([CatalogEntry].self, from: data)
        return CatalogManifest(entries: entries)
    }

    /// Entry count.
    public var entryCount: Int { entries.count }
}

// MARK: - CatalogEntry

/// A single widget entry in the storybook catalog.
///
/// Maps directly to the dict format from SMWidgetsKatagamiManifest.emitJSON():
///   { "id": "SMPeople", "widgetKind": "people", "displayName": "People",
///     "description": "...", "primitives": "KatagamiHStack,KatagamiVStack",
///     "wave": "1", "ssimStatus": "pendingImpl" }
public struct CatalogEntry: Sendable, Codable, Equatable, Identifiable {
    public let id: String
    public let widgetKind: String
    public let displayName: String
    public let description: String
    /// Comma-separated primitive names from SMWidgetsKatagami.
    public let primitives: String
    /// Migration wave number as string (e.g. "1").
    public let wave: String
    /// SSIM status string (e.g. "pendingImpl", "pass(0.97)", "fail(0.91/0.95)").
    public let ssimStatus: String

    public init(
        id: String,
        widgetKind: String,
        displayName: String,
        description: String,
        primitives: String,
        wave: String,
        ssimStatus: String
    ) {
        self.id = id
        self.widgetKind = widgetKind
        self.displayName = displayName
        self.description = description
        self.primitives = primitives
        self.wave = wave
        self.ssimStatus = ssimStatus
    }

    /// Primitive list split from comma-separated string.
    public var primitiveList: [String] {
        primitives.split(separator: ",").map { String($0.trimmingCharacters(in: .whitespaces)) }
    }

    /// Wave as integer (nil if unparseable).
    public var waveInt: Int? { Int(wave) }
}
