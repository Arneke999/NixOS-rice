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
    brightnessctl
    swaynotificationcenter   # swaync — animated notifications + notification center
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
    XCURSOR_SIZE = "24";
  };

  # Out-of-store symlinks: live repo files (hot-reload + matugen can write them).
  xdg.configFile."niri/config.kdl".source =
    config.lib.file.mkOutOfStoreSymlink "${config.home.homeDirectory}/nix-config/dotfiles/niri/config.kdl";

  xdg.configFile."kitty/kitty.conf".source =
    config.lib.file.mkOutOfStoreSymlink "${config.home.homeDirectory}/nix-config/dotfiles/kitty/kitty.conf";

  xdg.configFile."fuzzel/fuzzel.ini".source =
    config.lib.file.mkOutOfStoreSymlink "${config.home.homeDirectory}/nix-config/dotfiles/fuzzel/fuzzel.ini";

  xdg.configFile."swaync/config.json".source =
    config.lib.file.mkOutOfStoreSymlink "${config.home.homeDirectory}/nix-config/dotfiles/swaync/config.json";
  xdg.configFile."swaync/style.css".source =
    config.lib.file.mkOutOfStoreSymlink "${config.home.homeDirectory}/nix-config/dotfiles/swaync/style.css";

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
