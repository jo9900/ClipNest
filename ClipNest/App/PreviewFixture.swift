#if DEBUG
import AppKit

/// Isolated content for UI review and screenshots; never reads the general clipboard.
@MainActor
final class PreviewFixture {
    let store: HistoryStore
    let monitor: ClipboardMonitor
    private let pasteboard = NSPasteboard.withUniqueName()
    private let suite = "com.jo9900.ClipNest.Preview"
    private let directory = FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString)

    init() {
        if ProcessInfo.processInfo.environment["CLIPNEST_PREVIEW_APPEARANCE"] == "light" {
            NSApp.appearance = NSAppearance(named: .aqua)
        }
        store = HistoryStore(fileURL: directory.appendingPathComponent("history.json"))
        let defaults = UserDefaults(suiteName: suite)!
        defaults.removePersistentDomain(forName: suite)
        monitor = ClipboardMonitor(store: store, pasteboard: pasteboard, defaults: defaults)
        if ProcessInfo.processInfo.environment["CLIPNEST_PREVIEW"] != "empty" {
            monitor.enable()
            let samples = [
                "Design is how it works.",
                "你好，世界。Hello, world.",
                "let idea = \"Keep it simple.\"",
                "https://developer.apple.com/swift/",
                "A place for the things you want to come back to."
            ]
            for (index, text) in samples.enumerated() {
                store.add(text, at: Date().addingTimeInterval(Double(index - samples.count) * 60))
            }
        }
    }

    func cleanUp() {
        monitor.stop()
        pasteboard.releaseGlobally()
        UserDefaults(suiteName: suite)?.removePersistentDomain(forName: suite)
        try? FileManager.default.removeItem(at: directory)
    }
}
#endif
