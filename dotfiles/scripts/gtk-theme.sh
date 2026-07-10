#!/usr/bin/env bash
# Apply dark GTK / libadwaita prefs via dconf (no gsettings/schemas needed).
dconf write /org/gnome/desktop/interface/color-scheme "'prefer-dark'"
dconf write /org/gnome/desktop/interface/gtk-theme    "'adw-gtk3-dark'"
dconf write /org/gnome/desktop/interface/icon-theme   "'Papirus-Dark'"
dconf write /org/gnome/desktop/interface/cursor-theme "'Bibata-Modern-Classic'"
dconf write /org/gnome/desktop/interface/cursor-size  24
