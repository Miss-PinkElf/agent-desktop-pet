#!/usr/bin/env bash

set -euo pipefail

MARKER_START="# >>> init-mac config >>>"
MARKER_END="# <<< init-mac config <<<"

log() {
  printf '[%s] %s\n' "$(date '+%H:%M:%S')" "$*"
}

remove_marked_block() {
  local file="$1"
  [[ -f "$file" ]] || return 0

  local tmp
  tmp="$(mktemp)"
  awk -v start="$MARKER_START" -v end="$MARKER_END" '
    $0 == start { skip = 1; next }
    $0 == end { skip = 0; next }
    skip != 1 { print }
  ' "$file" > "$tmp"
  mv "$tmp" "$file"
}

append_marked_block() {
  local file="$1"
  local body="$2"

  mkdir -p "$(dirname "$file")"
  touch "$file"

  remove_marked_block "$file"
  printf '\n%s\n%s\n%s\n' "$MARKER_START" "$body" "$MARKER_END" >> "$file"
}

configure_zsh() {
  local zsh_block
  zsh_block="$(cat <<'EOF'
if command -v starship >/dev/null 2>&1; then
  eval "$(starship init zsh)"
fi

if command -v zoxide >/dev/null 2>&1; then
  eval "$(zoxide init zsh)"
fi

if command -v brew >/dev/null 2>&1; then
  FZF_SHELL="$(brew --prefix)/opt/fzf/shell"
  [ -f "$FZF_SHELL/completion.zsh" ] && source "$FZF_SHELL/completion.zsh"
  [ -f "$FZF_SHELL/key-bindings.zsh" ] && source "$FZF_SHELL/key-bindings.zsh"
fi
EOF
)"

  append_marked_block "$HOME/.zshrc" "$zsh_block"
}

configure_starship() {
  local starship_file="$HOME/.config/starship.toml"
  local starship_block
  starship_block="$(cat <<'EOF'
add_newline = true

format = "$directory$git_branch$git_status$python$nodejs$character"

[character]
success_symbol = "[>](bold green)"
error_symbol = "[>](bold red)"
EOF
)"

  append_marked_block "$starship_file" "$starship_block"
}

show_keyboard_tips() {
  cat <<'EOF'

键盘映射建议（外接 Windows 键盘）
1) 打开：系统设置 -> 键盘 -> 键盘快捷键 -> 修饰键
2) 选择你的外接键盘
3) 按你的习惯调整：
   - 方案 A（接近 Mac 默认）：保持现状
   - 方案 B（常见 Win 用户）：交换 Option 和 Command

需要更复杂映射（按 App、组合键改写）时，再安装 Karabiner-Elements。
EOF
}

main() {
  configure_zsh
  configure_starship
  show_keyboard_tips
  log "post-config completed"
}

main "$@"
