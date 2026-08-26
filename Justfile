set shell := ["bash", "-eu", "-o", "pipefail", "-c"]

export ACCEL_OS := justfile_directory()

alias c := check

default:
  @just --list

fmt:
  ./scripts/format-emacs
  npm run fmt

fmt-check:
  ./scripts/format-emacs --check
  npm run fmt:check

typecheck:
  ./node_modules/.bin/tsc --project scripts/tsconfig.json --noEmit
  npm run typecheck

lint:
  npm run lint

test:
  node --test scripts/*.test.ts
  npm run test

check-completions:
  node scripts/check-completions.ts

check-host-config:
  node scripts/check-host-config.ts

check-emacs:
  ./scripts/check-emacs

doctor:
  node scripts/doctor.ts

check: check-completions check-host-config check-emacs fmt-check lint typecheck test
