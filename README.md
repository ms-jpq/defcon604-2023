# Structured Shell Programming (Recursions, Lambdas, Functional Paradigms)

The proposition is simple: **`SHELL` is the most effective programming technique** you can learn, because it's based on **process composition**, it necessarily works at a **higher level** than say compared to Haskell.

All the code plus the original defcon604 slides are available at [my github](https://github.com/ms-jpq/defcon604-2023)

#### Haskell?

Building block: _Functions_

```haskell
functions . pointfree . compose
```

#### Shell

Building block: _Programs_

```bash
process1 | process2 | process3
```

My goals in this essay isn't to explore the quirks of the `SHELL` programming languages, of which there are many. Rather, this is a distillation of the useful **semantics of process composition**.

---

## Case Study: Recursive Bash HTTP Server

For pedagogical purposes, this is my favorite program. I will break down the _interesting bits_.

```bash
#!/usr/bin/env -S -- bash -Eeu -O dotglob -O nullglob -O extglob -O failglob -O globstar

set -o pipefail

ADDR='127.0.0.1'
PORT='8888'
if [[ -t 0 ]]; then
  printf -- '%q ' curl -- "http://$ADDR":"$PORT"
  printf -- '\n'
  exec -- socat TCP-LISTEN:"$PORT,bind=$ADDR",reuseaddr,fork EXEC:"$0"
fi

tee <<-'EOF'
HTTP/1.1 200 OK

EOF

printf -- '%s\n' 'HELO' >&2
exec -- cat -- "$0"
```

### `#!`: shebang

```bash
#!/usr/bin/env -S -- bash -Eeu -O dotglob -O nullglob -O extglob -O failglob -O globstar
```

- In UNIX systems, `#!` are the magic bytes at begining of files that denote executable scripts, and it leads to a path i.e. `/usr/bin/env` as the script interpreter. This is fairly well known.

- This isn't all that interesting, but it is underutilized that you pay pass arguments to the script interpreter as well. For example, passing in `perl -CAS` to enable greater unicode support.

### `[[ -t 0 ]]`: is stdin `(fd 0)` a terminal?

- The recursion here works by checking if the script is run from the terminal, if so, the script re-spawns itself under a child process of `socat`, in which it is no longer attached to the terminal.

- The terminal is actually a fairly important concept for in shell programming, as it is the `$SHELL` itself. It poses some **interesting questions**:

1.  - On `ASCII` and strings: How do you _delete_ a character from the terminal, if the terminal is **just another process**? Surely `stdin` is _append only_.

    - As it turns out, `ASCII` has multiple deletion characters: `BS` and `DEL`, what's better, it even has a `BEL ('\a')` character that will blink your terminal.

2.  - So are strings really just text? Or should we view them as _instruction streams_?

    - The latter mental model should prove more fruitful for shell programming.

### `printf -- '%q '`: What kind of format is `%q`?

Two things are true:

1.  Recursion is difficult without argument passing.

2.  It is difficult to manually quote arguments in `$SHELL` languages.

The solution:

`%q ` **quotes arguments** to `printf` such that they can **`SHELL` expand back to their logical identity**.

This feature is not unique to `bash` and `zsh`. We can examine a few more languages to reveal their idiosyncrasies:

- **Python**: The quoted string is the most legible of the bunch.

- **Ruby**: You can really see the `perl` heritage here, both in syntax and in library names.

```python
from shlex import join

print(join(("\n ", "#$123", r"\@!-_")))
# '
#  ' '#$123' '\@!-_'
```

```ruby
require 'shellwords'

puts %W[\n#{' '} \#$123 \\@!-_].map(&:shellescape).join ' '
# '
# '\  \#\$123 \\@\!-_
```

- **Bash**: Observe that the quoted string is **a single line**, unlike `python` and `ruby`. This is deliberate, since `bash` like other `$SHELL` languages is fundamentally **line / record oriented**. Line breaks carry special currency in `$SHELL`, and need to be used **judiciously**.

Note: this is _NOT POSIX compliant_, due to `$'<string>'` being a bash extension.

```bash
printf -- '%q ' $'\n ' '#$123' '\@!-_'
# $'\n'\  \#\$123 \\@\!-_
```

- **PowerShell**: Wow, such Microsoft, much `UTF16-LE`, very `BASE64`.

Note: For escaping in general, `printf -- %s "$STRING" | base64 -d | "$SHELL"` is never a bad strategy. Since `base64 -d` is fairly ubiquitous.

```ps1
# Must be UTF16-LE encoded
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

### `exec -- socat TCP-LISTEN:"$PORT,bind=$ADDR",reuseaddr,fork EXEC:"$0"`

Three 🐓 (birds) one 🗿 (line).

- **`exec --`, `EXEC:`**: "exec\*" family of _syscalls_: **replace** current process with new process:

  - As a consequence of this **short-circuiting** behavior, we can author syntactically valid multi-language scripts:

#### Julia

As long as they have `#` as part of the comment syntax.

```julia
#!/usr/bin/env -S -- bash -Eeuo pipefail -O dotglob -O nullglob -O extglob -O failglob -O globstar
#=
set -x
JULIA_DEPOT_PATH="$(mktemp)"
export -- JULIA_DEPOT_PATH
exec -- julia "$0" "$@"
=#

print(@__FILE__)
```

#### Rust

Some languages like Javascript or Rust, specifically allow `#!` shebang even if the `#` is not part of the comment syntax.

Often, they will have `//` as the comment start, and due to `POSIX` path normalization, we can use `//usr/bin/true;` as a **NOOP**, followed by the actual script.

```rust
#!/usr/bin/env -S -- bash -Eeuo pipefail
//usr/bin/true; rustc --edition=2021 -o "${T:="$(mktemp)"}" -- "$0" && exec -a "$0" -- "$T" "$0" "$@"

#![deny(clippy::all, clippy::cargo, clippy::pedantic)]

fn main() {
// make build.rs executable!
}
```

#### Swift

In `BASH` specifically, `exec -a '<arg0>'` is used to set the **first argument** of the new process. Which conventionally is the **name of the executable**. (even under NT!)

This enables the polyglot script to _pass-through_ `argv[0]`.

```swift
#!/usr/bin/env -S -- bash -Eeuo pipefail
//usr/bin/true; swiftc -o "${TMPFILE:="$(mktemp)"}" -- "$0" && exec -a "$0" -- "$TMPFILE" "$@"

let arg0 = CommandLine.arguments.first!
print(arg0)
```

- **`$0`**: `argv[0]` (first argument)

  - Conventionally `ARGV[0]` is always present.

  - This has two important implications:

    1. Since we invoke programs by their name, we can use `ARGV[0]` to **perform recursion** as well as dispatch multi-call binaries like busybox.

    2. For scripts, conventionally the name of the script just happens to be the **path to itself**. This allows scripts have **knowledge of their own location**, and access resources relative to itself.

- **`fork`**: `fork` is another _syscall_. It **duplicates** the current process. That is to imply, ⇒ **parallelism**.

  - Since `$SHELL` programming is fundamentally **process oriented**, `fork` is the basis for concurrency, rather than threads, or coroutines.

  - Without `,fork`, `socat` will terminate upon a single connection.

### `tee <<-'EOF'`

`tee<<-'EOF'` is a _here-doc_, it prints content between `EOF...EOF` to stdout. Notably, as a child of `socat`, bash's `/dev/stdout` (file) actually writes to the file descriptor of the **TCP socket** provisioned by `socat`.

- Recall the UNIX mantra: **everything is a file**, and that **files are commutable with other files**.

- Files and **file systems** is a recurring theme in effective `$SHELL` programming, especially with regard to IPC.

  - Atomic transactions: POSIX `rename`, `reflink`, `link`, `symlink`, `rename`, `mkdir`, `flock`, etc.

  - "Consequence free" zone: `tmpfs` (in RAM FS): `/run`, `/tmp`

  - Constant time operations: `reflink` (xfs, apfs), `snapshot` (zfs, btrfs), etc.

`HTTP/1.1 200 OK\r\n\r\n` is the minimal valid HTTP response header, and whatever follows is the response body.

- Curiously we never used `\r\n` in our script, only `\n`, and yet it works.

  - Almost all HTTP clients support malformed responses.

- Exploit The **Postel's law**: "Be conservative in what you do, be liberal in what you accept from others".

  - Take advantage of the UNIX world of emergent & ossified protocols.

## Recursion is cool, but who gives a shit

_Who the fuck_ uses **`$SHELL` recursion** on a daily basis?

Probably **((you))**, if you use `SSH`.

```bash
ssh '<user@host>' '...' '<arguments>' '...'
```

```bash
"$SHELL" '->' ssh (client) '->' sshd (server) '->' "$SHELL"
```

However trivial the `ssh`'s arguments are, a login `$SHELL` → login `$SHELL` **recursion** always takes place, even in the degenerate case of zero arguments.

Percipiently, every argument passed to the local ssh client i.e. `'...' '<arguments>' '...'` are **evaluated and expanded** by the remote `$SHELL`.

Thus, for non-trivial arguments ⇉ `printf -- '%q '`.

## Homoplasies to Structural / Functional Programming

There is a persistent myth: that shell programs are only good for quick and dirty

<figure>
  <img src="https://github.com/ms-jpq/defcon604-2023/blob/main/pics/homology.png?raw=true">
  <figcaption>
    yes I know <code>homology != homoplasy</code>, but <code>homology</code> has prettier illustrations on wikipedia
  <figcaption>
</figure>

## `$SHELL` is built from lambdas??

_**YES: Almost everything in `$SHELL` outside of control flow and redirection is a pseudo-process**_

```txt
⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⣀⣤⣤⣤⣶⣤⣤⣀⣀⣀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀
⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⣠⣴⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣶⣄⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀
⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⢀⣾⣿⣿⣿⣿⣿⡿⠋⠉⠛⠛⠛⠿⣿⠿⠿⢿⣇⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀
⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⣾⣿⣿⣿⣿⣿⠟⠀⠀⠀⠀⠀⡀⢀⣽⣷⣆⡀⠙⣧⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀
⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⢰⣿⣿⣿⣿⣿⣷⠶⠋⠀⠀⣠⣤⣤⣉⣉⣿⠙⣿⠀⢸⡆⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀
⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⢸⣿⣿⣿⣿⣿⠁⠀⠀⠴⡟⣻⣿⣿⣿⣿⣿⣶⣿⣦⡀⣇⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀
⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⢨⠟⡿⠻⣿⠃⠀⠀⠀⠻⢿⣿⣿⣿⣿⣿⠏⢹⣿⣿⣿⢿⡇⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀
⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⣿⣼⣷⡶⣿⣄⠀⠀⠀⠀⠀⢉⣿⣿⣿⡿⠀⠸⣿⣿⡿⣷⠃⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀
⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⢻⡿⣦⢀⣿⣿⣄⡀⣀⣰⠾⠛⣻⣿⣿⣟⣲⡀⢸⡿⡟⠹⡆⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀
⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⢰⠞⣾⣿⡛⣿⣿⣿⣿⣰⣾⣿⣿⣿⣿⣿⣿⣿⣿⡇⢰⡇⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀
⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠘⠀⣿⡽⢿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⢿⠿⣍⣿⣧⡏⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀
⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⣿⣷⣿⣿⣿⣿⣿⣿⣿⣿⣷⣮⣽⣿⣷⣙⣿⡟⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀
⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠙⢿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⡟⣹⡿⠇⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀
⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠈⠛⢿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⡧⣦⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀
⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⢠⡆⠀⠀⠀⠀⠀⠀⠀⠉⠻⣿⣿⣾⣿⣿⣿⣿⣿⣿⡶⠏⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀
⠀⠀⠀⠀⠀⠀⠀⣀⣠⣤⡴⠞⠛⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠚⣿⣿⣿⠿⣿⣿⠿⠟⠁⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀
⠀⢀⣠⣤⠶⠚⠉⠉⠀⢀⡴⠂⠀⠀⠀⠀⠀⠀⠀⠀⢠⠀⠀⢀⣿⣿⠁⠀⡇⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀
⠞⠋⠁⠀⠀⠀⠀⣠⣴⡿⠃⠀⠀⠀⠀⠀⠀⠀⠀⠀⣾⠀⠀⣾⣿⠋⠀⢠⡇⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀
⡀⠀⠀⢀⣷⣶⣿⣿⣿⡇⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⣿⣆⣼⣿⠁⢠⠃⠈⠓⠦⣄⡀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀
⣿⣿⡛⠛⠿⠿⠿⠿⠿⢷⣦⣤⣤⣤⣦⣄⣀⣀⠀⢀⣿⣿⠻⣿⣰⠻⠀⠸⣧⡀⠀⠉⠳⣄⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀
⠛⢿⣿⣆⠀⠀⠀⠀⠀⠀⠀⠀⠈⠉⠉⠙⠛⠿⣦⣼⡏⢻⣿⣿⠇⠀⠁⠀⠻⣿⠙⣶⣄⠈⠳⣄⡀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀
⠀⠀⠈⠋⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠁⣐⠀⠀⠀⠈⠳⡘⣿⡟⣀⡠⠿⠶⠒⠟⠓⠀⠹⡄⢴⣬⣍⣑⠢⢤⡀⠀⠀⠀⠀⠀⠀⠀⠀⠀
⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠙⢀⣀⠐⠲⠤⠁⢘⣠⣿⣷⣦⠀⠀⠀⠀⠀⠀⠙⢿⣿⣏⠉⠉⠂⠉⠉⠓⠒⠦⣄⡀⠀⠀⠀
⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠉⠀⠀⠀⠀⠈⣿⣿⣷⣯⠀⠀⠀⠀⠀⠀⠀⠀⠉⠻⢦⣷⡀⠀⠀⠀⠀⠀⠀⠉⠲⣄⠀
⠠⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠘⢦⠀⢹⣿⣏⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠙⢻⣷⣄⠀⠀⠀⠀⠀⠀⠈⠳
⠀⠀⠁⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠁⣸⣿⣿⡀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠈⣽⡟⢶⣄⠀⠀⠀⠀⠀
⠯⠀⠀⠀⠒⠀⠀⠀⠀⠀⠐⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⢻⣿⣿⣷⣄⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⢸⣿⡄⠈⠳⠀⠀⠀⠀
⠀⠀⢀⣀⣀⡀⣼⣤⡟⣬⣿⣷⣤⣀⣄⣀⡀⠀⠀⠀⠀⠀⠀⠈⣿⣿⡄⣉⡀⠀⠀⠀⠀⠀⠀⠀⢀⠀⠀⠀⠀⠀⣿⣿⣄⠀⣀⣀⡀⠀
```

### Case Study: `process1 | λ | process2 | process3`

- **`process1`**: Print deleted files in git with `commit-id` followed by repeated `file-name` for each commit.

- **`lambda`**: Associate each `file-name` with the `commit-id` that deleted it.

- **`process2 | process3`**: Encrypt the deleted file uniquely identified via `commit-id:file-name`.

```bash
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
```

- Notice for the `λ` section, only `$SHELL` built-ins was used.

  - `λ` effectively acts as part of the pipe

```bash
#!/usr/bin/env -S -- zsh

die() {
  printf -- '%s\n' "$0"
  return 88
}

die
printf -- '%s\n' $?
```

---

### Emgenrent Protocol -- Posix SH

Similar to how the ubiquity of C made its `.h` headers the universal FFI API, the ubiquity of the `int system(const char *command)` has made the `posix` shell an accidental API in of itself.

Basically, for any given `unix` program, if it has an mechanism for spawning processes, chances are, the arguments to the parent program are carried over more or less verbatim into
the system shell.

i.e.

- [`ssh -o ProxyCommand=...`](ssh_config)

- [`rsync --rsh ...`](rsync)

- [`fzf --preview ...`](fzf)

- [`fzf --execute ...`](fzf)

**Never quote by hand**, especially for nested recursions

## You can write ~~Java~~ Shell in any language

I have written the same basic shell program in 15 languages, with

## prolog

- `++++` Cool as shit

- `++` Fast interpertor spin up

- `+` Shares the same (yes -> continue / no -> abort) execution model as `bash -eux -o pipefail ...`

- `+` `DCG` is vastly more superior to `regex` for parsing complex grammar, esp with recursion

- `-` Poor tooling

- `---` Good luck using it in prod

## python

- `+++++` Legendary stdlib

- `+++` Best built-in argument parser of any language

- `++` Excellent tooling

- `-` Poor pipelining support

## clojure

- `+++` Beautiful language

- `-` Shell programming is orthogonal to Clojure's strengths

- `--` Slow JVM spin up

## perl

- `+++` Available almost anywhere `bash` is

- `++` Cool boomercore language.

- `--` Unicode support hidden behind flags, so nobody uses them, especially in shebangs.

## ruby

- `+++` Most powerful built-in templating of any language (erb).

- `++` Passable stdlib, including decent pipelining & rake (ruby's Make)

- `++` More sane version of `perl`

- `-` Working with raw bytes an after thought

## nodejs

- `+++` Stream oriented + `async function*`

- `++` Fast interpertor spin up

- `---` Stdlib is sucky

## powershell

- `++` Access to `.NET` stdlib

- `-` Poor tooling

- `---` SLOW as hell interpertor spin up for a shell language

## fsharp

- `--` Enterprisy stdlib

- `+` Pretty decent tooling actually

## haskell

- `++` Beautiful language.

- `--` Form over function

- `---` Really slow compile time when running via shebang

## lua

## R

## php

- `--` Is `php`

## rust

- `+` If it passes `#![deny(clippy::all, clippy::pedantic)]`, it work good

- `---` Only ever going to be used to make `build.rs` executable

## kotlin

- `-----` Some how slower than julia at `Hello World`

---

## λ

---

### Referential Transparency

## Systemd Socket Programming

```systemd
[Socket]
Accept      = yes
```

```systemd
[Unit]
CollectMode = inactive-or-failed
[Service]
Type        = oneshot
```

---

## Acknowledgements

Thank you so much to my employer [Graveflex]() and especially my Boss (with capital B) [Lynn Hurley]() for providing an environment where I was able to nature my skills as a programmer :).
