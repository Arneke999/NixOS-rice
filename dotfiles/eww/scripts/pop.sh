#!/usr/bin/env bash
# Mutually-exclusive bar popups with a click-away backdrop.
#   pop.sh <window>   toggle that popup (opens a fullscreen transparent backdrop
#                     behind it; clicking anywhere off the popup hits the backdrop
#                     and closes everything)
#   pop.sh close      close every popup + the backdrop
pops="pop-brightness pop-audio pop-wifi pop-bt calendar"

close_all() { eww close $pops pop-backdrop >/dev/null 2>&1 || true; }

case "${1:-close}" in
  close) close_all ;;
  *)
    if eww active-windows 2>/dev/null | grep -qw "$1"; then
      close_all                       # already open → toggle shut
    else
      close_all                       # close any other popup first
      eww open pop-backdrop >/dev/null 2>&1 || true
      eww open "$1"          >/dev/null 2>&1 || true   # opened last → stacks on top
    fi
    ;;
esac
