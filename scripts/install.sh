#!/bin/sh

set -eu

repo_root=$(CDPATH= cd -- "$(dirname "$0")/.." && pwd)
stamp=$(date +%Y%m%d-%H%M%S)

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
link_file "$repo_root/shell/weztrunk.zsh" "$HOME/.config/weztrunk/weztrunk.zsh"

chmod +x "$HOME/.local/bin/wt-code" "$HOME/.local/bin/worktrunk-code-commit"

zshrc_line='source "$HOME/.config/weztrunk/weztrunk.zsh"'
touch "$HOME/.zshrc"
if ! grep -Fq "$zshrc_line" "$HOME/.zshrc"; then
  printf '\n%s\n' "$zshrc_line" >> "$HOME/.zshrc"
fi

printf 'Installed WezTrunk symlinks from %s\n' "$repo_root"
printf 'Reload your shell or run: source ~/.zshrc\n'
