#!/usr/bin/env bash

set -euo pipefail

MARKER_START="# >>> init-mac config >>>"
MARKER_END="# <<< init-mac config <<<"

ASSUME_YES=0
REMOVE_BOOTSTRAP=0

BREW_FORMULAE=(
  python@3.11
  node
  git
  pnpm
  starship
  zoxide
  fzf
)

BREW_CASKS=(
  visual-studio-code
  google-chrome
  microsoft-edge
  qq
  wechat
  trae
  karabiner-elements
  clash-verge-rev
  clashx
)

NPM_GLOBAL_PACKAGES=(
  opencode
  claudecode
)

usage() {
  cat <<'EOF'
Usage: reset-init-mac.sh [options]

Options:
  --yes               Run non-interactive (no confirmation prompt)
  --remove-bootstrap  Also remove Homebrew and Xcode CLT
  --help              Show this help

Examples:
  bash scripts/reset-init-mac.sh --yes
  bash scripts/reset-init-mac.sh --yes --remove-bootstrap
EOF
}

log() {
  printf '[%s] %s\n' "$(date '+%H:%M:%S')" "$*"
}

warn() {
  printf '[%s] WARN: %s\n' "$(date '+%H:%M:%S')" "$*" >&2
}

command_exists() {
  command -v "$1" >/dev/null 2>&1
}

ensure_macos() {
  if [[ "$(uname -s)" != "Darwin" ]]; then
    warn "This reset script is intended for macOS"
  fi
}

confirm_or_exit() {
  if [[ "$ASSUME_YES" -eq 1 ]]; then
    return
  fi

  cat <<'EOF'
This will remove tools/configs installed by init-mac.
Use Ctrl+C now if you want to stop.
EOF
  read -r -p "Continue? [y/N] " answer
  if [[ ! "$answer" =~ ^[Yy]$ ]]; then
    log "Cancelled by user."
    exit 0
  fi
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

reset_shell_config() {
  log "Reset shell config markers"
  remove_marked_block "$HOME/.zshrc"
  remove_marked_block "$HOME/.zprofile"
  remove_marked_block "$HOME/.bashrc"
  remove_marked_block "$HOME/.bash_profile"
  remove_marked_block "$HOME/.config/starship.toml"
}

reset_registry_config() {
  log "Reset npm/pnpm/pip mirror config"

  if command_exists npm; then
    npm config delete registry >/dev/null 2>&1 || true
    npm config delete prefix >/dev/null 2>&1 || true
  fi

  if command_exists pnpm; then
    pnpm config delete registry >/dev/null 2>&1 || true
  fi

  remove_marked_block "$HOME/.npmrc"
  remove_marked_block "$HOME/.config/pnpm/rc"
  remove_marked_block "$HOME/.pip/pip.conf"
  remove_marked_block "$HOME/.config/pip/pip.conf"

  if [[ -d "$HOME/.npm-global" ]]; then
    log "Remove npm user prefix directory"
    rm -rf "$HOME/.npm-global"
  fi
}

uninstall_npm_globals() {
  if ! command_exists npm; then
    warn "npm not found, skip global package removal"
    return
  fi

  local npm_root
  npm_root="$(npm root -g 2>/dev/null || true)"

  for pkg in "${NPM_GLOBAL_PACKAGES[@]}"; do
    if [[ -n "$npm_root" && -d "$npm_root/$pkg" ]]; then
      log "Uninstall npm global package: $pkg"
      npm uninstall -g "$pkg" >/dev/null 2>&1 || warn "Failed to uninstall npm package: $pkg"
    else
      log "Skip npm package (not installed): $pkg"
    fi
  done
}

uninstall_brew_packages() {
  if ! command_exists brew; then
    warn "Homebrew not found, skip brew package removal"
    return
  fi

  log "Uninstall brew formulae"
  for pkg in "${BREW_FORMULAE[@]}"; do
    if brew list --formula "$pkg" >/dev/null 2>&1; then
      log "brew uninstall $pkg"
      brew uninstall "$pkg" >/dev/null 2>&1 || warn "Failed to uninstall formula: $pkg"
    else
      log "Skip formula (not installed): $pkg"
    fi
  done

  log "Uninstall brew casks"
  for pkg in "${BREW_CASKS[@]}"; do
    if brew list --cask "$pkg" >/dev/null 2>&1; then
      log "brew uninstall --cask $pkg"
      brew uninstall --cask "$pkg" >/dev/null 2>&1 || warn "Failed to uninstall cask: $pkg"
    else
      log "Skip cask (not installed): $pkg"
    fi
  done

  brew autoremove >/dev/null 2>&1 || true
  brew cleanup -s >/dev/null 2>&1 || true
}

remove_bootstrap_tools() {
  if [[ "$REMOVE_BOOTSTRAP" -ne 1 ]]; then
    return
  fi

  if command_exists brew; then
    log "Remove Homebrew (official uninstall script)"
    NONINTERACTIVE=1 /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/uninstall.sh)" \
      || warn "Homebrew uninstall failed, you may need to rerun manually"
  else
    log "Skip Homebrew uninstall (brew not found)"
  fi

  if [[ -d "/Library/Developer/CommandLineTools" ]]; then
    warn "Removing CLT requires sudo password"
    sudo rm -rf "/Library/Developer/CommandLineTools" || warn "Failed to remove CLT"
    sudo xcode-select --reset >/dev/null 2>&1 || true
  else
    log "Skip CLT removal (not found)"
  fi
}

cleanup_logs() {
  if [[ -d "$HOME/init-mac-logs" ]]; then
    log "Remove init logs directory"
    rm -rf "$HOME/init-mac-logs"
  fi
}

parse_args() {
  while [[ $# -gt 0 ]]; do
    case "$1" in
      --yes)
        ASSUME_YES=1
        ;;
      --remove-bootstrap)
        REMOVE_BOOTSTRAP=1
        ;;
      --help|-h)
        usage
        exit 0
        ;;
      *)
        warn "Unknown option: $1"
        usage
        exit 1
        ;;
    esac
    shift
  done
}

main() {
  parse_args "$@"
  ensure_macos
  confirm_or_exit

  uninstall_npm_globals
  uninstall_brew_packages
  reset_registry_config
  reset_shell_config
  cleanup_logs
  remove_bootstrap_tools

  log "Done. Environment reset completed."
}

main "$@"
