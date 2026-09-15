import SwiftUI

struct HistoryPanelView: View {
    @ObservedObject var store: HistoryStore
    @ObservedObject var monitor: ClipboardMonitor
    @ObservedObject var selection: HistorySelection
    let shortcutAvailable: Bool
    let copy: (HistoryEntry) -> Void
    let clear: () -> Void
    let settings: () -> Void
    let dismiss: () -> Void
    @FocusState private var searchFocused: Bool

    private var results: [HistoryEntry] { selection.results(in: store.entries) }

    var body: some View {
        VStack(spacing: 0) {
            header.padding(.horizontal, 20).padding(.top, 20).padding(.bottom, 16)
            if monitor.hasStarted {
                search.padding(.horizontal, 20).padding(.bottom, 12)
            }
            if let issue = store.storageIssue ?? monitor.copyIssue ?? monitor.accessIssue {
                Text(issue)
                    .font(.system(size: 12))
                    .foregroundStyle(.primary)
                    .padding(10)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .background(Color.orange.opacity(0.12), in: RoundedRectangle(cornerRadius: 8))
                    .padding(.horizontal, 20).padding(.bottom, 8)
            }
            if !monitor.hasStarted {
                emptyState(symbol: "square.on.square", title: "A little room for your copies.",
                           detail: "Keep your last 20 text clips and links on this Mac.\nChoose one whenever you need it again.") {
                    Button("Start Saving History") { monitor.enable(); searchFocused = true }
                        .buttonStyle(.borderedProminent).controlSize(.large)
                }
            } else if store.entries.isEmpty {
                emptyState(symbol: monitor.isPaused ? "pause.circle" : "doc.on.clipboard",
                           title: monitor.isPaused ? "History is paused." : "Your next copy starts here.",
                           detail: monitor.isPaused ? "Resume to save new text and links." : "Copy some text or a link in any app.\nIt will be waiting right here.") {
                    if monitor.isPaused { Button("Resume Recording") { monitor.togglePause() } }
                }
            } else if results.isEmpty {
                emptyState(symbol: "magnifyingglass", title: "No matching clips.",
                           detail: "Try a different word or clear your search.") {
                    Button("Clear Search") { selection.query = ""; searchFocused = true }
                }
            } else {
                historyList
            }
            Divider()
            footer.padding(.horizontal, 20).padding(.vertical, 12)
        }
        .background(Color(nsColor: .windowBackgroundColor))
        .ignoresSafeArea(edges: .top)
        .onAppear { DispatchQueue.main.async { searchFocused = true } }
        .onExitCommand(perform: dismiss)
    }

    private var header: some View {
        HStack(spacing: 10) {
            Image(nsImage: NSApplication.shared.applicationIconImage)
                .resizable().frame(width: 36, height: 36).accessibilityHidden(true)
            VStack(alignment: .leading, spacing: 3) {
                Text("ClipNest").font(.system(size: 18, weight: .semibold))
                Text(monitor.isPaused ? "Recording paused" : "A home for your last 20 copies")
                    .font(.system(size: 11)).foregroundStyle(.secondary)
            }
            Spacer()
            Button(action: settings) { Image(systemName: "gearshape").frame(width: 26, height: 26) }
                .buttonStyle(.plain).help("Settings").accessibilityLabel("Settings")
            Button(action: dismiss) { Image(systemName: "xmark").frame(width: 26, height: 26) }
                .buttonStyle(.plain).help("Close (Esc)").accessibilityLabel("Close history")
        }
    }

    private var search: some View {
        HStack(spacing: 8) {
            Image(systemName: "magnifyingglass").foregroundStyle(.secondary).accessibilityHidden(true)
            TextField("Search your clipboard", text: $selection.query)
                .textFieldStyle(.plain).focused($searchFocused)
                .accessibilityLabel("Search clipboard history")
                .onSubmit { if let entry = selection.selected(in: store.entries) { copy(entry) } }
            Text("\(store.entries.count)/20").font(.system(size: 11).monospacedDigit()).foregroundStyle(.secondary)
        }
        .padding(11)
        .background(Color(nsColor: .textBackgroundColor), in: RoundedRectangle(cornerRadius: 8))
        .overlay { RoundedRectangle(cornerRadius: 8).strokeBorder(Color.primary.opacity(0.12)) }
    }

    private var historyList: some View {
        ScrollViewReader { proxy in
            ScrollView {
                LazyVStack(spacing: 5) {
                    ForEach(results) { entry in
                        HistoryRow(entry: entry, isSelected: selection.selected(in: store.entries)?.id == entry.id,
                                   copy: { copy(entry) }, remove: { store.remove(entry.id) })
                            .id(entry.id)
                    }
                }
                .padding(.horizontal, 20).padding(.bottom, 12)
            }
            .onReceive(selection.$selectedID) { id in
                if let id { proxy.scrollTo(id, anchor: .center) }
            }
        }
    }

    private var footer: some View {
        HStack {
            Text(shortcutAvailable ? "↑↓ browse   ↩ copy   esc close" : "Open from the menu bar · shortcut unavailable")
                .font(.system(size: 10)).foregroundStyle(.secondary)
            Spacer(minLength: 4)
            Button(action: clear) { Label("Clear All", systemImage: "trash").font(.system(size: 11)) }
                .buttonStyle(.plain)
                .disabled(store.entries.isEmpty && store.storageIssue == nil)
                .accessibilityLabel("Clear all clipboard history")
        }
    }

    private func emptyState<Actions: View>(symbol: String, title: String, detail: String,
                                           @ViewBuilder actions: () -> Actions) -> some View {
        VStack(spacing: 14) {
            Spacer()
            Image(systemName: symbol).font(.system(size: 34, weight: .light)).foregroundStyle(Color.accentColor)
            Text(title).font(.system(size: 17, weight: .semibold))
            Text(detail).font(.system(size: 12)).foregroundStyle(.secondary).multilineTextAlignment(.center)
            actions().padding(.top, 5)
            Spacer()
            Text("Saved locally. No account. No cloud.")
                .font(.system(size: 10)).foregroundStyle(.secondary).padding(.bottom, 20)
        }.frame(maxWidth: .infinity).padding(.horizontal, 20)
    }
}
