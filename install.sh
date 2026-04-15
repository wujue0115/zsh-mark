#!/bin/zsh

INSTALL_DIR="${HOME}/.zsh-mark"
ZSHRC="${ZDOTDIR:-$HOME}/.zshrc"
PLUGIN_LINE="source \"$INSTALL_DIR/mark.plugin.zsh\""
MAN_DIR="${HOME}/.local/share/man/man1"
SCRIPT_DIR="$(dirname "$0")"

echo "Installing zsh-mark..."

# Copy plugin file
mkdir -p "$INSTALL_DIR"
cp "$SCRIPT_DIR/mark.plugin.zsh" "$INSTALL_DIR/mark.plugin.zsh"

# Install man page
if [[ -f "$SCRIPT_DIR/man/mark.1" ]]; then
  mkdir -p "$MAN_DIR"
  cp "$SCRIPT_DIR/man/mark.1" "$MAN_DIR/mark.1"
  # Rebuild man index if mandb is available; suppress output
  if command -v mandb &>/dev/null; then
    mandb -q 2>/dev/null || true
  fi
  echo "Installed man page (run: man mark)"
fi

# Add source line to .zshrc if not already present
if grep -qF "$PLUGIN_LINE" "$ZSHRC" 2>/dev/null; then
  echo "Already installed in $ZSHRC"
else
  printf '\n%s\n' "$PLUGIN_LINE" >> "$ZSHRC"
  echo "Added to $ZSHRC"
fi

echo "Done. Restart your shell or run: source $ZSHRC"
