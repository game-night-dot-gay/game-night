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

      packages.game-night-docker = pkgs.dockerTools.buildLayeredImage {
        name = "game-night";
        tag = "0.1.0";
        contents = [
          pkgs.bash pkgs.coreutils
        ];

        config = {
          Env = [
            "VUE_BUNDLE=${packages.game-night-frontend}"
            "RUST_LOG=info,game_night=debug"
          ];
          Cmd = [ "${packages.game-night-backend}/bin/game-night" ];
          WorkingDir = "/app";
        };
      };

      defaultPackage = packages.game-night-docker;


      apps.game-night-backend = utils.lib.mkApp {
        drv = packages.game-night-backend;
        exePath = "/bin/game-night";
      };

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
          sqlx-cli

          # Typescript / Frontend
          nodejs
          nodePackages.npm
          nodePackages.yarn
          nodePackages.vue-cli

          # Infrastructure
          tfswitch
          packer

        ];

        RUST_SRC_PATH = "${pkgs.rust.packages.stable.rustPlatform.rustLibSrc}";
      };
    });
}
