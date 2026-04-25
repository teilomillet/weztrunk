# WezTrunk Manual

WezTrunk is four things glued together:

1. WezTerm keybindings and command-palette actions
2. Worktrunk worktree switching, aliases, and hooks
3. A branch-scoped code-agent session runner built on `dtach`
4. Conservative repo upkeep, dirty-work backup, reconcile worktrees, and doctor checks for watched work repos

## Daily Use

- `Cmd+Shift+G` on macOS or `Ctrl+Shift+G` on Linux: open the Worktrunk picker and launch or re-attach the agent
- `Cmd+B g` on macOS or `Ctrl+B g` on Linux: same action on the leader layer
- `Cmd+B G` on macOS or `Ctrl+B G` on Linux: create a branch/worktree, then launch the agent
- `Cmd+Shift+M` on macOS or `Ctrl+Shift+M` on Linux: open this manual in a new tab
- `Cmd+B m` on macOS or `Ctrl+B m` on Linux: same manual action on the leader layer
- `wtx`: open the Worktrunk picker and launch the agent
- `wtx feature-x`: switch to a branch worktree and launch the agent there
- `wtn feature-x`: create a branch/worktree and launch the agent
- `wtx feature-x -- 'Fix flaky test'`: pass an initial prompt into the agent
- `weztrunk man`: open this manual
- `weztrunk man remove`: search this manual for a topic
- `weztrunk profile`: show the active provider/profile
- `weztrunk profile list`: list the named profiles from `config.toml`
- `weztrunk repos status`: show watched repo branch, dirty state, ahead/behind, and latest commit
- `weztrunk repos pull`: safely fetch and fast-forward watched repos
- `weztrunk repos timer enable`: enable the user-level auto-pull timer
- `weztrunk backup snapshot`: snapshot dirty watched repos into local state
- `weztrunk backup timer enable`: enable the dirty-work backup timer
- `weztrunk upkeep maybe`: opportunistic pull/backup, throttled by config
- `weztrunk upkeep status`: show the current opportunistic upkeep state
- `weztrunk reconcile status`: show watched worktrees and whether they are on top of the base branch
- `weztrunk reconcile current --agent conflict`: create a scratch rebase worktree and launch the agent on conflicts
- `weztrunk reconcile watch`: keep creating fresh scratch rebase worktrees while the current repo changes
- `weztrunk reconcile watch-all`: manager loop for every worktree in every watched repo
- `weztrunk doctor`: check install links, dependencies, GitHub/SSH state, timers, and watched repos
- `wthelp` or `wtm`: same manual command
- `wzt`: short alias for `weztrunk`, if that name is not already taken
- `wts`: short alias for `weztrunk repos status`
- `wtpull`: short alias for `weztrunk repos pull`
- `wtd`: short alias for `weztrunk doctor`
- `wtb`: short alias for `weztrunk backup snapshot`
- `wtr`: short alias for `weztrunk reconcile`
- `wt step weztrunk-agent`: re-attach the current worktree's agent session
- `wt step weztrunk-hydrate`: copy gitignored files into the current worktree on demand
- `wt step weztrunk-manual`: print this manual from inside a repo

## Shell

- `wtx`: picker + launch or re-attach the agent
- `wtx main`: jump straight to an existing worktree
- `wtn feature-x`: create a branch/worktree and launch the agent
- `weztrunk man profiles`: jump straight to the profile section
- `weztrunk profile`: show the active provider/profile/binary
- `weztrunk profile list`: list all named profiles
- `weztrunk repos status`: quick status dashboard for watched repos
- `weztrunk repos pull`: conservative fast-forward updater
- `weztrunk backup snapshot`: local dirty-work snapshot
- `weztrunk reconcile current`: scratch-worktree rebase onto latest base
- `weztrunk doctor`: install and environment checkup
- `wtp`: short alias for `weztrunk profile`
- `wts`: short alias for `weztrunk repos status`
- `wtpull`: short alias for `weztrunk repos pull`
- `wtd`: short alias for `weztrunk doctor`
- `wtb`: short alias for `weztrunk backup snapshot`
- `wtr`: short alias for `weztrunk reconcile`

## WezTerm

