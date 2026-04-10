# WezTrunk Manual

WezTrunk is three things glued together:

1. WezTerm keybindings and command-palette actions
2. Worktrunk worktree switching, aliases, and hooks
3. A branch-scoped code-agent session runner built on `dtach`

## Daily Use

From WezTerm:

- `Cmd+Shift+G`: open the Worktrunk picker and launch or re-attach the agent
- `Cmd+B g`: same action on the leader layer
- `Cmd+B G`: create a branch/worktree, then launch the agent
- `Cmd+Shift+M`: open this manual in a new tab
- `Cmd+B m`: same manual action on the leader layer

From the shell:

- `wtx`: open the Worktrunk picker and launch the agent
- `wtx feature-x`: switch to a branch worktree and launch the agent there
- `wtn feature-x`: create a branch/worktree and launch the agent
- `wtx feature-x -- 'Fix flaky test'`: pass an initial prompt into the agent
- `wthelp`: open this manual

From Worktrunk directly:

- `wt step weztrunk-agent`: re-attach the current worktree's agent session
- `wt step weztrunk-hydrate`: copy gitignored files into the current worktree on demand
- `wt step weztrunk-manual`: print this manual from inside a repo

## Agent Selection

The active provider comes from `WEZTRUNK_AGENT`.

Built-in values:

- `codex`
- `claude-code`
- `opencode`

Examples:

```sh
export WEZTRUNK_AGENT=codex
export WEZTRUNK_AGENT=claude-code
export WEZTRUNK_AGENT=opencode
```

If the executable name differs from the provider name, set:

```sh
export WEZTRUNK_AGENT_BIN=/custom/path/to/agent
```

## Extra Flags

Provider-specific extra flags live under:

- `~/.config/weztrunk/providers/<provider>/launch.args`
- `~/.config/weztrunk/providers/<provider>/commit.args`

Each non-comment line is one CLI argument.

Example `claude-code/launch.args`:

```text
--model
sonnet
--permission-mode
acceptEdits
```

Example `opencode/launch.args`:

```text
--model
anthropic/claude-sonnet-4-5
--variant
high
```

Example `codex/launch.args`:

```text
-m
gpt-5.4
```

These files are appended to WezTrunk's built-in provider defaults. They are the intended place to put model, permission, effort, or provider-specific runtime flags.

## Built-In Provider Behavior

`codex`

- interactive sessions default to `workspace-write` plus network-enabled sandbox
- commit generation uses `codex exec`

`claude-code`

- interactive sessions default to plain `claude`
- commit generation uses `claude -p` with tools disabled

`opencode`

- interactive sessions default to plain `opencode`
- commit generation uses `opencode run` with the Worktrunk prompt attached as a temporary file

## Custom Providers

If you want a different CLI entirely, create:

- `~/.config/weztrunk/agent-profile.local.sh`

Then define:

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

## Session Model

- each repo/branch gets a separate `dtach` socket
- the session survives terminal closes and tab closes
- `wt remove` and `wt merge` trigger a Worktrunk `post-remove` hook that cleans up the branch session socket

Sleep inhibition:

- macOS uses `caffeinate -s` when available
- Linux uses `systemd-inhibit --what=sleep` when available
- `WEZTRUNK_SLEEP_GUARD=none` disables this

## Propagating Changes

If your machine is installed via symlinks from the repo:

- normal edits propagate with `git pull`
- WezTerm needs reload or restart
- shell changes need a new shell or `source`

If a repo update adds new linked files, rerun `bash scripts/install.sh` once on that machine.

## Useful Paths

- manual: `~/.config/weztrunk/MANUAL.md`
- profile: `~/.config/weztrunk/agent-profile.sh`
- local override: `~/.config/weztrunk/agent-profile.local.sh`
- provider flags: `~/.config/weztrunk/providers/`
- WezTerm config: `~/.wezterm.lua`
- Worktrunk config: `~/.config/worktrunk/config.toml`
