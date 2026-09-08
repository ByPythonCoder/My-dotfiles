#!/bin/bash

cd ~/.config/quickshell || exit

if pgrep quickshell >/dev/null; then
  pkill quickshell
fi

# toggle via simple state file
STATE_FILE=".layout"

STATE=$(cat "$STATE_FILE" 2>/dev/null)

if [ "$STATE" = "bar" ]; then
  NEXT="pills"
else
  NEXT="bar"
fi

echo "$NEXT" >"$STATE_FILE"

# IMPORTANT: overwrite ONLY entry file behavior via symlink (controlled now)
if [ "$NEXT" = "bar" ]; then
  ln -sf shell-bar.qml shell.qml
else
  ln -sf shell-pills.qml shell.qml
fi

quickshell -c ~/.config/quickshell &
