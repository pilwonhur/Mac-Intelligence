import Foundation

/// Locates the vendor CLIs (`claude`, `codex`, `agy`) without relying on the shell PATH.
///
/// A GUI .app launched from Finder inherits a minimal PATH (`/usr/bin:/bin:/usr/sbin:/sbin`),
/// so the CLIs — which live in `~/.local/bin` and `/opt/homebrew/bin` — are invisible to it.
/// `agy` is worse: it is a shell *function* in the user's zsh profile, so it does not exist
/// outside an interactive shell at all, and the function delegates to the IDE when given
/// arguments. We therefore resolve absolute paths ourselves.
enum CLIDiscovery {

    /// User-supplied absolute path wins over auto-detection (Settings → "CLI path").
    static func overrideKey(for tool: CLIBackend.Tool) -> String { "cli_path_\(tool.command)" }

    static func override(for tool: CLIBackend.Tool) -> String? {
        let v = UserDefaults.standard.string(forKey: overrideKey(for: tool))?
            .trimmingCharacters(in: .whitespacesAndNewlines)
        return (v?.isEmpty == false) ? v : nil
    }

    static func setOverride(_ path: String?, for tool: CLIBackend.Tool) {
        let trimmed = path?.trimmingCharacters(in: .whitespacesAndNewlines) ?? ""
        if trimmed.isEmpty {
            UserDefaults.standard.removeObject(forKey: overrideKey(for: tool))
        } else {
            UserDefaults.standard.set(trimmed, forKey: overrideKey(for: tool))
        }
    }

    /// Absolute path to the CLI, or nil if it is not installed.
    static func locate(_ tool: CLIBackend.Tool) -> String? {
        if let override = override(for: tool) {
            let expanded = (override as NSString).expandingTildeInPath
            return isUsable(expanded, tool: tool) ? expanded : nil
        }
        for candidate in candidates(for: tool) where isUsable(candidate, tool: tool) {
            return candidate
        }
        return nil
    }

    private static func candidates(for tool: CLIBackend.Tool) -> [String] {
        let home = NSHomeDirectory()
        switch tool {
        case .claude:
            return ["\(home)/.local/bin/claude",
                    "\(home)/.claude/local/claude",
                    "/opt/homebrew/bin/claude",
                    "/usr/local/bin/claude"]
        case .codex:
            return ["/opt/homebrew/bin/codex",
                    "/usr/local/bin/codex",
                    "\(home)/.local/bin/codex",
                    "\(home)/.codex/bin/codex"]
        case .agy:
            // ~/.local/bin/agy is the real CLI dropped by the installer. A PATH hit may
            // instead point inside the Antigravity.app bundle — that launcher ignores -p
            // and opens a window, so it is filtered out in isUsable(_:tool:).
            return ["\(home)/.local/bin/agy",
                    "\(home)/.antigravity/antigravity/bin/agy",
                    "\(home)/.antigravity-ide/antigravity-ide/bin/agy",
                    "/opt/homebrew/bin/agy",
                    "/usr/local/bin/agy"]
        }
    }

    private static func isUsable(_ path: String, tool: CLIBackend.Tool) -> Bool {
        guard FileManager.default.isExecutableFile(atPath: path) else { return false }
        if tool == .agy {
            // Resolve symlinks: anything landing inside an .app bundle is the IDE launcher.
            let resolved = URL(fileURLWithPath: path).resolvingSymlinksInPath().path
            if resolved.contains(".app/") { return false }
        }
        return true
    }
}

/// Runs an already-logged-in vendor CLI headlessly and streams its answer back.
///
/// OAuth is handled entirely by the CLI itself — this app never sees a client_id, a token,
/// or a credentials file. It just spawns the tool the user installed and signed into, which
/// is what each vendor's headless mode (`claude -p`, `codex exec`, `agy -p`) is for.
final class CLIBackend {
    static let shared = CLIBackend()

    enum Tool: String, CaseIterable {
        case claude, codex, agy

        var command: String { rawValue }

        var displayName: String {
            switch self {
            case .claude: return "Claude Code"
            case .codex:  return "Codex CLI"
            case .agy:    return "Antigravity CLI"
            }
        }

