{ config, pkgs, username, ... }:

{
  home.username = username;
  home.homeDirectory = "/home/${username}";
  home.stateVersion = "26.05";   # <-- match system.stateVersion in configuration.nix
  home.packages = with pkgs; [
    kitty
    matugen
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
    grim                     # screenshots (Print binds)
    slurp                    # region select for screenshots
    wl-clipboard             # wl-copy — screenshots to clipboard
    brightnessctl
    swaynotificationcenter   # swaync — animated notifications + notification center
    hyprlock                 # the Lain lockscreen (CRT shader, pink input)
    hypridle                 # idle -> lock (drives lock via logind for Niri)
    neovim
    # Neovim tooling (installed via Nix, NOT mason — mason binaries break on NixOS):
    lua-language-server   # lua_ls
    nixd                  # Nix LSP
    ripgrep               # telescope live-grep
    fd                    # telescope find-files
    gcc                   # compile treesitter parsers + fzf-native
    gnumake               # build telescope-fzf-native + LuaSnip jsregexp
    # Shell (zsh) + interactive tooling. Note: zsh-autosuggestions and
    # zsh-syntax-highlighting are provided by programs.zsh.* in configuration.nix
    # (loaded via /etc/zshrc), so they're not listed here.
    zsh
    starship              # prompt (matugen-themed)
    fzf                   # Ctrl-R history / Ctrl-T files
    eza                   # modern ls
    bat                   # cat with syntax highlighting
    libnotify
    adw-gtk3
    papirus-icon-theme
    bibata-cursors
    inter
  ];

  fonts.fontconfig.enable = true;

  home.sessionVariables = {
    XCURSOR_THEME = "Bibata-Modern-Classic";
    XCURSOR_SIZE = "20";
  };

  # Out-of-store symlinks: live repo files (hot-reload + matugen can write them).
  # hyprland.conf is matugen-generated from hyprland.conf.in (pink border tracks
  # the wallpaper). Hyprland's search path is ~/.config/hypr, so this drops in
  # alongside hyprlock/hypridle and is a straight copy to Arch.
  xdg.configFile."hypr/hyprland.conf".source =
    config.lib.file.mkOutOfStoreSymlink "${config.home.homeDirectory}/nix-config/dotfiles/hypr/hyprland.conf";

  xdg.configFile."kitty/kitty.conf".source =
    config.lib.file.mkOutOfStoreSymlink "${config.home.homeDirectory}/nix-config/dotfiles/kitty/kitty.conf";

  xdg.configFile."fuzzel/fuzzel.ini".source =
    config.lib.file.mkOutOfStoreSymlink "${config.home.homeDirectory}/nix-config/dotfiles/fuzzel/fuzzel.ini";

  xdg.configFile."swaync/config.json".source =
    config.lib.file.mkOutOfStoreSymlink "${config.home.homeDirectory}/nix-config/dotfiles/swaync/config.json";
  xdg.configFile."swaync/style.css".source =
    config.lib.file.mkOutOfStoreSymlink "${config.home.homeDirectory}/nix-config/dotfiles/swaync/style.css";

  # hyprlock + hypridle (kept in dotfiles/hypr/ — hyprlock's default search path
  # is ~/.config/hypr, so this is a straight copy to Arch). The .frag is the CRT
  # shader (static); hyprlock.conf is matugen-generated from hyprlock.conf.in.
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

  xdg.configFile."fastfetch/config.jsonc".source =
    config.lib.file.mkOutOfStoreSymlink "${config.home.homeDirectory}/nix-config/dotfiles/fastfetch/config.jsonc";

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
}
