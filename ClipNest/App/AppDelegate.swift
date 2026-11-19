import AppKit
import SwiftUI

@MainActor
final class AppDelegate: NSObject, NSApplicationDelegate {
    private var statusItem: NSStatusItem?
    private var store: HistoryStore!
    private var monitor: ClipboardMonitor!
    private var panel: HistoryPanelController!
    private var shortcut: GlobalHotKey?
    private let login = LoginItemManager()
    private var settingsWindow: NSWindow?
    private var isPreview = false
    #if DEBUG
    private var preview: PreviewFixture?
    #endif

    func applicationDidFinishLaunching(_ notification: Notification) {
        // Hosted unit tests must never read the user's clipboard or register shortcuts.
        guard NSClassFromString("XCTestCase") == nil else { return }
        #if DEBUG
        if ProcessInfo.processInfo.environment["CLIPNEST_PREVIEW"] != nil {
            let fixture = PreviewFixture()
            preview = fixture
            store = fixture.store
            monitor = fixture.monitor
            isPreview = true
        }
        #endif
        if store == nil {
            store = HistoryStore()
            monitor = ClipboardMonitor(store: store)
        }
        panel = HistoryPanelController(store: store, monitor: monitor)
        panel.showSettings = { [weak self] in self?.openSettings() }
        shortcut = GlobalHotKey { [weak self] in self?.panel.toggle() }
        panel.shortcutAvailable = shortcut?.isRegistered == true
        let item = NSStatusBar.system.statusItem(withLength: NSStatusItem.squareLength)
        if let button = item.button {
            button.image = NSImage(systemSymbolName: "square.on.square", accessibilityDescription: "Copiary Clipboard")
            button.image?.isTemplate = true
            button.toolTip = String(localized: "Copiary Clipboard (⌥⌘V)")
            button.target = self
            button.action = #selector(statusClicked)
            button.sendAction(on: [.leftMouseUp, .rightMouseUp])
        }
        statusItem = item
        monitor.start()
        if !monitor.hasStarted || isPreview { panel.show() }
    }

    func applicationShouldHandleReopen(_ sender: NSApplication, hasVisibleWindows flag: Bool) -> Bool {
        panel?.show()
        return true
    }

    func applicationWillTerminate(_ notification: Notification) {
        monitor?.stop()
        panel?.shutdown()
        shortcut?.unregister()
        #if DEBUG
        preview?.cleanUp()
        #endif
    }

    @objc private func statusClicked() {
        guard let event = NSApp.currentEvent, let button = statusItem?.button else { return }
        if event.type == .rightMouseUp {
            let menu = NSMenu()
            menu.addItem(item(String(localized: "Open History"), action: #selector(openHistory)))
            menu.addItem(item(monitor.isPaused ? String(localized: "Resume Recording") : String(localized: "Pause Recording"), action: #selector(togglePause)))
            menu.addItem(.separator())
            menu.addItem(item(String(localized: "Settings…"), action: #selector(openSettings)))
            menu.addItem(item(String(localized: "Quit Copiary Clipboard"), action: #selector(quit)))
            NSMenu.popUpContextMenu(menu, with: event, for: button)
        } else {
            panel.toggle()
        }
    }

    private func item(_ title: String, action: Selector) -> NSMenuItem {
        let item = NSMenuItem(title: title, action: action, keyEquivalent: "")
        item.target = self
        return item
    }

    @objc private func openHistory() { panel.show() }
    @objc private func togglePause() { if monitor.hasStarted { monitor.togglePause() } else { panel.show() } }
    @objc private func quit() { NSApp.terminate(nil) }

    @objc private func openSettings() {
        if settingsWindow == nil {
            let window = NSWindow(contentRect: NSRect(x: 0, y: 0, width: 440, height: 420),
                                  styleMask: [.titled, .closable], backing: .buffered, defer: false)
            window.title = String(localized: "Copiary Clipboard Settings")
            window.isReleasedWhenClosed = false
            window.contentView = NSHostingView(rootView: SettingsView(monitor: monitor, login: login,
                                                                     shortcutAvailable: shortcut?.isRegistered == true))
            settingsWindow = window
        }
        panel.dismiss(restoreFocus: false)
        login.refresh()
        settingsWindow?.center()
        NSApp.activate(ignoringOtherApps: true)
        settingsWindow?.makeKeyAndOrderFront(nil)
    }
}
