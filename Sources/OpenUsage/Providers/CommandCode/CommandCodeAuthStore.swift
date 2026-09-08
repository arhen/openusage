import Foundation

/// Detects Command Code usage on the machine. Command Code's Provider API has no usage endpoint
/// (probed 2026-09: only chat/messages/models exist), so the card is fed entirely from local harness
/// logs — pi's session JSONL carries authoritative per-message costs. No network credential is read:
/// the probe checks pi's auth store for a `commandcode` key as the "user has this" signal.
struct CommandCodeAuthStore: Sendable {
    private let files: TextFileAccessing
    private let homeDirectory: @Sendable () -> URL

    init(
        files: TextFileAccessing = LocalTextFileAccessor(),
        homeDirectory: @escaping @Sendable () -> URL = { FileManager.default.homeDirectoryForCurrentUser }
    ) {
        self.files = files
        self.homeDirectory = homeDirectory
    }

    /// True when pi has a Command Code credential stored (pi writes `auth.json` with a `commandcode`
    /// object holding `key`). Parse-tolerant: a malformed file counts as absent, never a crash.
    func hasPiCredential() -> Bool {
        let path = homeDirectory().appendingPathComponent(".pi/agent/auth.json").path
        guard let text = try? files.readTextIfPresent(path),
              let root = ProviderParse.jsonObject(Data(text.utf8)),
              let entry = root["commandcode"] as? [String: Any]
        else { return false }
        return (entry["key"] as? String)?.trimmingCharacters(in: .whitespacesAndNewlines).nilIfEmpty != nil
    }
}
