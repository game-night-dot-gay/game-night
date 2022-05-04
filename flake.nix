{
  description = "Game Night";

  inputs = {
    utils.url = "github:numtide/flake-utils";
    naersk.url = "github:nmattia/naersk";
  };

  outputs = { self, nixpkgs, utils, naersk }:
    utils.lib.eachDefaultSystem (system: let
      pkgs = nixpkgs.legacyPackages."${system}";
      naersk-lib = naersk.lib."${system}";
    in rec {
      packages.game-night-backend = naersk-lib.buildPackage {
        pname = "game-night-backend";
        root = ./backend;
        doCheck = true;
      };

      packages.game-night-frontend = pkgs.mkYarnPackage {
        pname = "game-night-frontend";
        src = ./frontend;

        # Create a node modules folder that is writable based on the downloaded dependencies
        configurePhase = ''
          cp -r $node_modules node_modules
          chmod -R 755 node_modules;
        '';

        # run the vue-cli-service build in offline mode to avoid pull dependencies
        buildPhase = ''
          yarn run --offline build
        '';

        # copy the built sources into the output folder
        installPhase = ''
          cp -r dist/  $out
        '';

        # do not attempt to build distribution bundles
        distPhase = ''
          true
        '';
      };

      defaultPackage = packages.game-night-backend;

      devShell = pkgs.mkShell {
        nativeBuildInputs = with pkgs; [
          # General
          just

          # Rust / Backend
          cargo
          cargo-edit
          cargo-outdated
          clippy
          rustc
          rustfmt
          rust-analyzer

          # TypeScript / Frontend
          yarn
        ];

        RUST_SRC_PATH = "${pkgs.rust.packages.stable.rustPlatform.rustLibSrc}";
      };
    });
}
