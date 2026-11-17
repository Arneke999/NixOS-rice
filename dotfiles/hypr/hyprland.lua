-- Hyprland — the working desktop. Dynamic (dwindle) tiling: one window fills the
-- screen, a second auto-splits beside it, a fresh workspace opens empty. NO analog
-- texture here — the CRT/scanline look lives ONLY on hyprlock + the boot splash.
--
-- Colors are Catppuccin Mocha (pink accent), baked in — edit the hexes here directly.
-- Ported 1:1 from the old niri config.kdl, then from hyprland.conf (hyprlang) to Lua
-- when Hyprland 0.57 dropped hyprlang configs.
--
-- Docs: https://wiki.hypr.land/configuring/
-- API reference (types for every hl.* call): <hyprland pkg>/share/hypr/stubs/hl.meta.lua

local mod     = "SUPER"
local scripts = "~/nix-config/dotfiles/scripts"
local eww     = "~/nix-config/dotfiles/eww/scripts"

-- ── Monitors ───────────────────────────────────────────────────────────────
-- The VM's virtual output, pinned to 1920x1200 (its "preferred" mode is a small
-- 1280x800, so it must be set explicitly). The catch-all below covers the laptop's
-- eDP-1 at its preferred mode, so the config stays portable without editing.
hl.monitor({ output = "Virtual-1", mode = "1920x1200@60", position = "auto", scale = 1 })
hl.monitor({ output = "",          mode = "preferred",    position = "auto", scale = 1 })

-- ── Environment ──────────────────────────────────────────────────────────────
hl.env("XCURSOR_THEME", "Bibata-Modern-Classic")
hl.env("XCURSOR_SIZE", "20")

