#!/usr/bin/env bash

tmpfile="$(mktemp -u /tmp/screenshot_XXXXXX.png)"
slurpcoords="$(slurp)"
notify-send -t 5000 "Slurp coordinates" "We have slurpcoords: $slurpcoords"

grim -g "$slurpcoords" "$tmpfile" || exit 1

screenshot_name="$(zenity --title "Screenshot file" --entry --text "screenshot name" | sed 's/[^a-zA-Z0-9-]/_/g')"

if [ -z "$screenshot_name" ]; then
  notify-send -u critical "Not captured" "Aborting on empty file name"
  exit 1
fi

mv "$tmpfile" "$HOME/screendumps/$(date +%F)_$screenshot_name.png"

wl-copy < "$HOME/screendumps/$(date +%F)_$screenshot_name.png"

notify-send -t 20000 -i "$HOME/screendumps/$(date +%F)_$screenshot_name.png" "Captured" "\~/screendumps/$(date +%F)_$screenshot_name.png now exists (and was copied to pastebuffer)"