        /// Whether the CLI emits token-level deltas in its JSON stream.
        /// `codex exec --json` does not — it emits the finished message in one
        /// `item.completed` event, so its answer appears all at once.
        var streamsDeltas: Bool { self != .codex }

        var loginHint: String {
            switch self {
            case .claude: return "Run `claude` in Terminal and sign in."
            case .codex:  return "Run `codex` in Terminal and sign in with ChatGPT."
            case .agy:    return "Run `agy` in Terminal and sign in."
            }
        }

        /// `claude` has WebSearch/WebFetch and `codex` has `--search`. `agy` has a
        /// `search_web` tool, but headless runs auto-deny tool permissions and the only
        /// override is `--dangerously-skip-permissions`, which would also auto-approve
        /// file writes and shell commands — too broad for this app.
        var supportsWebSearch: Bool { self != .agy }
    }

    private var process: Process?
    private var stdoutBuffer = Data()
    private var stderrText = ""
    private var sawText = false
    private var finished = false

    var isRunning: Bool { process?.isRunning ?? false }

    /// Spawns `tool` with `prompt` and streams text back on the main queue.
    /// `onComplete` fires exactly once.
    func stream(tool: Tool,
                model: String,
                systemPrompt: String,
                prompt: String,
                useWebSearch: Bool = false,
                onUpdate: @escaping (String) -> Void,
                onComplete: @escaping () -> Void) {

        cancel()
        stdoutBuffer = Data()
        stderrText = ""
        sawText = false
        finished = false

        guard let binary = CLIDiscovery.locate(tool) else {
            onUpdate("❌ \(tool.displayName) not found. Install it, or set its path in Settings. \(tool.loginHint)")
            onComplete()
            return
        }

        let proc = Process()
        proc.executableURL = URL(fileURLWithPath: binary)
        proc.arguments = arguments(for: tool, model: model, systemPrompt: systemPrompt,
                                   prompt: prompt,
                                   useWebSearch: useWebSearch && tool.supportsWebSearch)
        proc.currentDirectoryURL = scratchDirectory()
        proc.environment = childEnvironment()

        let outPipe = Pipe()
        let errPipe = Pipe()
        proc.standardOutput = outPipe
        proc.standardError = errPipe
        // codex reads instructions from stdin when it is not closed ("Reading additional
        // input from stdin..."), which would hang the panel forever.
        proc.standardInput = FileHandle.nullDevice

        let complete: () -> Void = { [weak self] in
            guard let self = self, !self.finished else { return }
            self.finished = true
            onComplete()
        }

        outPipe.fileHandleForReading.readabilityHandler = { [weak self] handle in
            let chunk = handle.availableData
            guard let self = self, !chunk.isEmpty else { return }
            DispatchQueue.main.async {
                self.consume(chunk, tool: tool, onUpdate: onUpdate, onComplete: complete)
            }
        }

        errPipe.fileHandleForReading.readabilityHandler = { [weak self] handle in
            let chunk = handle.availableData
            guard let self = self, !chunk.isEmpty,
                  let text = String(data: chunk, encoding: .utf8) else { return }
            DispatchQueue.main.async { self.stderrText += text }
        }

        proc.terminationHandler = { [weak self] finishedProc in
            outPipe.fileHandleForReading.readabilityHandler = nil
            errPipe.fileHandleForReading.readabilityHandler = nil
            DispatchQueue.main.async {
                guard let self = self, !self.finished else { return }
                if !self.sawText {
                    onUpdate(self.failureMessage(tool: tool, status: finishedProc.terminationStatus))
                }
                complete()
            }
        }

        do {
            try proc.run()
            process = proc
        } catch {
            onUpdate("❌ Could not launch \(tool.displayName): \(error.localizedDescription)")
            complete()
        }
    }

    func cancel() {
        if let proc = process, proc.isRunning { proc.terminate() }
        process = nil
    }

    // MARK: - Command lines

