{
  description = "Ruby 3.4.2 development environment";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";
    flake-utils.url = "github:numtide/flake-utils";
  };

  outputs = { self, nixpkgs, flake-utils }:
    flake-utils.lib.eachDefaultSystem (system:
      let
        pkgs = nixpkgs.legacyPackages.${system};
      in
      {
        devShells.default = pkgs.mkShell {
          buildInputs = with pkgs; [
            (ruby_3_4.override {
              jemallocSupport = true;
              docSupport = false;
            })

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
