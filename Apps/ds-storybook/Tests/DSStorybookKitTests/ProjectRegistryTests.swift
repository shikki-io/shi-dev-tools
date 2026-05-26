// ProjectRegistryTests.swift — DSStorybookKitTests
//
// Tests for ProjectRegistry: round-trip JSON, CRUD, auto-seed, ManifestEmitter.
//
// Isolation: all tests use SHIKKI_STORYBOOK_PROJECTS_PATH to redirect to
// a temp file so the operator's real projects.json is never touched.

import Foundation
import Testing
@testable import DSStorybookKit

// MARK: - Helpers

private func tempRegistryURL() -> URL {
    let dir = FileManager.default.homeDirectoryForCurrentUser
        .appendingPathComponent(".shikki/tmp", isDirectory: true)
    try? FileManager.default.createDirectory(at: dir, withIntermediateDirectories: true)
    return dir.appendingPathComponent("test-projects-\(UUID().uuidString).json")
}

/// Sets SHIKKI_STORYBOOK_PROJECTS_PATH to `url.path` for the duration of the closure.
/// Note: setenv is process-global; tests run serially in the same process, so this is safe.
private func withTempRegistry(url: URL, _ body: () -> Void) {
    setenv("SHIKKI_STORYBOOK_PROJECTS_PATH", url.path, 1)
    defer {
        unsetenv("SHIKKI_STORYBOOK_PROJECTS_PATH")
        try? FileManager.default.removeItem(at: url)
    }
    body()
}

// MARK: - Suite

@Suite("ProjectRegistry", .serialized)
@MainActor
struct ProjectRegistryTests {

    // MARK: - Auto-seed

    @Test("auto-seeds 3 default projects on first launch")
    func autoSeedsOnFirstLaunch() {
        let url = tempRegistryURL()
        withTempRegistry(url: url) {
            let registry = ProjectRegistry()
            #expect(registry.projects.count == 3)
            let slugs = registry.projects.map(\.slug)
            #expect(slugs.contains("katagami"))
            #expect(slugs.contains("c-tech"))
            #expect(slugs.contains("sigma"))
        }
    }

    @Test("activeProjectSlug defaults to katagami after seed")
    func defaultActiveIsKatagami() {
        let url = tempRegistryURL()
        withTempRegistry(url: url) {
            let registry = ProjectRegistry()
            #expect(registry.activeProjectSlug == "katagami")
        }
    }

    // MARK: - Round-trip JSON

    @Test("round-trips projects.json — save then reload")
    func roundTripJSON() {
        let url = tempRegistryURL()
        withTempRegistry(url: url) {
            let registry = ProjectRegistry()
            // Add a custom project.
            let custom = ProjectRecord(
                slug: "test-proj",
                displayName: "Test Proj",
                description: "For testing",
                catalogPath: "/tmp/test",
                manifestCommand: "echo hello --target {output}",
                brandKey: "sigma"
            )
            registry.add(project: custom)

            // Reload from the same file.
            let registry2 = ProjectRegistry()
            let found = registry2.projects.first(where: { $0.slug == "test-proj" })
            #expect(found != nil)
            #expect(found?.displayName == "Test Proj")
            #expect(found?.catalogPath == "/tmp/test")
        }
    }

    // MARK: - CRUD

    @Test("add project — upsert by slug")
    func addProjectUpserts() {
        let url = tempRegistryURL()
        withTempRegistry(url: url) {
            let registry = ProjectRegistry()
            let initial = registry.projects.count

            registry.add(project: ProjectRecord(
                slug: "upsert-test",
                displayName: "Original",
                description: "d",
                brandKey: "sigma"
            ))
            #expect(registry.projects.count == initial + 1)

            // Upsert same slug — count stays, displayName updates.
            registry.add(project: ProjectRecord(
                slug: "upsert-test",
                displayName: "Updated",
                description: "d",
                brandKey: "sigma"
            ))
            #expect(registry.projects.count == initial + 1)
            #expect(registry.projects.first(where: { $0.slug == "upsert-test" })?.displayName == "Updated")
        }
    }

    @Test("remove project — removes by slug")
    func removeProject() {
        let url = tempRegistryURL()
        withTempRegistry(url: url) {
            let registry = ProjectRegistry()
            registry.add(project: ProjectRecord(
                slug: "to-remove",
                displayName: "To Remove",
                description: "d",
                brandKey: "sigma"
            ))
            let before = registry.projects.count
            registry.remove(slug: "to-remove")
            #expect(registry.projects.count == before - 1)
            #expect(!registry.projects.contains(where: { $0.slug == "to-remove" }))
        }
    }

