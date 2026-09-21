{
	description = "NixOS + Hyprland rice";
	inputs = {
		nixpkgs.url = "github:nixos/nixpkgs/nixos-unstable";
    nix-claude-code.url = "github:ryoppippi/nix-claude-code";
    sops-nix.url = "github:Mic92/sops-nix";
    brave-previews.url = "github:jdcodes28/brave-browser-flake";
    brave-previews.inputs.nixpkgs.follows = "nixpkgs";
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
					home-manager.extraSpecialArgs = { inherit username; };
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
