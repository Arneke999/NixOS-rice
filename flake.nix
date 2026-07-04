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
	
	outputs = { self, nixpkgs, home-manager, niri, ... }@inputs: {
		nixosConfigurations.nixos = nixpkgs.lib.nixosSystem {
			system = "x86_64-linux";
			specialArgs = { inherit inputs;};
			modules = [
				./hosts/nixos/configuration.nix
				niri.nixosModules.niri
				#home-manager.nixosModules.home-manager
				#{
					#home-manager.useGlobalPkgs = true;
					#home-manager.useUserPackages = true;
					#home-manager.users.lain = import ./home/home.nix;
				#}
			];
		};
	};
}
