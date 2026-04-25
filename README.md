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
- Tracks selected repos with conservative status, pull, dirty-work backup, conflict reconciliation, doctor, and optional user-level systemd timers.
- Shows `repo:branch` in WezTerm tab titles for worktree tabs.

## Files

- [`.wezterm.lua`](./.wezterm.lua): WezTerm config with Worktrunk actions and tmux-style ergonomics.
- [`.config/weztrunk/MANUAL.md`](./.config/weztrunk/MANUAL.md): built-in manual for day-to-day usage and provider setup.
- [`.config/weztrunk/config.toml`](./.config/weztrunk/config.toml): named provider/profile defaults.
- [`.config/weztrunk/repos.txt`](./.config/weztrunk/repos.txt): repos watched by `weztrunk repos`.
- [`.config/weztrunk/agent-profile.sh`](./.config/weztrunk/agent-profile.sh): agent-specific launch and commit behavior.
- [`.config/weztrunk/providers/`](./.config/weztrunk/providers): per-provider extra-flag files.
- [`shell/weztrunk.sh`](./shell/weztrunk.sh): shared `bash`/`zsh` integration for `wt`, `wtx`, and `wtn`.
- [`.config/worktrunk/config.toml`](./.config/worktrunk/config.toml): Worktrunk defaults.
- [`.config/systemd/user/`](./.config/systemd/user): optional Linux repo-upkeep and backup user services and timers.
- [`.local/bin/weztrunk`](./.local/bin/weztrunk): top-level CLI entrypoint for manual and helper subcommands.
- [`.local/bin/weztrunk-backup`](./.local/bin/weztrunk-backup): dirty-work snapshot helper.
- [`.local/bin/weztrunk-config`](./.local/bin/weztrunk-config): TOML-backed profile reader.
- [`.local/bin/weztrunk-doctor`](./.local/bin/weztrunk-doctor): local install and dependency checkup.
- [`.local/bin/weztrunk-agent`](./.local/bin/weztrunk-agent): shared agent dispatcher and session utilities.
- [`.local/bin/weztrunk-manual`](./.local/bin/weztrunk-manual): manual viewer for shell and WezTerm.
- [`.local/bin/weztrunk-reconcile`](./.local/bin/weztrunk-reconcile): scratch-worktree rebase and conflict-resolution launcher.
- [`.local/bin/weztrunk-repos`](./.local/bin/weztrunk-repos): repo status, safe pull, and timer management.
- [`.local/bin/weztrunk-upkeep`](./.local/bin/weztrunk-upkeep): opportunistic pull/backup maintenance without a scheduler.
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

Sleep inhibition is optional and controlled by `[sleep] guard` in `config.toml`:

- macOS: `caffeinate` is used automatically via `/usr/bin/caffeinate -s` when present
- Linux: `systemd-inhibit --what=sleep` is used automatically when present
- `guard = "none"` leaves sleep behavior alone, which is the tracked default for managed-work-machine friendliness

## Install

```bash
git clone https://github.com/teilomillet/weztrunk.git ~/Code/weztrunk
cd ~/Code/weztrunk
bash scripts/install.sh
source ~/.zshrc
```

On a managed Mac, or anywhere you want no persistent scheduler links, use:

