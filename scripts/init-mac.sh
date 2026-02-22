#!/usr/bin/env bash

set -euo pipefail

MARKER_START="# >>> init-mac config >>>"
MARKER_END="# <<< init-mac config <<<"

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
LOG_DIR="$HOME/init-mac-logs"

USE_BREW_MIRROR=1
INSTALL_KARABINER=0
INSTALL_CLASH=0
SKIP_GUI=0

NPM_REGISTRY="https://registry.npmmirror.com"
PIP_INDEX_URL="https://pypi.tuna.tsinghua.edu.cn/simple"
PIP_TRUST_HOST="pypi.tuna.tsinghua.edu.cn"

BREW_FORMULAE=(
  python@3.11
  node
  git
  pnpm
  starship
  zoxide
  fzf
)

BASE_CASKS=(
  visual-studio-code
  google-chrome
  microsoft-edge
  qq
  wechat
  trae
)

usage() {
  cat <<'EOF'
Usage: init-mac.sh [options]

Options:
  --brew-mirror      Enable brew bottle mirror for this run (default)
  --no-brew-mirror   Disable brew bottle mirror for this run
  --with-karabiner   Install karabiner-elements
  --with-clash       Install clash-verge-rev cask
  --skip-gui         Skip GUI app installations
  --help             Show this help

Examples:
  bash scripts/init-mac.sh
  bash scripts/init-mac.sh --with-clash
  bash scripts/init-mac.sh --no-brew-mirror
EOF
}

log() {
  printf '[%s] %s\n' "$(date '+%H:%M:%S')" "$*"
}

warn() {
  printf '[%s] WARN: %s\n' "$(date '+%H:%M:%S')" "$*" >&2
}

die() {
  printf '[%s] ERROR: %s\n' "$(date '+%H:%M:%S')" "$*" >&2
  exit 1
}

command_exists() {
  command -v "$1" >/dev/null 2>&1
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

parse_args() {
  while [[ $# -gt 0 ]]; do
    case "$1" in
      --brew-mirror)
        USE_BREW_MIRROR=1
        ;;
      --no-brew-mirror)
        USE_BREW_MIRROR=0
        ;;
      --with-karabiner)
        INSTALL_KARABINER=1
        ;;
      --with-clash)
        INSTALL_CLASH=1
        ;;
      --skip-gui)
        SKIP_GUI=1
        ;;
      --help|-h)
        usage
        exit 0
        ;;
      *)
        die "Unknown option: $1"
        ;;
    esac
    shift
  done
}

ensure_macos() {
  if [[ "$(uname -s)" != "Darwin" ]]; then
    die "This script only supports macOS."
  fi

  if [[ "$(uname -m)" != "arm64" ]]; then
    warn "Current architecture is not arm64. Script will continue."
  fi
}

prepare_logs() {
  mkdir -p "$LOG_DIR"
  local run_log
  run_log="$LOG_DIR/init-mac-$(date '+%Y%m%d-%H%M%S').log"
  exec > >(tee -a "$run_log") 2>&1
  log "Log file: $run_log"
}

ensure_clt() {
  if xcode-select -p >/dev/null 2>&1; then
    log "Xcode Command Line Tools already installed"
    return
  fi

  log "Installing Xcode Command Line Tools"
  xcode-select --install >/dev/null 2>&1 || true
  log "Waiting for CLT installation to complete..."

  local retries=90
  while ! xcode-select -p >/dev/null 2>&1; do
    sleep 20
    retries=$((retries - 1))
    if [[ "$retries" -le 0 ]]; then
      die "CLT is not ready. Complete popup installer and rerun this script."
    fi
  done

  log "CLT installation detected"
}

load_brew_shellenv() {
  if [[ -x "/opt/homebrew/bin/brew" ]]; then
    eval "$(/opt/homebrew/bin/brew shellenv)"
  elif [[ -x "/usr/local/bin/brew" ]]; then
    eval "$(/usr/local/bin/brew shellenv)"
  fi
}

ensure_homebrew() {
  if command_exists brew; then
    log "Homebrew already installed"
    load_brew_shellenv
    return
  fi

  log "Installing Homebrew"
  NONINTERACTIVE=1 /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
  load_brew_shellenv

  if ! command_exists brew; then
    die "Homebrew installation failed"
  fi
}

configure_brew_env() {
  if [[ "$USE_BREW_MIRROR" -eq 1 ]]; then
    export HOMEBREW_BOTTLE_DOMAIN="https://mirrors.ustc.edu.cn/homebrew-bottles"
    log "Brew mirror enabled for current run"
  else
    log "Brew mirror disabled for current run"
  fi
}

