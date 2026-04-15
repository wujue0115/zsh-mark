#!/bin/zsh

INSTALL_DIR="${HOME}/.zsh-mark"
ZSHRC="${ZDOTDIR:-$HOME}/.zshrc"
PLUGIN_LINE="source \"$INSTALL_DIR/mark.plugin.zsh\""
MAN_PAGE="${HOME}/.local/share/man/man1/mark.1"

echo "Uninstalling zsh-mark..."

# Remove plugin files
if [[ -d "$INSTALL_DIR" ]]; then
  rm -rf "$INSTALL_DIR"
  echo "Removed $INSTALL_DIR"
fi

# Remove man page
if [[ -f "$MAN_PAGE" ]]; then
  rm -f "$MAN_PAGE"
  if command -v mandb &>/dev/null; then
    mandb -q 2>/dev/null || true
  fi
  echo "Removed man page"
fi

# Remove source line from .zshrc
if grep -qF "$PLUGIN_LINE" "$ZSHRC" 2>/dev/null; then
  # Use a temp file to avoid in-place issues across platforms
  grep -vF "$PLUGIN_LINE" "$ZSHRC" > "$ZSHRC.tmp" && mv "$ZSHRC.tmp" "$ZSHRC"
  echo "Removed from $ZSHRC"
fi

echo "Done."
echo "Note: bookmarks in ~/.local/share/zsh-mark were not removed. Delete manually if needed."
echo "Note: mark commands are still active in this session. Start a new shell to fully unload."
