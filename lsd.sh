#!/usr/bin/env -S -- bash -Eeu -O dotglob -O nullglob -O extglob -O failglob -O globstar

set -o pipefail

cd -- "${0%/*}"

HEAD=1
git log --diff-filter=D --name-only --pretty='format:%h' -z | while read -d '' -r LINE; do
  if [[ -z "$LINE" ]]; then
    HEAD=1
    continue
  fi
  if ((HEAD)); then
    SHA="${LINE%%$'\n'*}"
    LINE="${LINE#*$'\n'}"
    HEAD=0
  fi
  printf -- '%s\0' "$SHA^:$LINE"
done | xargs -r -0 -n 1 -- git show | gpg --encrypt --armor
