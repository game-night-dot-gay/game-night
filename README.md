# Game Night

This project is intended to allow groups of friends to organize game nights.

## Goals

- People can invite new members to the group and admins can grant approval.
- People can host game nights with specific games in mind or a selection of options from everyone's boardgame libraries.
- People can express their dietary needs so that food plans accommodate everyone.
- Frequent, pre-planned boardgame nights make people not feel left out if they can't make a specific night.

## Local Development

For local development, [`just`](https://github.com/casey/just) is used to automate common workflows  (see [`justfile`](./justfile)).

### Nix

If you are using [`nix`](https://nixos.org/), there is a [`nix` `flake`](./flake.nix) that defines a `devShell` environment with all of the necessary dependencies for development. [`direnv`](https://direnv.net/) is recommended to automatically apply this `devShell` when you are working in this directory.

### Non-Nix

You'll want to install the following tools:

- [`just`](https://github.com/casey/just)
- [`cargo`, `clippy`, `rustfmt`, & `rust-analyzer` through `rustup`](https://rustup.rs/)
- [`sqlx-cli`](https://github.com/launchbadge/sqlx/blob/master/sqlx-cli/README.md)
- [`yarn`](https://yarnpkg.com/)
- [`vue-cli`](https://cli.vuejs.org/)
- [`http-server`](https://www.npmjs.com/package/http-server)
- [`tfswitch`](https://tfswitch.warrensbox.com/)
- [`packer`](https://www.packer.io/)

## License

This software is licensed under the [BGDC License](https://twitter.com/scanlime/status/1304825753029107712).