```bash
bash scripts/install.sh --profile managed-mac
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

Then reload WezTerm with `Cmd+Shift+R` on macOS or `Ctrl+Shift+R` on Linux/Ubuntu.

If you are upgrading an older install, rerun the installer once. This version adds new linked files, so a plain `git pull` is not enough on an existing machine until those new symlinks exist.

## Usage

### Shell

- `wtx`: open the Worktrunk picker, then launch or re-attach the agent
- `wtx feature-x`: switch to that worktree and attach the branch session
- `wtn feature-x`: create the branch/worktree and launch the agent
- `wtx feature-x -- 'Fix flaky test'`: pass an initial prompt to Codex
- `weztrunk man remove`: search the manual for a topic
- `weztrunk profile`: show the active provider/profile
- `weztrunk profile list`: list the named profiles
- `weztrunk repos status`: show branch, dirty state, ahead/behind, and latest commit for watched repos
- `weztrunk repos pull`: fetch and fast-forward watched repos only when their worktrees are clean
- `weztrunk repos timer enable`: start the user-level auto-pull timer
- `weztrunk backup snapshot`: snapshot dirty watched repos into local state
- `weztrunk backup timer enable`: start the user-level dirty-work backup timer
- `weztrunk upkeep maybe`: opportunistic pull/backup, throttled by config
- `weztrunk upkeep status --verbose`: show upkeep state, last log, reconcile fingerprints, and reconcile status
- `weztrunk reconcile status`: show watched worktrees and whether they are on top of the base branch
- `weztrunk reconcile current --agent conflict`: create a scratch reconciliation worktree for the current repo
- `weztrunk reconcile promote --remove`: fast-forward the target branch to a reviewed scratch result, then remove the scratch worktree
- `weztrunk reconcile adopt --remove`: replace the target branch with a reviewed scratch result, with a safety branch first
- `weztrunk reconcile prune --dry-run`: preview old clean scratch worktrees that can be removed
- `weztrunk reconcile watch`: keep creating fresh scratch reconciliation worktrees while the current repo changes
- `weztrunk reconcile watch-all`: manager loop for every worktree in every watched repo
- `weztrunk doctor`: check install links, required commands, SSH/GitHub state, timers, and watched repos
- `wtman merge`: same manual search path from the shell
- `wthelp` or `wtm`: open the built-in manual
- `wzt`: short alias for `weztrunk`, added only if the name is not already taken
- `wtp`: short alias for `weztrunk profile`
- `wts`: short alias for `weztrunk repos status`
- `wtpull`: short alias for `weztrunk repos pull`
- `wtd`: short alias for `weztrunk doctor`
- `wtb`: short alias for `weztrunk backup snapshot`
- `wtr`: short alias for `weztrunk reconcile`
- `wt step weztrunk-agent`: re-attach the current worktree's agent session
- `wt step weztrunk-hydrate`: copy gitignored files into the current worktree on demand
- `wt step weztrunk-manual`: print the manual from inside a repo

### WezTerm

WezTrunk shortcuts on Linux/Ubuntu avoid the Super key because GNOME reserves several Super combinations before WezTerm can receive them.

| Action | macOS | Linux/Ubuntu |
| --- | --- | --- |
| Worktrunk picker + launch/re-attach agent | `Cmd+Shift+G` | `Ctrl+Shift+G` |
| Same action on the leader layer | `Cmd+B g` | `Ctrl+B g` |
| Prompt for branch name, create worktree, launch agent | `Cmd+B G` | `Ctrl+B G` |
| Open the WezTrunk manual in a new tab | `Cmd+Shift+M` | `Ctrl+Shift+M` |
| Prompt for a manual topic and open a focused search in a new tab | `Cmd+Shift+/` | `Ctrl+Shift+/` |
| Same manual action on the leader layer | `Cmd+B m` | `Ctrl+B m` |
| Same manual-search action on the leader layer | `Cmd+B /` | `Ctrl+B /` |
| Close the current pane | `Cmd+B x` | `Ctrl+B x` or `Ctrl+Alt+X` |
| Previous / next tab | `Cmd+Shift+[` / `Cmd+Shift+]` | `Ctrl+Alt+A` / `Ctrl+Alt+D` |
| Jump to tab | `Cmd+1` ... `Cmd+8`, `Cmd+9` last tab | `Alt+1` ... `Alt+8`, `Alt+9` last tab |
| Self-documented command-palette entries | `Cmd+Shift+P`, then type `Worktrunk` | `Ctrl+Shift+P`, then type `Worktrunk` |

### Behavior

- Each repo/branch gets its own `dtach` socket.
- On macOS, `caffeinate -s` keeps the process alive without forcing the display on.
  Note: `-s` only prevents system sleep on AC power.
- On Linux, `systemd-inhibit --what=sleep` is used for the same purpose when available.
- Worktrunk summaries and commit generation use the configured provider non-interactively.
- Repo upkeep uses fast-forward-only pulls and skips dirty, detached, untracked, or diverged work.
- Dirty-work backup snapshots diffs and small text untracked files without committing, stashing, or modifying the repo.
- Reconciliation happens in scratch worktrees and never rewrites the active worktree automatically.
- `post-switch` renames the current tmux window to the active branch when inside tmux.
- `post-remove` cleans up the detached branch session socket after a worktree is removed.

## Repo Upkeep

Watched repos live in [`repos.txt`](./.config/weztrunk/repos.txt), one path per line:

```text
~/Code/vauban
~/Code/kayak
~/Code/weztrunk
```

Useful commands:

```bash
weztrunk repos status
weztrunk repos pull
weztrunk repos timer enable
weztrunk repos timer status
weztrunk repos timer disable
```

The pull command fetches each repo, then fast-forwards only when the current branch is clean and behind its upstream. It skips repos with local changes, detached HEADs, missing upstreams, or diverged branches.

On Linux with systemd user services, `weztrunk repos timer enable` starts a timer that runs shortly after login and then every five minutes. When `notify-send` is available, timer runs use desktop notifications for skipped repos. On macOS, the installer skips these systemd unit links and leaves scheduled upkeep to the opportunistic mode below.

## Opportunistic Upkeep

For managed Macs or any machine where a persistent login scheduler is undesirable, use opportunistic upkeep instead of launchd/systemd timers. It runs only from normal terminal commands and is throttled by a timestamp under `~/.local/state/weztrunk/upkeep`.

```bash
weztrunk upkeep maybe
weztrunk upkeep run
weztrunk upkeep status --verbose
```

`wtx` and `wtn` call `weztrunk upkeep maybe --quiet` before switching or creating a worktree. The command checks `[upkeep]` in `config.toml`; with `mode = "opportunistic"`, it runs `backup snapshot` and `repos pull` only if `interval_seconds` has elapsed. No daemon, login item, root privileges, launchd job, or systemd timer is required.

By default, opportunistic upkeep also runs one `reconcile watch-all --once` manager pass. The practical rule is simple: clean worktrees may be fast-forwarded, dirty worktrees are never rewritten, and their current state gets a fresh scratch candidate on top of `origin/main`.

## Dirty-Work Backup

Backups are local snapshots under `~/.local/state/weztrunk/work-backups` by default. For each dirty watched repo, the snapshot includes:

- branch, HEAD, timestamp, and status
- staged and unstaged binary-capable diffs
- untracked file list
- copies of small text untracked files

Useful commands:

```bash
weztrunk backup snapshot
weztrunk backup status
weztrunk backup timer enable
weztrunk backup timer status
weztrunk backup timer disable
```

The timer runs shortly after login and then every ten minutes. Repeated identical dirty states are deduplicated by fingerprint, so a repo does not get a new backup every timer tick unless the work changed.

## Reconcile

Use reconcile when a branch or dirty worktree needs to be rebased onto the latest base branch without touching the active worktree.

```bash
weztrunk reconcile status
weztrunk reconcile current
weztrunk reconcile current --agent conflict
weztrunk reconcile current --agent always
weztrunk reconcile promote --remove
weztrunk reconcile adopt --remove
weztrunk reconcile prune --dry-run
weztrunk reconcile watch --interval 30 --stable 5
weztrunk reconcile watch-all --once
weztrunk reconcile watch-all --interval 30 --stable 5
```

`current` creates a branch named like `weztrunk/reconcile/<branch>-<timestamp>` and a matching scratch worktree under `.worktrees/`, adding that directory to the repo-local Git exclude if needed. It also writes an ignored `.weztrunk/INTENT.md` contract inside the scratch worktree so an assistant can see immediately that this is the integration candidate. If the active worktree is dirty, those changes are copied into the scratch worktree and committed as a WIP snapshot there. The scratch branch is then rebased onto `origin/HEAD` or `origin/main`.

`watch` is the manager mode for work that is still moving. It fingerprints the active checkout, waits until it is stable, then runs `current` from that exact state. If files change while the scratch rebase is being created, it waits and tries again. This keeps an integration worktree on top of `origin/main` without rewriting the worktree your editor or another agent is using.

`watch-all` does the same repo-manager work across all worktrees in the watched repos. Clean worktrees are fast-forwarded when Git can do that safely. Dirty, diverged, detached, and scratch worktrees are not rewritten; dirty or diverged worktrees get fresh reconcile candidates instead.

`promote` moves the target branch to a reviewed scratch result only when Git can fast-forward the target to that scratch branch. It creates a safety branch named like `weztrunk/safety/<branch>-before-promote-<timestamp>` before moving anything, and `--remove` deletes the scratch worktree and branch after a successful promotion.

`adopt` is the explicit reviewed-rewrite path for scratch branches that contain rebased local commits and therefore cannot be promoted by fast-forward. It requires a clean scratch worktree, a clean target worktree, and a scratch result on top of the chosen base. It creates `weztrunk/safety/<branch>-before-adopt-<timestamp>`, then moves the target branch to the scratch result with `reset --hard` when the target is checked out or `branch -f` when it is not.

`prune` removes old clean reconcile scratch worktrees. By default it keeps the newest two per source branch and only removes candidates at least seven days old; use `--dry-run` to preview.

The bitter lesson for assistants is part of the model: a reconcile worktree is the integration candidate, not a random side branch. It should be `origin/main` first, then the user's work above it, with conflicts resolved there so the result can be reviewed and promoted by fast-forward. The active dirty worktree stays as the live editing surface until promotion is intentional.

When the rebase or patch application conflicts, `--agent conflict` launches the configured code agent in the scratch worktree with instructions to resolve the integration. Review the scratch branch before merging or replacing your original branch.

## Doctor

Run:

```bash
weztrunk doctor
```

It checks required commands, installed symlinks, GitHub CLI auth, SSH config, repo timers, backup timers, and watched repo status.
On macOS, doctor treats systemd timers as intentionally skipped.

## Profiles

The default config lives in [`config.toml`](./.config/weztrunk/config.toml) and ships with built-in support for:

- `codex`
- `claude-code`
- `opencode`

The moving pieces are:

- [`wt-code`](./.local/bin/wt-code) owns session lifecycle: `dtach`, sleep inhibition, and branch-scoped sockets.
- [`weztrunk-agent`](./.local/bin/weztrunk-agent) loads the active agent profile and exposes shared utilities.
- [`weztrunk-config`](./.local/bin/weztrunk-config) reads the shared TOML config and resolves named profiles.
- [`agent-profile.sh`](./.config/weztrunk/agent-profile.sh) defines `weztrunk_agent_launch()` and `weztrunk_agent_commit()`.
- [`providers/`](./.config/weztrunk/providers) contains optional machine-local extra arguments, one CLI argument per line.

Default selection:

```toml
[agent]
provider = "codex"
profile = "deep"
```

Quick inspection:

```bash
weztrunk profile
weztrunk profile list
weztrunk profile list codex
```

The normal way to change defaults is to edit `~/.config/weztrunk/config.toml`:

```toml
[agent]
provider = "claude-code"
profile = "fast"

