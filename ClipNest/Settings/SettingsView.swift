import ServiceManagement
import SwiftUI

struct SettingsView: View {
    @ObservedObject var monitor: ClipboardMonitor
    @ObservedObject var login: LoginItemManager
    let shortcutAvailable: Bool

    var body: some View {
        Form {
            Section {
                Toggle("Launch at login", isOn: Binding(get: { login.isEnabled }, set: login.setEnabled))
                    .help("Start ClipNest quietly in the menu bar when you log in")
                if login.status == .requiresApproval {
                    Text("Approve ClipNest in Login Items to finish enabling startup.")
                        .font(.callout).foregroundStyle(.secondary)
                    Button("Open Login Items Settings", action: login.openSettings)
                }
                if let issue = login.issue {
                    Text(issue).font(.callout).foregroundStyle(.red)
                }
                Toggle("Pause recording", isOn: Binding(get: { monitor.isPaused }, set: { _ in monitor.togglePause() }))
                    .disabled(!monitor.hasStarted)
                LabeledContent {
                    if shortcutAvailable {
                        Text(verbatim: "⌥⌘V").environment(\.layoutDirection, .leftToRight)
                    } else {
                        Text("Menu bar (shortcut in use)")
                    }
                } label: { Text("Open history") }
            } header: { Text("General") }
            Section {
                Text("Up to 20 text clips and links are saved on this Mac, including across restarts. Older clips are removed automatically.")
                Text("Clips marked as concealed or temporary by the source app are ignored. Other sensitive text can still be saved; pause recording when needed.")
                Text("Choose a clip to copy it, then press ⌘V in your app to paste.")
                if let issue = monitor.accessIssue {
                    Text(issue)
                    Button("Retry Clipboard Access") { monitor.poll(userInitiated: true) }
                }
            } header: { Text("Your clipboard stays yours") }
            .font(.system(size: 12))
            .foregroundStyle(.secondary)
            HStack {
                Text("ClipNest 1.0 · Free & open source").font(.caption).foregroundStyle(.secondary)
                Spacer()
                Button("Quit ClipNest") { NSApp.terminate(nil) }
            }
        }
        .formStyle(.grouped)
        .environment(\.layoutDirection, Locale.Language(identifier: Bundle.main.preferredLocalizations.first ?? "en")
            .characterDirection == .rightToLeft ? .rightToLeft : .leftToRight)
        .frame(width: 440, height: 420)
        .onAppear { login.refresh() }
        .onReceive(NotificationCenter.default.publisher(for: NSApplication.didBecomeActiveNotification)) { _ in
            login.refresh()
        }
    }
}
