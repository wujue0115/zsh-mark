# mark.plugin.zsh
# Directory bookmark system
# Usage: mark <command> [args]

MARKS_DIR="${XDG_DATA_HOME:-$HOME/.local/share}/zsh-mark"
MARKS_FILE="$MARKS_DIR/bookmarks"
mkdir -p "$MARKS_DIR"

# Resolve external tools at load time so subshells inherit the correct full path
# regardless of how PATH is configured in the user's environment.
: ${_mark_awk:=${commands[awk]:-$_mark_awk}}
: ${_mark_wc:=${commands[wc]:-/usr/bin/wc}}
: ${_mark_tail:=${commands[tail]:-/usr/bin/tail}}
: ${_mark_sort:=${commands[sort]:-/usr/bin/sort}}

# Preserve candidate ordering (disable zsh's default alphabetical sort)
zstyle ':completion:*:*:mark:*' sort false

# Levenshtein distance between two strings
_mark_levenshtein() {
  local s="$1" t="$2"
  local -i slen=${#s} tlen=${#t} i j cost min
  local -a prev curr

  for (( j = 0; j <= tlen; j++ )); do prev[j+1]=$j; done

  for (( i = 1; i <= slen; i++ )); do
    curr=()
    curr[1]=$i
    for (( j = 1; j <= tlen; j++ )); do
      if [[ "${s[i]}" == "${t[j]}" ]]; then cost=-2; else cost=1; fi
      min=$(( prev[j+1] + 1 ))
      (( curr[j] + 1 < min )) && min=$(( curr[j] + 1 ))
      (( prev[j] + cost < min )) && min=$(( prev[j] + cost ))
      curr[j+1]=$min
    done
    prev=("${curr[@]}")
  done

  echo "${prev[tlen+1]}"
}

# Returns 0 if query characters appear in order within name (not necessarily contiguous)
_mark_is_subsequence() {
  local query="$1" name="$2"
  local -i qi=1 ni
  for (( ni = 1; ni <= ${#name}; ni++ )); do
    [[ "${name[ni]}" == "${query[qi]}" ]] && (( qi++ ))
    (( qi > ${#query} )) && return 0
  done
  return 1
}

# Score for a candidate (lower = higher priority)
# tier_offset + levenshtein_distance
# Tiers: exact=0, substring=10000, subsequence=20000, other=30000
_mark_score() {
  local query="$1" name="$2"
  local -i dist tier=30000
  dist=$(_mark_levenshtein "$query" "$name")

  if [[ "$query" == "$name" ]]; then
    tier=0
  elif [[ "$name" == *"$query"* ]]; then
    tier=10000
  elif _mark_is_subsequence "$query" "$name"; then
    tier=20000
  fi

  echo $(( tier + dist ))
}

# Look up the path for a bookmark name. Prints the path on success, exits 1 if not found.
_mark_lookup() {
  local name="$1"
  [[ ! -f "$MARKS_FILE" ]] && return 1
  $_mark_awk -v name="$name" 'BEGIN{found=0} {
    if (substr($0, 1, length(name)+1) == name "=") {
      print substr($0, length(name)+2)
      found=1
      exit
    }
  } END{ exit !found }' "$MARKS_FILE"
}

# Returns 0 if a bookmark with the given name exists.
_mark_name_exists() {
  [[ ! -f "$MARKS_FILE" ]] && return 1
  $_mark_awk -v name="$1" 'BEGIN{found=0} {
    if (substr($0, 1, length(name)+1) == name "=") { found=1; exit }
  } END{ exit !found }' "$MARKS_FILE"
}

# Remove an entry by name from the bookmarks file in-place via a temp file.
_mark_remove_entry() {
  local name="$1"
  $_mark_awk -v name="$name" '{
    if (substr($0, 1, length(name)+1) != name "=") print
  }' "$MARKS_FILE" > "${MARKS_FILE}.tmp" && mv "${MARKS_FILE}.tmp" "$MARKS_FILE"
}

mark() {
  local cmd="$1"
  shift

  case "$cmd" in
    add)
      local name="${1:-$(basename "$PWD")}"
      mkdir -p "$MARKS_DIR"
      touch "$MARKS_FILE"
      _mark_remove_entry "$name"
      echo "${name}=${PWD}" >> "$MARKS_FILE"
      echo "Marked '$PWD' as '$name'"
      ;;
    go)
      local path
      path=$(_mark_lookup "$1") || { echo "No bookmark: $1"; return 1; }
      cd "$path"
      echo "$1" >> "$MARKS_DIR/.history"
      # Keep history file bounded to last 200 lines
      if [[ $($_mark_wc -l < "$MARKS_DIR/.history") -gt 200 ]]; then
        local tmp
        tmp=$($_mark_tail -n 200 "$MARKS_DIR/.history") && echo "$tmp" > "$MARKS_DIR/.history"
      fi
      ;;
    ls)
      [[ ! -f "$MARKS_FILE" ]] && return 0
      $_mark_awk '{
        name = $0; sub(/=.*/, "", name)
        path = substr($0, length(name)+2)
        printf "%-20s -> %s\n", name, path
      }' "$MARKS_FILE"
      ;;
    mv)
      if [[ -z "$1" || -z "$2" ]]; then
        echo "Usage: mark mv <old-name> <new-name>"
        return 1
      fi
      if ! _mark_name_exists "$1"; then
        echo "No bookmark: $1"
        return 1
      fi
      if _mark_name_exists "$2"; then
        echo "Bookmark already exists: $2"
        return 1
      fi
      local old="$1" new="$2"
      $_mark_awk -v old="$old" -v new="$new" '{
        if (substr($0, 1, length(old)+1) == old "=") {
          print new "=" substr($0, length(old)+2)
        } else {
          print
        }
      }' "$MARKS_FILE" > "${MARKS_FILE}.tmp" && mv "${MARKS_FILE}.tmp" "$MARKS_FILE"
      echo "Renamed bookmark '$old' to '$new'"
      ;;
    rm)
      if ! _mark_name_exists "$1"; then
        echo "No bookmark: $1"
        return 1
      fi
      _mark_remove_entry "$1"
      echo "Removed bookmark '$1'"
      ;;
    help|"")
      cat <<EOF
