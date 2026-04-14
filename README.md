# zsh-mark

A minimal directory bookmark system for zsh.

## Commands

```
mark add [name]        Save current directory as a bookmark (default: current dir name)
mark go <name>         Jump to a bookmarked directory
mark ls                List all bookmarks
mark mv <old> <new>    Rename a bookmark
mark rm <name>         Remove a bookmark
mark help              Show help
```

## Installation

### Manual

```zsh
git clone https://github.com/wujue0115/zsh-mark.git
cd zsh-mark
./install.sh
```

### Oh-My-Zsh

```zsh
git clone https://github.com/wujue0115/zsh-mark.git ${ZSH_CUSTOM:-~/.oh-my-zsh/custom}/plugins/zsh-mark
```

Then add `zsh-mark` to your plugins in `~/.zshrc`:

```zsh
plugins=(... zsh-mark)
```

### zinit

```zsh
zinit light wujue0115/zsh-mark
```

## Tab Completion

`go`, `rm`, and `mv` support tab completion (triggered by <kbd>Tab</kbd> or <kbd>↓</kbd>) with smart ranking. Candidates are sorted by match quality:

| Priority | Condition |
|----------|-----------|
| 1st | Exact match |
| 2nd | Query is a substring of the bookmark name |
| 3rd | Query characters appear in order (subsequence) |
| 4th | Everything else |

Within each tier, results are further ranked by [Levenshtein distance](https://en.wikipedia.org/wiki/Levenshtein_distance). Each candidate also shows its target path:

```
$ mark go pr<Tab>

projects   --> /Users/you/projects
profiles   --> /Users/you/.config/profiles
```

## Data

Bookmarks are stored as symlinks in `~/.local/share/zsh-mark/` (or `$XDG_DATA_HOME/zsh-mark` if set).

## Uninstall

```zsh
./uninstall.sh
```

Bookmarks in `~/.local/share/zsh-mark/` are not removed automatically. Delete the directory manually if needed.
