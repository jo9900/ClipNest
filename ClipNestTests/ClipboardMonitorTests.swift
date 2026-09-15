import AppKit
import XCTest
@testable import ClipNest

@MainActor
final class ClipboardMonitorTests: XCTestCase {
    func testCapturePrivacyPauseCopyAndClearUseAnIsolatedPasteboard() throws {
        let suite = "ClipNestTests.\(UUID())"
        let defaults = try XCTUnwrap(UserDefaults(suiteName: suite))
        let directory = FileManager.default.temporaryDirectory.appendingPathComponent(suite)
        let store = HistoryStore(fileURL: directory.appendingPathComponent("history.json"))
        let pasteboard = NSPasteboard.withUniqueName()
        defer {
            pasteboard.releaseGlobally()
            defaults.removePersistentDomain(forName: suite)
            try? FileManager.default.removeItem(at: directory)
        }
        let monitor = ClipboardMonitor(store: store, pasteboard: pasteboard, defaults: defaults)
        func write(_ text: String, marker: NSPasteboard.PasteboardType? = nil) {
            pasteboard.clearContents()
            pasteboard.setString(text, forType: .string)
            if let marker { pasteboard.setData(Data(), forType: marker) }
        }

        write("before consent")
        monitor.poll()
        XCTAssertTrue(store.entries.isEmpty)
        monitor.enable()
        monitor.poll()
        XCTAssertTrue(store.entries.isEmpty)
        write("first")
        monitor.poll()
        XCTAssertEqual(store.entries.map(\.text), ["first"])
        for marker in ClipboardMonitor.ignoredTypes {
            write("private", marker: marker)
            monitor.poll()
        }
        XCTAssertEqual(store.entries.map(\.text), ["first"])

        monitor.togglePause()
        let relaunched = ClipboardMonitor(store: store, pasteboard: pasteboard, defaults: defaults)
        XCTAssertTrue(relaunched.isPaused)
        write("during pause")
        monitor.poll()
        monitor.togglePause()
        monitor.poll()
        XCTAssertEqual(store.entries.map(\.text), ["first"])
        write("second")
        monitor.poll()
        let old = try XCTUnwrap(store.entries.last)
        XCTAssertTrue(monitor.copy(old))
        XCTAssertEqual(pasteboard.string(forType: .string), "first")
        monitor.poll()
        XCTAssertEqual(store.entries.map(\.text), ["second", "first"])

        monitor.clearHistory()
        monitor.poll()
        XCTAssertTrue(store.entries.isEmpty)
        XCTAssertEqual(pasteboard.string(forType: .string), "first")
        write("after clear")
        monitor.poll()
        XCTAssertEqual(store.entries.map(\.text), ["after clear"])
    }
}
