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
  ];

  # --- The rice: symlink raw dotfiles into ~/.config ---
  # Out-of-store symlink: points ~/.config/niri/config.kdl straight at the live
  # repo file (not a read-only store copy), so edits hot-reload without a rebuild
  # AND matugen can overwrite it at runtime. Absolute path required.
  xdg.configFile."niri/config.kdl".source =
    config.lib.file.mkOutOfStoreSymlink "/home/lain/nix-config/dotfiles/niri/config.kdl";
}
