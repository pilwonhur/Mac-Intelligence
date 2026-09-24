#!/bin/bash
#
# Installs or updates Mac Intelligence straight from GitHub. The same command does both:
#
#     curl -fsSL https://raw.githubusercontent.com/pilwonhur/Mac-Intelligence/main/install.sh | bash
#
# What it does:
#   1. Checks for the Xcode Command Line Tools (swiftc, git) and asks to install them if missing
#   2. Clones the repo into ~/.mac-intelligence, or fast-forwards it to the latest main
#   3. Creates the local signing certificate once (see make_signing_cert.sh)
#   4. Builds the app, replaces the installed copy, and relaunches it
#
# Run from inside a checkout (./install.sh) it builds that checkout as-is instead of
# pulling from GitHub, which is handy while developing.
#
# Options:
#   --force   rebuild even if the installed app is already at the latest commit
#
# Environment:
#   MI_SRC_DIR       where the managed clone lives   (default: ~/.mac-intelligence)
#   MI_INSTALL_DIR   where the app is installed      (default: /Applications, or
#                                                     ~/Applications if not writable)

set -euo pipefail

# Everything lives in main(), called on the last line, so a truncated download
# piped into bash runs nothing at all.
main() {
    local repo_url="https://github.com/pilwonhur/Mac-Intelligence.git"
    local branch="main"
    local bundle="MacIntelligence.app"
    local src_dir="${MI_SRC_DIR:-$HOME/.mac-intelligence}"
    local force=0

    for arg in "$@"; do
        case "$arg" in
            --force) force=1 ;;
            *) fail "Unknown option: $arg" ;;
        esac
    done

    [ "$(uname -s)" = "Darwin" ] || fail "Mac Intelligence runs on macOS only."

    # --- 1. Toolchain -----------------------------------------------------------
    if ! xcode-select -p >/dev/null 2>&1 || ! command -v swiftc >/dev/null 2>&1; then
        say "📦 The Xcode Command Line Tools are required (they provide swiftc and git)."
        xcode-select --install 2>/dev/null || true
        fail "Finish the installer window that just opened, then run this command again."
    fi

    # --- 2. Source --------------------------------------------------------------
    # A checkout that contains this script builds itself; the managed clone (and a
    # script piped from curl, which has no directory) builds from GitHub.
    local script_dir=""
    if [ -n "${BASH_SOURCE[0]:-}" ] && [ -f "${BASH_SOURCE[0]}" ]; then
        script_dir="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
    fi

    if [ -n "$script_dir" ] && [ -f "$script_dir/build_app.sh" ] \
        && [ "$script_dir" != "$(cd "$src_dir" 2>/dev/null && pwd)" ]; then
        src_dir="$script_dir"
        say "📂 Building the local checkout at $src_dir (no GitHub pull)."
    elif [ -d "$src_dir/.git" ]; then
        say "⬇️  Updating $src_dir..."
        # The managed clone is ours alone, so match origin exactly rather than merging.
        git -C "$src_dir" fetch --quiet origin "$branch"
        git -C "$src_dir" reset --quiet --hard "origin/$branch"
    elif [ -e "$src_dir" ]; then
        fail "$src_dir exists but is not a git clone. Move it aside or set MI_SRC_DIR."
    else
        say "⬇️  Downloading Mac Intelligence into $src_dir..."
        # A full clone, not --depth 1: the build number is the commit count.
        git clone --quiet --branch "$branch" "$repo_url" "$src_dir"
    fi

    # --- Install location -------------------------------------------------------
    local install_dir="${MI_INSTALL_DIR:-}"
    if [ -z "$install_dir" ]; then
        if [ -w /Applications ]; then
            install_dir="/Applications"
        else
            install_dir="$HOME/Applications"
        fi
    fi
    mkdir -p "$install_dir"
    local target="$install_dir/$bundle"

    # Skip the rebuild when the installed app already matches this commit.
    local head installed
    head="$(git -C "$src_dir" rev-parse --short HEAD 2>/dev/null || echo unknown)"
    installed="$(defaults read "$target/Contents/Info" MIGitCommit 2>/dev/null || true)"
    if [ "$force" -eq 0 ] && [ "$installed" = "$head" ] \
        && [ -z "$(git -C "$src_dir" status --porcelain 2>/dev/null)" ]; then
        say "✅ Mac Intelligence is already up to date ($head) at $target."
        say "   Pass --force to rebuild anyway."
        return 0
    fi

    # --- 3. Signing certificate (once per machine) -------------------------------
    cd "$src_dir"
    ./make_signing_cert.sh

    # --- 4. Build and install ---------------------------------------------------
    ./build_app.sh

    if pgrep -x MacIntelligence >/dev/null 2>&1; then
        say "⏹  Quitting the running copy..."
        pkill -x MacIntelligence || true
        for _ in 1 2 3 4 5 6 7 8 9 10; do
            pgrep -x MacIntelligence >/dev/null 2>&1 || break
            sleep 0.5
        done
    fi

    say "📲 Installing to $target..."
    rm -rf "$target"
    cp -R "$bundle" "$target"

    open "$target"

    local version
    version="$(defaults read "$target/Contents/Info" CFBundleShortVersionString 2>/dev/null || echo "?")"
    say ""
    say "🎉 Mac Intelligence $version ($head) is installed and running."
    say "   Press Cmd+Shift+K in any app. On first launch, allow Accessibility in"
    say "   System Settings ▸ Privacy & Security ▸ Accessibility."
    say ""
    say "   To update later, run the same command again:"
    say "   curl -fsSL https://raw.githubusercontent.com/pilwonhur/Mac-Intelligence/main/install.sh | bash"
}

say() { printf '%s\n' "$*"; }
fail() { printf '❌ %s\n' "$*" >&2; exit 1; }

main "$@"
