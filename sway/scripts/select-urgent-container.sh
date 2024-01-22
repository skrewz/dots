#!/usr/bin/env bash


any_urgent_id=$(swaymsg -t get_tree| jq -r '[recurse(.nodes[]?) | recurse(.floating_nodes[]?) | select(.type=="con"), select(.type=="floating_con") | select(.urgent==true) | {id, app_id, name}] | .[0] | (.id|tostring)')

swaymsg "[con_id=$any_urgent_id]" focus
