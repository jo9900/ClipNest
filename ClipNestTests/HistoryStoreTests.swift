import XCTest
@testable import ClipNest

@MainActor
final class HistoryStoreTests: XCTestCase {
    private func location() throws -> URL {
        let directory = FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString)
        try FileManager.default.createDirectory(at: directory, withIntermediateDirectories: true)
        addTeardownBlock { try? FileManager.default.removeItem(at: directory) }
        return directory.appendingPathComponent("history.json")
    }

    func testCapacityDeduplicationAndExactTextSurviveRelaunch() throws {
        let url = try location()
        let store = HistoryStore(fileURL: url)
        for index in 1...25 { store.add("Clip \(index)") }
        XCTAssertEqual(store.entries.count, 20)
        XCTAssertEqual(store.entries.first?.text, "Clip 25")
        XCTAssertEqual(store.entries.last?.text, "Clip 6")
        store.add("Clip 10")
        XCTAssertEqual(store.entries.first?.text, "Clip 10")
        XCTAssertEqual(store.entries.filter { $0.text == "Clip 10" }.count, 1)
        let id = store.entries.first?.id
        XCTAssertFalse(store.add("Clip 10"))
        XCTAssertEqual(store.entries.first?.id, id)
        let exact = "  你好 👩🏽‍💻\n\tlet value = 42  "
        XCTAssertTrue(store.add(exact))
        let restored = HistoryStore(fileURL: url)
        XCTAssertEqual(restored.entries, store.entries)
        XCTAssertEqual(restored.entries.first?.text, exact)
        XCTAssertNil(restored.storageIssue)
        let permissions = try FileManager.default.attributesOfItem(atPath: url.path)[.posixPermissions] as? Int
        XCTAssertEqual(permissions, 0o600)
    }

    func testEmptyOversizedRemoveAndClear() throws {
        let url = try location()
        let store = HistoryStore(fileURL: url)
        XCTAssertFalse(store.add(""))
        XCTAssertFalse(store.add(" \n\t "))
        XCTAssertFalse(store.add(String(repeating: "中", count: HistoryStore.maximumTextBytes / 3 + 1)))
        XCTAssertTrue(store.add(String(repeating: "a", count: HistoryStore.maximumTextBytes)))
        store.remove(try XCTUnwrap(store.entries.first?.id))
        XCTAssertTrue(HistoryStore(fileURL: url).entries.isEmpty)
        store.add("remove me")
        XCTAssertTrue(store.clear())
        XCTAssertFalse(FileManager.default.fileExists(atPath: url.path))
        XCTAssertTrue(HistoryStore(fileURL: url).entries.isEmpty)
    }

    func testCorruptFileIsPreservedUntilExplicitClear() throws {
        let url = try location()
        let corrupt = Data("broken saved history".utf8)
        try corrupt.write(to: url)
        let store = HistoryStore(fileURL: url)
        XCTAssertNotNil(store.storageIssue)
        store.add("new clip")
        XCTAssertEqual(try Data(contentsOf: url), corrupt)
        XCTAssertTrue(store.clear())
        store.add("fresh start")
        XCTAssertNil(store.storageIssue)
        XCTAssertEqual(HistoryStore(fileURL: url).entries.first?.text, "fresh start")
    }

    func testSaveFailureKeepsInMemoryHistoryAndReportsError() throws {
        let parent = try location()
        try Data("not a directory".utf8).write(to: parent)
        let store = HistoryStore(fileURL: parent.appendingPathComponent("history.json"))
        store.add("still available")
        XCTAssertEqual(store.entries.first?.text, "still available")
        XCTAssertNotNil(store.storageIssue)
    }

    func testLoadingNormalizesDuplicateAndInvalidEntries() throws {
        let url = try location()
        let duplicate = HistoryEntry(text: "kept once")
        let saved = [duplicate, duplicate, HistoryEntry(text: " \n")] + (1...25).map { HistoryEntry(text: "\($0)") }
        try JSONEncoder().encode(saved).write(to: url)
        let store = HistoryStore(fileURL: url)
        XCTAssertEqual(store.entries.count, 20)
        XCTAssertEqual(store.entries.filter { $0.text == duplicate.text }.count, 1)
        XCTAssertFalse(store.entries.contains { $0.text == " \n" })
    }
}
