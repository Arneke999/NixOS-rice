#!/usr/bin/env bash
# Nearby Wi-Fi networks as JSON for the popup picker: [{ssid,signal,secure,active}].
# Deduped by SSID (strongest kept), active network first then by signal desc. Empty
# [] when the radio is off. Reads NetworkManager's cached scan (fast) — the popup's
# rescan button (wifi-rescan.sh) is what forces a fresh scan.
[ "$(nmcli -t radio wifi 2>/dev/null)" = enabled ] || { echo '[]'; exit 0; }

nmcli -t -f IN-USE,SIGNAL,SECURITY,SSID dev wifi list 2>/dev/null \
| awk -F: '
    { ssid=$4; for (i=5;i<=NF;i++) ssid=ssid":"$i        # SSID is last field → rejoin colons
      gsub(/\\:/,":",ssid); gsub(/\\\\/,"\\",ssid)        # unescape nmcli terse escaping
      if (ssid=="") next                                  # skip hidden SSIDs
      printf "%s\t%s\t%s\t%s\n", $1, $2+0, $3, ssid }' \
| sort -t$'\t' -k4,4 -k2,2nr \
| awk -F'\t' '!seen[$4]++' \
| sort -t$'\t' -k1,1r -k2,2nr \
| jq -R -s 'split("\n") | map(select(length>0) | split("\t"))
            | map({ active:(.[0]=="*"), signal:(.[1]|tonumber), secure:(.[2]!=""), ssid:.[3] })'
