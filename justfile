set export := true
set dotenv-load := true

# --------------
# Internal Use
#      Or
# Documentation
# --------------
# Application

database := justfile_directory() + "server/database"
server := justfile_directory() + "/server"
client := justfile_directory() + "/client"
server_port := "8080"

# Deploy
deploy_host := env_var_or_default("DEPLOY_HOST", "NONE")

# Utils

replace := if os() == "linux" { "sed -i" } else { "sed -i '' -e" }

# Lists all availiable targets
default:
    just --list

[doc('Formats source code. Options = { "client" [Default], "server", "justfile" }')]
format source='client':
    #!/usr/bin/env bash
    set -euo pipefail
    t=$(echo {{ source }} | cut -f2 -d=)
    echo "Selected Target: $t"
    if [[ $t == "client" ]]; then
        zig fmt .
    elif [[ $t == "justfile" ]]; then
        just --fmt --unstable
    elif [[ $t == "server" ]]; then
        erlfmt -w $(find ./server/src/ -type f \( -iname \*.erl -o -iname \*.hrl \))
    else
        echo "No formating selected, skipping step..."
    fi

# ---------
# Database
# ---------

# Login into the local Database as `admin`
db:
    psql -U admin mmo

# Bootstraps the local nix-based postgres server
postgres:
    devenv up

# -------
# Client
# -------

client:
    cd client && zig build run

client-build:
    cd client && zig build

client-test:
    cd client && zig build test

client-build-ci:
    cd client && zig build -fsys=raylib

client-test-ci:
    cd client && zig build test -fsys=raylib

client-deps:
    cd client && nix run github:Cloudef/zig2nix#zon2nix -- build.zig.zon > zon-deps.nix

# --------
# Backend
# --------

build:
    cd server && rebar3 compile

# Fetches rebar3 dependencies, updates both the rebar and nix lockfiles
deps:
    cd server && rebar3 get-deps
    cd server && rebar3 nix lock

# Runs ther erlang server (inside the rebar shell)
server: build
    cd server && rebar3 shell

# Runs unit tests in the server
test:
    cd server && rebar3 do eunit, ct

# Migrates the DB (up)
db-up:
    ./server/database/migrate_up.sh

# Nukes the DB
db-down:
    ./server/database/migrate_down.sh

# Populate DB
db-input:
    ./server/database/migrate_input.sh

# Hard reset DB
db-reset: db-down db-up db-input

# --------
# Releases
# --------

# Create a prod release of the server
release: deps
    rebar3 as prod release

# Create a prod release (for nix) of the server
release-nix:
    rebar3 as prod tar

# ----------
# Deployment
# ----------

# Builds the deployment docker image with Nix
build-docker:
    nix build .#dockerImage

deploy:
    @echo "Attemping to deploy to: {{deploy_host}}"
    ./deploy.sh --deploy-host {{deploy_host}}
