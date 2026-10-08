{ config, lib, pkgs, inputs, username, ... }:

let
  # RStudio from the pinned nixpkgs (see nixpkgs-rstudio in flake.nix for why).
  # Same nixpkgs config as the system, so the Electron permit still applies.
  pkgsRstudio = import inputs.nixpkgs-rstudio {
    inherit (pkgs.stdenv.hostPlatform) system;
    inherit (pkgs) config;
  };

  # R packages for RStudio AND terminal R (one list → same packages in both). Install
  # them here, not with install.packages(): compiled packages need system libraries
  # NixOS doesn't expose to R, and ones that do build link against store paths the
  # weekly garbage collection can delete. R's 15 "recommended" packages (MASS,
  # lattice, Matrix, survival, …) are added by the wrappers automatically.
  # Names: https://search.nixos.org/packages?query=rPackages
  rPackages = with pkgsRstudio.rPackages; [
    tidyverse   # ggplot2, dplyr, tidyr, readr, readxl, haven (SPSS/Stata), broom, …
    rmarkdown   # R Markdown / knit to HTML/Word/PDF
    knitr
    lessR       # simplified stats/plots for class: BarChart(), Histogram(), ttest(), reg(), …
    car
  ];

  # The pinned RStudio's Electron is linked against the older glibc, so it can't load
  # the system's (newer) Mesa graphics driver ("GLIBC_2.43 not found") and falls back
  # to slow software rendering. Point it at the Mesa from its own nixpkgs instead.
  # Remove together with the pin.
  rstudio = (pkgsRstudio.rstudioWrapper.override { packages = rPackages; }).overrideAttrs (old: {
    buildCommand = old.buildCommand + ''
      wrapProgram $out/bin/rstudio \
        --set GBM_BACKENDS_PATH ${pkgsRstudio.mesa}/lib/gbm \
        --set LIBGL_DRIVERS_PATH ${pkgsRstudio.mesa}/lib/dri \
        --set __EGL_VENDOR_LIBRARY_FILENAMES ${pkgsRstudio.mesa}/share/glvnd/egl_vendor.d/50_mesa.json

      # Start R in ~. RStudio treats every existing path among its launch arguments as
      # "what you opened", and the LAST one becomes R's working directory. nixpkgs'
      # launcher passes RStudio's own read-only app folder as an argument, so R started
      # inside the Nix store (.Rhistory/.RData couldn't save; relative paths and
      # file.choose() started there; the initial_working_directory pref is overridden).
      # Passing $HOME after it fixes that. A file you open (rstudio script.R) still
      # comes later and wins.
      mv $out/bin/rstudio $out/bin/.rstudio-home
      cat > $out/bin/rstudio <<EOF
      #!${pkgsRstudio.runtimeShell}
      exec $out/bin/.rstudio-home "\$HOME" "\$@"
      EOF
      chmod +x $out/bin/rstudio
    '';
  });

  # `R` / `Rscript` in the terminal: same R version and packages as RStudio.
  R = pkgsRstudio.rWrapper.override { packages = rPackages; };

  # RISC-V (computerarchitectuur): the GNU toolchain for RV32 + RV64 and QEMU to run
  # the programs on this x86 laptop.
  riscvBinutils64 = pkgs.pkgsCross.riscv64.buildPackages.binutils;

  # `rv run|debug|dump prog.s`, see dotfiles/scripts/rv.sh. Carries its own toolchain
  # on PATH, so it works from any terminal, Neovim or Codium.
  rv = pkgs.writeShellApplication {
    name = "rv";
    runtimeInputs = with pkgs; [
      qemu-user
      gdb
      pkgsCross.riscv32.buildPackages.gcc
      pkgsCross.riscv64.buildPackages.gcc
    ];
    text = builtins.readFile ../dotfiles/scripts/rv.sh;
  };

  # RARS, the RISC-V simulator (Java GUI). On Hyprland Java needs
  # _JAVA_AWT_WM_NONREPARENTING=1, or its panes collapse (the editor squashed into a
  # thin strip on the left). Note: `rars prog.s` runs in the terminal and exits;
  # plain `rars` opens the GUI.
  rars = pkgs.symlinkJoin {
    name = "rars";
    paths = [ pkgs.rars ];
    nativeBuildInputs = [ pkgs.makeWrapper ];
    postBuild = "wrapProgram $out/bin/rars --set _JAVA_AWT_WM_NONREPARENTING 1";
  };
