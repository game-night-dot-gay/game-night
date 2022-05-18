# Game Night

This project is intended to allow groups of friends to organize game nights.

## Goals

- People can invite new members to the group and admins can grant approval.
- People can host game nights with specific games in mind or a selection of options from everyone's boardgame libraries.
- People can express their dietary needs so that food plans accommodate everyone.
- Frequent, pre-planned boardgame nights make people not feel left out if they can't make a specific night.

## Local Development

For local development, [`just`](https://github.com/casey/just) is used to automate common workflows  (see [`justfile`](./justfile)).

### Configuration

#### SendGrid

For email to work for login links, you will need a SendGrid token. You can find generate a new one under [Settings > API Keys](https://app.sendgrid.com/settings/api_keys) and either add it to your environment as `EMAIL_TOKEN` when running the application or store it in `app_config.toml` under the key `email_token`.

### Development Tooling

#### Nix

If you are using [`nix`](https://nixos.org/), there is a [`nix` `flake`](./flake.nix) that defines a `devShell` environment with all of the necessary dependencies for development. [`direnv`](https://direnv.net/) is recommended to automatically apply this `devShell` when you are working in this directory.

#### Non-Nix

You'll want to install the following tools:

- [`just`](https://github.com/casey/just)
- [`cargo`, `clippy`, `rustfmt`, & `rust-analyzer` through `rustup`](https://rustup.rs/)
- [`sqlx-cli`](https://github.com/launchbadge/sqlx/blob/master/sqlx-cli/README.md)
- [`yarn`](https://yarnpkg.com/)
- [`vue-cli`](https://cli.vuejs.org/)
- [`tfswitch`](https://tfswitch.warrensbox.com/)
- [`packer`](https://www.packer.io/)

### Docker / Postman

The local development infrastructure is written to be compatible with both [Docker](https://www.docker.com/) and [Podman](https://podman.io/) when configured to [replace the `docker` command](https://podman.io/whatis.html).

### Workflows

#### Database

To get started with a local database, you'll want to:

1. `just database-start` to pull a PostgreSQL image and start a container
2. `just database-create` to initialize the `game-night-db`
3. `just database-migrate` to run the existing migrations
   - This is not needed, since the app runs migrations on startup, but is a good smoke test
4. `just database-shell` to get a `psql` session in the `game-night-db` to further smoke test

After making changes to the database via migrations, run `just database-prepare-for-ci` to re-generate the [`sqlx-data.json`](./backend/sqlx-data.json) file that ensures that the compile time checks of the SQL queries are up to date and correct.

#### Application

1. `just build-backend` to build a release version of the backend application
2. `just run-app` to start a local running instance that connects to the containerized PostgreSQL instance

## License

This software is licensed under the [BGDC License](https://twitter.com/scanlime/status/1304825753029107712).