    private func arguments(for tool: Tool, model: String, systemPrompt: String,
                           prompt: String, useWebSearch: Bool) -> [String] {
        let model = model.trimmingCharacters(in: .whitespacesAndNewlines)
        // Everything except the search tools stays blocked: this is a Q&A panel, not a
        // coding agent pointed at the user's disk.
        let blockedTools = useWebSearch
            ? "Bash,Edit,Write,Read,Task,Skill,NotebookEdit"
            : "Bash,Edit,Write,Read,Task,Skill,WebSearch,WebFetch,NotebookEdit"
        switch tool {
        case .claude:
            // stream-json requires --verbose with -p; --include-partial-messages gives deltas.
            //
            // The context-trimming flags matter: every call ships Claude Code's agent
            // scaffolding, and a ghost-panel question is only a few dozen tokens against it.
            // Measured on claude-haiku-4-5, per short query:
            //   bare `claude -p X --output-format json` .. ~26,500 tokens
            //   + --setting-sources "" --strict-mcp-config ~17,150
            //   + --system-prompt --exclude-dynamic... ... ~10,850
            // --system-prompt replaces Claude Code's coding-agent prompt outright, which is
            // scaffolding this app never wants. (--bare would trim more but is API-key only:
            // "OAuth and keychain are never read".)
            var args = ["-p", prompt,
                        "--output-format", "stream-json",
                        "--include-partial-messages",
                        "--verbose",
                        "--strict-mcp-config",
                        "--setting-sources", "",
                        "--system-prompt", systemPrompt,
                        "--exclude-dynamic-system-prompt-sections",
                        "--disallowed-tools", blockedTools]
            // Dropping the search tools from --disallowed-tools is not enough — without an
            // explicit --allowed-tools the model reports no web search tool available.
            if useWebSearch { args += ["--allowed-tools", "WebSearch,WebFetch"] }
            if !model.isEmpty { args += ["--model", model] }
            return args
        case .codex:
            // No --system-prompt equivalent, so it rides along in the prompt text.
            var args = ["exec", "--json", "--skip-git-repo-check", "-s", "read-only"]
            // `--search` exists only on the top-level `codex` command, not on `exec`,
            // where the equivalent is a config override.
            if useWebSearch { args += ["-c", "tools.web_search=true"] }
            if !model.isEmpty { args += ["-m", model] }
            return args + ["\(systemPrompt)\n\n\(prompt)"]
        case .agy:
            var args = ["-p", "\(systemPrompt)\n\n\(prompt)",
                        "--output-format", "stream-json",
                        "--disable-slash-commands",
                        "--print-timeout", "5m"]
            if !model.isEmpty { args += ["--model", model] }
            return args
        }
    }

    /// The CLIs shell out to node/git, so give them a usable PATH.
    ///
    /// HOME/USER/LOGNAME are guaranteed rather than merely inherited: Claude Code keeps its
    /// OAuth session in the login keychain (`Claude Code-credentials`) and reports
    /// "Not logged in" when those are missing, which is exactly what a GUI process launched
    /// with a stripped environment would hit.
    private func childEnvironment() -> [String: String] {
        var env = ProcessInfo.processInfo.environment
        let home = NSHomeDirectory()
        env["HOME"] = home
        if (env["USER"] ?? "").isEmpty { env["USER"] = NSUserName() }
        if (env["LOGNAME"] ?? "").isEmpty { env["LOGNAME"] = NSUserName() }

        let extras = ["\(home)/.local/bin", "/opt/homebrew/bin", "/usr/local/bin",
                      "/usr/bin", "/bin", "/usr/sbin", "/sbin"]
        let existing = (env["PATH"] ?? "").split(separator: ":").map(String.init)
        var merged: [String] = []
        for path in extras + existing where !merged.contains(path) { merged.append(path) }
        env["PATH"] = merged.joined(separator: ":")
        return env
    }

    /// An empty working directory keeps the agentic CLIs from discovering CLAUDE.md,
    /// AGENTS.md, or whatever project happens to be in front of the user.
    private func scratchDirectory() -> URL {
        let dir = FileManager.default.temporaryDirectory
            .appendingPathComponent("MacIntelligence-cli", isDirectory: true)
        try? FileManager.default.createDirectory(at: dir, withIntermediateDirectories: true)
        return dir
    }

    // MARK: - NDJSON parsing

