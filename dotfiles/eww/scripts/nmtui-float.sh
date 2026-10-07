#!/usr/bin/env bash
# nmtui in a centred floating terminal: the escape hatch for what the Wi-Fi popup
# can't do itself: hidden networks, enterprise logins (username + certificate),
# static IPs. Usage: nmtui-float.sh [connect|edit]   (no arg → nmtui's main menu)
# Hyprland exec rules ([float; size; center]) so no windowrule is needed.
"$(dirname "$0")/pop.sh" close
case "${1:-}" in connect|edit) sub="$1" ;; *) sub="" ;; esac
hyprctl dispatch exec "[float; size 760 560; center] kitty --class nmtui-float -e nmtui $sub" >/dev/null 2>&1
