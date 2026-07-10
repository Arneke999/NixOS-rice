#!/usr/bin/env bash
# Stream the focused output's workspaces as a JSON array for eww (deflisten).
emit() {
  niri msg --json workspaces | jq -c '
    (map(select(.is_focused)) | .[0].output) as $o
    | [ .[] | select(.output == $o) ] | sort_by(.idx)
  '
}
emit
niri msg --json event-stream | while read -r _; do emit; done
