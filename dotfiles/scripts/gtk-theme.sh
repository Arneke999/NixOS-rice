#!/usr/bin/env bash
# Apply dark GTK / libadwaita prefs via dconf (no gsettings/schemas needed).
dconf write /org/gnome/desktop/interface/color-scheme "'prefer-dark'"
dconf write /org/gnome/desktop/interface/gtk-theme    "'adw-gtk3-dark'"
dconf write /org/gnome/desktop/interface/icon-theme   "'Papirus-Dark'"
dconf write /org/gnome/desktop/interface/cursor-theme "'Bibata-Modern-Classic'"
dconf write /org/gnome/desktop/interface/cursor-size  24

# Extra polish for libadwaita apps (which ignore settings.ini): named pink
# accent, app fonts, crisp text rendering. No-ops on pre-GNOME-47 libadwaita.
dconf write /org/gnome/desktop/interface/accent-color        "'pink'"
dconf write /org/gnome/desktop/interface/font-name           "'Inter 10'"
dconf write /org/gnome/desktop/interface/monospace-font-name "'JetBrainsMono Nerd Font 10'"
dconf write /org/gnome/desktop/interface/font-antialiasing   "'grayscale'"
dconf write /org/gnome/desktop/interface/font-hinting        "'slight'"
