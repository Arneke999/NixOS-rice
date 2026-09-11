#!/usr/bin/env bash
# Count registered StatusNotifierItems (system-tray icons). eww polls this so the
# tray *pill* can be hidden when the tray is empty — an empty pill would show as a
# near-black blob left of CPU/RAM. Prints a bare integer (0 when empty/unavailable).
out="$(busctl --user get-property org.kde.StatusNotifierWatcher /StatusNotifierWatcher \
        org.kde.StatusNotifierWatcher RegisteredStatusNotifierItems 2>/dev/null)"
# Property prints e.g. `as 0` (empty) or `as 2 "…" "…"` — field 2 is the count.
awk '{print $2+0}' <<<"$out"
