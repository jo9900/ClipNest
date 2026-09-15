import SwiftUI

struct HistoryRow: View {
    let entry: HistoryEntry
    let isSelected: Bool
    let copy: () -> Void
    let remove: () -> Void
    @State private var isHovered = false

    var body: some View {
        Button(action: copy) {
            HStack(spacing: 12) {
                Image(systemName: entry.isLink ? "link" : "doc.text")
                    .font(.system(size: 18, weight: .regular))
                    .foregroundStyle(isSelected ? Color.accentColor : .secondary)
                    .frame(width: 36, height: 38)
                    .background(Color.primary.opacity(0.035), in: RoundedRectangle(cornerRadius: 8))
                    .accessibilityHidden(true)
                VStack(alignment: .leading, spacing: 5) {
                    Text(verbatim: entry.preview)
                        .font(.system(size: 13, weight: .medium))
                        .lineLimit(2)
                        .multilineTextAlignment(.leading)
                        .frame(maxWidth: .infinity, alignment: .leading)
                    HStack(spacing: 6) {
                        Text(entry.isLink ? "Link" : "Text")
                        Text("·")
                        Text(entry.copiedAt, style: .relative)
                        Spacer()
                        if isSelected { Image(systemName: "return").accessibilityHidden(true) }
                    }
                    .font(.system(size: 10))
                    .foregroundStyle(.secondary)
                }
            }
            .padding(10)
            .frame(minHeight: 68)
            .background(background, in: RoundedRectangle(cornerRadius: 10))
            .overlay {
                RoundedRectangle(cornerRadius: 10)
                    .strokeBorder(isSelected ? Color.accentColor.opacity(0.45) : .clear, lineWidth: 1)
            }
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .onHover { isHovered = $0 }
        .accessibilityLabel("Copy \(entry.preview)")
        .accessibilityHint("Copies this entry and closes the history panel")
        .contextMenu { Button("Delete Entry", role: .destructive, action: remove) }
    }

    private var background: Color {
        if isSelected { return Color.accentColor.opacity(0.09) }
        return Color.primary.opacity(isHovered ? 0.05 : 0.015)
    }
}
