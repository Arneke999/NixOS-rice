#!/usr/bin/env bash
# Connect to a Wi-Fi network chosen in the popup. Args: SSID KIND
#   KIND (from wifi-list.sh) = psk | open | eap   (legacy true/false = psk/open)
#
#   already on it   → nothing to do.
#   saved profile   → bring it up. If a password network rejects the saved password,
#                     ask again and UPDATE that profile. Saved profiles are never
#                     deleted: the old "forget + re-prompt" also wiped campusroam's
#                     sops-managed profile when it was merely out of range.
#   new, password   → themed fuzzel prompt. A wrong password re-asks right there
#                     ("wrong password, try again", 3 tries). It used to fail once with
#                     nmcli's "Secrets were required, but not provided", delete the
#                     profile and make you start over, which is why nmtui was the fallback.
#   new, open       → connect.
#   new, enterprise → a username + certificate settings don't fit one password box,
#                     so this opens nmtui (floating) instead.
#   After a successful connect: captive-portal check (café / train / hotel Wi-Fi). If
#   the network intercepts web traffic, its sign-in page opens in the browser.
#
# ── WHY THIS DETACHES ───────────────────────────────────────────────────────
# eww runs this as the onclick CHILD of the network button. Closing the popup (for
# the password prompt) and rebuilding the list both destroy the widget that owns the
# child, and eww then kills its process group: fuzzel was orphaned and the connect
# after it never ran. So re-exec ourselves in a new session (setsid) first.
set -uo pipefail

ssid="${1:-}"; kind="${2:-psk}"
case "$kind" in true) kind=psk ;; false) kind=open ;; esac
[ -z "$ssid" ] && exit 0

if [ "${WIFI_CONNECT_DETACHED:-}" != 1 ]; then
  setsid -f env WIFI_CONNECT_DETACHED=1 "$0" "$ssid" "$kind" >/dev/null 2>&1 || true
  exit 0
fi

d="$(dirname "$0")"
CFG="$HOME/nix-config/dotfiles/fuzzel/picker.ini"
created=""   # uuid of a profile THIS run created: removed again if we give up

note()     { command -v notify-send >/dev/null 2>&1 && notify-send -a "Wi-Fi" "$@"; }
refresh()  { eww update wifi="$("$d/wifi.sh")" net="$("$d/net.sh")" wifi_nets="$("$d/wifi-list.sh")" >/dev/null 2>&1 || true; }
clean()    { sed -e 's/^Error: //' -e '/^Hint: /d' -e 's/[[:space:]]*$//' -e 's/\.$//' <<<"$1"; }  # tidy nmcli text for a toast
wrong_pw() { grep -qi 'secrets were required' <<<"$1"; }   # how NM reports a rejected key
give_up()  { [ -n "$created" ] && nmcli connection delete uuid "$created" >/dev/null 2>&1; refresh; exit 0; }

# UUIDs of the saved Wi-Fi profiles for this SSID. Matched on the SSID, not the
# profile name (a profile renamed in nmtui keeps its SSID). -g escapes ':' and '\'.
saved_uuids() {
  local u t s
  while IFS=: read -r u t; do
    [ "$t" = 802-11-wireless ] || continue
    s="$(nmcli -g 802-11-wireless.ssid connection show uuid "$u" 2>/dev/null | sed -e 's/\\:/:/g' -e 's/\\\\/\\/g')"
    [ "$s" = "$ssid" ] && echo "$u"
  done < <(nmcli -t -f UUID,TYPE connection show 2>/dev/null)
}

