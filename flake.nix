{
	description = "NixOS + Hyprland rice";
	inputs = {
		nixpkgs.url = "github:nixos/nixpkgs/nixos-unstable";
    nix-claude-code.url = "github:ryoppippi/nix-claude-code";
    sops-nix.url = "github:Mic92/sops-nix";
    brave-previews.url = "github:jdcodes28/brave-browser-flake";
    brave-previews.inputs.nixpkgs.follows = "nixpkgs";
    # RStudio only, pinned to the 2026-09-23 nixpkgs (same RStudio 2026.09.0+174).
    # Newer unstable builds it against an updated Boost and the link fails
    # (undefined reference to boost::urls::grammar::detail::condition_cat), and
    # there's no cached build, so a rebuild compiled it for ages and then failed.
    # Used in home/home.nix. Drop both once `nix build nixpkgs#rstudio` works again.
    nixpkgs-rstudio.url = "github:nixos/nixpkgs/4975466d324710c576dc11ad614684e6bd8cad8e";
		home-manager = {
			url = "github:nix-community/home-manager/master";
			inputs.nixpkgs.follows = "nixpkgs";
			};
		};

	outputs = { self, nixpkgs, home-manager, sops-nix, brave-previews, ... }@inputs:
	let
		# ── Single source of truth ─────────────────────────────────────────
		# Change this one line (or set it via install.sh) to rename the user.
		# Everything else (home dir, symlinks, account) derives from it.
		username = "lain";
	in {
		nixosConfigurations.nixos = nixpkgs.lib.nixosSystem {
			system = "x86_64-linux";
			specialArgs = { inherit inputs username; };
			modules = [
				./hosts/nixos/configuration.nix
				home-manager.nixosModules.home-manager
        sops-nix.nixosModules.sops
				{
					home-manager.useGlobalPkgs = true;
					home-manager.useUserPackages = true;
					home-manager.extraSpecialArgs = { inherit inputs username; };
					home-manager.users.${username} = import ./home/home.nix;
				}
        brave-previews.nixosModules.default
        {
          programs.brave-origin-nightly = {
            enable = true;
            extensions = [
              "cjpalhdlnbpafiamejdnhcphjbkeiagm" # uBlock Origin
            ];
          };
        }
      ];
		};
	};
}