[sleep]
guard = "none"

[upkeep]
mode = "opportunistic"
interval_seconds = 1800
pull = true
backup = true
reconcile = true
reconcile_agent = "never"
```

If you want machine-local extras after the named TOML profile, edit the matching files under [`providers/`](./.config/weztrunk/providers), for example:

- [`providers/codex/launch.args`](./.config/weztrunk/providers/codex/launch.args)
- [`providers/claude-code/launch.args`](./.config/weztrunk/providers/claude-code/launch.args)
- [`providers/opencode/launch.args`](./.config/weztrunk/providers/opencode/launch.args)

For custom providers, add `~/.config/weztrunk/agent-profile.local.sh` and define `weztrunk_custom_agent_launch()` / `weztrunk_custom_agent_commit()`. The built-in manual covers that flow.

Environment overrides are still accepted for temporary one-off sessions:

- `WEZTRUNK_AGENT`: provider name
- `WEZTRUNK_PROFILE`: profile name inside that provider
- `WEZTRUNK_AGENT_BIN`: explicit agent binary path
- `WEZTRUNK_CONFIG_PATH`: alternate config TOML path
- `WEZTRUNK_AGENT_ARGS_DIR`: alternate provider-args root
- `WEZTRUNK_AGENT_LOCAL_PROFILE`: alternate local override file
- `WEZTRUNK_AGENT_DISPATCHER`: alternate dispatcher path
- `WEZTRUNK_SLEEP_GUARD`: `auto`, `none`, `caffeinate`, or `systemd-inhibit`

The older `WWC_AGENT_BIN` name is still accepted for compatibility.

## Why The Repo Name Is Generic

The repo is named `weztrunk`, not `wezterm-worktrunk-codex`, because the WezTerm + Worktrunk integration is the stable part. The launched code agent is the replaceable part.
