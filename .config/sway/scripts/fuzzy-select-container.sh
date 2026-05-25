#!/usr/bin/env bash

# Somewhat inspired by https://github.com/ldelossa/sway-fzfify

function render_containers ()
{
  swaymsg -t get_tree| jq -r 'recurse(.nodes[]?) | recurse(.floating_nodes[]?) | select(.type=="con"), select(.type=="floating_con") | select((.app_id != null) or .name != null) | {id, app_id, name} | .name+" "+.app_id+" ("+(.id|tostring)+")"'
}

selected="$(render_containers | wofi --prompt "Container selection:" --matching fuzzy --gtk-dark --insensitive --show dmenu)"

selected_id="$(sed -r 's|^.*[(]([0-9]+)[)]$|\1|' <<< "$selected")"
swaymsg "[con_id=$selected_id]" focus
