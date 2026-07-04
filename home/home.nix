{ config, pkgs, ... }:

{
  home.username = "lain";
  home.homeDirectory = "/home/lain";
  home.stateVersion = "26.05";   # <-- match system.stateVersion in configuration.nix

  home.packages = with pkgs; [
    kitty
  ];

  # --- The rice: symlink raw dotfiles into ~/.config ---
  xdg.configFile."niri/config.kdl".source = ../dotfiles/niri/config.kdl;
}
