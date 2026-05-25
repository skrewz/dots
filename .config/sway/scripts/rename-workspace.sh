#!/usr/bin/env bash

workspace_names_file="${XDG_CACHE_HOME:-$HOME/.cache}/create-workspace.sh-names.txt"
touch "$workspace_names_file"

workspace_names="$(sort -u < "$workspace_names_file")"
workspace_name="$(echo "$workspace_names" | wofi --prompt "Rename workspace to:" --matching fuzzy --gtk-dark --insensitive --show dmenu)"

(echo "$workspace_names"$'\n'"$workspace_name" ) | sort -u > "$workspace_names_file"

swaymsg rename workspace to "$workspace_name"
