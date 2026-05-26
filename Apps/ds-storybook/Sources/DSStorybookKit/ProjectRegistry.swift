// ProjectRegistry.swift — DSStorybookKit
//
// Settings system — Project Registry (persistence layer).
//
// Manages ~/.shikki/storybook/projects.json:
//   - Codable load/save of registered projects.
//   - Auto-seeds c-tech + sigma + Katagami Primitives (built-in) on first launch.
//   - ObservableObject for SwiftUI binding.
//   - activeProject drives the toolbar picker.
//
// Path precedence:
//   1. SHIKKI_STORYBOOK_PROJECTS_PATH env var (test override)
//   2. ~/.shikki/storybook/projects.json
//
// Memory: [[feedback_db-centralized-no-magic-strings]] — path resolved via env /
//          config; no raw string literals for the path.

import Foundation
import Combine

// MARK: - ProjectRecord

/// A registered project in the storybook.
///
/// `catalogPath` is optional: built-in projects (Katagami Primitives) omit it.
/// `manifestCommand` contains `{output}` which is substituted with a temp path
/// before shell-out. Example: "sm-storybook-emit --target {output}"
public struct ProjectRecord: Sendable, Codable, Equatable, Identifiable {
    public var id: String { slug }

    /// URL-safe identifier (e.g. "c-tech", "sigma", "katagami").
    public var slug: String
    /// Human-readable name shown in UI (e.g. "Cliff Tech").
    public var displayName: String
    /// One-line description.
    public var description: String
    /// Absolute path to the package/repo root. Nil for built-in projects.
    public var catalogPath: String?
    /// Shell command template. `{output}` is substituted with a temp JSON path.
    /// Nil for built-in projects (uses PrimitiveCatalog.all directly).
    public var manifestCommand: String?
    /// Absolute path used as the last successful manifest output.
    /// Written after a successful re-emit.
    public var manifestPath: String?
    /// ISO-8601 timestamp of the last successful load.
    public var lastLoadedAt: String?
    /// DSKintsugi brand key (e.g. "sigma", "c-tech", "katagami").
    public var brandKey: String

    public init(
        slug: String,
        displayName: String,
        description: String,
        catalogPath: String? = nil,
        manifestCommand: String? = nil,
        manifestPath: String? = nil,
        lastLoadedAt: String? = nil,
        brandKey: String
    ) {
        self.slug = slug
        self.displayName = displayName
        self.description = description
        self.catalogPath = catalogPath
        self.manifestCommand = manifestCommand
        self.manifestPath = manifestPath
        self.lastLoadedAt = lastLoadedAt
        self.brandKey = brandKey
    }

    /// True for the built-in Katagami Primitives project (no catalogPath / manifestCommand).
    public var isBuiltIn: Bool {
        catalogPath == nil && manifestCommand == nil
    }
}

// MARK: - ProjectsFile (on-disk shape)

private struct ProjectsFile: Codable {
    var version: Int
    var activeProjectSlug: String
    var projects: [ProjectRecord]
}

// MARK: - ProjectRegistry

/// Observable project registry — loads/saves projects.json, drives the
/// toolbar picker and Settings panel.
@MainActor
public final class ProjectRegistry: ObservableObject {

    // MARK: - File path resolution

    /// Resolved path to projects.json.
    /// Env override: SHIKKI_STORYBOOK_PROJECTS_PATH
    public static var registryURL: URL {
        if let override = ProcessInfo.processInfo.environment["SHIKKI_STORYBOOK_PROJECTS_PATH"] {
            return URL(fileURLWithPath: override)
        }
        return FileManager.default.homeDirectoryForCurrentUser
            .appendingPathComponent(".shikki/storybook/projects.json")
    }

    // MARK: - Published state

    /// All registered projects (including built-in).
    @Published public private(set) var projects: [ProjectRecord] = []

    /// The slug of the currently-active project.
    @Published public private(set) var activeProjectSlug: String = "katagami"