# Password box: themed fuzzel with no list (--prompt-only), input masked.
# $1 = hint shown as the placeholder. Prints the text; non-zero exit on Esc.
ask_pw() {
  "$d/pop.sh" close
  local prompt="󰌾 $ssid  " w
  w=$(( ${#prompt} + ${#1} + 3 )); [ "$w" -lt 36 ] && w=36   # fit SSID + hint (no cut-off)
  local args=(--dmenu --prompt-only "$prompt" --password --placeholder "$1")
  [ -f "$CFG" ] && args+=(--config "$CFG")
  args+=(--width "$w")
  fuzzel "${args[@]}" </dev/null
}

# Ask → connect → on a rejected key, ask again (3 tries).
# $1 = uuid of the profile to update ("" = brand-new network), $2 = first hint.
psk_flow() {
  local uuid="$1" hint="$2" pw err tries=0
  while :; do
    pw="$(ask_pw "$hint")" || give_up                  # Esc = cancel
    # WPA passwords are 8–63 characters (64 = raw hex key). Anything else can never
    # work, so re-ask without using up a try (an empty Enter lands here too).
    if [ "${#pw}" -lt 8 ] || [ "${#pw}" -gt 64 ]; then hint="must be 8–63 characters"; continue; fi
    tries=$((tries + 1))
    if [ -n "$uuid" ]; then
      nmcli connection modify uuid "$uuid" wifi-sec.psk "$pw" >/dev/null 2>&1
      err="$(nmcli --wait 30 connection up uuid "$uuid" 2>&1 >/dev/null)" && return 0
    else
      err="$(nmcli --wait 30 device wifi connect "$ssid" password "$pw" 2>&1 >/dev/null)" && return 0
      # The failed attempt can leave its new profile behind: adopt it, so a retry
      # updates it instead of piling up "SSID 1", "SSID 2"… (give_up removes it).
      uuid="$(saved_uuids | head -1)"; created="$uuid"
    fi
    wrong_pw "$err" || { note "Couldn't connect to $ssid" "$(clean "$err")"; give_up; }
    [ "$tries" -ge 3 ] && { note "Couldn't connect to $ssid" "Wrong password (3 tries)"; give_up; }
    hint="wrong password, try again"
  done
}

# Captive portal? This URL returns a fixed line of text; a portal answers with its
# own page or a redirect instead. No answer at all means offline (or DHCP still
# settling), not a portal, so stay quiet then.
portal_check() {
  local url="${WIFI_PORTAL_URL:-http://nmcheck.gnome.org/check_network_status.txt}" resp="" i
  for i in 1 2 3; do
    resp="$(curl -s -m 5 -w '\n%{http_code}' "$url" 2>/dev/null)" && break
    resp=""; sleep 2
  done
  [ -z "$resp" ] && return 0
  [ "${resp##*$'\n'}" = 200 ] && [[ "$resp" == "NetworkManager is online"* ]] && return 0
  note "󰖩  Sign-in required" "$ssid has a login page, opening it in your browser"
  setsid -f xdg-open "http://neverssl.com" >/dev/null 2>&1
}

mapfile -t saved < <(saved_uuids)

# Already on it → nothing to do (re-activating would just drop the link).
for u in "${saved[@]}"; do
  [ "$(nmcli -g GENERAL.STATE connection show uuid "$u" 2>/dev/null)" = activated ] && { refresh; exit 0; }
done

if [ "${#saved[@]}" -gt 0 ]; then
  # Try each profile for the SSID (there can be several). Only a password (PSK/SAE)
  # profile whose key was rejected gets re-asked; anything else reports why.
  err=""; km=""
  for u in "${saved[@]}"; do
    err="$(nmcli --wait 30 connection up uuid "$u" 2>&1 >/dev/null)" && { refresh; portal_check; exit 0; }
    km="$(nmcli -g 802-11-wireless-security.key-mgmt connection show uuid "$u" 2>/dev/null)"
    if wrong_pw "$err" && { [ "$km" = wpa-psk ] || [ "$km" = sae ]; }; then
      psk_flow "$u" "saved password was rejected"; refresh; portal_check; exit 0
    fi
  done
  if wrong_pw "$err" && [ "$km" = wpa-eap ]; then
    note "Couldn't sign in to $ssid" "The network rejected the saved username/password"
  else
    note "Couldn't connect to $ssid" "$(clean "$err")"
  fi
  refresh; exit 0
fi

case "$kind" in
  open)
    if err="$(nmcli --wait 30 device wifi connect "$ssid" 2>&1 >/dev/null)"; then
      refresh; portal_check
    else
      note "Couldn't connect to $ssid" "$(clean "$err")"
    fi ;;
  eap)
    note "$ssid needs a username" \
         "Enterprise login: in nmtui pick Add → Wi-Fi, SSID $ssid, security \"WPA & WPA2 Enterprise\""
    "$d/nmtui-float.sh" edit ;;
  *)
    psk_flow "" "password"; refresh; portal_check ;;
esac
refresh
