#!/usr/bin/env bash
# List audio OUTPUT devices (sinks) as JSON for the eww volume popup's device picker:
#   [{ "id":54, "name":"DualShock 4 … Analog Stereo", "active":true }]
# `active` = the current default sink (wpctl marks it with `*`). Parses the first
# "Sinks:" block of `wpctl status` (the Audio section; a later empty Video block is
# ignored via the `seen` guard).
wpctl status 2>/dev/null | awk '
  /[├└]─ Sinks:/   { if (seen) inb=0; else { inb=1; seen=1 } ; next }
  /[├└]─ Sources:/ { inb=0 }
  inb {
    active = ($0 ~ /\*/) ? "1" : "0"
    if (match($0, /[0-9]+\. /)) {
      id   = substr($0, RSTART, RLENGTH-2)
      name = substr($0, RSTART + RLENGTH)
      sub(/ *\[vol:.*$/, "", name)      # drop the trailing " [vol: 0.50]"
      # Shorten for the picker so long names stay distinguishable when truncated:
      gsub(/\[[^]]*\] */, "", name)     # drop model-code tags, e.g. "[CUH-ZCT2x] "
      sub(/^.* HD Audio /, "", name)    # drop verbose Intel-HDA card prefix → "Speaker" / "HDMI…"
      gsub(/  +/, " ", name)            # squeeze doubled spaces
      gsub(/^ +| +$/, "", name)
      if (name != "") printf "%s\t%s\t%s\n", active, id, name
    }
  }' \
| jq -R -s 'split("\n") | map(select(length>0) | split("\t"))
            | map({ active:(.[0]=="1"), id:(.[1]|tonumber), name:.[2] })'
