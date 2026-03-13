import AppKit
import ApplicationServices

/// Resolve a running application by name or bundle identifier and return its root AXUIElement.
enum AppResolver {
    static func findRunningApp(_ nameOrBundle: String) -> AXUIElement? {
        let apps = NSWorkspace.shared.runningApplications
        let query = nameOrBundle.lowercased()
        let match = apps.first {
            $0.localizedName?.lowercased() == query ||
            $0.bundleIdentifier?.lowercased() == query
        }
        guard let pid = match?.processIdentifier else { return nil }
        return AXUIElementCreateApplication(pid)
    }

    /// List running apps that are regular (have UI) for discovery.
    static func listRunningApps() -> [(name: String, bundle: String, pid: pid_t)] {
        NSWorkspace.shared.runningApplications
            .filter { $0.activationPolicy == .regular }
            .compactMap { app in
                guard let name = app.localizedName,
                      let bundle = app.bundleIdentifier else { return nil }
                return (name: name, bundle: bundle, pid: app.processIdentifier)
            }
            .sorted { $0.name.lowercased() < $1.name.lowercased() }
    }
}
