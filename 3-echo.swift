#!/usr/bin/env -S -- bash -Eeuo pipefail
// || swiftc -o "${TMPFILE:="$(mktemp)"}" -- "$0"; exec -a "$0" -- "$TMPFILE" "$@"

let arg0 = CommandLine.arguments.first!
print("ECHO :: VIA -- " + arg0)
