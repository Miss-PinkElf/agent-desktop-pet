#!/usr/bin/env bash

set -euo pipefail

FAIL_COUNT=0
WARN_COUNT=0

NPM_EXPECTED="https://registry.npmmirror.com"

log_ok() {
  printf '[OK] %s\n' "$*"
}

log_warn() {
  WARN_COUNT=$((WARN_COUNT + 1))
  printf '[WARN] %s\n' "$*"
}

log_fail() {
  FAIL_COUNT=$((FAIL_COUNT + 1))
  printf '[FAIL] %s\n' "$*"
}

command_exists() {
  command -v "$1" >/dev/null 2>&1
}

first_line() {
  sed -n '1p'
}

normalize_registry() {
  local value="$1"
  value="${value%/}"
  printf '%s' "$value"
}

check_command() {
  local cmd="$1"
  if command_exists "$cmd"; then
    local version
    version="$($cmd --version 2>/dev/null | first_line || true)"
    if [[ -n "$version" ]]; then
      log_ok "$cmd detected ($version)"
    else
      log_ok "$cmd detected"
    fi
  else
    log_fail "$cmd not found"
  fi
}

check_app() {
  local display_name="$1"
  local app_path="$2"

  if [[ -d "$app_path" ]]; then
    log_ok "$display_name installed ($app_path)"
  else
    log_fail "$display_name missing ($app_path)"
  fi
}

check_optional_app() {
  local display_name="$1"
  local app_path="$2"

  if [[ -d "$app_path" ]]; then
    log_ok "$display_name installed ($app_path)"
  else
    log_warn "$display_name missing ($app_path)"
  fi
}

check_registry() {
  if command_exists npm; then
    local npm_registry
    npm_registry="$(normalize_registry "$(npm config get registry 2>/dev/null || true)")"
    if [[ "$npm_registry" == "$(normalize_registry "$NPM_EXPECTED")" ]]; then
      log_ok "npm registry is npmmirror"
    else
      log_fail "npm registry mismatch: $npm_registry"
    fi
  else
    log_fail "npm missing, cannot verify npm registry"
  fi

  if command_exists pnpm; then
    local pnpm_registry
    pnpm_registry="$(normalize_registry "$(pnpm config get registry 2>/dev/null || true)")"
    if [[ "$pnpm_registry" == "$(normalize_registry "$NPM_EXPECTED")" ]]; then
      log_ok "pnpm registry is npmmirror"
    else
      log_fail "pnpm registry mismatch: $pnpm_registry"
    fi
  else
    log_fail "pnpm missing, cannot verify pnpm registry"
  fi
}

check_pip_config() {
  local pip_conf="$HOME/.pip/pip.conf"
  if [[ -f "$pip_conf" ]]; then
    if grep -E "index-url\s*=\s*https://pypi\.(tuna|aliyun)" "$pip_conf" >/dev/null 2>&1; then
      log_ok "pip mirror configured ($pip_conf)"
    else
      log_fail "pip mirror not found in $pip_conf"
    fi
  else
    log_fail "pip config not found ($pip_conf)"
  fi
}

print_result() {
  echo ""
  echo "Verification result: FAIL=$FAIL_COUNT, WARN=$WARN_COUNT"
  if [[ "$FAIL_COUNT" -gt 0 ]]; then
    exit 1
  fi
}

main() {
  if [[ "$(uname -s)" != "Darwin" ]]; then
    echo "This verifier is intended for macOS."
    exit 1
  fi

  echo "== CLI checks =="
  check_command brew
  check_command python3.11
  check_command node
  check_command npm
  check_command git
  check_command pnpm
  check_command opencode
  check_command claudecode

  echo ""
  echo "== Mirror checks =="
  check_registry
  check_pip_config

  echo ""
  echo "== App checks =="
  check_app "Visual Studio Code" "/Applications/Visual Studio Code.app"
  check_app "Google Chrome" "/Applications/Google Chrome.app"
  check_app "Microsoft Edge" "/Applications/Microsoft Edge.app"
  check_app "QQ" "/Applications/QQ.app"
  check_app "WeChat" "/Applications/WeChat.app"
  check_optional_app "Trae" "/Applications/Trae.app"

  print_result
}

main "$@"
