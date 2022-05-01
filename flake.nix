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
      defaultPackage = packages.game-night-backend;

      devShell = pkgs.mkShell {
        nativeBuildInputs = with pkgs; [
          # general
          just

          # rust / backend
          cargo
          cargo-edit
          cargo-outdated
          clippy
          rustc
          rustfmt
          rust-analyzer
        ];

        RUST_SRC_PATH = "${pkgs.rust.packages.stable.rustPlatform.rustLibSrc}";
      };
    });
}
