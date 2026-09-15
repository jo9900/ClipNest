import Combine
import Foundation

@MainActor
final class HistorySelection: ObservableObject {
    @Published var query = "" {
        didSet { selectedID = nil }
    }
    @Published var selectedID: UUID?

    func results(in entries: [HistoryEntry]) -> [HistoryEntry] {
        let query = query.trimmingCharacters(in: .whitespacesAndNewlines)
        return query.isEmpty ? entries : entries.filter { $0.text.localizedStandardContains(query) }
    }

    func selected(in entries: [HistoryEntry]) -> HistoryEntry? {
        let results = results(in: entries)
        return results.first { $0.id == selectedID } ?? results.first
    }

    func move(_ offset: Int, in entries: [HistoryEntry]) {
        let results = results(in: entries)
        guard !results.isEmpty else { return }
        let index = results.firstIndex { $0.id == selectedID } ?? 0
        selectedID = results[min(max(index + offset, 0), results.count - 1)].id
    }
}
