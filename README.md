# lain — NixOS + Hyprland rice

A declarative NixOS desktop built around **Hyprland** and an **eww** bar, themed after
*Serial Experiments Lain*: near‑black surfaces (`#0f0f11`), **Catppuccin Mocha** text
colours and a pink accent (`#f5c2e7`). Everything, from the boot splash to the login screen,
lock screen, bar, terminal and editor, is configured in this repo.

> [!NOTE]
> This repo is **public**. No secrets live in it in plaintext; see [Secrets](#secrets).

---

## Contents

- [Stack](#stack)
- [Repo layout](#repo-layout)
- [How it works](#how-it-works)
- [Install](#install)
- [Keybinds](#keybinds)
- [The bar (eww)](#the-bar-eww)
- [Useful commands](#useful-commands)
- [Secrets](#secrets)
- [Known quirks & gotchas](#known-quirks--gotchas)

---

## Stack

| Layer | Tool |
|---|---|
| OS / packaging | NixOS (unstable), flakes, Home Manager |
| Boot | GRUB (EFI, os‑prober) → Plymouth (custom `lain` theme) |
| Login | SDDM (Qt6, Wayland greeter on **kwin**) + `sddm-astronaut` theme |
| Compositor | Hyprland (dwindle tiling) |
| Bar & popups | eww (yuck + scss + bash scripts) |
| Launcher / pickers | fuzzel |
| Notifications / OSD | swaync (notification centre + DND) · eww volume/brightness OSD |
| Lock / idle | hyprlock (CRT shader) + hypridle |
| Power menu | wlogout |
| Wallpaper | awww (with transitions) |
| Terminal | kitty (JetBrainsMono Nerd Font) |
| Shell | zsh + starship, fzf, eza, bat |
| Files | yazi |
| Editor | Neovim (lazy.nvim, LSP, Telescope, Treesitter, inline diagnostics) |
| Audio | PipeWire + WirePlumber (`wpctl`) |
| Network | NetworkManager (incl. declarative WPA2‑Enterprise for campusroam) |
| Bluetooth | BlueZ (`bluetoothctl`) |
| Power | TLP + thermald, charge limit 75–80 %, PSR1, low‑battery warnings + safe suspend at 5 % |
| Secrets | sops‑nix (age) |
| Theme | Catppuccin Mocha · Papirus‑Dark icons · Bibata cursor · adw‑gtk3 |

Flake inputs: `nixpkgs` (unstable), `home-manager`, `sops-nix`, `nix-claude-code`
(overlay for an up‑to‑date Claude Code) and `brave-previews` (Brave Origin Nightly).

---

## Repo layout

```
nix-config/
├── flake.nix                  # inputs, the nixosSystem, and `username` (single source of truth)
├── flake.lock                 # pinned versions of every input
├── install.sh                 # first-time bootstrap (username + password hash)
├── hosts/nixos/
│   ├── configuration.nix      # system: boot, SDDM, networking, BT, power, secrets, packages
│   └── hardware-configuration.nix
├── home/home.nix              # user packages + symlinks from dotfiles/ into ~/.config
├── dotfiles/                  # the actual rice — edited live, see "How it works"
│   ├── hypr/                  # hyprland.conf, hyprlock.conf/.frag, hypridle.conf, nightlight.frag
│   ├── eww/                   # eww.yuck (layout), eww.scss (style), scripts/ (data + actions)
│   ├── scripts/               # wallpaper, screenshots, float mode, connection toasts, GTK theme
│   ├── kitty/ nvim/ zsh/ starship/ bat/ yazi/ fuzzel/ swaync/ wlogout/ gtk/ fastfetch/
│   └── plymouth/lain/         # boot splash theme
├── secrets/secrets.yaml       # sops-encrypted (safe to commit)
├── .sops.yaml                 # which age keys may decrypt which files
└── wallpapers/                # everything here is in the picker / random rotation
```

---

## How it works

### One flake, two layers
`flake.nix` builds a single `nixosSystem` called **`nixos`**. Home Manager runs as a NixOS
module with `useGlobalPkgs = true`, so system and user packages share one nixpkgs (and one
`nixpkgs.config`, which matters for things like `allowUnfree` and permitted insecure packages).

`username` is defined **once** in `flake.nix` and passed down through `specialArgs`. The home
directory, the account and all symlinks are derived from it.

### Live dotfiles (no rebuild for most tweaks)
Nearly everything in `dotfiles/` is linked into `~/.config` with Home Manager's
`mkOutOfStoreSymlink`. That means the symlink points **at the repo file itself**, not at a
copy in the Nix store. Edit the file, reload the program, and you're done:

| You changed… | To apply |
|---|---|
| `dotfiles/hypr/hyprland.conf` | saves auto‑reload (or `hyprctl reload`) |
| `dotfiles/eww/eww.yuck` / `eww.scss` | `eww reload` |
| `dotfiles/eww/scripts/*` | nothing, scripts run fresh on every click/poll |
| `dotfiles/kitty/kitty.conf` | `Ctrl+Shift+F5` in kitty |
| `dotfiles/swaync/*` | `swaync-client -R -rs` (config + CSS) |
| `dotfiles/nvim/*` | restart nvim (plugins install themselves via lazy.nvim) |
| anything in `*.nix`, new packages, services | `sudo nixos-rebuild switch --flake ~/nix-config#nixos` |

> [!IMPORTANT]
> Scripts and symlinks reference absolute paths under `~/nix-config`, so the repo **must**
> live there.

### The bar
eww is split into three parts:
- `eww.yuck`: layout (windows, widgets, popups)
- `eww.scss`: styling
- `scripts/`: small bash scripts that either **produce data** (polled or streamed as JSON into
  eww variables) or **perform actions** (on click)

A few patterns repeat throughout the scripts:
- **Optimistic UI.** Toggles flip the icon immediately, then do the slow work.
- **Detached work.** Anything slow or popup‑closing runs under `setsid` with a
  `trap … EXIT`. eww kills a click's child process when its popup closes, so without this,
  scans would stall and Wi‑Fi connects would die halfway.
- **Popup reflow.** eww sizes a window once, when it opens. When a list grows (for example
  after a Bluetooth scan), `scripts/reflow.sh` closes and reopens the popup so it fits.

### Background helpers (autostarted)
Small long‑running scripts started by Hyprland's `exec-once`. Each one replaces any
older copy of itself on startup, so they never stack up across logins.

| Helper | What it does |
|---|---|
| `scripts/conn-notify.sh` | Toast when Wi‑Fi or a Bluetooth device connects |
| `scripts/battery-notify.sh` | Warns at 20 % and 10 % (critical), and at 5 % gives a 60 s countdown then suspends. Plugging in cancels it; waking up unplugged gives you 5 minutes to save |
| `eww/scripts/osd-volume-watch.sh` | Shows the volume OSD for *any* volume change: keys, bar scroll, AirPods, apps. Event‑driven through `pactl subscribe` |
| `scripts/float-ws-listen.sh` | Floats new windows on workspaces in free‑float mode |
| `playerctld` | Remembers the most recently active media player |

### Theme
The colours are fixed Catppuccin Mocha values, repeated inline in each tool's config:
Hyprland, eww, kitty, fuzzel, swaync, wlogout, SDDM, hyprlock, yazi, nvim and GTK. There is no
generated theme step. Wallpapers only change the image, never the colours.

---

## Install

On a fresh NixOS install with flakes available:

```bash
git clone <this repo> ~/nix-config
~/nix-config/install.sh                              # asks for a username + login password
sudo nixos-rebuild switch --flake ~/nix-config#nixos
```

`install.sh` writes the username into `flake.nix` and stores your password **hash** in
`/etc/nixos-secrets/password` (root‑only, outside git). Wi‑Fi secrets additionally need the
age key described under [Secrets](#secrets). Without it, the build still works; only the
campusroam profile will fail to decrypt.

---

## Keybinds

`Super` is the main modifier.

### Apps & system
| Keys | Action |
|---|---|
| `Super + Space` | Terminal (kitty) |
| `Alt + Space` | App launcher (fuzzel) |
| `Super + E` | File manager (yazi in kitty) |
| `Super + B` | Browser (Brave) |
| `Super + W` | Wallpaper picker (thumbnails) |
| `Super + Shift + W` | Random wallpaper |
| `Super + N` | Toggle notification centre |
| `Super + Shift + N` | Toggle Do Not Disturb |
| `Super + L` | Power menu (lock / logout / suspend / reboot / shutdown) |
| `Super + Alt + L` | Lock screen |
| `Super + Shift + P` | Turn displays off (any input wakes them) |
| `Super + Alt + S` | Toggle screen reader (orca) |
| `Super + Shift + E` / `Ctrl + Alt + Del` | Exit Hyprland |

### Windows
| Keys | Action |
|---|---|
| `Super + Q` | Close window |
| `Super + ←↓↑→` / `Super + H J K` | Move focus |
| `Super + Ctrl + ←↓↑→` / `H J K L` | Move window |
| `Super + F` | Maximise (keeps bar and gaps) |
| `Super + Shift + F` | True fullscreen |
| `Super + V` | Float window (pops out centred) / re‑tile |
| `Super + Shift + V` | Free‑float mode for this workspace (new windows float too) |
| `Super + R` | Flip split direction |
| `Super + G` | Toggle tabbed group |
| `Super + Tab` | Cycle windows in a group |
| `Super + −` / `=` | Shrink / grow width |
| `Super + Shift + −` / `=` | Shrink / grow height |
| `Super + Left‑drag` | Move window |
| `Super + Right‑drag` | Resize window |

### Workspaces & monitors
| Keys | Action |
|---|---|
| `Super + 1…9` | Go to workspace |
| `Super + Shift + 1…9` | Move window to workspace |
| `Super + U` / `I` (or `PgDn` / `PgUp`) | Next / previous workspace |
| `Super + Ctrl + U` / `I` | Move window to next / previous workspace |
| `Super + Scroll` | Cycle workspaces |
| `Super + Shift + ←/→` (or `H`/`L`) | Focus other monitor |
| `Super + Shift + Ctrl + ←/→` (or `H`/`L`) | Move window to other monitor |

### Screenshots
All screenshots go to `~/Pictures/Screenshots` **and** the clipboard.

| Keys | Action |
|---|---|
| `Print` / `Super + Shift + S` | Region |
| `Ctrl + Print` | Full screen |
| `Alt + Print` | Active window |

### Hardware keys & headset buttons
Volume up/down/mute, mic mute and brightness up/down all work. They update the bar
instantly and show an **on‑screen display** (bottom centre, disappears after a moment).
The volume OSD also appears when the volume changes from AirPods or an app. **Media keys** (play/pause, next, previous, stop, seek) work from the keyboard,
from wired‑headset remotes, and from **Bluetooth headset buttons**. BlueZ turns a headset's
AVRCP presses into media keys through a virtual `<device> (AVRCP)` keyboard.

| AirPods | Action |
|---|---|
| Squeeze once | Play / pause |
| Squeeze twice | Next track |
| Squeeze three times | Previous track |

They always control the player that's **actually playing**, falling back to the one you used
last (`eww/scripts/media-target.sh` + `playerctld`), so with Spotify and a Brave tab both open
you don't end up pausing the wrong one. The bar's now‑playing widget follows the same player.

### Kitty
| Keys | Action |
|---|---|
| `Ctrl + =` / `Ctrl + −` | Zoom in / out |
| `Ctrl + 0` | Reset zoom |

### Neovim (leader = `Space`)
| Keys | Action |
|---|---|
| `<leader>sf` / `sg` / `sw` | Find files / live grep / grep word |
| `<leader><leader>` | Open buffers |
| `<leader>/` | Fuzzy find in buffer |
| `<leader>sd` / `sk` / `sh` / `sr` | Diagnostics / keymaps / help / resume search |
| `gd` / `gr` / `gI` / `gD` | Definition / references / implementation / declaration |
| `K` | Hover docs |
| `<leader>rn` / `<leader>ca` | Rename / code action |
| `<leader>e` | Diagnostics for this line (float) |
| `[d` / `]d` | Previous / next diagnostic |
| `<leader>ud` | Toggle inline ("Error Lens") diagnostics |
| `]h` / `[h` | Next / previous git hunk |
| `<leader>hs` / `hr` / `hp` / `hb` | Stage / reset / preview hunk, blame line |
| `Ctrl + h j k l` | Move between splits |

LSPs: `lua_ls`, `nixd`, `basedpyright` and `ruff`, all installed through Nix (no mason).

### Shell aliases
`ls`, `ll`, `la` and `lt` are all `eza` with icons (`lt` shows a tree).

---

## The bar (eww)

Left to right: **workspaces** · **now playing** · **clock** · then the right‑hand pill with
the tray, CPU/RAM, toggles, weather and date.

| Element | Click | Other |
|---|---|---|
| Workspace dots | — | pink = focused; flashes when a window opens on another workspace |
| Now playing | media popup (art, seek bar, prev/play/next) | only shown while a track is loaded |
| Clock | notification centre | |
| System tray | app menu (right‑click) | only shown when an app is in the tray |
| CPU / RAM rings | — | hover for % |
| Brightness | slider popup | scroll to adjust |
| Volume | slider + **output device picker** | middle‑click mute · scroll to adjust |
| Wi‑Fi | network list, rescan, on/off, password prompt | |
| Bluetooth | paired devices + auto‑scan, pair new devices | middle‑click on/off |
| ☕ Caffeine | keep screen awake (holds an idle inhibitor; closing the lid still suspends *and locks*) | |
| 🔔 DND | silence notifications | |
| 🌙 Night light | warm screen tint (Hyprland shader) | |
| Weather | 3‑day forecast popup | auto location via wttr.in |
| Battery | — | hover for time remaining |
| Date | calendar | |

Clicking anywhere outside a popup closes it.

---

## Useful commands

```bash
# Apply config changes
sudo nixos-rebuild switch --flake ~/nix-config#nixos
sudo nixos-rebuild test   --flake ~/nix-config#nixos   # apply without adding a boot entry
sudo nixos-rebuild switch --rollback                   # undo the last switch
sudo nix-collect-garbage --delete-older-than 14d       # clean up now (runs weekly automatically)

# Update packages (updates flake.lock), then rebuild
nix flake update                     # everything
nix flake update nixpkgs             # just one input

# Reload live-edited pieces
eww reload · hyprctl reload · swaync-client -R -rs

# Secrets
sops ~/nix-config/secrets/secrets.yaml      # edit encrypted secrets in $EDITOR

# Battery
sudo tlp fullcharge BAT0             # charge to 100 % once (e.g. before class); the 80 % cap resumes after
sudo tlp-stat -b                     # battery health + charge thresholds
sudo powertop                        # what is draining power

# Networking / Bluetooth
nmcli connection up campusroam
bluetoothctl info <MAC> | grep -E 'Paired|Bonded|Trusted|Connected'
```

---

## Secrets

- **Login password:** only the *hash* is stored, in `/etc/nixos-secrets/password` (root, `0600`,
  never committed). It's referenced from `configuration.nix` through `hashedPasswordFile`.
  Never put `hashedPassword = "$6$…"` inline.
- **Everything else** (for example the KU Leuven Wi‑Fi identity and password) lives in
  `secrets/secrets.yaml`, encrypted with **sops + age**. That file is safe to commit.
  - Your personal key, used for editing: `~/.config/sops/age/keys.txt`
  - The machine key, used to decrypt at boot: `/var/lib/sops-nix/key.txt`
  - Neither key is ever in the repo, and `.gitignore` guards against committing them by accident.
- At activation, secrets are decrypted to `/run/secrets/…`. A sops template turns them into an
  env file that NetworkManager's `ensureProfiles` reads (`$CAMPUSROAM_ID`, `$CAMPUSROAM_PW`).

**SSH server is off.** It was a leftover from when this ran in a VM, and it accepted
password logins on every network (including campusroam). See `configuration.nix` for the
key‑only snippet if you ever need to SSH *into* this laptop.

To add a secret, declare `sops.secrets.<name> = { };` in Nix, run `sops secrets/secrets.yaml`,
add a `<name>: value` line, and rebuild.

---

## Known quirks & gotchas

Things that cost real debugging time, written down so they don't have to be rediscovered.

- **campusroam / eduroam (WPA2‑Enterprise) on NixOS:** don't use `system-ca-certs = true`. It
  makes wpa_supplicant read `/etc/ssl/certs` as a hashed *directory*, which NixOS doesn't
  provide. It then trusts nothing and the network deauths you with
  `Reason 23 (IEEE8021X_FAILED)`, which looks exactly like a wrong password. Use
  `ca-cert = "/etc/ssl/certs/ca-certificates.crt"` with `domain-suffix-match = "kuleuven.be"`
  instead. Both `campusroam` and `campusroam-2.4` are generated from one helper.
- **Bluetooth pairing must *bond*:** if the adapter isn't pairable while you pair, BlueZ does a
  non‑bonding pairing. It works until the next reboot, then fails with
  `br-connection-key-missing`. The fix is `AlwaysPairable = true` plus `bt-pair.sh` turning
  pairable on. Check with `bluetoothctl info` that it says **`Bonded: yes`**.
- **AirPods battery isn't readable:** Apple reports it over a proprietary protocol that BlueZ
  can't decode. The bar shows battery % for Bluetooth devices that *do* report it.
- **Panel Self‑Refresh:** `i915.enable_psr=1` (PSR1 only). PSR2's "selective fetch" is buggy on
  this panel and made animations stutter, so PSR used to be fully off (`=0`), at a battery
  cost. If the stutter ever comes back, set it back to `0`. Note that
  `/sys/module/i915/parameters/enable_psr` is root‑readable only, so a non‑root read failing
  does *not* mean the parameter is missing.
- **Caffeine** holds a systemd idle inhibitor (`systemd-inhibit --what=idle`); it does *not*
  stop `hypridle`. That matters because `hypridle` is also what locks the screen before
  suspend. An older version killed it, so closing the lid while caffeinated slept unlocked.
- **Housekeeping:** weekly garbage collection keeps 14 days of generations, the store is
  auto‑optimised, and GRUB/`/boot` keep the newest 15 entries. Without this, `/boot` (1 GB)
  slowly fills with old kernels until a rebuild fails.
- **Night light** uses Hyprland's `decoration:screen_shader` rather than gammastep, because
  gamma control isn't available on every GPU/output. The shader works everywhere.
- **RStudio** pulls in an end‑of‑life Electron that nixpkgs flags as insecure. It's allowed
  explicitly in `nixpkgs.config.permittedInsecurePackages`. Bump that version string if a future
  update complains about a different one. For R packages, use
  `rstudioWrapper.override { packages = with rPackages; [ … ]; }` instead of
  `install.packages()`.
- **eww's SCSS compiler (grass)** rejects comma‑combined keyframes like `0%,100% { }`. Give each
  stop its own block.
- **`nix flake update` can briefly break the build** when nixpkgs‑unstable is mid‑transition
  (for example `buildGo125Module has been removed` coming from sops). Recover with
  `git checkout flake.lock && nix flake lock`, which goes back to the last working lock and
  keeps any newly added inputs.
- **Screenshots from scripts:** on this machine `grim` needs `-o eDP-1`. Plain `grim` can hang,
  and a hung grim blocks later ones until you `pkill -9 grim`.
