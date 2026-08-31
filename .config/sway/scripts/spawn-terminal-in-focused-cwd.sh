#!/usr/bin/env bash

set -uo pipefail

note() { notify-send "spawn-term-cwd" "$1" 2>/dev/null || true; }

KITTY_PW="$(sed -nre 's/^remote_control_password "([^"]+)"\s*$/\1/;T;p' "$HOME/.config/kitty/kitty.credentials.conf")"

if [ -z "${KITTY_PUBLIC_KEY:-}" ]; then
  kmaster="$(pgrep -x kitty | head -1)"
  for pid in $(pgrep -P "${kmaster:-0}" 2>/dev/null); do
    v="$(tr '\0' '\n' < "/proc/$pid/environ" 2>/dev/null | sed -n 's/^KITTY_PUBLIC_KEY=//p')"
    [ -n "$v" ] && export KITTY_PUBLIC_KEY="$v" && break
  done
fi

# On failure (e.g. no running instance to inherit from) fall back to a plain new
# window so the keybind always yields a terminal — but say so, don't fail silently.
if ! err="$(kitten @ --to unix:@mykitty --password "$KITTY_PW" launch --type=os-window --cwd=current 2>&1 >/dev/null)"; then
  note "RC launch failed, opening plain kitty. ${err}"
  exec kitty --single-instance --listen-on unix:@mykitty
fi
