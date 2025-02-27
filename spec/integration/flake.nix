{
  description = "SpecForge - Rails development environment";

  inputs = {
    nixpkgs.url = "github:nixos/nixpkgs/nixos-unstable";
    flake-utils.url = "github:numtide/flake-utils";
  };

  outputs = { self, nixpkgs, flake-utils }:
    flake-utils.lib.eachDefaultSystem (system:
      let
        pkgs = import nixpkgs {
          inherit system;
          config.allowUnfree = true;
        };

        db_user = "spec_forge";
        db_pass = "password12345";
      in
      {
        devShells.default = pkgs.mkShell {
          buildInputs = with pkgs; [
            (ruby_3_3.override {
              jemallocSupport = true;
              docSupport = false;
            })

            (with ruby_3_3.gems; [
              htmlbeautifier
            ])

            nodejs_22
            yarn

            # Database
            postgresql_17

            # Build dependencies
            pkg-config
            openssl
            libyaml
            zlib
            libxml2
            libxslt
            shared-mime-info
          ];

          shellHook = ''
            export LANG=C.UTF-8

            # Ruby/Rails related
            export BUNDLE_PATH=vendor/bundle
            export GEM_HOME=$PWD/vendor/bundle
            export PATH=$GEM_HOME/bin:$PATH

            # Postgres related
            export PGDATA=$PWD/tmp/postgres
            export POSTGRES_INITDB_ARGS="--encoding=UTF8 --locale=C"

            # Node/Vite related
            export PATH=$PWD/node_modules/.bin:$PATH

            # Creating the user
            if ! psql postgres -tAc "SELECT 1 FROM pg_roles WHERE rolname='${db_user}'" | grep -q 1; then
              echo "Creating database user ${db_user}..."
              psql postgres -c "CREATE USER ${db_user} WITH SUPERUSER PASSWORD '${db_pass}';"
            fi
          '';
        };
      }
    );
}
