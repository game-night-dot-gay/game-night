{
  description = "Game Night";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";
    flake-utils.url = "github:numtide/flake-utils";

    crane = {
      url = "github:ipetkov/crane";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    rust-overlay = {
      url = "github:oxalica/rust-overlay";
      inputs = {
        nixpkgs.follows = "nixpkgs";
        flake-utils.follows = "flake-utils";
      };
    };
  };

  outputs = { self, nixpkgs, flake-utils, crane, rust-overlay, ... }:
    flake-utils.lib.eachDefaultSystem (system:
      let
        pkgs = import nixpkgs {
          inherit system;
          overlays = [ (import rust-overlay) ];
        };

        rustToolchain = pkgs.rust-bin.stable.latest.default.override {
          extensions = [ "rust-analyzer" "rust-src" ];
        };

        craneLib = (crane.mkLib pkgs).overrideToolchain rustToolchain;

        src = craneLib.cleanCargoSource (craneLib.path ./backend);

        commonArgs = {
          inherit src;

          pname = "game-night-backend";
          version = "0.1.0";

          nativeBuildInputs = [ pkgs.grpc-tools ];
        };

        cargoArtifacts = craneLib.buildDepsOnly commonArgs;

        game-night-backend = craneLib.buildPackage (commonArgs // {
          inherit cargoArtifacts;
        });

      in
      rec {
        checks = {
          inherit game-night-backend;

          clippy = craneLib.cargoClippy (commonArgs // {
            inherit cargoArtifacts;
          });

          doc = craneLib.cargoDoc (commonArgs // {
            inherit cargoArtifacts;
          });

          fmt = craneLib.cargoFmt (commonArgs // {
            inherit src;
          });
        };

        packages.game-night-backend = game-night-backend;

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

        packages.game-night-docker = pkgs.dockerTools.buildLayeredImage {
          name = "game-night";
          tag = "latest";
          contents = [
            pkgs.bash
            pkgs.coreutils
            pkgs.cacert
          ];

          config = {
            Env = [
              "FRONTEND_DIR=${packages.game-night-frontend}"
              "RUST_LOG=debug,h2::proto=warn,game_night=trace"
            ];
            Cmd = [ "${packages.game-night-backend}/bin/game-night" ];
            WorkingDir = "/app";
            ExposedPorts = { "2727" = { }; };
          };
        };

        packages.default = packages.game-night-docker;


        apps.game-night-backend = flake-utils.lib.mkApp {
          drv = packages.game-night-backend;
          exePath = "/bin/game-night";
        };

        apps.default = apps.game-night-backend;

        devShells.default = pkgs.mkShell {
          packages = with pkgs; [
            # General
            just

            # Rust / Backend
            rustToolchain
            cargo-edit
            cargo-outdated
            sqlx-cli

            # Build Dependencies
            grpc-tools

            # Typescript / Frontend
            nodejs
            nodePackages.npm
            nodePackages.yarn
            nodePackages.vue-cli

            # Infrastructure
            tfswitch
            packer

            # GitHub tooling
            gh

            # Nix
            nixpkgs-fmt
          ];
        };
      });
}