    @Test("remove built-in katagami is a no-op")
    func removeBuiltInIsNoop() {
        let url = tempRegistryURL()
        withTempRegistry(url: url) {
            let registry = ProjectRegistry()
            let before = registry.projects.count
            registry.remove(slug: "katagami")
            #expect(registry.projects.count == before)
        }
    }

    @Test("setActive updates activeProjectSlug")
    func setActiveUpdates() {
        let url = tempRegistryURL()
        withTempRegistry(url: url) {
            let registry = ProjectRegistry()
            #expect(registry.activeProjectSlug == "katagami")
            registry.setActive(slug: "c-tech")
            #expect(registry.activeProjectSlug == "c-tech")
        }
    }

    @Test("setActive to unknown slug is a no-op")
    func setActiveUnknownIsNoop() {
        let url = tempRegistryURL()
        withTempRegistry(url: url) {
            let registry = ProjectRegistry()
            registry.setActive(slug: "does-not-exist")
            #expect(registry.activeProjectSlug == "katagami")
        }
    }

    @Test("touchLastLoaded writes ISO-8601 timestamp")
    func touchLastLoaded() {
        let url = tempRegistryURL()
        withTempRegistry(url: url) {
            let registry = ProjectRegistry()
            registry.touchLastLoaded(slug: "katagami")
            let loaded = registry.projects.first(where: { $0.slug == "katagami" })?.lastLoadedAt
            #expect(loaded != nil)
            // Basic ISO-8601 shape check.
            #expect(loaded?.contains("T") == true)
        }
    }

    // MARK: - Built-in record

    @Test("built-in katagami has no catalogPath or manifestCommand")
    func builtInHasNoPathOrCommand() {
        let katagami = ProjectRegistry.builtInKatagami
        #expect(katagami.isBuiltIn)
        #expect(katagami.catalogPath == nil)
        #expect(katagami.manifestCommand == nil)
    }

    // MARK: - ManifestEmitter outputPath

    @Test("ManifestEmitter.outputPath is under ~/.shikki/tmp and uses slug")
    func emitterOutputPath() {
        let path = ManifestEmitter.outputPath(for: "my-project")
        #expect(path.contains(".shikki/tmp"))
        #expect(path.contains("my-project-manifest.json"))
    }

    // MARK: - ManifestEmitter emit — no command

    @Test("ManifestEmitter throws noCommandDefined for built-in project")
    func emitterThrowsForBuiltIn() async {
        let builtIn = ProjectRegistry.builtInKatagami
        do {
            _ = try await ManifestEmitter.emit(project: builtIn)
            Issue.record("Expected throw for built-in project")
        } catch ManifestEmitter.EmitError.noCommandDefined {
            // Expected.
        } catch {
            Issue.record("Unexpected error type: \(error)")
        }
    }

    // MARK: - ManifestEmitter emit — successful shell-out

    @Test("ManifestEmitter runs command and decodes output JSON")
    func emitterRunsCommand() async throws {
        let url = tempRegistryURL()
        let outputPath = ManifestEmitter.outputPath(for: "emit-test-\(UUID().uuidString)")
        defer { try? FileManager.default.removeItem(atPath: outputPath) }

        // Build a minimal CatalogManifest JSON that the command will write.
        let manifestJSON = """
        [{"id":"Emit1","widgetKind":"emit.test","displayName":"EmitTest",
          "description":"d","primitives":"","wave":"1","ssimStatus":"pass"}]
        """

        // Command writes the manifest JSON to {output}.
        let command = "printf '%s' '\(manifestJSON)' > {output}"

        withTempRegistry(url: url) {
            let project = ProjectRecord(
                slug: "emit-test",
                displayName: "Emit Test",
                description: "d",
                catalogPath: "/tmp",
                manifestCommand: command,
                brandKey: "sigma"
            )

            let expectation = _Concurrency.Task { @MainActor in
                try await ManifestEmitter.emit(project: project)
            }

            // Await inline since we're already in an async test.
            Task {
                do {
                    let manifest = try await expectation.value
                    #expect(manifest.entryCount == 1)
                    #expect(manifest.entries.first?.id == "Emit1")
                } catch {
                    Issue.record("ManifestEmitter.emit threw unexpectedly: \(error)")
                }
            }
        }
    }
}
