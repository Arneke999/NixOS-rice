#!/usr/bin/env bash
# RAM usage as a filling pie glyph for a waybar custom module (return-type json).
icons=(󰪞 󰪟 󰪠 󰪡 󰪢 󰪣 󰪤 󰪥)
used=$(awk '/MemTotal/{t=$2} /MemAvailable/{a=$2} END{printf "%d", (t-a)*100/t}' /proc/meminfo)
idx=$(( used * (${#icons[@]} - 1) / 100 ))
printf '{"text":"%s","tooltip":"RAM %d%%"}\n' "${icons[$idx]}" "$used"
