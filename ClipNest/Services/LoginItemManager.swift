import Combine
import ServiceManagement

@MainActor
final class LoginItemManager: ObservableObject {
    @Published private(set) var status = SMAppService.mainApp.status
    @Published private(set) var issue: String?

    var isEnabled: Bool { status == .enabled || status == .requiresApproval }

    func refresh() { status = SMAppService.mainApp.status }

    func setEnabled(_ enabled: Bool) {
        do {
            if enabled { try SMAppService.mainApp.register() }
            else { try SMAppService.mainApp.unregister() }
            issue = nil
        } catch {
            issue = "Launch at login could not be changed: \(error.localizedDescription)"
        }
        refresh()
    }

    func openSettings() { SMAppService.openSystemSettingsLoginItems() }
}
