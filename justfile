_default:
  @just --list

build-backend:
  cd backend && cargo build --release