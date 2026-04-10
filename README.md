# WezTrunk

WezTerm + Worktrunk + code-agent glue for fast worktree switching from the terminal itself.

The name stays agent-neutral on purpose. The current default implementation targets the Codex CLI, but the repo structure is meant to make that swap isolated to two small scripts.

## What It Does

- Opens Worktrunk from inside WezTerm with first-class shortcuts.
- Creates predictable worktrees at `.worktrees/<branch>`.
- Launches or re-attaches a detached code-agent session per repo/branch.
- Keeps the agent alive with `caffeinate -s` while letting the display sleep.
- Uses Worktrunk summaries and non-interactive commit generation.
- Shows `repo:branch` in WezTerm tab titles for worktree tabs.

## Files

- [`.wezterm.lua`](./.wezterm.lua): WezTerm config with Worktrunk actions and tmux-style ergonomics.
- [`shell/weztrunk.zsh`](./shell/weztrunk.zsh): `zsh` integration for `wt`, `wtx`, and `wtn`.
- [`.config/worktrunk/config.toml`](./.config/worktrunk/config.toml): Worktrunk defaults.
- [`.local/bin/wt-code`](./.local/bin/wt-code): detached interactive agent launcher.
- [`.local/bin/worktrunk-code-commit`](./.local/bin/worktrunk-code-commit): non-interactive commit-message helper.
- [`scripts/install.sh`](./scripts/install.sh): symlink-based installer with backups.

## Requirements

- macOS
- `wezterm`
- `wt` (Worktrunk)
- `codex`
- `dtach`
- `gh`

Install example:

```bash
brew install wezterm worktrunk dtach gh
```

Codex is expected to already be installed and authenticated.

## Install

```bash
git clone https://github.com/teilomillet/weztrunk.git ~/Code/weztrunk
cd ~/Code/weztrunk
bash scripts/install.sh
source ~/.zshrc
```

Then reload WezTerm with `Cmd+Shift+R`.

## Usage

### Shell

- `wtx`: open the Worktrunk picker, then launch or re-attach the agent
- `wtx feature-x`: switch to that worktree and attach the branch session
- `wtn feature-x`: create the branch/worktree and launch the agent
- `wtx feature-x -- 'Fix flaky test'`: pass an initial prompt to Codex

### WezTerm

- `Cmd+Shift+G`: Worktrunk picker + launch/re-attach agent
- `Cmd+B g`: same action on the leader layer
- `Cmd+B G`: prompt for branch name, create worktree, launch agent
- `Cmd+Shift+P`, then type `Worktrunk`: self-documented command-palette entries

### Behavior

- Each repo/branch gets its own `dtach` socket.
- `caffeinate -s` keeps the process alive without forcing the display on.
  Note: `-s` only prevents system sleep on AC power.
- Worktrunk summaries and commit generation use Codex non-interactively.

## Agent Assumptions

The default scripts are Codex-oriented:

- [`wt-code`](./.local/bin/wt-code) starts `codex` with `workspace-write`, network access, and `xhigh` reasoning.
- [`worktrunk-code-commit`](./.local/bin/worktrunk-code-commit) runs `codex exec` to emit a commit message.

If you want to swap agents, those are the two files to edit first.

## Why The Repo Name Is Generic

The repo is named `weztrunk`, not `wezterm-worktrunk-codex`, because the WezTerm + Worktrunk integration is the stable part. The launched code agent is the replaceable part.
