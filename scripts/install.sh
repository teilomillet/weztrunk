#!/bin/sh

set -eu

repo_root=$(CDPATH= cd -- "$(dirname "$0")/.." && pwd)
stamp=$(date +%Y%m%d-%H%M%S)

detect_shell_rc() {
  if [ -n "${WEZTRUNK_SHELL_RC:-}" ]; then
    printf '%s\n' "$WEZTRUNK_SHELL_RC"
    return
  fi

  shell_name=$(basename "${SHELL:-}")
  case "$shell_name" in
    zsh)
      printf '%s\n' "$HOME/.zshrc"
      ;;
    bash)
      printf '%s\n' "$HOME/.bashrc"
      ;;
    *)
      printf '%s\n' "$HOME/.profile"
      ;;
  esac
}

bash_login_profile_sources_bashrc() {
  for candidate in "$HOME/.bash_profile" "$HOME/.bash_login" "$HOME/.profile"; do
    if [ -f "$candidate" ] && grep -Eq '(^|[[:space:]])(\.|source)[[:space:]].*bashrc([[:space:]]|$)' "$candidate"; then
      return 0
    fi
  done

  return 1
}

backup_if_needed() {
  target=$1

  if [ -L "$target" ]; then
    rm -f "$target"
    return
  fi

  if [ -e "$target" ]; then
    mv "$target" "$target.bak.$stamp"
  fi
}

link_file() {
  source_path=$1
  target_path=$2

  mkdir -p "$(dirname "$target_path")"
  backup_if_needed "$target_path"
  ln -s "$source_path" "$target_path"
}

link_file "$repo_root/.wezterm.lua" "$HOME/.wezterm.lua"
link_file "$repo_root/.config/worktrunk/config.toml" "$HOME/.config/worktrunk/config.toml"
link_file "$repo_root/.config/weztrunk/MANUAL.md" "$HOME/.config/weztrunk/MANUAL.md"
link_file "$repo_root/.config/weztrunk/config.toml" "$HOME/.config/weztrunk/config.toml"
link_file "$repo_root/.config/weztrunk/agent-profile.sh" "$HOME/.config/weztrunk/agent-profile.sh"
link_file "$repo_root/.config/weztrunk/providers/codex/launch.args" "$HOME/.config/weztrunk/providers/codex/launch.args"
link_file "$repo_root/.config/weztrunk/providers/codex/commit.args" "$HOME/.config/weztrunk/providers/codex/commit.args"
link_file "$repo_root/.config/weztrunk/providers/claude-code/launch.args" "$HOME/.config/weztrunk/providers/claude-code/launch.args"
link_file "$repo_root/.config/weztrunk/providers/claude-code/commit.args" "$HOME/.config/weztrunk/providers/claude-code/commit.args"
link_file "$repo_root/.config/weztrunk/providers/opencode/launch.args" "$HOME/.config/weztrunk/providers/opencode/launch.args"
link_file "$repo_root/.config/weztrunk/providers/opencode/commit.args" "$HOME/.config/weztrunk/providers/opencode/commit.args"
link_file "$repo_root/.local/bin/weztrunk-agent" "$HOME/.local/bin/weztrunk-agent"
link_file "$repo_root/.local/bin/weztrunk" "$HOME/.local/bin/weztrunk"
link_file "$repo_root/.local/bin/weztrunk-config" "$HOME/.local/bin/weztrunk-config"
link_file "$repo_root/.local/bin/weztrunk-manual" "$HOME/.local/bin/weztrunk-manual"
link_file "$repo_root/.local/bin/weztrunk-switch" "$HOME/.local/bin/weztrunk-switch"
link_file "$repo_root/.local/bin/wt-code" "$HOME/.local/bin/wt-code"
link_file "$repo_root/.local/bin/worktrunk-code-commit" "$HOME/.local/bin/worktrunk-code-commit"
link_file "$repo_root/shell/weztrunk.sh" "$HOME/.config/weztrunk/weztrunk.sh"
link_file "$repo_root/shell/weztrunk.zsh" "$HOME/.config/weztrunk/weztrunk.zsh"

chmod +x \
  "$HOME/.local/bin/weztrunk-manual" \
  "$HOME/.config/weztrunk/agent-profile.sh" \
  "$HOME/.local/bin/weztrunk-agent" \
  "$HOME/.local/bin/weztrunk" \
  "$HOME/.local/bin/weztrunk-config" \
  "$HOME/.local/bin/weztrunk-switch" \
  "$HOME/.local/bin/wt-code" \
  "$HOME/.local/bin/worktrunk-code-commit"

shell_rc=$(detect_shell_rc)
rc_line='source "$HOME/.config/weztrunk/weztrunk.sh"'
touch "$shell_rc"
if ! grep -Fq "$rc_line" "$shell_rc"; then
  printf '\n%s\n' "$rc_line" >> "$shell_rc"
fi

printf 'Installed WezTrunk symlinks from %s\n' "$repo_root"
printf 'Updated shell startup file: %s\n' "$shell_rc"
printf 'Reload your shell or run: source %s\n' "$shell_rc"

if [ "$shell_rc" = "$HOME/.bashrc" ] && ! bash_login_profile_sources_bashrc; then
  printf 'Note: bash login shells may not load %s unless ~/.bash_profile, ~/.bash_login, or ~/.profile sources it.\n' "$shell_rc"
  printf 'If your Linux terminal starts login shells, add `source ~/.bashrc` to one of those files or reinstall with WEZTRUNK_SHELL_RC=~/.profile.\n'
fi
