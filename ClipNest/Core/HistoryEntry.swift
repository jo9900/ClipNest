import Foundation

struct HistoryEntry: Codable, Identifiable, Equatable {
    let id: UUID
    let text: String
    let copiedAt: Date

    init(text: String, copiedAt: Date = Date(), id: UUID = UUID()) {
        self.id = id
        self.text = text
        self.copiedAt = copiedAt
    }

    var preview: String {
        text.prefix(240).split(whereSeparator: \.isWhitespace).joined(separator: " ")
    }

    var isLink: Bool {
        guard text.utf8.count < 8_192,
              let url = URL(string: text), let scheme = url.scheme?.lowercased() else { return false }
        return ["https", "http"].contains(scheme) && url.host != nil
    }
}
