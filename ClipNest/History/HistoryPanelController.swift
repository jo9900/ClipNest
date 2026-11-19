import AppKit
import SwiftUI

@MainActor
final class HistoryPanelController: NSObject, NSWindowDelegate {
    private let store: HistoryStore
    private let monitor: ClipboardMonitor
    private let selection = HistorySelection()
    private let panel: NSPanel
    private var keyboardMonitor: Any?
    private var previousApp: NSRunningApplication?
    var showSettings: (() -> Void)?
    var shortcutAvailable = true

    init(store: HistoryStore, monitor: ClipboardMonitor) {
        self.store = store
        self.monitor = monitor
        panel = NSPanel(contentRect: NSRect(x: 0, y: 0, width: 560, height: 520),
                        styleMask: [.titled, .fullSizeContentView], backing: .buffered, defer: false)
        super.init()
        panel.title = "Copiary Clipboard"
        panel.titleVisibility = .hidden
        panel.titlebarAppearsTransparent = true
        panel.isMovable = false
        panel.isFloatingPanel = true
        panel.hidesOnDeactivate = false
        panel.level = .floating
        panel.collectionBehavior = [.moveToActiveSpace, .fullScreenAuxiliary]
        panel.isReleasedWhenClosed = false
        panel.delegate = self
        keyboardMonitor = NSEvent.addLocalMonitorForEvents(matching: .keyDown) { [weak self] event in
            guard let self, event.window === self.panel,
                  event.modifierFlags.intersection([.command, .option, .control, .shift]).isEmpty else { return event }
            if let editor = self.panel.firstResponder as? NSTextView, editor.hasMarkedText() { return event }
            switch event.keyCode {
            case 53: self.dismiss()
            case 125: self.selection.move(1, in: self.store.entries)
            case 126: self.selection.move(-1, in: self.store.entries)
            case 36, 76:
                guard let entry = self.selection.selected(in: self.store.entries) else { return event }
                self.copy(entry)
            default: return event
            }
            return nil
        }
    }

    func toggle() {
        if panel.isVisible { dismiss() } else { show() }
    }

    func show() {
        let frontmost = NSWorkspace.shared.frontmostApplication
        if frontmost?.processIdentifier != ProcessInfo.processInfo.processIdentifier { previousApp = frontmost }
        selection.query = ""
        panel.contentView = NSHostingView(rootView: HistoryPanelView(
            store: store, monitor: monitor, selection: selection, shortcutAvailable: shortcutAvailable,
            copy: { [weak self] in self?.copy($0) }, clear: { [weak self] in self?.monitor.clearHistory() },
            settings: { [weak self] in self?.openSettings() }, dismiss: { [weak self] in self?.dismiss() }
        ))
        let screen = NSScreen.screens.first { $0.frame.contains(NSEvent.mouseLocation) } ?? NSScreen.main
        if let frame = screen?.visibleFrame {
            panel.setFrameOrigin(NSPoint(x: frame.midX - panel.frame.width / 2,
                                         y: frame.midY - panel.frame.height / 2))
        }
        NSApp.activate(ignoringOtherApps: true)
        panel.makeKeyAndOrderFront(nil)
    }

    func dismiss(restoreFocus: Bool = true) {
        guard panel.isVisible else { return }
        // orderOut synchronously resigns key status; keep the restoration target outside that callback.
        let application = previousApp
        previousApp = nil
        panel.orderOut(nil)
        if restoreFocus { application?.activate(options: []) }
    }

    func shutdown() {
        if let keyboardMonitor { NSEvent.removeMonitor(keyboardMonitor) }
        keyboardMonitor = nil
    }

    func windowDidResignKey(_ notification: Notification) {
        dismiss(restoreFocus: false)
    }

    private func copy(_ entry: HistoryEntry) {
        if monitor.copy(entry) { dismiss() }
    }

    private func openSettings() {
        dismiss(restoreFocus: false)
        showSettings?()
    }
}