configure_shell_env() {
  local zprofile_block
  zprofile_block="$(cat <<'EOF'
if [ -x "/opt/homebrew/bin/brew" ]; then
  eval "$(/opt/homebrew/bin/brew shellenv)"
elif [ -x "/usr/local/bin/brew" ]; then
  eval "$(/usr/local/bin/brew shellenv)"
fi

if [ -d "$HOME/.npm-global/bin" ]; then
  export PATH="$HOME/.npm-global/bin:$PATH"
fi
EOF
)"

  append_marked_block "$HOME/.zprofile" "$zprofile_block"
}

install_formula() {
  local pkg="$1"
  if brew list --formula "$pkg" >/dev/null 2>&1; then
    log "Formula already installed: $pkg"
    return
  fi

  log "Installing formula: $pkg"
  brew install "$pkg"
}

install_cli_tools() {
  log "Updating brew metadata"
  brew update

  local pkg
  for pkg in "${BREW_FORMULAE[@]}"; do
    install_formula "$pkg"
  done
}

configure_mirrors() {
  log "Configuring npm/pnpm/pip mirrors"

  if command_exists npm; then
    npm config set registry "$NPM_REGISTRY"
  else
    warn "npm not found, skip npm mirror"
  fi

  if command_exists pnpm; then
    pnpm config set registry "$NPM_REGISTRY"
  else
    warn "pnpm not found, skip pnpm mirror"
  fi

  local pip_file="$HOME/.pip/pip.conf"
  local pip_block
  pip_block="$(cat <<EOF
[global]
index-url = $PIP_INDEX_URL
trusted-host = $PIP_TRUST_HOST
EOF
)"
  append_marked_block "$pip_file" "$pip_block"
}

install_npm_global_pkg() {
  local pkg="$1"

  if npm list -g --depth=0 "$pkg" >/dev/null 2>&1; then
    log "npm global already installed: $pkg"
    return
  fi

  log "Installing npm global package: $pkg"
  if npm install -g "$pkg" >/dev/null 2>&1; then
    return
  fi

  warn "Default npm global install failed, retry with user prefix"
  mkdir -p "$HOME/.npm-global"
  npm config set prefix "$HOME/.npm-global"
  export PATH="$HOME/.npm-global/bin:$PATH"

  if ! npm install -g "$pkg" >/dev/null 2>&1; then
    warn "Failed to install npm global package: $pkg"
  fi
}

install_npm_globals() {
  if ! command_exists npm; then
    warn "npm not found, skip npm global installs"
    return
  fi

  install_npm_global_pkg "opencode"
  install_npm_global_pkg "claudecode"
}

install_cask() {
  local pkg="$1"

  if brew list --cask "$pkg" >/dev/null 2>&1; then
    log "Cask already installed: $pkg"
    return
  fi

  if ! brew info --cask "$pkg" >/dev/null 2>&1; then
    warn "Cask not found: $pkg"
    return
  fi

  log "Installing cask: $pkg"
  brew install --cask "$pkg" || warn "Failed cask install: $pkg"
}

install_gui_apps() {
  if [[ "$SKIP_GUI" -eq 1 ]]; then
    log "Skip GUI app installation"
    return
  fi

  local casks=("${BASE_CASKS[@]}")
  if [[ "$INSTALL_KARABINER" -eq 1 ]]; then
    casks+=(karabiner-elements)
  fi
  if [[ "$INSTALL_CLASH" -eq 1 ]]; then
    casks+=(clash-verge-rev)
  fi

  local pkg
  for pkg in "${casks[@]}"; do
    install_cask "$pkg"
  done
}

run_post_config() {
  if [[ -f "$SCRIPT_DIR/post-config.sh" ]]; then
    bash "$SCRIPT_DIR/post-config.sh"
  else
    warn "post-config.sh not found, skip"
  fi
}

show_next_steps() {
  cat <<'EOF'

Install flow completed.
Next steps:
1) Restart terminal or run: source ~/.zprofile && source ~/.zshrc
2) Verify install: bash scripts/verify-init.sh
3) If you want Clash app: rerun with --with-clash

Windows keyboard mapping:
- Open: System Settings -> Keyboard -> Keyboard Shortcuts -> Modifier Keys
- Select your external keyboard and adjust Option/Command per habit
EOF
}

main() {
  parse_args "$@"
  ensure_macos
  prepare_logs

  ensure_clt
  ensure_homebrew
  configure_brew_env
  configure_shell_env
  install_cli_tools
  configure_mirrors
  install_npm_globals
  install_gui_apps
  run_post_config
  show_next_steps
}

main "$@"
