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
link_file "$repo_root/.local/bin/wt-code" "$HOME/.local/bin/wt-code"
link_file "$repo_root/.local/bin/worktrunk-code-commit" "$HOME/.local/bin/worktrunk-code-commit"
link_file "$repo_root/shell/weztrunk.sh" "$HOME/.config/weztrunk/weztrunk.sh"
link_file "$repo_root/shell/weztrunk.zsh" "$HOME/.config/weztrunk/weztrunk.zsh"

chmod +x "$HOME/.local/bin/wt-code" "$HOME/.local/bin/worktrunk-code-commit"

shell_rc=$(detect_shell_rc)
rc_line='source "$HOME/.config/weztrunk/weztrunk.sh"'
touch "$shell_rc"
if ! grep -Fq "$rc_line" "$shell_rc"; then
  printf '\n%s\n' "$rc_line" >> "$shell_rc"
fi

printf 'Installed WezTrunk symlinks from %s\n' "$repo_root"
printf 'Updated shell startup file: %s\n' "$shell_rc"
printf 'Reload your shell or run: source %s\n' "$shell_rc"