Usage: mark <command> [args]

Commands:
  add [name]        Save current directory as a bookmark (default: current dir name)
  go <name>         Jump to a bookmarked directory
  ls                List all bookmarks
  mv <old> <new>    Rename a bookmark
  rm <name>         Remove a bookmark
  help              Show this help message
EOF
      ;;
    *)
      echo "Unknown command: $cmd"
      echo "Run 'mark help' for usage."
      return 1
      ;;
  esac
}

# Tab completion
_mark_complete() {
  local -a subcommands
  subcommands=(add go ls mv rm help)

  if (( CURRENT == 2 )); then
    _describe 'command' subcommands
    return
  fi

  local subcmd="${words[2]}"
  local query pos=0
  [[ "$subcmd" == (go|rm) && $CURRENT == 3 ]] && pos=3
  [[ "$subcmd" == "mv"    && $CURRENT == 3 ]] && pos=3
  [[ "$subcmd" == "mv"    && $CURRENT == 4 ]] && pos=4

  (( pos == 0 )) && return

  query="${words[$pos]}"

  # Load all bookmarks into an associative array (name -> path) and an ordered list
  local -A mark_paths
  local -a all_marks
  if [[ -f "$MARKS_FILE" ]]; then
    while IFS= read -r line; do
      local bm="${line%%=*}"
      mark_paths[$bm]="${line#*=}"
      all_marks+=("$bm")
    done < "$MARKS_FILE"
  fi

  local -a ordered

  # When no query is given for 'go', show recently used marks first
  if [[ "$subcmd" == "go" && -z "$query" && -f "$MARKS_DIR/.history" ]]; then
    local -a history_lines
    local -A seen_map
    while IFS= read -r line; do
      history_lines+=("$line")
    done < "$MARKS_DIR/.history"
    # Iterate in reverse (most recent first), deduplicate, skip deleted marks
    for (( i = ${#history_lines[@]}; i >= 1; i-- )); do
      local bm="${history_lines[$i]}"
      if [[ -n "${mark_paths[$bm]}" && -z "${seen_map[$bm]}" ]]; then
        ordered+=("$bm")
        seen_map[$bm]=1
      fi
    done
    # Append any bookmarks not yet in recent history
    for bm in "${all_marks[@]}"; do
      [[ -z "${seen_map[$bm]}" ]] && ordered+=("$bm")
    done
  else
    # Score every bookmark and sort ascending
    local -a pairs
    for bm in "${all_marks[@]}"; do
      pairs+=("$(_mark_score "$query" "$bm"):$bm")
    done

    local -a sorted
    sorted=($(printf '%s\n' "${pairs[@]}" | $_mark_sort -t: -k1 -n))

    for pair in "${sorted[@]}"; do ordered+=("${pair#*:}"); done
  fi

  # Calculate max name width for alignment
  local -i max_len=0
  for bm in "${ordered[@]}"; do
    (( ${#bm} > max_len )) && max_len=${#bm}
  done

  local -a names descs
  for bm in "${ordered[@]}"; do
    names+=("$bm")
    descs+=("$(printf "%-${max_len}s --> %s" "$bm" "${mark_paths[$bm]}")")
  done

  # -U: disable prefix filtering
  # -V: unsorted group, preserves our priority ordering
  compstate[insert]='menu'
  compadd -U -V mark-bookmarks -l -d descs -a names
}

compdef _mark_complete mark

# In menu-selection mode, pressing Enter accepts the candidate and immediately
# executes the command (instead of requiring a second Enter to run).
zmodload zsh/complist
bindkey -M menuselect '^M' accept-and-send

# Trigger completion on down arrow when typing a mark command.
# This is useful in terminals (e.g. Warp) that intercept Tab before zsh can
# handle it: the down-arrow key press goes through zsh's line editor, so
# calling expand-or-complete internally bypasses the terminal's Tab intercept.
_mark_down_or_complete() {
  if [[ "$BUFFER" =~ '^mark (go|rm|mv) ' ]]; then
    zle expand-or-complete
  else
    zle down-line-or-history
  fi
}
zle -N _mark_down_or_complete
bindkey '^[[B' _mark_down_or_complete  # down arrow (standard)
bindkey '\eOB' _mark_down_or_complete  # down arrow (application mode)
