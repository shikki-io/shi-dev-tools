// UserWidgetCatalog.swift — DSStorybookKit
//
// D4: Operator widget addition — file-based catalog loading + FileMonitor.
//
// Scans ~/.shikki/storybook/user-widgets/*.json on launch and on
// file-system change (via DispatchSource EVFILT_VNODE).  Each JSON file
// must be a single CatalogEntry-compatible object (same shape as the
// c-tech manifest entries).
//
// Resolved dir precedence:
//   1. SHIKKI_STORYBOOK_USER_WIDGETS env var (override for tests)
//   2. ~/.shikki/storybook/user-widgets/
//
// The catalog is exposed as an @Observable class for SwiftUI binding.
// FileMonitor wakes within ~1 second of a file change — well inside
// the 2s acceptance gate.

import Foundation
import Combine

// MARK: - UserWidgetEntry (Codable shape)

/// JSON schema for a user-widget JSON file.
/// Mirrors CatalogEntry fields; `codeSnippet` and `ssimStatus` default.
public struct UserWidgetEntry: Sendable, Codable, Identifiable {
    public let id: String
    public let widgetKind: String
    public let displayName: String
    public let description: String
    public let primitives: String
    public let wave: String
    public let ssimStatus: String
    public let codeSnippet: String?

    public init(
        id: String,
        widgetKind: String,
        displayName: String,
        description: String,
        primitives: String = "",
        wave: String = "user",
        ssimStatus: String = "user",
        codeSnippet: String? = nil
    ) {
        self.id = id
        self.widgetKind = widgetKind
        self.displayName = displayName
        self.description = description
        self.primitives = primitives
        self.wave = wave
        self.ssimStatus = ssimStatus
        self.codeSnippet = codeSnippet
    }

    /// Convert to CatalogEntry for use in existing views.
    public func catalogEntry() -> CatalogEntry {
        CatalogEntry(
            id: id,
            widgetKind: widgetKind,
            displayName: displayName,
            description: description,
            primitives: primitives,
            wave: wave,
            ssimStatus: ssimStatus,
            codeSnippet: codeSnippet
        )
    }
}

// MARK: - UserWidgetCatalog

/// Observable catalog loader for operator-authored user widgets.
///
/// Instantiate once at app launch and pass into StorybookBrowserView.
/// Entries update on file change via FileMonitor.
@MainActor
public final class UserWidgetCatalog: ObservableObject {

    /// Default scan directory: ~/.shikki/storybook/user-widgets/
    public static var defaultDirectory: URL {
        if let override = ProcessInfo.processInfo.environment["SHIKKI_STORYBOOK_USER_WIDGETS"] {
            return URL(fileURLWithPath: override, isDirectory: true)
        }
        return FileManager.default.homeDirectoryForCurrentUser
            .appendingPathComponent(".shikki/storybook/user-widgets", isDirectory: true)
    }

    @Published public private(set) var entries: [CatalogEntry] = []

    private let directory: URL
    private var fileMonitor: FileMonitor?

    public init(directory: URL? = nil) {
        self.directory = directory ?? Self.defaultDirectory
        reload()
        startMonitoring()
    }

    deinit {
        fileMonitor?.stop()
    }

    // MARK: - Loading

    public func reload() {
        let fm = FileManager.default
        guard fm.fileExists(atPath: directory.path) else {
            entries = []
            return
        }

        let decoder = JSONDecoder()
        var loaded: [CatalogEntry] = []

        let urls = (try? fm.contentsOfDirectory(
            at: directory,
            includingPropertiesForKeys: nil,
            options: [.skipsHiddenFiles]
        )) ?? []

        for url in urls where url.pathExtension == "json" {
            guard let data = try? Data(contentsOf: url) else { continue }
            if let entry = try? decoder.decode(UserWidgetEntry.self, from: data) {
                loaded.append(entry.catalogEntry())
            }
        }

        entries = loaded.sorted { $0.displayName < $1.displayName }
    }

    // MARK: - File monitoring

    private func startMonitoring() {
        let fm = FileManager.default
        if !fm.fileExists(atPath: directory.path) {
            try? fm.createDirectory(at: directory, withIntermediateDirectories: true)
        }
        fileMonitor = FileMonitor(url: directory) { [weak self] in
            Task { @MainActor [weak self] in
                self?.reload()
            }
        }
        fileMonitor?.start()
    }
}

// MARK: - FileMonitor

/// Watches a directory for changes using DispatchSource EVFILT_VNODE.
/// Coalesces rapid events with a 500ms debounce.
public final class FileMonitor: @unchecked Sendable {
    private let url: URL
    private let callback: @Sendable () -> Void
    private var source: DispatchSourceFileSystemObject?
    private var debounceWorkItem: DispatchWorkItem?
    private let queue = DispatchQueue(label: "one.obyw.shikki.filemonitor", qos: .utility)

    public init(url: URL, callback: @escaping @Sendable () -> Void) {
        self.url = url
        self.callback = callback
    }

    public func start() {
        let fd = open(url.path, O_EVTONLY)
        guard fd >= 0 else { return }

        let src = DispatchSource.makeFileSystemObjectSource(
            fileDescriptor: fd,
            eventMask: [.write, .rename, .delete, .link],
            queue: queue
        )

        src.setEventHandler { [weak self] in
            self?.debounce()
        }
        src.setCancelHandler {
            close(fd)
        }
        src.resume()
        self.source = src
    }

    public func stop() {
        source?.cancel()
        source = nil
    }

    private func debounce() {
        debounceWorkItem?.cancel()
        let work = DispatchWorkItem { [weak self] in
            self?.callback()
        }
        debounceWorkItem = work
        queue.asyncAfter(deadline: .now() + 0.5, execute: work)
    }
}
