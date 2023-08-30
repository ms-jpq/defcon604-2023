#!/usr/bin/env -S -- bash -Eeu -O dotglob -O nullglob -O extglob -O failglob -O globstar

set -o pipefail

SH="$PWD/$0"
cd -- "${0%/*}"

printf -- '%s\n' "HELO :: VIA -- ${0##*/}"
bat -- "$SH"
