import XCTest
@testable import ClipNest

@MainActor
final class HistorySelectionTests: XCTestCase {
    func testSearchKeyboardBoundsAndDeletedSelection() {
        let entries = [HistoryEntry(text: "Café"), HistoryEntry(text: "SWIFT\nhello"), HistoryEntry(text: "你好")]
        let selection = HistorySelection()
        XCTAssertEqual(selection.selected(in: entries)?.id, entries[0].id)
        selection.move(-1, in: entries)
        XCTAssertEqual(selection.selectedID, entries[0].id)
        selection.move(1, in: entries)
        XCTAssertEqual(selection.selectedID, entries[1].id)
        selection.move(99, in: entries)
        XCTAssertEqual(selection.selectedID, entries[2].id)
        XCTAssertEqual(selection.selected(in: Array(entries.prefix(2)))?.id, entries[0].id)
        selection.query = " swift "
        XCTAssertEqual(selection.results(in: entries), [entries[1]])
        selection.query = "cafe"
        XCTAssertEqual(selection.results(in: entries), [entries[0]])
        selection.query = "missing"
        selection.move(1, in: entries)
        XCTAssertNil(selection.selected(in: entries))
        XCTAssertNil(selection.selected(in: []))
    }
}
