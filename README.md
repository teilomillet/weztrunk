# WezTrunk

WezTerm + Worktrunk + code-agent glue for fast worktree switching from the terminal itself.

The name stays agent-neutral on purpose. The current default implementation targets the Codex CLI, but the repo structure now isolates agent-specific behavior in a single profile file.

## What It Does

- Opens Worktrunk from inside WezTerm with first-class shortcuts.
- Creates predictable worktrees at `.worktrees/<branch>`.
- Launches or re-attaches a detached code-agent session per repo/branch.
- Keeps the agent alive while still allowing the display to sleep.
- Uses Worktrunk summaries and non-interactive commit generation.
- Adds Worktrunk aliases and hooks for agent resume, manual cache hydration, tmux renaming, and branch-session cleanup.
- Shows `repo:branch` in WezTerm tab titles for worktree tabs.

## Files

- [`.wezterm.lua`](./.wezterm.lua): WezTerm config with Worktrunk actions and tmux-style ergonomics.
- [`.config/weztrunk/MANUAL.md`](./.config/weztrunk/MANUAL.md): built-in manual for day-to-day usage and provider setup.
- [`.config/weztrunk/agent-profile.sh`](./.config/weztrunk/agent-profile.sh): agent-specific launch and commit behavior.
- [`.config/weztrunk/providers/`](./.config/weztrunk/providers): per-provider extra-flag files.
- [`shell/weztrunk.sh`](./shell/weztrunk.sh): shared `bash`/`zsh` integration for `wt`, `wtx`, and `wtn`.
- [`.config/worktrunk/config.toml`](./.config/worktrunk/config.toml): Worktrunk defaults.
- [`.local/bin/weztrunk-agent`](./.local/bin/weztrunk-agent): shared agent dispatcher and session utilities.
- [`.local/bin/weztrunk-manual`](./.local/bin/weztrunk-manual): manual viewer for shell and WezTerm.
- [`.local/bin/wt-code`](./.local/bin/wt-code): detached interactive agent launcher.
- [`.local/bin/worktrunk-code-commit`](./.local/bin/worktrunk-code-commit): non-interactive commit-message helper.
- [`scripts/install.sh`](./scripts/install.sh): symlink-based installer with backups.

## Requirements

- macOS or Linux
- `wezterm`
- `wt` (Worktrunk)
- `dtach`
- a supported code-agent CLI
- `gh`

Install example:

```bash
brew install wezterm worktrunk dtach gh
```

The default profile expects `codex` to already be installed and authenticated.

Sleep inhibition is optional but recommended:

- macOS: `caffeinate` is used automatically via `/usr/bin/caffeinate -s` when present
- Linux: `systemd-inhibit --what=sleep` is used automatically when present
- otherwise, sessions still work but the machine may sleep normally

## Install

```bash
git clone https://github.com/teilomillet/weztrunk.git ~/Code/weztrunk
cd ~/Code/weztrunk
bash scripts/install.sh
source ~/.zshrc
```

The installer auto-selects your shell startup file from `$SHELL`:

- `zsh` -> `~/.zshrc`
- `bash` -> `~/.bashrc`
- fallback -> `~/.profile`

When `bash` is detected, the installer also checks whether `~/.bash_profile`, `~/.bash_login`, or `~/.profile` appears to source `~/.bashrc`. If not, it prints a Linux/login-shell note so you can decide whether to keep `~/.bashrc` or target `~/.profile` instead.

You can override that with:

```bash
WEZTRUNK_SHELL_RC=~/.bash_profile bash scripts/install.sh
```

Then reload WezTerm with `Cmd+Shift+R`.

If you are upgrading an older install, rerun the installer once. This version adds new linked files, so a plain `git pull` is not enough on an existing machine until those new symlinks exist.

## Usage

### Shell

- `wtx`: open the Worktrunk picker, then launch or re-attach the agent
- `wtx feature-x`: switch to that worktree and attach the branch session
- `wtn feature-x`: create the branch/worktree and launch the agent
- `wtx feature-x -- 'Fix flaky test'`: pass an initial prompt to Codex
- `wthelp` or `wtm`: open the built-in manual
- `wt step weztrunk-agent`: re-attach the current worktree's agent session
- `wt step weztrunk-hydrate`: copy gitignored files into the current worktree on demand
- `wt step weztrunk-manual`: print the manual from inside a repo

### WezTerm

- `Cmd+Shift+G`: Worktrunk picker + launch/re-attach agent
- `Cmd+B g`: same action on the leader layer
- `Cmd+B G`: prompt for branch name, create worktree, launch agent
- `Cmd+Shift+M`: open the WezTrunk manual in a new tab
- `Cmd+B m`: same manual action on the leader layer
- `Cmd+Shift+P`, then type `Worktrunk`: self-documented command-palette entries

### Behavior

- Each repo/branch gets its own `dtach` socket.
- On macOS, `caffeinate -s` keeps the process alive without forcing the display on.
  Note: `-s` only prevents system sleep on AC power.
- On Linux, `systemd-inhibit --what=sleep` is used for the same purpose when available.
- Worktrunk summaries and commit generation use the configured provider non-interactively.
- `post-switch` renames the current tmux window to the active branch when inside tmux.
- `post-remove` cleans up the detached branch session socket after a worktree is removed.

## Agent Profile

The default profile ships with built-in support for:

- `codex`
- `claude-code`
- `opencode`

The moving pieces are:

- [`wt-code`](./.local/bin/wt-code) owns session lifecycle: `dtach`, sleep inhibition, and branch-scoped sockets.
- [`weztrunk-agent`](./.local/bin/weztrunk-agent) loads the active agent profile and exposes shared utilities.
- [`agent-profile.sh`](./.config/weztrunk/agent-profile.sh) defines `weztrunk_agent_launch()` and `weztrunk_agent_commit()`.
- [`providers/`](./.config/weztrunk/providers) contains per-provider extra arguments, one CLI argument per line.

Pick a provider with:

```bash
export WEZTRUNK_AGENT=codex
export WEZTRUNK_AGENT=claude-code
export WEZTRUNK_AGENT=opencode
```

If you want extra flags, edit the matching files under [`providers/`](./.config/weztrunk/providers), for example:

- [`providers/codex/launch.args`](./.config/weztrunk/providers/codex/launch.args)
- [`providers/claude-code/launch.args`](./.config/weztrunk/providers/claude-code/launch.args)
- [`providers/opencode/launch.args`](./.config/weztrunk/providers/opencode/launch.args)

For custom providers, add `~/.config/weztrunk/agent-profile.local.sh` and define `weztrunk_custom_agent_launch()` / `weztrunk_custom_agent_commit()`. The built-in manual covers that flow.

Useful environment overrides:

- `WEZTRUNK_AGENT`: provider name
- `WEZTRUNK_AGENT_BIN`: explicit agent binary path
- `WEZTRUNK_AGENT_ARGS_DIR`: alternate provider-args root
- `WEZTRUNK_AGENT_LOCAL_PROFILE`: alternate local override file
- `WEZTRUNK_AGENT_DISPATCHER`: alternate dispatcher path
- `WEZTRUNK_SLEEP_GUARD`: `auto`, `none`, `caffeinate`, or `systemd-inhibit`

The older `WWC_AGENT_BIN` name is still accepted for compatibility.

## Why The Repo Name Is Generic

The repo is named `weztrunk`, not `wezterm-worktrunk-codex`, because the WezTerm + Worktrunk integration is the stable part. The launched code agent is the replaceable part.