    /// The currently-active project record (never nil — falls back to built-in).
    public var activeProject: ProjectRecord {
        projects.first(where: { $0.slug == activeProjectSlug })
            ?? projects.first(where: { $0.isBuiltIn })
            ?? Self.builtInKatagami
    }

    // MARK: - Init

    public init() {
        load()
    }

    // MARK: - Load

    public func load() {
        let url = Self.registryURL
        let fm = FileManager.default

        // Ensure parent dir exists.
        let parent = url.deletingLastPathComponent()
        if !fm.fileExists(atPath: parent.path) {
            try? fm.createDirectory(at: parent, withIntermediateDirectories: true)
        }

        guard fm.fileExists(atPath: url.path),
              let data = try? Data(contentsOf: url),
              let file = try? JSONDecoder().decode(ProjectsFile.self, from: data) else {
            // First launch — seed defaults.
            seed()
            return
        }

        projects = file.projects
        activeProjectSlug = file.activeProjectSlug
    }

    // MARK: - Save

    public func save() {
        let file = ProjectsFile(
            version: 1,
            activeProjectSlug: activeProjectSlug,
            projects: projects
        )
        let encoder = JSONEncoder()
        encoder.outputFormatting = [.prettyPrinted, .sortedKeys]
        guard let data = try? encoder.encode(file) else { return }
        try? data.write(to: Self.registryURL, options: .atomic)
    }

    // MARK: - Mutations

    public func add(project: ProjectRecord) {
        // Upsert by slug.
        if let idx = projects.firstIndex(where: { $0.slug == project.slug }) {
            projects[idx] = project
        } else {
            projects.append(project)
        }
        save()
    }

    public func remove(slug: String) {
        guard slug != "katagami" else { return } // Never remove built-in.
        projects.removeAll(where: { $0.slug == slug })
        if activeProjectSlug == slug {
            activeProjectSlug = projects.first?.slug ?? "katagami"
        }
        save()
    }

    public func setActive(slug: String) {
        guard projects.contains(where: { $0.slug == slug }) else { return }
        activeProjectSlug = slug
        save()
    }

    /// Updates lastLoadedAt on the active project to now.
    public func touchLastLoaded(slug: String) {
        guard let idx = projects.firstIndex(where: { $0.slug == slug }) else { return }
        let iso = ISO8601DateFormatter().string(from: Date())
        projects[idx].lastLoadedAt = iso
        save()
    }

    /// Writes back the manifestPath after a successful re-emit.
    public func updateManifestPath(slug: String, path: String) {
        guard let idx = projects.firstIndex(where: { $0.slug == slug }) else { return }
        projects[idx].manifestPath = path
        save()
    }

    // MARK: - Built-in records

    static let builtInKatagami = ProjectRecord(
        slug: "katagami",
        displayName: "Katagami Primitives",
        description: "28 built-in Katagami canonical primitives (atoms / layout / components / composites). No catalog path needed — rendered directly from PrimitiveCatalog.",
        catalogPath: nil,
        manifestCommand: nil,
        manifestPath: nil,
        lastLoadedAt: nil,
        brandKey: "katagami"
    )

    static let defaultCTech = ProjectRecord(
        slug: "c-tech",
        displayName: "Cliff Tech",
        description: "c-tech native widgets (SMPeople, SMProduct, SMCart, SMQRCode, SMEndCap, SMProgramGuide, SMContentCard).",
        catalogPath: "/Users/jeoffrey/.shikki/workspaces/cliff-tech/projects/sm-widgets-native/packages/SMWidgets",
        manifestCommand: "sm-storybook-emit --target {output}",
        manifestPath: "/Users/jeoffrey/.shikki/tmp/c-tech-manifest.json",
        lastLoadedAt: nil,
        brandKey: "c-tech"
    )