- `Cmd+Shift+G` on macOS or `Ctrl+Shift+G` on Linux: Worktrunk picker + launch/re-attach agent
- `Cmd+B g` on macOS or `Ctrl+B g` on Linux: same action on the leader layer
- `Cmd+B G` on macOS or `Ctrl+B G` on Linux: prompt for a branch name, create the worktree, then launch the agent
- `Cmd+Shift+M` on macOS or `Ctrl+Shift+M` on Linux: open the full manual in a new tab
- `Cmd+Shift+/` on macOS or `Ctrl+Shift+/` on Linux: prompt for a topic and open a focused manual search in a new tab
- `Cmd+B x` on macOS or `Ctrl+B x` / `Ctrl+Alt+X` on Linux: close the current pane
- `Cmd+Shift+[` / `Cmd+Shift+]` on macOS or `Ctrl+Alt+A` / `Ctrl+Alt+D` on Linux: previous / next tab
- `Cmd+1` ... `Cmd+8`, `Cmd+9` on macOS or `Alt+1` ... `Alt+8`, `Alt+9` on Linux: jump to tab, with `9` selecting the last tab
- `Cmd+Shift+P` on macOS or `Ctrl+Shift+P` on Linux, then type `Worktrunk`: self-documented command-palette entries

## Worktrunk Tasks

### Remove Or Close A Worktree

- `wt remove`
- `wt remove --no-delete-branch`: remove the worktree but keep the branch
- `wt remove -f`: remove even if the worktree has untracked files
- `wt remove -D`: allow deletion of an unmerged branch

### Merge A Worktree

- `wt merge`
- `wt merge --no-remove`: merge but keep the worktree around
- `wt merge develop`: merge into a non-default target branch

### Switch Or Create Worktrees

- `wtx main`: jump straight to an existing worktree
- `wtn feature-x`: create a branch/worktree and launch the agent
- `weztrunk switch pick "$PWD"`: raw picker helper if you want the lower-level path

### Sessions

- `wt step weztrunk-agent`: re-attach the current worktree session
- `weztrunk man session`: jump to this section
- each repo/branch gets a separate `dtach` socket
- `wt remove` and `wt merge` trigger a Worktrunk `post-remove` hook that cleans up the branch session socket

## Repo Upkeep

Watched repos are listed in `~/.config/weztrunk/repos.txt`, one path per line. Blank lines and comments are ignored. `~` and `$HOME` are expanded.

Default example:

```text
~/Code/vauban
~/Code/kayak
~/Code/weztrunk
```

Status:

```sh
weztrunk repos status
wts
```

Safe pull:

```sh
weztrunk repos pull
wtpull
```

The pull helper fetches each repo and fast-forwards only when the current branch is clean and behind its upstream. It skips missing repos, detached HEADs, branches with no upstream, local changes, and ahead/diverged branches.

Timer management:

```sh
weztrunk repos timer enable
weztrunk repos timer status
weztrunk repos timer disable
```

On Linux with systemd user services, the timer runs shortly after login and then every five minutes. Timer pulls pass `--notify`, so skipped repos can trigger desktop notifications when `notify-send` is available.

## Dirty-Work Backup

Backups are local snapshots under `~/.local/state/weztrunk/work-backups` by default. They do not commit, stash, or modify the repo.

Each dirty watched repo snapshot includes:

- branch, HEAD, timestamp, and status
- staged and unstaged binary-capable diffs
- untracked file list
- copies of small text untracked files

Useful commands:

```sh
weztrunk backup snapshot
weztrunk backup status
weztrunk backup timer enable
weztrunk backup timer status
weztrunk backup timer disable
```

The backup timer runs shortly after login and then every ten minutes. Identical dirty states are deduplicated by fingerprint, so a repo does not get a new backup every tick unless the work changed.

## Opportunistic Upkeep

For managed Macs or any machine where a persistent login scheduler is undesirable, use opportunistic upkeep instead of launchd/systemd timers. It runs only from normal terminal commands and is throttled by a timestamp under `~/.local/state/weztrunk/upkeep`.

```sh
weztrunk upkeep maybe
weztrunk upkeep run
weztrunk upkeep status
```

`wtx` and `wtn` call `weztrunk upkeep maybe --quiet` before switching or creating a worktree. The command checks `[upkeep]` in `config.toml`; with `mode = "opportunistic"`, it runs `backup snapshot` and `repos pull` only if `interval_seconds` has elapsed. No daemon, login item, root privileges, launchd job, or systemd timer is required.

## Reconcile Work

Reconcile creates a scratch integration worktree so your active worktree is not rewritten while conflicts are being resolved.

