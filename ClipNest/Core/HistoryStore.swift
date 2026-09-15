import Combine
import Foundation

@MainActor
final class HistoryStore: ObservableObject {
    static let capacity = 20
    static let maximumTextBytes = 1_048_576

    @Published private(set) var entries: [HistoryEntry] = []
    @Published private(set) var storageIssue: String?
    private let fileURL: URL
    private var canSave = true

    init(fileURL: URL = HistoryStore.defaultURL) {
        self.fileURL = fileURL
        load()
    }

    nonisolated static var defaultURL: URL {
        FileManager.default.urls(for: .applicationSupportDirectory, in: .userDomainMask)[0]
            .appendingPathComponent("ClipNest", isDirectory: true)
            .appendingPathComponent("history.json")
    }

    @discardableResult
    func add(_ text: String, at date: Date = Date()) -> Bool {
        guard Self.accepts(text) else { return false }
        if entries.first?.text == text { return false }
        entries.removeAll { $0.text == text }
        entries.insert(HistoryEntry(text: text, copiedAt: date), at: 0)
        entries = Array(entries.prefix(Self.capacity))
        save()
        return true
    }

    func remove(_ id: UUID) {
        entries.removeAll { $0.id == id }
        save()
    }

    @discardableResult
    func clear() -> Bool {
        do {
            if FileManager.default.fileExists(atPath: fileURL.path) {
                try FileManager.default.removeItem(at: fileURL)
            }
            entries = []
            storageIssue = nil
            canSave = true
            return true
        } catch {
            storageIssue = "Could not clear saved history. Check available disk access and try again."
            return false
        }
    }

    static func accepts(_ text: String) -> Bool {
        text.utf8.count <= maximumTextBytes && text.contains { !$0.isWhitespace }
    }

    private func load() {
        guard FileManager.default.fileExists(atPath: fileURL.path) else { return }
        do {
            let data = try Data(contentsOf: fileURL, options: .mappedIfSafe)
            // JSON escaping can expand each input byte to six bytes.
            guard data.count <= Self.capacity * Self.maximumTextBytes * 6 + 65_536 else {
                throw CocoaError(.fileReadCorruptFile)
            }
            let saved = try JSONDecoder().decode([HistoryEntry].self, from: data)
            var seenText = Set<String>()
            var seenIDs = Set<UUID>()
            entries = Array(saved.filter {
                Self.accepts($0.text) && seenText.insert($0.text).inserted && seenIDs.insert($0.id).inserted
            }.prefix(Self.capacity))
        } catch {
            canSave = false
            storageIssue = "Saved history could not be read. New copies stay in memory. Clear All to start fresh."
        }
    }

    private func save() {
        guard canSave else { return }
        // ponytail: bounded to 20 × 1 MiB; move writes off-main if profiling shows stalls with large clips.
        do {
            try FileManager.default.createDirectory(
                at: fileURL.deletingLastPathComponent(), withIntermediateDirectories: true,
                attributes: [.posixPermissions: 0o700]
            )
            try JSONEncoder().encode(entries).write(to: fileURL, options: .atomic)
            try FileManager.default.setAttributes([.posixPermissions: 0o600], ofItemAtPath: fileURL.path)
            storageIssue = nil
        } catch {
            storageIssue = "History is in memory, but could not be saved. Check disk space and folder access."
        }
    }
}