-- ── Startup ──────────────────────────────────────────────────────────────────
-- NOTE: no boot-time auto-lock here anymore. Login is now a real pre-session
-- greeter (ReGreet, services.greetd in the NixOS config) that authenticates
-- BEFORE Hyprland starts, so locking again on launch would just be a second
-- password prompt. hyprlock still handles idle-lock (hypridle) and the manual
-- Super+Alt+L bind below.
--
-- "hyprland.start" fires once at launch (the old exec-once); it does NOT re-run on
-- `hyprctl reload`. Commands run through /bin/sh -c, so ~, && and || work.
hl.on("hyprland.start", function()
    -- Make portals / screenshare see the running session: push the compositor env
    -- into systemd+dbus, then activate the session target (defined in home.nix as
    -- hyprland-session.target -> BindsTo graphical-session.target). Without the
    -- second step xdg-desktop-portal refuses to start (Requisite=graphical-session
    -- .target) and portal-backed things silently hang — file pickers, screenshare,
    -- Flatpak webviews (Sober's Roblox captcha). graphical-session.target itself has
    -- RefuseManualStart, so the BindsTo target is the only way in — on Arch, drop the
    -- same unit into ~/.config/systemd/user/hyprland-session.target.
    hl.exec_cmd("dbus-update-activation-environment --systemd WAYLAND_DISPLAY XDG_CURRENT_DESKTOP XDG_SESSION_TYPE HYPRLAND_INSTANCE_SIGNATURE && systemctl --user start hyprland-session.target")
    -- Bar (eww).
    hl.exec_cmd("eww open bar")
    -- Notification daemon (swaync).
    hl.exec_cmd("swaync")
    -- Idle daemon: screen off after 6 min idle; locks before suspend (auto-lock disabled).
    hl.exec_cmd("hypridle")
    -- Track the most recently active media player so play/pause/next hit the one you're
    -- actually listening to (Spotify vs a Brave tab), not whichever playerctl lists first.
    hl.exec_cmd("playerctld daemon")
    -- Dark GTK / libadwaita prefs (dconf).
    hl.exec_cmd(scripts .. "/gtk-theme.sh")
    -- Restore the last-used wallpaper on login (no arg → reads ~/.cache/wallpaper).
    hl.exec_cmd(scripts .. "/set-wallpaper.sh")
    -- Auto-float new windows on workspaces toggled to "free-float" (Super+Shift+V).
    hl.exec_cmd(scripts .. "/float-ws-listen.sh")
    -- Toast when a Wi-Fi network or Bluetooth device connects.
    hl.exec_cmd(scripts .. "/conn-notify.sh")
    -- Low-battery warnings at 20 % / 10 %, and a safe suspend at 5 % (never just die mid-class).
    hl.exec_cmd(scripts .. "/battery-notify.sh")
    -- Volume OSD for ANY volume change (keys, scroll, AirPods, apps) — event-driven via pactl.
    hl.exec_cmd(eww .. "/osd-volume-watch.sh")
end)

-- ── Options: input, layout & look ────────────────────────────────────────────
hl.config({
    input = {
        numlock_by_default = true,
        -- kb_layout is left unset so it inherits the system locale (localectl),
        -- matching the old niri behavior. Set it here if you want azerty etc.
        follow_mouse = 1,
        -- Pointer speed (libinput accel, range -1.0 … 1.0). Bumped up because the
        -- touchpad felt sluggish — you had to drag a long way to move the cursor.
        -- Tune to taste; lower if it now feels too twitchy.
        sensitivity = 0.5,
        touchpad = {
            natural_scroll = true,
            tap_to_click   = true,   -- was `tap-to-click` in hyprlang
            -- Larger multiplier = less finger travel to cross the screen.
            scroll_factor  = 1.0,
        },
    },

    cursor = {
        inactive_timeout = 0,
    },

    general = {
        gaps_in     = 4,   -- between windows (tightened — 8+8 felt too airy)
        gaps_out    = 8,   -- screen edges
        border_size = 2,   -- was niri focus-ring width 2
        -- Active border = Catppuccin pink; inactive is a muted grey.
        col = {
            active_border   = "rgb(f5c2e7)",
            inactive_border = "rgb(505050)",
        },
        layout           = "dwindle",
        resize_on_border = true,
    },

    decoration = {
        rounding = 8,      -- was niri geometry-corner-radius 8
        -- Flat, disciplined desktop — no blur, no shadow (texture lives on hyprlock).
        blur   = { enabled = false },
        shadow = { enabled = false },
    },

    dwindle = {
        preserve_split = true,
    },

    misc = {
        disable_hyprland_logo    = true,
        disable_splash_rendering = true,
        force_default_wallpaper  = 0,   -- awww paints the wallpaper, not Hyprland
        -- The frame Hyprland shows before awww paints the wallpaper — pin it to the rice
        -- near-black so the SDDM→desktop handoff stays dark end-to-end (no black flash of
        -- Hyprland's default) instead of popping from black to wallpaper.
        background_color = "rgb(0f0f11)",
    },

    animations = {
        enabled = true,
    },
})

-- ── Animations ───────────────────────────────────────────────────────────────
-- Buttery but crisp. easeOutQuint at 450–550ms read "smooth but ~30fps" — its tail
-- decelerates so hard that the final stretch shows per-frame stepping on a 60Hz
-- panel. Fix: `butter` is now easeOutCubic (brisk, clean finish — no crawl) and
-- durations are shorter (~320–360ms), so motion still glides but resolves before
-- the tail can visibly step. NOTE: Hyprland 0.55 removed the misc:vfr /
-- render:explicit_sync knobs (explicit sync is always-on via aquamarine now), so
-- curve + duration is the only lever here. If it STILL reads like 30fps it's
-- genuine frame pacing (ARL + aquamarine) → revisit under the laptop power work
-- (GPU staying clocked down on battery).
hl.curve("butter",   { type = "bezier", points = { {0.33, 1.0},  {0.68, 1.0}  } })  -- easeOutCubic — smooth glide, brisk finish
hl.curve("smoothIO", { type = "bezier", points = { {0.65, 0.0},  {0.35, 1.0}  } })  -- easeInOutCubic — for window moves
hl.curve("gentle",   { type = "bezier", points = { {0.25, 0.46}, {0.45, 0.94} } })  -- soft ease for fades/borders

hl.animation({ leaf = "windows",     enabled = true, speed = 3.2, bezier = "butter",   style = "popin 96%" })
hl.animation({ leaf = "windowsIn",   enabled = true, speed = 3.2, bezier = "butter",   style = "popin 96%" })
hl.animation({ leaf = "windowsOut",  enabled = true, speed = 2.6, bezier = "butter",   style = "popin 96%" })
hl.animation({ leaf = "windowsMove", enabled = true, speed = 3.0, bezier = "smoothIO" })
hl.animation({ leaf = "fade",        enabled = true, speed = 2.6, bezier = "gentle" })
hl.animation({ leaf = "border",      enabled = true, speed = 5.0, bezier = "gentle" })
hl.animation({ leaf = "workspaces",  enabled = true, speed = 3.6, bezier = "butter",   style = "slide" })

-- ── Window rules ─────────────────────────────────────────────────────────────
-- Firefox picture-in-picture floats (both host + flatpak Firefox).
hl.window_rule({
    name  = "pip-float",
    match = { title = "^(Picture-in-Picture)$" },
    float = true,
})

-- ── Binds ────────────────────────────────────────────────────────────────────
-- "Mod" was niri's Super; here mod = SUPER. Layout is dynamic tiling now, so the
-- niri column/scroll binds are replaced by their dwindle equivalents.
--
-- hyprlang bind flavours → Lua opts:  bindl = { locked = true }
--   binde = { repeating = true }   bindel = { locked = true, repeating = true }
--   bindm = { mouse = true }
local locked    = { locked = true }
local repeating = { repeating = true }
local lockedRep = { locked = true, repeating = true }

local function exec(cmd) return hl.dsp.exec_cmd(cmd) end

-- Apps.
hl.bind(mod .. " + Space",     exec("kitty"))
hl.bind(mod .. " + E",         exec("kitty -e yazi"))   -- file manager (yazi TUI) in a kitty window
hl.bind("ALT + Space",         exec("fuzzel"))
hl.bind(mod .. " + B",         exec("brave"))
hl.bind(mod .. " + N",         exec("swaync-client -t -sw"))
hl.bind(mod .. " + SHIFT + N", exec("swaync-client -d -sw"))
-- Lock via logind so hypridle catches the signal and runs hyprlock.
hl.bind("SUPER + ALT + L",     exec("loginctl lock-session"))
-- Reset to the default wallpaper (lain.jpg).
hl.bind(mod .. " + SHIFT + W", exec(scripts .. "/wall-random.sh"))
-- Screen reader toggle (works while locked).
hl.bind("SUPER + ALT + S",     exec("pkill orca || orca"), locked)

-- Window management.
hl.bind(mod .. " + Q",         hl.dsp.window.close())
hl.bind(mod .. " + V",         exec(scripts .. "/float-toggle.sh"))     -- float (pops out centered) / re-tile
hl.bind(mod .. " + SHIFT + V", exec(scripts .. "/float-ws-toggle.sh"))  -- free-float mode for this workspace (new windows float too)
hl.bind(mod .. " + F",         hl.dsp.window.fullscreen({ mode = "maximized" }))   -- maximize (keeps bar/gaps) — was niri maximize-column
hl.bind(mod .. " + SHIFT + F", hl.dsp.window.fullscreen({ mode = "fullscreen" }))  -- true fullscreen — was niri fullscreen-window
hl.bind(mod .. " + R",         hl.dsp.layout("togglesplit"))            -- flip dwindle split — replaces niri preset widths
hl.bind(mod .. " + W",         exec(scripts .. "/wall-picker.sh"))      -- wallpaper picker (fuzzel)
hl.bind(mod .. " + G",         hl.dsp.group.toggle())                   -- tabbed group — closest to niri tabbed column (moved off W)
hl.bind(mod .. " + Tab",       hl.dsp.group.next())                     -- cycle within a group

-- Focus (arrows + vim keys).
hl.bind(mod .. " + left",  hl.dsp.focus({ direction = "left" }))
hl.bind(mod .. " + down",  hl.dsp.focus({ direction = "down" }))
hl.bind(mod .. " + up",    hl.dsp.focus({ direction = "up" }))
hl.bind(mod .. " + right", hl.dsp.focus({ direction = "right" }))
hl.bind(mod .. " + H",     hl.dsp.focus({ direction = "left" }))
hl.bind(mod .. " + J",     hl.dsp.focus({ direction = "down" }))
hl.bind(mod .. " + K",     hl.dsp.focus({ direction = "up" }))
hl.bind(mod .. " + L",     exec("pkill wlogout || wlogout -b 5 -p layer-shell"))  -- power menu, one row of icons (focus-right stays on mod+right)

-- Move window.
hl.bind(mod .. " + CTRL + left",  hl.dsp.window.move({ direction = "left" }))
hl.bind(mod .. " + CTRL + down",  hl.dsp.window.move({ direction = "down" }))
hl.bind(mod .. " + CTRL + up",    hl.dsp.window.move({ direction = "up" }))
hl.bind(mod .. " + CTRL + right", hl.dsp.window.move({ direction = "right" }))
hl.bind(mod .. " + CTRL + H",     hl.dsp.window.move({ direction = "left" }))
hl.bind(mod .. " + CTRL + J",     hl.dsp.window.move({ direction = "down" }))
hl.bind(mod .. " + CTRL + K",     hl.dsp.window.move({ direction = "up" }))
hl.bind(mod .. " + CTRL + L",     hl.dsp.window.move({ direction = "right" }))

-- Focus monitor.
hl.bind(mod .. " + SHIFT + left",  hl.dsp.focus({ monitor = "l" }))
hl.bind(mod .. " + SHIFT + right", hl.dsp.focus({ monitor = "r" }))
hl.bind(mod .. " + SHIFT + H",     hl.dsp.focus({ monitor = "l" }))
hl.bind(mod .. " + SHIFT + L",     hl.dsp.focus({ monitor = "r" }))

-- Move window to monitor.
hl.bind(mod .. " + SHIFT + CTRL + left",  hl.dsp.window.move({ monitor = "l" }))
hl.bind(mod .. " + SHIFT + CTRL + right", hl.dsp.window.move({ monitor = "r" }))
hl.bind(mod .. " + SHIFT + CTRL + H",     hl.dsp.window.move({ monitor = "l" }))
hl.bind(mod .. " + SHIFT + CTRL + L",     hl.dsp.window.move({ monitor = "r" }))

-- Resize (repeatable). kitty zoom uses Ctrl+/- now, so these can live on bare Super.
-- The Lua resize dispatcher takes pixels only (hyprlang's "-10%" is gone), so grow /
-- shrink by 10% of the window's current size, same as the old `resizeactive -10% 0`.
local function resizeBy(fx, fy)
    return function()
        local w = hl.get_active_window()
        if not w then return end
        hl.dispatch(hl.dsp.window.resize({ x = w.size.x * fx, y = w.size.y * fy, relative = true }))
    end
end
hl.bind(mod .. " + minus",         resizeBy(-0.1, 0),  repeating)
hl.bind(mod .. " + equal",         resizeBy( 0.1, 0),  repeating)
hl.bind(mod .. " + SHIFT + minus", resizeBy(0, -0.1),  repeating)
hl.bind(mod .. " + SHIFT + equal", resizeBy(0,  0.1),  repeating)

-- Workspaces: next/prev (Page keys + U/I, matching the old niri binds).
hl.bind(mod .. " + Page_Down",        hl.dsp.focus({ workspace = "+1" }))
hl.bind(mod .. " + Page_Up",          hl.dsp.focus({ workspace = "-1" }))
hl.bind(mod .. " + U",                hl.dsp.focus({ workspace = "+1" }))
hl.bind(mod .. " + I",                hl.dsp.focus({ workspace = "-1" }))
hl.bind(mod .. " + CTRL + Page_Down", hl.dsp.window.move({ workspace = "+1" }))
hl.bind(mod .. " + CTRL + Page_Up",   hl.dsp.window.move({ workspace = "-1" }))
hl.bind(mod .. " + CTRL + U",         hl.dsp.window.move({ workspace = "+1" }))
hl.bind(mod .. " + CTRL + I",         hl.dsp.window.move({ workspace = "-1" }))

-- Workspaces by number; Super+Shift+N moves the focused window there (CachyOS habit).
for i = 1, 9 do
    hl.bind(mod .. " + " .. i,         hl.dsp.focus({ workspace = i }))
    hl.bind(mod .. " + SHIFT + " .. i, hl.dsp.window.move({ workspace = i }))
end

-- Mouse wheel over the desktop cycles workspaces (was Mod+Wheel in niri).
hl.bind(mod .. " + mouse_down", hl.dsp.focus({ workspace = "e+1" }))
hl.bind(mod .. " + mouse_up",   hl.dsp.focus({ workspace = "e-1" }))
-- Drag to move / resize floating windows.
hl.bind(mod .. " + mouse:272", hl.dsp.window.drag(),   { mouse = true })
hl.bind(mod .. " + mouse:273", hl.dsp.window.resize(), { mouse = true })

-- Session.
hl.bind(mod .. " + SHIFT + E",  hl.dsp.exit())
hl.bind("CTRL + ALT + Delete",  hl.dsp.exit())
hl.bind(mod .. " + SHIFT + P",  hl.dsp.dpms({ action = "off" }))   -- blank monitors; any input wakes them

-- Screenshots (screenshot.sh: grim + slurp + wl-clipboard). Each mode copies to the
-- clipboard AND saves a PNG to ~/Pictures/Screenshots, then notifies with a preview.
hl.bind("Print",               exec(scripts .. "/screenshot.sh region"))
-- Super+Shift+S: same region-select screenshot (Windows/Snip muscle memory).
hl.bind(mod .. " + SHIFT + S", exec(scripts .. "/screenshot.sh region"))
hl.bind("CTRL + Print",        exec(scripts .. "/screenshot.sh full"))
hl.bind("ALT + Print",         exec(scripts .. "/screenshot.sh window"))

-- Media / brightness keys (work while locked, repeatable where it makes sense).
-- Routed through the eww helpers so the bar widget updates instantly (they change
-- the value AND push it to eww); the mic-mute has no widget so it stays direct.
hl.bind("XF86AudioRaiseVolume",  exec(eww .. "/vol-ctl.sh up"),   lockedRep)
hl.bind("XF86AudioLowerVolume",  exec(eww .. "/vol-ctl.sh down"), lockedRep)
hl.bind("XF86AudioMute",         exec(eww .. "/vol-ctl.sh mute"), locked)
hl.bind("XF86AudioMicMute",      exec("wpctl set-mute @DEFAULT_AUDIO_SOURCE@ toggle"), locked)
hl.bind("XF86MonBrightnessUp",   exec(eww .. "/bri-ctl.sh up"),   lockedRep)
hl.bind("XF86MonBrightnessDown", exec(eww .. "/bri-ctl.sh down"), lockedRep)

-- Media transport. Bluetooth headsets (AirPods, Sony, Bose, …) send their button
-- presses over AVRCP; BlueZ turns them into these keys via a virtual keyboard named
-- "<device> (AVRCP)". Wired-headset buttons and keyboard media keys use the same keys.
-- media-ctl.sh targets the player that is PLAYING (else the most recent). locked =
-- also works on the lock screen. (AirPods: squeeze = play/pause, double = next, triple = prev.)
hl.bind("XF86AudioPlay",    exec(eww .. "/media-ctl.sh play-pause"), locked)
hl.bind("XF86AudioPause",   exec(eww .. "/media-ctl.sh play-pause"), locked)
hl.bind("XF86AudioNext",    exec(eww .. "/media-ctl.sh next"),       locked)
hl.bind("XF86AudioPrev",    exec(eww .. "/media-ctl.sh previous"),   locked)
hl.bind("XF86AudioStop",    exec(eww .. "/media-ctl.sh stop"),       locked)
hl.bind("XF86AudioForward", exec(eww .. "/media-ctl.sh seek+"),      locked)
hl.bind("XF86AudioRewind",  exec(eww .. "/media-ctl.sh seek-"),      locked)