in
{
  home.username = username;
  home.homeDirectory = "/home/${username}";
  home.stateVersion = "26.05";   # <-- match system.stateVersion in configuration.nix
  home.packages = with pkgs; [
    github-cli
    kitty
    awww
    brave
    claude-code
    fastfetch
    yazi
    nerd-fonts.jetbrains-mono
    fuzzel
    eww
    jq
    socat                    # eww workspace widget: Hyprland socket2 event stream
    playerctl                # eww now-playing widget: MPRIS metadata + transport controls
    pulseaudio               # client tools only (pactl) — the volume OSD listens to `pactl subscribe`; PipeWire still does the audio
    # (night light uses Hyprland's decoration:screen_shader — dotfiles/hypr/nightlight.frag —
    #  not gammastep, since this VM's virtio-gpu has no gamma-control support.)
    grim                     # screenshots (Print binds)
    slurp                    # region select for screenshots
    wl-clipboard             # wl-copy — screenshots to clipboard
    imagemagick              # `magick` — generates the wallpaper-picker thumbnails (Super+W)
    brightnessctl
    swaynotificationcenter   # swaync — animated notifications + notification center
    hyprlock                 # the Lain lockscreen (CRT shader, pink input)
    hypridle                 # idle -> screen off after 6 min; locks before suspend (via logind)
    wlogout                  # power menu (Super+L): lock/logout/suspend/reboot/shutdown
    neovim                   # Neovim tooling (installed via Nix, NOT mason — mason binaries break on NixOS):
    lua-language-server   # lua_ls
    nixd                  # Nix LSP
    basedpyright          # Python LSP (pyright fork) — type/import/syntax diagnostics
    ruff                  # Python linter LSP (fast) — unused imports, undefined names, style
    ripgrep               # telescope live-grep
    fd                    # telescope find-files
    gcc                   # compile treesitter parsers + fzf-native
    gnumake               # build telescope-fzf-native + LuaSnip jsregexp
    asm-lsp               # assembly LSP (RISC-V): instruction docs on K, completion, assembler errors
    # RISC-V assembly (see the let-block): rv = build/run/debug, gdb = debugger (nixpkgs
    # builds it for every architecture), rars = visual simulator (registers, memory, step).
    rv
    gdb
    rars
    # Shell (zsh) + interactive tooling. Note: zsh-autosuggestions and
    # zsh-syntax-highlighting are provided by programs.zsh.* in configuration.nix
    # (loaded via /etc/zshrc), so they're not listed here.
    zsh
    starship              # prompt (Catppuccin Mocha)
    fzf                   # Ctrl-R history / Ctrl-T files
    eza                   # modern ls
    bat                   # cat with syntax highlighting
    libnotify
    adw-gtk3
    papirus-icon-theme
    bibata-cursors
    inter
    firefox
    nmap
    sqlite
    openvpn
    discord
    steam
    sops
    age
    httpx
    protonplus
    rstudio   # pinned + R packages + graphics fix, see the let-block above
    R         # terminal R/Rscript with the same packages
    uv                    # Python projects/venvs; its downloaded Pythons run via nix-ld (configuration.nix)
  ];

  fonts.fontconfig.enable = true;

  # Session target for the plain (non-UWSM) start-hyprland launch. Hyprland >=0.46
  # no longer ships hyprland-session.target, and nothing else activates
  # graphical-session.target — but xdg-desktop-portal has
  # `Requisite=graphical-session.target`, so without this the portal never starts
  # ("NameHasNoOwner: Could not activate remote peer org.freedesktop.portal.Desktop")
  # and anything portal-backed breaks: Flatpak webviews (Sober's Roblox captcha
  # hangs on its proxy lookup), file pickers, screenshare. hyprland.conf starts
  # this target on launch, right after dbus-update-activation-environment.
  systemd.user.targets.hyprland-session = {
    Unit = {
      Description = "Hyprland compositor session";
      Documentation = [ "man:systemd.special(7)" ];
      BindsTo = [ "graphical-session.target" ];
      Wants = [ "graphical-session-pre.target" ];
      After = [ "graphical-session-pre.target" ];
    };
  };

  home.sessionVariables = {
    XCURSOR_THEME = "Bibata-Modern-Classic";
    XCURSOR_SIZE = "20";
  };

  # Out-of-store symlinks: live repo files (edited in place, hot-reloaded).
  # hyprland.conf carries the Catppuccin colours inline. Hyprland's search path is
  # ~/.config/hypr, so this drops in alongside hyprlock/hypridle and is a straight
  # copy to Arch.
  xdg.configFile."hypr/hyprland.conf".source =
    config.lib.file.mkOutOfStoreSymlink "${config.home.homeDirectory}/nix-config/dotfiles/hypr/hyprland.conf";

  xdg.configFile."kitty/kitty.conf".source =
    config.lib.file.mkOutOfStoreSymlink "${config.home.homeDirectory}/nix-config/dotfiles/kitty/kitty.conf";

  # yazi (Super+E) — Catppuccin Mocha pink theme on the rice near-black.
  xdg.configFile."yazi/theme.toml".source =
    config.lib.file.mkOutOfStoreSymlink "${config.home.homeDirectory}/nix-config/dotfiles/yazi/theme.toml";

  xdg.configFile."fuzzel/fuzzel.ini".source =
    config.lib.file.mkOutOfStoreSymlink "${config.home.homeDirectory}/nix-config/dotfiles/fuzzel/fuzzel.ini";

  xdg.configFile."swaync/config.json".source =
    config.lib.file.mkOutOfStoreSymlink "${config.home.homeDirectory}/nix-config/dotfiles/swaync/config.json";
  xdg.configFile."swaync/style.css".source =
    config.lib.file.mkOutOfStoreSymlink "${config.home.homeDirectory}/nix-config/dotfiles/swaync/style.css";

  # hyprlock + hypridle (kept in dotfiles/hypr/ — hyprlock's default search path
  # is ~/.config/hypr, so this is a straight copy to Arch). The .frag is the CRT
  # shader (static); hyprlock.conf carries the Catppuccin colours inline.
  xdg.configFile."hypr/hyprlock.conf".source =
    config.lib.file.mkOutOfStoreSymlink "${config.home.homeDirectory}/nix-config/dotfiles/hypr/hyprlock.conf";
  xdg.configFile."hypr/hyprlock.frag".source =
    config.lib.file.mkOutOfStoreSymlink "${config.home.homeDirectory}/nix-config/dotfiles/hypr/hyprlock.frag";
  xdg.configFile."hypr/hypridle.conf".source =
    config.lib.file.mkOutOfStoreSymlink "${config.home.homeDirectory}/nix-config/dotfiles/hypr/hypridle.conf";

  xdg.configFile."eww/eww.yuck".source =
    config.lib.file.mkOutOfStoreSymlink "${config.home.homeDirectory}/nix-config/dotfiles/eww/eww.yuck";
  xdg.configFile."eww/eww.scss".source =
    config.lib.file.mkOutOfStoreSymlink "${config.home.homeDirectory}/nix-config/dotfiles/eww/eww.scss";

  xdg.configFile."gtk-3.0/settings.ini".source =
    config.lib.file.mkOutOfStoreSymlink "${config.home.homeDirectory}/nix-config/dotfiles/gtk/settings.ini";
  xdg.configFile."gtk-4.0/settings.ini".source =
    config.lib.file.mkOutOfStoreSymlink "${config.home.homeDirectory}/nix-config/dotfiles/gtk/settings.ini";
  xdg.configFile."gtk-3.0/gtk.css".source =
    config.lib.file.mkOutOfStoreSymlink "${config.home.homeDirectory}/nix-config/dotfiles/gtk/gtk.css";
  xdg.configFile."gtk-4.0/gtk.css".source =
    config.lib.file.mkOutOfStoreSymlink "${config.home.homeDirectory}/nix-config/dotfiles/gtk/gtk.css";

  # uv: always use uv's own downloaded Pythons. Those run through nix-ld, so pip wheels
  # with compiled parts (numpy, pandas, …) find libstdc++/zlib. The Nix python3 on PATH
  # doesn't go through nix-ld, and uv would otherwise prefer it.
  # asm-lsp: every .s file is RISC-V (GNU as syntax) unless a project ships its own
  # .asm-lsp.toml. Errors come from the real RISC-V assembler; the rv64 one also accepts
  # RV32 code, so it covers both. -o /dev/null so checking never writes a.out files.
  # RARS ships no .desktop file; this makes it show up in the app launcher.
  xdg.desktopEntries.rars = {
    name = "RARS";
    genericName = "RISC-V simulator";
    comment = "Assemble, run and step through RISC-V programs";
    exec = "rars";
    icon = "applications-engineering";
    categories = [ "Development" "Education" ];
  };

  xdg.configFile."asm-lsp/.asm-lsp.toml".text = ''
    [default_config]
    version = "0.10.1"
    assembler = "gas"
    instruction_set = "riscv"

    [default_config.opts]
    compiler = "${riscvBinutils64}/bin/riscv64-unknown-linux-gnu-as"
    compile_flags_txt = ["-o", "/dev/null"]
    diagnostics = true
    default_diagnostics = false
  '';

  xdg.configFile."uv/uv.toml".text = ''
    python-preference = "only-managed"
  '';

  xdg.configFile."fastfetch/config.jsonc".source =
    config.lib.file.mkOutOfStoreSymlink "${config.home.homeDirectory}/nix-config/dotfiles/fastfetch/config.jsonc";

  # wlogout power menu (Super+L): layout (the buttons) + Catppuccin style.css.
  xdg.configFile."wlogout/layout".source =
    config.lib.file.mkOutOfStoreSymlink "${config.home.homeDirectory}/nix-config/dotfiles/wlogout/layout";
  xdg.configFile."wlogout/style.css".source =
    config.lib.file.mkOutOfStoreSymlink "${config.home.homeDirectory}/nix-config/dotfiles/wlogout/style.css";

  home.file.".zshrc".source =
    config.lib.file.mkOutOfStoreSymlink "${config.home.homeDirectory}/nix-config/dotfiles/zsh/.zshrc";
  xdg.configFile."starship.toml".source =
    config.lib.file.mkOutOfStoreSymlink "${config.home.homeDirectory}/nix-config/dotfiles/starship/starship.toml";
  xdg.configFile."bat/config".source =
    config.lib.file.mkOutOfStoreSymlink "${config.home.homeDirectory}/nix-config/dotfiles/bat/config";

  # Whole nvim dir symlinked live (raw Lua, portable to Arch). lazy.nvim installs
  # plugins into ~/.local/share/nvim, and lazy-lock.json lands back in the repo.
  xdg.configFile."nvim".source =
    config.lib.file.mkOutOfStoreSymlink "${config.home.homeDirectory}/nix-config/dotfiles/nvim";

  # RStudio: start R in ~ instead of RStudio's read-only app folder in the Nix store.
  # With empty prefs, R's working dir was .../rstudio/resources/app — so .Rhistory
  # failed to save and read.csv("data.csv") looked in the wrong place. RStudio owns
  # this JSON (it writes your prefs into it), so we MERGE one key rather than symlink
  # the file; `//=` only fills it when unset, so a directory you pick in Tools >
  # Global Options still wins.
  home.activation.rstudioWorkingDir = lib.hm.dag.entryAfter [ "writeBoundary" ] ''
    prefs="${config.xdg.configHome}/rstudio/rstudio-prefs.json"
    if [[ ! -v DRY_RUN ]]; then
      mkdir -p "$(dirname "$prefs")"
      [ -s "$prefs" ] || echo '{}' > "$prefs"
      ${pkgs.jq}/bin/jq '.initial_working_directory //= "~"' "$prefs" > "$prefs.tmp" \
        && mv "$prefs.tmp" "$prefs"
    fi
  '';
}
