set dotenv-load
set export

_default:
  @just --list

build-backend:
  cd backend && cargo build --release

build-frontend:
  cd frontend && npm run build

build: build-backend build-frontend

build-and-run: build run-app

build-flake-backend:
  nix build .#game-night-backend

build-flake-frontend:
  nix build .#game-night-frontend

build-flake-docker:
  nix build .#game-night-docker
  docker load < result

run-app:
  APP_DOMAIN=localhost \
    FRONTEND_DIR={{justfile_directory()}}/frontend/dist \
    EMAIL_SENDER=noreply@gamenight.gay \
    RUST_LOG=debug,game_night=trace \
    {{justfile_directory()}}/backend/target/release/game-night

database-start:
  # ensure the data folder exists
  mkdir -p data
  docker run -d \
    --name game-night-db \
    -e POSTGRES_USER=postgres \
    -e POSTGRES_PASSWORD=postgres \
    -e POSTGRES_DB=game-night \
    -p 5432:5432 \
    -v {{justfile_directory()}}/data:/var/lib/postgresql/data \
    postgres:14.2

database-stop:
  docker stop game-night-db
  docker rm game-night-db

database-shell:
  docker exec -it game-night-db psql -U postgres game-night

database-create:
  sqlx database create

database-drop:
  sqlx database drop

database-migrate:
  cd backend && sqlx migrate run

database-create-migration name:
  cd backend && sqlx migrate add -r {{name}}

database-prepare-for-ci:
  cd backend && cargo sqlx prepare
