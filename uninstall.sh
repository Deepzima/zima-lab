#!/usr/bin/env bash
set -euo pipefail

CONFIG_DIR="${ZLAB_CONFIG_DIR:-$HOME/.config/zlab}"
BIN_DIR="${ZLAB_BIN_DIR:-$HOME/.local/bin}"

echo "zlab uninstaller"
echo ""

# Remove binary symlink
if [[ -L "$BIN_DIR/zlab" ]]; then
  rm "$BIN_DIR/zlab"
  echo "Removed: $BIN_DIR/zlab"
fi

# Remove config symlinks (keep user config.yaml)
for item in templates stacks aliases.zsh; do
  if [[ -L "$CONFIG_DIR/$item" ]]; then
    rm "$CONFIG_DIR/$item"
    echo "Removed: $CONFIG_DIR/$item"
  fi
done

echo ""
if [[ -f "$CONFIG_DIR/config.yaml" ]]; then
  echo "Kept: $CONFIG_DIR/config.yaml (your personal config)"
  echo "Remove manually if you want a full cleanup: rm -rf $CONFIG_DIR"
else
  rmdir "$CONFIG_DIR" 2>/dev/null && echo "Removed: $CONFIG_DIR" || true
fi

echo ""
echo "zlab uninstalled. Repo can be safely deleted."
