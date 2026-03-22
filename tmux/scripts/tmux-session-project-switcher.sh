#!/bin/sh

set -eu

if [ -z "${TMUX:-}" ]; then
  echo "tmux session/project switcher must run inside tmux." >&2
  exit 1
fi

list_sessions() {
  tmux list-sessions -F '#{session_name}\t#{session_path}\t#{?session_attached,attached,detached}' 2>/dev/null |
    while IFS="$(printf '\t')" read -r name path state; do
      [ -n "$name" ] || continue
      printf 'session\t%s\t%s\t%s\n' "$name" "$path" "$state"
    done
}

list_projects() {
  zoxide query -ls 2>/dev/null |
    sed -E 's/^[[:space:]]*[0-9.]+[[:space:]]+//' |
    awk '!seen[$0]++' |
    while IFS= read -r dir; do
      [ -d "$dir" ] || continue
      case "$dir" in
        */.git|*/.git/*|*/.worktrees|*/.worktrees/*|*/node_modules|*/node_modules/*|*/dist|*/dist/*|*/build|*/build/*|/Users/eugene/Downloads|/Users/eugene/Documents|/Users/eugene/.ssh|/opt/homebrew/*)
          continue
          ;;
      esac

      base=$(basename "$dir")
      [ -n "$base" ] || base="$dir"
      printf 'project\t%s\t%s\t-\n' "$base" "$dir"
    done
}

session_for_path() {
  target_path=$1
  tmux list-sessions -F '#{session_name}\t#{session_path}' 2>/dev/null |
    awk -F '\t' -v path="$target_path" '$2 == path { print $1; exit }'
}

sanitized_name_for_path() {
  target_path=$1
  base=$(basename "$target_path" | tr '[:upper:]' '[:lower:]' | tr -cs '[:alnum:]' '-')
  base=$(printf '%s' "$base" | sed 's/^-*//; s/-*$//')
  [ -n "$base" ] || base="project"
  printf '%s' "$base"
}

ensure_session_for_project() {
  target_path=$1

  existing_session=$(session_for_path "$target_path")
  if [ -n "$existing_session" ]; then
    printf '%s' "$existing_session"
    return
  fi

  session_name=$(sanitized_name_for_path "$target_path")
  current_path=$(tmux list-sessions -F '#{session_name}\t#{session_path}' 2>/dev/null |
    awk -F '\t' -v name="$session_name" '$1 == name { print $2; exit }')

  if [ -n "$current_path" ] && [ "$current_path" != "$target_path" ]; then
    suffix=$(printf '%s' "$target_path" | cksum | awk '{print $1}' | cut -c 1-6)
    session_name="${session_name}-${suffix}"
  fi

  if ! tmux has-session -t "=${session_name}" 2>/dev/null; then
    tmux new-session -ds "$session_name" -c "$target_path"
  fi

  printf '%s' "$session_name"
}

selection=$(
  {
    list_sessions
    list_projects
  } | fzf \
    --layout=reverse \
    --height=100% \
    --border=rounded \
    --delimiter="$(printf '\t')" \
    --with-nth=1,2,3,4 \
    --prompt='tmux> ' \
    --header='Enter: switch/create session | Esc: close'
)

[ -n "$selection" ] || exit 0

kind=$(printf '%s\n' "$selection" | cut -f 1)
name=$(printf '%s\n' "$selection" | cut -f 2)
path=$(printf '%s\n' "$selection" | cut -f 3)

case "$kind" in
  session)
    tmux switch-client -t "$name"
    ;;
  project)
    session_name=$(ensure_session_for_project "$path")
    tmux switch-client -t "$session_name"
    ;;
esac
