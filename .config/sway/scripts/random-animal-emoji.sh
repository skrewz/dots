#!/usr/bin/env bash
# Type a randomly-chosen animal emoji into the focused window via wtype.
# Bound in Sway to $mod+Shift+period, sibling of the bemoji picker on $mod+period.
# wtype usage ("xdotool type for wayland"): https://github.com/atx/wtype

if ! command -v wtype >/dev/null 2>&1; then
  notify-send -u critical "random-animal-emoji" "wtype is not installed — try: sudo apt install wtype"
  exit 1
fi

# Single-codepoint, emoji-presentation-default animals only, so each one types
# and renders as an emoji without depending on variation selectors or ZWJ joins.
animals=(
  🐶 🐱 🐭 🐹 🐰 🦊 🐻 🐼 🐨 🐯 🦁 🐮 🐷 🐸 🐵
  🐔 🐧 🐦 🐤 🦆 🦅 🦉 🦇 🐺 🐗 🐴 🦄 🐝 🐛 🦋
  🐌 🐞 🐜 🦗 🦂 🐢 🐍 🦎 🦖 🦕 🐙 🦑 🦐 🦀 🐡
  🐠 🐟 🐬 🐳 🐋 🦈 🐊 🐅 🐆 🦓 🦍 🐘 🦏 🐪 🐫
  🦒 🐃 🐄 🐎 🐖 🐏 🐑 🐐 🦌 🐕 🐩 🐈 🐓 🦃 🐇
  🐀 🐁 🐒 🦔
)

emoji="${animals[RANDOM % ${#animals[@]}]}"

wtype "$emoji"
