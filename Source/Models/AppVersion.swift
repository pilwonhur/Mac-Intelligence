import Foundation

/// Version info that `build_app.sh` stamps into Info.plist. A bare `run.sh` binary has no
/// Info.plist, so everything falls back to "dev".
enum AppVersion {
    /// Release version, from the VERSION file (CFBundleShortVersionString).
    static var version: String { info("CFBundleShortVersionString") ?? "dev" }

    /// Commit count at build time (CFBundleVersion) — rises with every commit.
    static var build: String? { info("CFBundleVersion") }

    /// Short commit hash, with "-dirty" appended if the build had uncommitted changes.
    static var commit: String? { info("MIGitCommit") }

    /// e.g. "1.1.0 (11 · 7fd0d35)"
    static var display: String {
        let detail = [build, commit].compactMap { $0 }.joined(separator: " · ")
        return detail.isEmpty ? version : "\(version) (\(detail))"
    }

    private static func info(_ key: String) -> String? {
        guard let value = Bundle.main.infoDictionary?[key] as? String, !value.isEmpty else { return nil }
        return value
    }
}
