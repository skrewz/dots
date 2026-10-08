#!/usr/bin/env bash
# Colourised network bitrate for Waybar (custom module, return-type: json).
#
# Waybar's builtin `network` module cannot colour by value: it only exposes
# state-based CSS classes (disconnected/linked/ethernet/wifi), see
# https://man.archlinux.org/man/waybar-network.5.en
#
# This script samples the kernel byte counters, diffs them against the previous
# run, and returns the rate as Pango markup so each arrow is coloured on its own
# (a single CSS class could only tint the whole module).
#
# Requires `escape` to stay unset/false in the module config, otherwise Waybar
# escapes the markup instead of rendering it.

set -uo pipefail

WARN_MBPS=10   # >= 10 Mb/s -> orange
CRIT_MBPS=50   # >= 50 Mb/s -> red
C_OK='#d8d8d8'
C_WARN='#fe8019'
C_CRIT='#f53c3c'

fmt() { # bytes/s -> human-readable bits/s
  awk -v b="$(awk -v x="$1" 'BEGIN{printf "%.0f", x*8}')" 'BEGIN{
    split("b/s Kb/s Mb/s Gb/s Tb/s", u, " ")
    i = 1
    while (b >= 1000 && i < 5) { b /= 1000; i++ }
    printf (i == 1 ? "%.0f %s" : "%.1f %s"), b, u[i]
  }'
}

colour() { # bytes/s -> hex colour, thresholded in Mb/s
  awk -v b="$1" -v w="$WARN_MBPS" -v c="$CRIT_MBPS" \
      -v ok="$C_OK" -v ora="$C_WARN" -v red="$C_CRIT" 'BEGIN{
    m = (b * 8) / 1e6
    if (m >= c) print red; else if (m >= w) print ora; else print ok
  }'
}

# NETRATE_IFACE pins the interface; otherwise follow the default route.
iface="${NETRATE_IFACE:-$(ip route show default 2>/dev/null | awk '/^default/{print $5; exit}')}"
if [[ -z "$iface" || ! -r "/sys/class/net/$iface/statistics/rx_bytes" ]]; then
  printf '{"text":""}\n'   # empty text -> Waybar hides the module
  exit 0
fi

now=$(date +%s.%N)
rx=$(<"/sys/class/net/$iface/statistics/rx_bytes")
tx=$(<"/sys/class/net/$iface/statistics/tx_bytes")
state="${XDG_RUNTIME_DIR:-/tmp}/waybar-netrate.$iface"

if [[ -r "$state" ]]; then
  read -r prx ptx pnow <"$state"
  dt=$(awk -v a="$now" -v b="$pnow" 'BEGIN{d=a-b; print (d>0)?d:1}')
  # negative delta == interface (re)initialised or counter wrapped
  drx=$(awk -v a="$rx" -v b="$prx" 'BEGIN{print (a<b)?0:a-b}')
  dtx=$(awk -v a="$tx" -v b="$ptx" 'BEGIN{print (a<b)?0:a-b}')
else
  dt=1; drx=0; dtx=0   # first sample after startup
fi
printf '%s %s %s\n' "$rx" "$tx" "$now" >"$state"

rx_Bps=$(awk -v d="$drx" -v t="$dt" 'BEGIN{printf "%.0f", d/t}')
tx_Bps=$(awk -v d="$dtx" -v t="$dt" 'BEGIN{printf "%.0f", d/t}')

# Down on line 1, up on line 2: matches the vertical bar and the previous
# "↓{bandwidthDownBits}\n↑{bandwidthUpBits}" layout. Attribute values use XML
# single quotes so the JSON string needs no escaping.
printf '{"text":"\\u2193<span foreground=\x27%s\x27>%s</span>\\n\\u2191<span foreground=\x27%s\x27>%s</span>",' \
  "$(colour "$rx_Bps")" "$(fmt "$rx_Bps")" "$(colour "$tx_Bps")" "$(fmt "$tx_Bps")"
printf '"class":"netrate-%s"}\n' \
  "$(awk -v r="$rx_Bps" -v t="$tx_Bps" -v w="$WARN_MBPS" -v c="$CRIT_MBPS" 'BEGIN{
    m = (r>t ? r : t) * 8 / 1e6
    print (m>=c) ? "crit" : ((m>=w) ? "warn" : "ok")
  }')"
