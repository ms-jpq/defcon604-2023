#!/usr/bin/env -S -- lookatme --theme light

# Bash for Advanced Dummies

## about:me

```bash
> whoami
Wang, Hao

> whois
https://github.com/ms-jpq
```

---

## My Projects

### CLI

```bash
pip3 install -- gay

cowsay hello defcon | gay
```

```bash
brew install -- sad

find | sad systemd flamebait
```

### Vim

```
https://github.com/preservim/nerdtree -> https://github.com/ms-jpq/chadtree
https://github.com/neoclide/coc.nvim  -> https://github.com/ms-jpq/coq_nvim
```

---

## High Level Language

What is the building block?

### Haskell?

Functions

```haskell
functions . pointfree . compose
```

### Bash

Programs

```bash
program | program  | program
```

---

## Recursion

HTTP server

```bash
./1-http-server.sh
```

1. `$0` is the script's own name

2. `[[ -t 0 ]]` test of stdin connected to `tty`

3. HTTP clients don't care about `\r` carriage return

---

## Can't afford AWS lambda?

```systemd
[Socket]
Accept       = yes
```

```systemd
[Unit]
CollectMode    = inactive-or-failed
[Service]
Type           = oneshot
StandardInput  = socket
StandardOutput = socket
```

---

## Mutual Recursion

```bash
./2-git-ls-d.sh

cat -- ./2-git-ls-d.sh ./2-fzf-lr.sh
```

0. We do this all the time

1. `$SHELL` → ssh → `$SHELL`

2. - ASCII SEP, i.e. `\4`, `\0` etc

```bash
man -- ascii
cowsay hello defcon | gay | command -- cat -v
```

3. - `printf -- '%q '` quoting

```bash
printf -- '%q ' $'\n' '#$123' '\@!-_'
```

4. Never quote by hand

---

## Powershell

```ps1
# UTF16-LE
$pwsh = @"
...
"@
$argv = @(
  'powershell.exe'
  '-NoProfile'
  '-NonInteractive'
  '-WindowStyle', 'Hidden'
  '-EncodedCommand', [Convert]::ToBase64String([Text.Encoding]::Unicode.GetBytes($pwsh))
)
```

---

## X"00"

```bash
printf -- '%s\n' "$PATH"

./3-echo.cob

cat -- ./3-echo.cob
```

1. `cobol` calls into `c` `"getenv"`

2. `CString` can't contain `\0` → File paths can't contain `\0` either.

---

## More Comments

non sequitur

```bash
# Scripting in swift
./3-echo.swift

# Change JULIA_DEPOT_PATH to random location
./3-echo.jl

cat -- ./3-echo.swift ./3-echo.jl
```

---

## `-> | while | ->`

```bash
cat -- ./2-git-ls-d.sh

"${ARGV[@]}" | while read -d '' -r LINE; do
  if [[ -z "$LINE" ]]; then
    HEAD=1
    continue
  fi
  if ((HEAD)); then
    SHA_TIME="${LINE%%$'\n'*}"
    LINE="${LINE#*$'\n'}"
    HEAD=0
  fi
  printf -- '%s\n%s\0' "$SHA_TIME" "$LINE"
done | "${0%/*}/2-fzf-lr.sh" "$0"
```

1. Notice how the `while loop` act like a program

2. Almost all shell builtins act like programs

3. Branching is done via exit codes

```bash
[[ -x ./README.md ]] && printf -- '%s\n' $?

[[ -d ./README.md ]] || printf -- '%s\n' $?
```

---

## Do one thing

```bash
set -Eeu
set -o pipefail
```

1. exit `0` is success

2. exit `!0` is failure

```txt
command -- tree -- 4-pipeline
```

3. enforce using [shellcheck](https://www.shellcheck.net/)

4. `.shellcheckrc` `enable=all`

---

## autodie

```bash
if ! [[ -v RECUR ]]; then
  if RECUR=1 "$0" "$@"; then
    # success!
  else
    # failed!
  fi
fi
```

---

## Data type

Lines & Fields

```bash
# these comes by default on macOS
# apt install -- athena-jot rs

jot -r 100

jot -r 100 | rs 20 5
jot -r 100 | rs 5 20

jot -r 100 | rs 10 10 | sort -n -k 2
```

- `cut`, `awk`, `perl`, `ruby`, `numfmt`

- `$IFS`

---

## "$PATH"

`https://xkcd.com/927/`

```bash
./3-echo.cob | tr -- ':' '\n'
```

1. Every OS has 1 or more clipboards

2. I want to write a one that works over SSH connections

```bash
type -a -- pbcopy
# https://github.com/ms-jpq/isomorphic_copy
```

---

## Windows

Useful to share CI scripts

There is about 20 different bashes on Windows, mostly from `msys2 / cygwin` derivatives

```ps1
# Github CI
Get-Command -All -- bash
```

- `C:\Program Files\Git\bin\bash.exe`

- `C:\Windows\system32\bash.exe`

- `C:\Program Files\Git\usr\bin\bash.exe`

...

1. Convert between NT and UNIX paths using `cygpath`

---

## Don't have to write in bash

```bash
printf -- '%q\0' ./5-helo/* | xargs -0 -L1 -- time
```

---

## Slides / Scripts

[https://github.com/ms-jpq/defcon604-2023](https://github.com/ms-jpq/defcon604-2023)
