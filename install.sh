#!/bin/zsh

INSTALL_DIR="${HOME}/.zsh-mark"
ZSHRC="${ZDOTDIR:-$HOME}/.zshrc"
PLUGIN_LINE="source \"$INSTALL_DIR/mark.plugin.zsh\""

echo "Installing zsh-mark..."

# Copy plugin file
mkdir -p "$INSTALL_DIR"
cp "$(dirname "$0")/mark.plugin.zsh" "$INSTALL_DIR/mark.plugin.zsh"

# Add source line to .zshrc if not already present
if grep -qF "$PLUGIN_LINE" "$ZSHRC" 2>/dev/null; then
  echo "Already installed in $ZSHRC"
else
  printf '\n%s\n' "$PLUGIN_LINE" >> "$ZSHRC"
  echo "Added to $ZSHRC"
fi

echo "Done. Restart your shell or run: source $ZSHRC"
