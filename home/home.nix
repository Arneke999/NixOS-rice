{ config, pkgs, ... }:

{
  home.username = "lain";
  home.homeDirectory = "/home/lain";
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
    mako
    eww
    jq
    brightnessctl
    neovim
    libnotify
    adw-gtk3
    papirus-icon-theme
    bibata-cursors
    inter
  ];

  fonts.fontconfig.enable = true;

  home.sessionVariables = {
    XCURSOR_THEME = "Bibata-Modern-Classic";
    XCURSOR_SIZE = "24";
  };

  # Out-of-store symlinks: live repo files (hot-reload + matugen can write them).
  xdg.configFile."niri/config.kdl".source =
    config.lib.file.mkOutOfStoreSymlink "/home/lain/nix-config/dotfiles/niri/config.kdl";

  xdg.configFile."kitty/kitty.conf".source =
    config.lib.file.mkOutOfStoreSymlink "/home/lain/nix-config/dotfiles/kitty/kitty.conf";

  xdg.configFile."fuzzel/fuzzel.ini".source =
    config.lib.file.mkOutOfStoreSymlink "/home/lain/nix-config/dotfiles/fuzzel/fuzzel.ini";

  xdg.configFile."mako/config".source =
    config.lib.file.mkOutOfStoreSymlink "/home/lain/nix-config/dotfiles/mako/config";

  xdg.configFile."eww/eww.yuck".source =
    config.lib.file.mkOutOfStoreSymlink "/home/lain/nix-config/dotfiles/eww/eww.yuck";
  xdg.configFile."eww/eww.scss".source =
    config.lib.file.mkOutOfStoreSymlink "/home/lain/nix-config/dotfiles/eww/eww.scss";

  xdg.configFile."gtk-3.0/settings.ini".source =
    config.lib.file.mkOutOfStoreSymlink "/home/lain/nix-config/dotfiles/gtk/settings.ini";
  xdg.configFile."gtk-4.0/settings.ini".source =
    config.lib.file.mkOutOfStoreSymlink "/home/lain/nix-config/dotfiles/gtk/settings.ini";
}
