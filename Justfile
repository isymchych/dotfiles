set shell := ["bash", "-eu", "-o", "pipefail", "-c"]

export ACCEL_OS := justfile_directory()

alias c := check

default:
  @just --list

fmt:
  npm run fmt

fmt-check:
  npm run fmt:check

typecheck:
  npm run typecheck

lint:
  npm run lint

test:
  npm run test

check:
  npm run check