```sh
weztrunk reconcile status
weztrunk reconcile current
weztrunk reconcile current --agent conflict
weztrunk reconcile current --agent always
weztrunk reconcile watch --interval 30 --stable 5
weztrunk reconcile watch-all --once
weztrunk reconcile watch-all --interval 30 --stable 5
wtr status
```

`current` creates a branch named like `weztrunk/reconcile/<branch>-<timestamp>` and a matching worktree under `.worktrees/`, adding that directory to the repo-local Git exclude if needed. If the active worktree has local changes, those changes are copied into the scratch worktree and committed there as a WIP snapshot. Then the scratch branch is rebased onto `origin/HEAD` or `origin/main`.

`watch` is the manager mode for work that is still moving. It fingerprints the active checkout, waits until it is stable, then runs `current` from that exact state. If files change while the scratch rebase is being created, it waits and tries again. This keeps an integration worktree on top of `origin/main` without rewriting the worktree your editor or another agent is using.

`watch-all` does the same repo-manager work across all worktrees in the watched repos. Clean worktrees are fast-forwarded when Git can do that safely. Dirty, diverged, detached, and scratch worktrees are not rewritten; dirty or diverged worktrees get fresh reconcile candidates instead.

With `--agent conflict`, WezTrunk launches the configured code agent only when patch application or rebase conflicts need help. With `--agent always`, it launches the agent even when the rebase succeeds, for review and cleanup.

## Doctor

```sh
weztrunk doctor
wtd
```

Doctor checks required commands, installed symlinks, GitHub CLI auth, SSH config, repo timers, backup timers, and watched repo status.

## Profiles

The active provider/profile now comes from `~/.config/weztrunk/config.toml`.

Default file:

```toml
[agent]
provider = "codex"
profile = "deep"
```

Built-in providers:

- `codex`
- `claude-code`
- `opencode`

Useful commands:

- `weztrunk profile`: show the active provider/profile/binary
- `weztrunk profile list`: list all named profiles
- `weztrunk profile list codex`: list only Codex profiles
- `weztrunk man profiles`: jump back to this section

Simple overrides:

- `WEZTRUNK_AGENT=claude-code`: override only the provider
- `WEZTRUNK_PROFILE=fast`: override only the named profile
- `WEZTRUNK_AGENT_BIN=/custom/path/to/agent`: override the executable path

Legacy local overlays still work and are appended after the TOML profile:

- `~/.config/weztrunk/providers/<provider>/launch.args`
- `~/.config/weztrunk/providers/<provider>/commit.args`

That is the right place for machine-local extras you do not want in the shared `config.toml`.

## Custom Providers

If you want a different CLI entirely, create `~/.config/weztrunk/agent-profile.local.sh` and define:

```sh
weztrunk_custom_agent_launch() {
  provider=$1
  shift
  # launch your provider here
}

weztrunk_custom_agent_commit() {
  provider=$1
  # emit commit text to stdout here
}
```

This keeps the tracked `agent-profile.sh` generic while still allowing repo-local overrides.

## Sleep Guard

- the session survives terminal closes and tab closes

- macOS uses `caffeinate -s` when available
- Linux uses `systemd-inhibit --what=sleep` when available
- set `[sleep] guard = "none"` in `config.toml` to disable this

## Manual Search

- `weztrunk man remove`
- `weztrunk man merge`
- `weztrunk man session`
- `weztrunk man profiles`
- `weztrunk man wezterm`

Useful flags:

- `weztrunk man --topics`: list the built-in quick topics
- `weztrunk man --raw`: print the full Markdown source
- `weztrunk man --path`: print the manual file path

## Propagating Changes

If your machine is installed via symlinks from the repo:

- normal edits propagate with `git pull`
- WezTerm needs reload or restart
- shell changes need a new shell or `source`

If a repo update adds new linked files, rerun `bash scripts/install.sh` once on that machine.

## Useful Paths

- manual: `~/.config/weztrunk/MANUAL.md`
- config: `~/.config/weztrunk/config.toml`
- watched repos: `~/.config/weztrunk/repos.txt`
- dirty-work backups: `~/.local/state/weztrunk/work-backups`
- profile: `~/.config/weztrunk/agent-profile.sh`
- local override: `~/.config/weztrunk/agent-profile.local.sh`
- provider flags: `~/.config/weztrunk/providers/`
- WezTerm config: `~/.wezterm.lua`
- Worktrunk config: `~/.config/worktrunk/config.toml`