    private func consume(_ chunk: Data, tool: Tool,
                         onUpdate: @escaping (String) -> Void,
                         onComplete: @escaping () -> Void) {
        stdoutBuffer.append(chunk)
        while let newline = stdoutBuffer.firstIndex(of: 10) {
            let lineData = stdoutBuffer.prefix(upTo: newline)
            stdoutBuffer.removeSubrange(stdoutBuffer.startIndex...newline)
            guard let line = String(data: lineData, encoding: .utf8)?
                .trimmingCharacters(in: .whitespaces), line.hasPrefix("{"),
                  let data = line.data(using: .utf8),
                  let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any]
            else { continue }
            handle(json, tool: tool, onUpdate: onUpdate, onComplete: onComplete)
        }
    }

    private func handle(_ json: [String: Any], tool: Tool,
                        onUpdate: @escaping (String) -> Void,
                        onComplete: @escaping () -> Void) {
        switch tool {
        case .claude:
            // {"type":"stream_event","event":{"type":"content_block_delta",
            //   "delta":{"type":"text_delta","text":"..."}}}
            if json["type"] as? String == "stream_event",
               let event = json["event"] as? [String: Any],
               event["type"] as? String == "content_block_delta",
               let delta = event["delta"] as? [String: Any],
               let text = delta["text"] as? String {
                emit(text, onUpdate: onUpdate)
            } else if json["type"] as? String == "result" {
                if json["is_error"] as? Bool == true, let result = json["result"] as? String {
                    onUpdate(sawText ? "\n\n❌ \(result)" : "❌ \(result)")
                    sawText = true
                }
                onComplete()
            }

        case .codex:
            // No deltas in this mode: the finished message arrives whole.
            if json["type"] as? String == "item.completed",
               let item = json["item"] as? [String: Any],
               item["type"] as? String == "agent_message",
               let text = item["text"] as? String {
                emit(text, onUpdate: onUpdate)
            } else if json["type"] as? String == "turn.failed" || json["type"] as? String == "error" {
                let message = (json["message"] as? String)
                    ?? ((json["error"] as? [String: Any])?["message"] as? String)
                    ?? "Codex reported an error."
                onUpdate(sawText ? "\n\n❌ \(message)" : "❌ \(message)")
                sawText = true
                onComplete()
            } else if json["type"] as? String == "turn.completed" {
                onComplete()
            }

        case .agy:
            // {"event":"step_update","step_update":{"step_type":"agent_response",
            //   "text_delta":"..."}}
            if json["event"] as? String == "step_update",
               let step = json["step_update"] as? [String: Any],
               step["step_type"] as? String == "agent_response",
               let text = step["text_delta"] as? String {
                emit(text, onUpdate: onUpdate)
            } else if json["event"] as? String == "result" {
                let result = json["result"] as? [String: Any]
                let status = result?["status"] as? String ?? "UNKNOWN"
                if !sawText {
                    // agy reports SUCCESS with an empty response when a tool permission
                    // was auto-denied in headless mode.
                    let response = (result?["response"] as? String ?? "")
                        .trimmingCharacters(in: .whitespacesAndNewlines)
                    if response.isEmpty {
                        onUpdate("❌ Antigravity returned an empty response (status \(status)). "
                                 + "A tool permission was likely auto-denied in headless mode.")
                        sawText = true
                    } else {
                        emit(response, onUpdate: onUpdate)
                    }
                }
                onComplete()
            }
        }
    }

    private func emit(_ text: String, onUpdate: @escaping (String) -> Void) {
        guard !text.isEmpty else { return }
        sawText = true
        onUpdate(text)
    }

    private func failureMessage(tool: Tool, status: Int32) -> String {
        let detail = stderrText
            .trimmingCharacters(in: .whitespacesAndNewlines)
            .split(separator: "\n")
            .filter { !$0.contains("ERROR codex_models_manager") }   // known harmless warning
            .suffix(3)
            .joined(separator: " ")
        if status == 0 {
            return "❌ \(tool.displayName) exited without an answer. \(detail)"
        }
        let hint = detail.isEmpty ? tool.loginHint : detail
        return "❌ \(tool.displayName) failed (exit \(status)). \(hint)"
    }
}
