# WezTrunk Manual

WezTrunk is three things glued together:

1. WezTerm keybindings and command-palette actions
2. Worktrunk worktree switching, aliases, and hooks
3. A branch-scoped code-agent session runner built on `dtach`

## Daily Use

- `Cmd+Shift+G`: open the Worktrunk picker and launch or re-attach the agent
- `Cmd+B g`: same action on the leader layer
- `Cmd+B G`: create a branch/worktree, then launch the agent
- `Cmd+Shift+M`: open this manual in a new tab
- `Cmd+B m`: same manual action on the leader layer
- `wtx`: open the Worktrunk picker and launch the agent
- `wtx feature-x`: switch to a branch worktree and launch the agent there
- `wtn feature-x`: create a branch/worktree and launch the agent
- `wtx feature-x -- 'Fix flaky test'`: pass an initial prompt into the agent
- `weztrunk man`: open this manual
- `weztrunk man remove`: search this manual for a topic
- `weztrunk profile`: show the active provider/profile
- `weztrunk profile list`: list the named profiles from `config.toml`
- `wthelp` or `wtm`: same manual command
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
- `wtp`: short alias for `weztrunk profile`

## WezTerm

- `Cmd+Shift+G`: Worktrunk picker + launch/re-attach agent
- `Cmd+B g`: same action on the leader layer
- `Cmd+B G`: prompt for a branch name, create the worktree, then launch the agent
- `Cmd+Shift+M`: open the full manual in a new tab
- `Cmd+Shift+/`: prompt for a topic and open a focused manual search in a new tab
- `Cmd+Shift+P`, then type `Worktrunk`: self-documented command-palette entries

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
- `WEZTRUNK_SLEEP_GUARD=none` disables this

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
- profile: `~/.config/weztrunk/agent-profile.sh`
- local override: `~/.config/weztrunk/agent-profile.local.sh`
- provider flags: `~/.config/weztrunk/providers/`
- WezTerm config: `~/.wezterm.lua`
- Worktrunk config: `~/.config/worktrunk/config.toml`
