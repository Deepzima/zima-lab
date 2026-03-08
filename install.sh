#!/usr/bin/env bash
set -euo pipefail

REPO_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
CONFIG_DIR="${ZLAB_CONFIG_DIR:-$HOME/.config/zlab}"
BIN_DIR="${ZLAB_BIN_DIR:-$HOME/.local/bin}"

echo "zlab installer"
echo ""

# --- Prerequisites ---
missing=()
for cmd in docker kind kubectl jq; do
  if ! command -v "$cmd" &>/dev/null; then
    missing+=("$cmd")
  fi
done

if ! command -v yq &>/dev/null; then
  if command -v brew &>/dev/null; then
    echo "Installing yq via brew..."
    brew install yq
  else
    missing+=("yq")
  fi
fi

if [[ ${#missing[@]} -gt 0 ]]; then
  echo "WARNING: missing prerequisites: ${missing[*]}"
  echo "Install them before using zlab."
  echo ""
fi

# --- Config directory ---
mkdir -p "$CONFIG_DIR"

# Symlink templates and stacks (always point to repo)
ln -sfn "$REPO_DIR/templates" "$CONFIG_DIR/templates"
ln -sfn "$REPO_DIR/stacks" "$CONFIG_DIR/stacks"

# Shell aliases
ln -sf "$REPO_DIR/aliases.zsh" "$CONFIG_DIR/aliases.zsh"

# Global config — copy only on first install (user editable)
if [[ ! -f "$CONFIG_DIR/config.yaml" ]]; then
  cp "$REPO_DIR/config.yaml" "$CONFIG_DIR/config.yaml"
  echo "Created global config: $CONFIG_DIR/config.yaml"
else
  echo "Global config exists: $CONFIG_DIR/config.yaml (not overwritten)"
fi

# --- Binary ---
mkdir -p "$BIN_DIR"
ln -sf "$REPO_DIR/bin/zlab" "$BIN_DIR/zlab"
chmod +x "$REPO_DIR/bin/zlab"

# --- Shell integration ---
echo ""
echo "Installation complete!"
echo ""

# Check if BIN_DIR is in PATH
if ! echo "$PATH" | tr ':' '\n' | grep -qx "$BIN_DIR"; then
  echo "Add to your shell profile:"
  echo "  export PATH=\"$BIN_DIR:\$PATH\""
  echo ""
fi

# Shell aliases hint
echo "For shell aliases (zlu, zld, zls, etc.), add to your .zshrc or .bashrc:"
echo "  [[ -f $CONFIG_DIR/aliases.zsh ]] && source $CONFIG_DIR/aliases.zsh"
echo ""
echo "Run 'zlab doctor' to verify setup."
