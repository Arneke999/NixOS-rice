#!/usr/bin/env bash
# Nearby Wi-Fi networks as JSON for the popup picker: [{ssid,signal,secure,active}].
# Deduped by SSID (strongest kept), active network first then by signal desc. Empty
# [] when the radio is off. Reads NetworkManager's cached scan (fast) — the popup's
# rescan button (wifi-rescan.sh) is what forces a fresh scan.
[ "$(nmcli -t radio wifi 2>/dev/null)" = enabled ] || { echo '[]'; exit 0; }

nmcli -t -f IN-USE,SIGNAL,SECURITY,SSID dev wifi list 2>/dev/null \
| awk -F: '
    { inuse=($1=="*")?1:0; sig=$2+0; sec=$3
      ssid=$4; for (i=5;i<=NF;i++) ssid=ssid":"$i         # SSID is last field → rejoin colons
      gsub(/\\:/,":",ssid); gsub(/\\\\/,"\\",ssid)         # unescape nmcli terse escaping
      if (ssid=="") next                                   # skip hidden SSIDs
      # Dedup by SSID keeping the strongest signal, but OR the active marker across
      # all its rows — the connected AP is often NOT the strongest-signal duplicate,
      # so keying "active" off a single kept row dropped it (list never highlighted
      # the current network). Track it per-SSID instead.
      if (!(ssid in sigmax) || sig>sigmax[ssid]) { sigmax[ssid]=sig; secof[ssid]=sec }
      if (inuse) act[ssid]=1 }
    END { for (s in sigmax) printf "%d\t%d\t%s\t%s\n", (act[s]?1:0), sigmax[s], secof[s], s }' \
| sort -t$'\t' -k1,1nr -k2,2nr \
| jq -R -s 'split("\n") | map(select(length>0) | split("\t"))
            | map({ active:(.[0]=="1"), signal:(.[1]|tonumber), secure:(.[2]!=""), ssid:.[3] })'
