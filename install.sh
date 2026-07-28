#!/usr/bin/env bash
# ─────────────────────────────────────────────────────────────────────────────
# NixOS + Niri rice — installer / bootstrap.
#
# Makes a fresh clone usable under ANY username by wiring up the one thing that
# can't parametrise itself:
#   1. flake.nix  -> the `username` (defaults to your $USER)
#
# Everything else derives from that at build time. The repo MUST live at
# ~/nix-config (the config path-assumption; also true on the Arch variant).
# Usage:  git clone <repo> ~/nix-config && ~/nix-config/install.sh
# ─────────────────────────────────────────────────────────────────────────────
set -euo pipefail

REPO_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
EXPECTED="$HOME/nix-config"

if [ "$REPO_DIR" != "$EXPECTED" ]; then
  echo "This config assumes it lives at ~/nix-config, but it's at:"
  echo "  $REPO_DIR"
  echo "Move/clone it there first:  git clone <repo> ~/nix-config"
  exit 1
fi

# ── 1. Username ──────────────────────────────────────────────────────────────
default_user="${SUDO_USER:-$USER}"
read -rp "Username for this install [${default_user}]: " USERNAME
USERNAME="${USERNAME:-$default_user}"
# Replace the single source-of-truth line in flake.nix.
sed -i -E "s/^([[:space:]]*)username = \".*\";/\1username = \"${USERNAME}\";/" "$REPO_DIR/flake.nix"
echo "→ flake.nix username set to '${USERNAME}'"

# ── 2. Password hash (kept OUTSIDE the repo/store) ───────────────────────────
# configuration.nix reads the hash from this file. It must exist BEFORE the
# first rebuild, or the account boots with no valid password. The file lives in
# /etc (root-only, 0600) and is NEVER committed — only its path is.
SECRET="/etc/nixos-secrets/password"
if ! sudo test -f "$SECRET"; then
  echo "Set your login/sudo password (hashed into ${SECRET}, not into git):"
  HASH="$(nix-shell -p mkpasswd --run 'mkpasswd -m sha-512')"
  sudo mkdir -p "$(dirname "$SECRET")"
  echo "$HASH" | sudo tee "$SECRET" >/dev/null
  sudo chmod 600 "$SECRET"
  echo "→ wrote ${SECRET}"
fi

# ── 3. Reminders the installer can't do for you ──────────────────────────────
cat <<EOF

Almost done. Before / after the first build, remember:
  • Rotate the password later:  mkpasswd -m sha-512 | sudo tee ${SECRET}  (then rebuild)
  • Drop your own wallpaper at ~/nix-config/wallpapers/lain.jpg (or edit the path)
  • hardware-configuration.nix is machine-specific — keep YOUR generated one
  • Review host bits in hosts/nixos/configuration.nix: hostName, timeZone

EOF

# ── 4. Build ─────────────────────────────────────────────────────────────────
read -rp "Run 'sudo nixos-rebuild switch --flake ~/nix-config#nixos' now? [y/N] " GO
if [[ "$GO" =~ ^[Yy]$ ]]; then
  sudo nixos-rebuild switch --flake "$EXPECTED#nixos"
else
  echo "Skipped. Build later with:"
  echo "  sudo nixos-rebuild switch --flake ~/nix-config#nixos"
fi
