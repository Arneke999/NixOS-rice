# Edit this configuration file to define what should be installed on
# your system. Help is available in the configuration.nix(5) man page, on
# https://search.nixos.org/options and in the NixOS manual (`nixos-help`).

{ config, lib, pkgs, username, ... }:

let
  # SDDM greeter theme: sddm-astronaut (Qt6/QML) themed to the rice — near-black
  # surfaces, pink accents, the lain wallpaper blurred + dimmed. Colours live here;
  # it's un-previewable until the greeter renders at boot, so iterate from there.
  # Keys are the theme's own (PascalCase) options, written into its [General] conf.
  sddm-astronaut = pkgs.sddm-astronaut.override {
    embeddedTheme = "astronaut";
    themeConfig = {
      Background = "${../../wallpapers/lain.jpg}";
      CropBackground = true;
      DimBackground = "0.45";
      FullBlur = true;
      Blur = "1.7";
      ScreenPadding = "0";
      Font = "JetBrainsMono Nerd Font";
      FormPosition = "center";
      HaveFormBackground = true;
      HideVirtualKeyboard = true;
      PasswordFocus = true;
      # Near-black surfaces.
      BackgroundColor = "#0a0a0b";
      FormBackgroundColor = "#0f0f11";
      DimBackgroundColor = "#0a0a0b";
      # Text.
      HeaderTextColor = "#cdd6f4";
      DateTextColor = "#a6adc8";
      TimeTextColor = "#cdd6f4";
      PlaceholderTextColor = "#a6adc8";
      # Input fields (pink icons).
      LoginFieldBackgroundColor = "#17171a";
      PasswordFieldBackgroundColor = "#17171a";
      LoginFieldTextColor = "#cdd6f4";
      PasswordFieldTextColor = "#cdd6f4";
      UserIconColor = "#f5c2e7";
      PasswordIconColor = "#f5c2e7";
      HoverUserIconColor = "#f5e0dc";
      HoverPasswordIconColor = "#f5e0dc";
      # Login button = pink; power icons muted.
      LoginButtonBackgroundColor = "#f5c2e7";
      LoginButtonTextColor = "#0f0f11";
      SystemButtonsIconsColor = "#a6adc8";
      # Highlights + dropdowns (session / user pickers).
      HighlightTextColor = "#0f0f11";
      HighlightBackgroundColor = "#f5c2e7";
      HighlightBorderColor = "#f5c2e7";
      DropdownBackgroundColor = "#0f0f11";
      DropdownTextColor = "#cdd6f4";
      DropdownSelectedBackgroundColor = "#f5c2e7";
      WarningColor = "#f38ba8";
    };
  };
