#!/usr/bin/env -S -- bash -Eeuo pipefail -O dotglob -O nullglob -O extglob -O failglob -O globstar
#=
set -x
JULIA_DEPOT_PATH="$(mktemp)"
export -- JULIA_DEPOT_PATH
exec -- julia "$0" "$@"
=#

cd(@__DIR__)
print("ECHO :: VIA -- $(@__FILE__)")