    static let defaultSigma = ProjectRecord(
        slug: "sigma",
        displayName: "Sigma Analytics",
        description: "16-entry Sigma DS (molecules + layout + surfaces). Cream + crimson sigma-default brand.",
        catalogPath: "/Users/jeoffrey/.shikki/workspaces/fj-studio/projects/sigma-analytics/tools/sigma-storybook-emit",
        manifestCommand: "sigma-storybook-emit --target {output}",
        manifestPath: "/Users/jeoffrey/.shikki/tmp/sigma-manifest.json",
        lastLoadedAt: nil,
        brandKey: "sigma"
    )

    // MARK: - First-launch seed

    private func seed() {
        projects = [Self.builtInKatagami, Self.defaultCTech, Self.defaultSigma]
        activeProjectSlug = "katagami"
        save()
    }
}

// MARK: - ManifestEmitter

/// Handles the Process-based manifest re-emit when switching projects.
///
/// Flow (per spec deliverable D):
///   1. Reads manifestCommand from the project record.
///   2. Substitutes {output} with a stable temp path under ~/.shikki/tmp/.
///   3. Runs the command via Process (inherits user PATH).
///   4. On exit-code 0: reads result JSON → decodes CatalogManifest.
///   5. Returns .success(CatalogManifest) or .failure(Error).
public enum ManifestEmitter {

    public enum EmitError: Error, LocalizedError {
        case noCommandDefined(slug: String)
        case commandFailed(command: String, code: Int32, stderr: String)
        case outputNotFound(path: String)
        case decodeFailed(path: String, underlying: Error)

        public var errorDescription: String? {
            switch self {
            case .noCommandDefined(let slug):
                return "Project '\(slug)' has no manifestCommand defined."
            case .commandFailed(let cmd, let code, let err):
                return "Emit command '\(cmd)' exited \(code).\n\(err)"
            case .outputNotFound(let path):
                return "Emit command completed but output not found at: \(path)"
            case .decodeFailed(let path, let err):
                return "Failed to decode manifest at \(path): \(err.localizedDescription)"
            }
        }
    }

    /// Temporary output path for a given project slug.
    /// Uses ~/.shikki/tmp/ (never /tmp — per shikki convention).
    public static func outputPath(for slug: String) -> String {
        let base = FileManager.default.homeDirectoryForCurrentUser
            .appendingPathComponent(".shikki/tmp", isDirectory: true)
        // Ensure dir exists.
        try? FileManager.default.createDirectory(at: base, withIntermediateDirectories: true)
        return base.appendingPathComponent("\(slug)-manifest.json").path
    }

    /// Run manifestCommand for the given project, decode the result.
    /// Throws ManifestEmitter.EmitError on any failure.
    public static func emit(project: ProjectRecord) async throws -> CatalogManifest {
        guard let commandTemplate = project.manifestCommand else {
            throw EmitError.noCommandDefined(slug: project.slug)
        }

        let outputPath = outputPath(for: project.slug)
        let command = commandTemplate.replacingOccurrences(of: "{output}", with: outputPath)

        // Run via /bin/sh so PATH is inherited from the login shell profile.
        let process = Process()
        process.executableURL = URL(fileURLWithPath: "/bin/sh")
        process.arguments = ["-l", "-c", command]

        let stderrPipe = Pipe()
        process.standardError = stderrPipe
        // stdout goes to the output file — no pipe needed.

        try process.run()
        process.waitUntilExit()

        let exitCode = process.terminationStatus
        if exitCode != 0 {
            let stderrData = stderrPipe.fileHandleForReading.readDataToEndOfFile()
            let stderrStr = String(data: stderrData, encoding: .utf8) ?? ""
            throw EmitError.commandFailed(command: command, code: exitCode, stderr: stderrStr)
        }

        guard FileManager.default.fileExists(atPath: outputPath) else {
            throw EmitError.outputNotFound(path: outputPath)
        }

        do {
            let data = try Data(contentsOf: URL(fileURLWithPath: outputPath))
            return try CatalogManifest.decode(from: data)
        } catch {
            throw EmitError.decodeFailed(path: outputPath, underlying: error)
        }
    }
}
