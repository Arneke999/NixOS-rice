#!/usr/bin/env bash
# Launch a terminal app from an eww popup. Closes the popup + backdrop first, then
# starts the terminal FULLY DETACHED (setsid -f) so it survives the popup closing.
# Without setsid the process is a child of the eww daemon's click handler and gets
# SIGHUP'd the instant the popup goes away — which is why the window flashed open
# and closed. Usage: term.sh <cmd> [args…]   e.g. term.sh nmtui
d="$(dirname "$0")"
"$d/pop.sh" close
setsid -f kitty -e "$@" >/dev/null 2>&1
