#!/usr/bin/env bash
# Current weather + 3-day forecast via wttr.in (IP-geolocated, no API key needed).
# Emits ONE JSON object for eww: current icon/temp/desc/city/metrics + a forecast
# array. Icons are Nerd Font MDI weather glyphs; the `class` field drives the colour
# + pulse animation in eww.scss. Caches the last good response so a dropped network
# shows stale data instead of blanking the bar.
set -uo pipefail
cache="${XDG_CACHE_HOME:-$HOME/.cache}/weather.json"
url='https://wttr.in/?format=j1'

# code -> glyph (ic) + class (cl). Day/night variant only for clear & partly.
icon_for() {
  local d="$2"
  case "$1" in
    113) [ "$d" = 1 ] && ic="󰖙" || ic="󰖔"; cl="clear" ;;
    116) [ "$d" = 1 ] && ic="󰖕" || ic="󰖔"; cl="partly" ;;
    119|122)                                   ic="󰖐"; cl="cloudy" ;;
    143|248|260)                               ic="󰖑"; cl="fog" ;;
    176|263|266|293|296|299|302|353|356)       ic="󰖗"; cl="rain" ;;
    305|308|359)                               ic="󰖖"; cl="rain" ;;
    182|185|281|284|311|314|317|320|350|362|365|374|377) ic="󰖒"; cl="sleet" ;;
    179|227|230|323|326|329|332|335|338|368|371)         ic="󰖘"; cl="snow" ;;
    200|386|389|392|395)                       ic="󰖓"; cl="thunder" ;;
    *)                                         ic="󰖐"; cl="cloudy" ;;
  esac
}

fail() { echo '{"ok":false,"icon":"󰅤","temp":0,"desc":"offline","city":"","class":"cloudy","feels":0,"humidity":0,"wind":0,"forecast":[]}'; }

# Fetch fresh (validate it's JSON); else fall back to cache; else emit an offline stub.
if raw="$(curl -s --max-time 12 "$url")" && [ -n "$raw" ] && jq -e . >/dev/null 2>&1 <<<"$raw"; then
  printf '%s' "$raw" > "$cache" 2>/dev/null || true
elif [ -f "$cache" ]; then
  raw="$(cat "$cache")"
else
  fail; exit 0
fi

hour=$(date +%-H); daynow=1; { [ "$hour" -ge 20 ] || [ "$hour" -lt 6 ]; } && daynow=0

cc_code="$(jq -r '.current_condition[0].weatherCode' <<<"$raw")"
icon_for "$cc_code" "$daynow"; cur_ic="$ic"; cur_cl="$cl"

# Build the forecast array (day glyphs; midday condition per day).
fc='[]'
ndays="$(jq '.weather | length' <<<"$raw")"
for i in $(seq 0 $((ndays-1))); do
  IFS=$'\t' read -r fdate hi lo fcode < <(jq -r --argjson i "$i" \
    '.weather[$i] | [.date, .maxtempC, .mintempC, ((.hourly[]|select(.time=="1200")).weatherCode)] | @tsv' <<<"$raw")
  icon_for "$fcode" 1
  dname="$(date -d "$fdate" +%a 2>/dev/null || echo "$fdate")"
  fc="$(jq --arg d "$dname" --argjson hi "$hi" --argjson lo "$lo" --arg ic "$ic" --arg cl "$cl" \
        '. + [{day:$d, hi:$hi, lo:$lo, icon:$ic, class:$cl}]' <<<"$fc")"
done

jq -c -n --arg icon "$cur_ic" --arg class "$cur_cl" --argjson fc "$fc" \
  --argjson cc "$(jq '.current_condition[0]' <<<"$raw")" \
  --argjson area "$(jq '.nearest_area[0]' <<<"$raw")" \
  '{ ok:true, icon:$icon, class:$class,
     temp:   ($cc.temp_C|tonumber),
     desc:   $cc.weatherDesc[0].value,
     feels:  ($cc.FeelsLikeC|tonumber),
     humidity:($cc.humidity|tonumber),
     wind:   ($cc.windspeedKmph|tonumber),
     city:   ($area.areaName[0].value),
     forecast: $fc }'