in
{
  imports =
    [ # Include the results of the hardware scan.
      ./hardware-configuration.nix
    ];

  nix.settings.experimental-features = [ "nix-command" "flakes" ];

  # Use the systemd-boot EFI boot loader.
  boot.loader.systemd-boot.enable = false;
  boot.loader.efi.canTouchEfiVariables = true;
  boot.loader.grub = {
    enable = true;
    efiSupport = true;
    device = "nodev";
    useOSProber = true;
    };

  # Boot splash: the Lain theme (near-black + pink wired motif). Texture is kept
  # restrained here; the heavier CRT look lives on the hyprlock lockscreen.
  # The theme is a raw plymouth script in dotfiles/plymouth/lain, wrapped into a
  # store package so NixOS can install it (its .plymouth ImageDir/ScriptFile need
  # absolute store paths, sed'd in here). The boot MENU is left visible (default
  # timeout) so rollback stays reachable.
  boot.plymouth = {
    enable = true;
    theme = "lain";
    themePackages = [
      (pkgs.runCommand "lain-plymouth-theme" { } ''
        dir=$out/share/plymouth/themes/lain
        mkdir -p "$dir"
        cp ${../../dotfiles/plymouth/lain}/lain.script "$dir/"
        cp ${../../dotfiles/plymouth/lain}/lain.plymouth "$dir/"
        substituteInPlace "$dir/lain.plymouth" --replace "@THEMEDIR@" "$dir"
      '')
    ];
  };
  # Quiet the kernel/initrd log spam so the splash reads clean.
  boot.consoleLogLevel = 0;
  boot.initrd.verbose = false;
  # i915.enable_psr=0 disables Panel Self-Refresh. The kernel logs "Selective fetch
  # area calculation failed in pipe A" — a PSR2 selective-fetch bug on this Arrow Lake
  # eDP panel — which reads as stuttery, ~30fps animations. Disabling PSR trades a
  # little idle battery for smooth motion. (Middle ground if power matters later:
  # i915.enable_psr=1, i.e. PSR1 only, no PSR2 selective fetch.)
  boot.kernelParams = [ "quiet" "splash" "loglevel=3" "rd.udev.log_level=3" "i915.enable_psr=0" ];

  networking.hostName = "nixos"; # Define your hostname.

  # Configure network connections interactively with nmcli or nmtui.
  networking.networkmanager.enable = true;

  # Set your time zone.
  time.timeZone = "Europe/Brussels";

  # Configure network proxy if necessary
  # networking.proxy.default = "http://user:password@proxy:port/";
  # networking.proxy.noProxy = "127.0.0.1,localhost,internal.domain";

  # Select internationalisation properties.
  # i18n.defaultLocale = "en_US.UTF-8";
  # console = {
  #   font = "Lat2-Terminus16";
  #   keyMap = "us";
  #   useXkbConfig = true; # use xkb.options in tty.
  # };
  
  #Enable clipboard sharing in virt-manager
  services.spice-vdagentd.enable = true;

  #Enable SSH
  services.openssh.enable = true;

  # Hyprland session (dynamic tiling). Built into nixpkgs — also pulls in the
  # Hyprland xdg-desktop-portal, so screenshare/file-picker work.
  programs.hyprland.enable = true;

  # VM workaround: this machine's virtio-gpu rejects atomic modesets for any mode
  # other than the current one ("atomic drm request: failed to commit: Invalid
  # argument"), so Hyprland can't set 1920x1200. AQ_NO_ATOMIC makes aquamarine use
  # the legacy DRM interface, which the virtual GPU accepts. NixOS-machine-only —
  # it's not synced to the Arch laptop, where atomic modeset is fine on real hw.
  # Set here for manual/shell launches; also inlined in the greetd command below,
  # since a greetd-spawned session doesn't source the shell profile.
  # environment.sessionVariables.AQ_NO_ATOMIC = "1";

  # Boot login: SDDM (Qt6) with the sddm-astronaut theme, themed to the rice via the
  # `sddm-astronaut` binding at the top of this file. Replaced ReGreet — libadwaita
  # capped how far that greeter could be pushed; SDDM's Qt6/QML theme matches the
  # Lain look (blurred wallpaper, big clock, pink accents) properly. Still a REAL
  # pre-session login (authenticates before Hyprland starts) — the security boundary
  # we need on an unencrypted drive. hyprlock stays for idle-lock (hypridle) + the
  # manual Super+Alt+L bind.
  # The greeter runs on WAYLAND, not X11. First attempt used an X11 greeter and it
  # FROZE after auth: on the VT switch to the Hyprland session the X server never
  # cleanly released DRM master, so Hyprland never started, and the X greeter then
  # SIGABRT'd in its xcb platform init (`init_platform` → qFatal). A Wayland greeter
  # hands DRM off cleanly to a Wayland session — the exact path ReGreet/greetd used
  # to work. (No services.xserver needed; XWayland for apps comes from Hyprland.)
  services.displayManager.sddm = {
    enable = true;
    wayland.enable = true;             # THE fix — Wayland greeter, clean DRM handoff
    package = pkgs.kdePackages.sddm;   # Qt6 SDDM — the theme is Qt6/QML
    theme = "sddm-astronaut-theme";
    extraPackages = [ sddm-astronaut ];
    # The greeter runs as the `sddm` user under weston, so the home-session
    # XCURSOR_THEME never reaches it → no visible pointer (had to Tab around).
    # SDDM exports these to the greeter's cursor; the theme itself is on the system
    # profile below (bibata-cursors) so weston can find it in the icon search path.
    settings.Theme = {
      CursorTheme = "Bibata-Modern-Classic";
      CursorSize = 24;
    };
  };
  # Default to the plain Hyprland session (start-hyprland — the launch path ReGreet
  # used successfully), NOT the uwsm-managed one, to avoid a second variable.
  services.displayManager.defaultSession = "hyprland";

  # ── Power management (laptop): TLP + thermald ────────────────────────────────
  # Max battery WITHOUT visible perf loss: full turbo + performance EPP on AC; on
  # battery drop EPP to balance_power and lean on the "invisible" savings (PCIe
  # ASPM, runtime PM, platform low-power) but KEEP turbo so bursts stay instant.
  # intel_pstate "powersave" still scales to max under load — not a fixed-low clock.
  services.power-profiles-daemon.enable = false;   # must be off — conflicts with TLP
  services.thermald.enable = true;                 # Intel thermal daemon (anti-throttle)
  services.tlp = {
    enable = true;
    settings = {
      CPU_SCALING_GOVERNOR_ON_AC    = "performance";
      CPU_SCALING_GOVERNOR_ON_BAT   = "powersave";
      CPU_ENERGY_PERF_POLICY_ON_AC  = "performance";
      CPU_ENERGY_PERF_POLICY_ON_BAT = "balance_power";
      CPU_BOOST_ON_AC  = 1;
      CPU_BOOST_ON_BAT = 1;               # keep turbo on battery → no visible perf loss
      PLATFORM_PROFILE_ON_AC  = "performance";
      PLATFORM_PROFILE_ON_BAT = "low-power";
      PCIE_ASPM_ON_BAT  = "powersupersave";
      RUNTIME_PM_ON_BAT = "auto";
      USB_AUTOSUSPEND = 1;
      # Optional Li-ion longevity (uncomment if the EC supports charge limits):
      # START_CHARGE_THRESH_BAT0 = 75;
      # STOP_CHARGE_THRESH_BAT0  = 80;
    };
  };

  # Expose ONLY the plain Hyprland session (Exec = start-hyprland), NOT the
  # `hyprland-uwsm.desktop` the hyprland package ALSO ships. That UWSM session runs
  # `uwsm start`, which needs UWSM's systemd user units — but programs.uwsm.enable is
  # false, so it fails ("wayland-session-bindpid@… exit 5") → black screen after login.
  # The plain start-hyprland is exactly what ReGreet launched successfully. Session
  # packages must declare passthru.providedSessions, so we wrap a one-file copy.
  services.displayManager.sessionPackages = [
    (pkgs.runCommand "hyprland-plain-session" {
      passthru.providedSessions = [ "hyprland" ];
    } ''
      mkdir -p "$out/share/wayland-sessions"
      cp ${config.programs.hyprland.package}/share/wayland-sessions/hyprland.desktop \
         "$out/share/wayland-sessions/"
    '')
  ];

  # Zsh as the login shell (adds it to /etc/shells, sets up /etc/zshrc).
  # The actual interactive config is the raw ~/.zshrc symlinked by Home Manager.
  programs.zsh.enable = true;
  # Load these via /etc/zshrc with the correct store paths (nixpkgs packages them
  # inconsistently, so path-probing in ~/.zshrc is unreliable on NixOS). The
  # ~/.zshrc keeps a guarded fallback that sources them on Arch.
  programs.zsh.autosuggestions.enable = true;
  programs.zsh.syntaxHighlighting.enable = true;

  # Keep the sudo password cached for 15 min (default is 5) so you re-enter less.
  security.sudo.extraConfig = ''
    Defaults timestamp_timeout=15
  '';

  # hyprlock authenticates via PAM — without this service it can't verify your
  # password and you'd be stuck on the lockscreen (escape hatch: a TTY).
  security.pam.services.hyprlock = { };
  
  #Allow unfree packages
  nixpkgs.config.allowUnfree = true;

  # Bluetooth (provides bluetoothctl; eww bar has a toggle widget).
  hardware.bluetooth.enable = true;
  hardware.bluetooth.powerOnBoot = true;

  # Audio
  security.rtkit.enable = true;
  services.pipewire = {
    enable = true;
    alsa.enable = true;
    alsa.support32Bit = true;
    pulse.enable = true;
  };

  # Enable the X11 windowing system.
  # services.xserver.enable = true;

  

  # Configure keymap in X11
  # services.xserver.xkb.layout = "us";
  # services.xserver.xkb.options = "eurosign:e,caps:escape";

  # Enable CUPS to print documents.
  # services.printing.enable = true;

  # Enable sound.
  # services.pulseaudio.enable = true;
  # OR
  # services.pipewire = {
  #   enable = true;
  #   pulse.enable = true;
  # };

  # Enable touchpad support (enabled default in most desktopManager).
  # services.libinput.enable = true;

  # Define a user account. Don't forget to set a password with ‘passwd’.
  users.users.${username} = {
     isNormalUser = true;
     shell = pkgs.zsh;
     extraGroups = [ "wheel" "networkmanager" ]; # Enable ‘sudo’ for the user.
     # Login + sudo password. The HASH lives in a file OUTSIDE this repo
     # (root-only, /etc/nixos-secrets/password) so it never lands in the PUBLIC
     # GitHub repo. Only this path is committed — the secret is not.
     #   Create/rotate it with:  mkpasswd -m sha-512 | sudo tee /etc/nixos-secrets/password
     #   (install.sh seeds it for a fresh clone.)
     # NEVER use inline `hashedPassword = "$6$..."` here — that would leak it again.
     hashedPasswordFile = "/etc/nixos-secrets/password";
     packages = with pkgs; [
       tree 
       git
       vscodium
     ];
   };

  # programs.firefox.enable = true;
  
  xdg.portal.config.common."org.freedesktop.impl.portal.FileChooser" = "gnome";

  # List packages installed in system profile.
  # You can use https://search.nixos.org/ to find more packages (and options).
  environment.systemPackages = with pkgs; [
    vim # Do not forget to add an editor to edit configuration.nix! The Nano editor is also installed by default.
    wget
    xdg-user-dirs
    bluez # bluetoothctl for the eww bluetooth widget
    sddm-astronaut # SDDM greeter theme (also in sddm.extraPackages; here so it's on the system profile)
    bibata-cursors # cursor theme for the SDDM greeter (matches the home-session cursor)
    spotify
  ];

  # Some programs need SUID wrappers, can be configured further or are
  # started in user sessions.
  # programs.mtr.enable = true;
  # programs.gnupg.agent = {
  #   enable = true;
  #   enableSSHSupport = true;
  # };

  # List services that you want to enable:

  # Enable the OpenSSH daemon.
  # services.openssh.enable = true;

  # Open ports in the firewall.
  # networking.firewall.allowedTCPPorts = [ ... ];
  # networking.firewall.allowedUDPPorts = [ ... ];
  # Or disable the firewall altogether.
  # networking.firewall.enable = false;

  # Copy the NixOS configuration file and link it from the resulting system
  # (/run/current-system/configuration.nix). This is useful in case you
  # accidentally delete configuration.nix.
  # system.copySystemConfiguration = true;

  # This option defines the first version of NixOS you have installed on this particular machine,
  # and is used to maintain compatibility with application data (e.g. databases) created on older NixOS versions.
  #
  # Most users should NEVER change this value after the initial install, for any reason,
  # even if you've upgraded your system to a new NixOS release.
  #
  # This value does NOT affect the Nixpkgs version your packages and OS are pulled from,
  # so changing it will NOT upgrade your system - see https://nixos.org/manual/nixos/stable/#sec-upgrading for how
  # to actually do that.
  #
  # This value being lower than the current NixOS release does NOT mean your system is
  # out of date, out of support, or vulnerable.
  #
  # Do NOT change this value unless you have manually inspected all the changes it would make to your configuration,
  # and migrated your data accordingly.
  #
  # For more information, see `man configuration.nix` or https://nixos.org/manual/nixos/stable/options#opt-system.stateVersion .
  system.stateVersion = "26.05"; # Did you read the comment?

}

