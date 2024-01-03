#!/usr/bin/env bash

grim -g "$(slurp)" /tmp/screenshot.png || exit 1

screenshot_name="$(zenity --title "Screenshot file" --entry --text "screenshot name" | sed 's/[^a-zA-Z0-9-]/_/g')"

if [ -z "$screenshot_name" ]; then
  notify-send -u critical "Not captured" "Aborting on empty file name"
  exit 1
fi

mv /tmp/screenshot.png "$HOME/screendumps/$(date +%F)_$screenshot_name.png"

notify-send -i "$HOME/screendumps/$(date +%F)_$screenshot_name.png" "Captured" "~/screendumps/$(date +%F)_$screenshot_name.png now exists"
