{
  description = "Ruby 3.2 development environment";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";
    flake-utils.url = "github:numtide/flake-utils";
    nixpkgs-ruby.url = "github:bobvanderlinden/nixpkgs-ruby";
    nixpkgs-ruby.inputs.nixpkgs.follows = "nixpkgs";
  };

  outputs =
    {
      self,
      nixpkgs,
      flake-utils,
      nixpkgs-ruby,
    }:
    flake-utils.lib.eachDefaultSystem (
      system:
      let
        pkgs = nixpkgs.legacyPackages.${system};
        ruby = nixpkgs-ruby.packages.${system}."ruby-3.2.9";
      in
      {
        devShells.default = pkgs.mkShell {
          buildInputs = with pkgs; [
            ruby

            # Dependencies for native gems
            pkg-config
            openssl
            readline
            zstd
            libyaml
          ];

          shellHook = ''
            export GEM_HOME="$PWD/vendor/bundle"
            export GEM_PATH="$GEM_HOME"
            export PATH="$GEM_HOME/bin:$PATH"

            echo "checking gems"
            bundle check || bundle install
          '';
        };
      }
    );
}
