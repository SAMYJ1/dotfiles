#!/bin/sh

set -eu

show_cheatsheet() {
  cat <<'EOF'
tmux workflow
=============

Core
- Prefix: Ctrl-b
- Reload config: Prefix r
- Next/previous window: Prefix n / Prefix p
- Split horizontally/vertically: Prefix | / Prefix -
- Kill pane: Prefix x
- Clear pane + history: Prefix K

Navigation
- Move panes: Prefix h j k l
- Resize panes: Prefix < > + _

Popup workflows
- Project/session switcher: Prefix f
- Lazygit popup: Prefix g
- Cheatsheet popup: Prefix ?
- Command menu: Prefix m

Copy mode
- Enter copy mode: Prefix [
- Begin selection: v
- Clear selection: Escape
- Mouse drag copy: enabled

3.6a extras
- Pane scrollbars: enabled
- Tiled layout max columns: 2
- Copy mode position/selection style: customized

Project switcher
- Existing session: switch directly
- Project path: create detached session if needed, then switch
- Project source: zoxide query database filtered for useful paths
EOF
}

if [ "${NO_PAGER:-0}" = "1" ]; then
  show_cheatsheet
  exit 0
fi

if [ -t 1 ] && command -v less >/dev/null 2>&1; then
  show_cheatsheet | less -R
else
  show_cheatsheet
fi
