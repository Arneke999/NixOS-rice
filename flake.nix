{
	description = "NixOS + Niri rice";
	inputs = {
		nixpkgs.url = "github:nixos/nixpkgs/nixos-unstable";
		home-manager = {
			url = "github:nix-community/home-manager/master";
			inputs.nixpkgs.follows = "nixpkgs";
		
			};
		niri.url = "github:sodiboo/niri-flake";
		};
	
	outputs = { self, nixpkgs, home-manager, niri, ... }@inputs:
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
				niri.nixosModules.niri
				home-manager.nixosModules.home-manager
				{
					home-manager.useGlobalPkgs = true;
					home-manager.useUserPackages = true;
					home-manager.extraSpecialArgs = { inherit username; };
					home-manager.users.${username} = import ./home/home.nix;
				}
			];
		};
	};
}
