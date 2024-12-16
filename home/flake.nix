{
	description = "Development Environment";
	outputs = { self, nixpkgs } : {
		devShell."aarch64-linux" = 
			let pkgs = nixpkgs.legacyPackages."aarch64-linux";
			in pkgs.mkShell {
				buildInputs = [ pkgs.sbcl ];
			};
	};
}
