# Structured Shell Programming (Recursions, Lambdas, Functional Paradigms)

All the code plus the original defcon604 slides are available at [my github](https://github.com/ms-jpq/defcon604-2023)

The proposition is simple: **`SHELL` is the most effective programming technique** you can learn, because it's based on **process composition**, it necessarily works at a **higher level** than say compared to even Haskell.

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

#### `#!`: shebang

```bash
#!/usr/bin/env -S -- bash -Eeu -O dotglob -O nullglob -O extglob -O failglob -O globstar
```

- In UNIX systems, `#!` are the magic bytes that denote executable scripts, and it leads to a path i.e. `/usr/bin/env` as the script interpreter. This is fairly well known.

- This isn't all that interesting, but it is underutilized that you pay pass arguments to the script interpreter as well. For example, passing in `perl -CAS` to enable greater unicode support.

#### `[[ -t 0 ]]`: is stdin `(fd 0)` a terminal?

- The recursion works by checking if the script is run from the terminal, if so, the script re-spawns itself under a subprocess of `socat`, in which it is no longer attached to the terminal.

- The terminal is actually a fairly important concept for in shell programming, as it is the `$SHELL` itself. It poses some **interesting questions**:

1.  - On `ASCII` and strings: How do you _delete_ a character from the terminal, if the terminal is **just another process**? Surely `stdin` is _append only_.

    - As it turns out, `ASCII` has multiple deletion characters: `BS` and `DEL`, what's better, it even has a `BEL` character that will blink your terminal.

2.  - So are strings really just text? Or should we view them as _instruction streams_?

    - The latter mental model should prove more fruitful for shell programming.

#### `printf -- '%q '`: What kind of format is `%q`?

Two things are true:

1.  Recursion is difficult without argument passing.

2.  It is difficult to manually quote arguments in `$SHELL` languages.

The _one-liner solution_:

`%q ` **quotes arguments** to `printf` such that they can **POSIX `SHELL` expand back to their original input**.

This feature is not unique to `bash` and `zsh`. We can examine a few similar facilities to reveal their design philosophies:

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

- **Bash**: Note the quoted string contains **no line breaks**, unlike `python` and `ruby`. This is essential, since `bash` like other `$SHELL` languages is fundamentally **line / record oriented**. Line breaks have a special significance in `$SHELL`.

```bash
printf -- '%q ' $'\n ' '#$123' '\@!-_'
# $'\n'\  \#\$123 \\@\!-_
```

- **PowerShell**: Wow, such Microsoft, much `UTF16-LE`, very `BASE64`, and yes, it can recursively quote itself for execution as well.

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

#### `exec -- socat`: Back to HTTP server

---

## What is Shell Programming

There is a distinct difference between **written in** shell and written **for shell**.

Shell programming is characterized by _process composition_ as much as say functional programming is characterized by _function composition_.

Indeed, just as it is possible to write Java in any language, it is also possible to write shell programs in any language. [Scroll to the end]() to see the same basic shell program in 15 different languages, along with some remarks on each.

### Homoplasies to Functional Programming & RAII (in the Rust sense)

This part is pretty boring compared to **recursion**.

Read it at the end [here]().

<figure>
  <img src="https://github.com/ms-jpq/defcon604-2023/blob/main/pics/homology.png?raw=true">
  <figcaption>
    yes I know <code>homology &lt;&gt; homoplasy</code>, but <code>homology</code> has prettier illustrations
  <figcaption>
</figure>

---

## Recursion

_Who the fuck_ uses shell recursion on a daily basis?

Probably **((you))**, if you use `SSH`.

SSH spawns the login shell on the server, and passes whitespace joined arguments verbatim from client to server.

```bash
# Typical interactive SSH usage
shell | ssh->sshd | shell
```

Even if most interactive uses of `SSH` passes zero arguments, the trivial recursion from your shell to the remote shell still takes place.

But before we do something useful, let's do something fun instead :)

#### Observations

##### Exploiting the Postel's law

`be conservative in what you do, be liberal in what you accept from others`

1. `HTTP/1` is TCP + `HTTP` headers + newline + body

2. The specified `\r` in `\r\n` in HTTP protocol isn't required in practice, when most clients are written to accept a liberal interpretation of it

3. Think, the UNIX world of (in)formal protocols

##### `$0`

1. The first argument of a process (`$0`) is conventionally, their own name. This works in almost all languages, on all `OS` (yes even in Microsoft land).

2. Recursion is performed via `$0`, which is almost always present, for example `python` wouldn't even let you call [`os.exec*`]() without it.

3. Famously `busybox` is a multi-call binary that distills many `gnu-coreutils` into a single executable based on invocations of `$0`

### Back to SSH

#### Recursive arguments

Notice in the HTTP example, there is a peculiar `printf` format: `%q`

If we were to look up `printf(1)` in the `glibc`, consepectiously, there is no `%q`.

As it turns out, `%q` is a `bash` / `gnu` extension to `printf` that transforms a string into a format that when evulated under the `posix` shell syntax, expands to it's own (logical) identity.

i.e. built for recursive evulation.

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

<summary>
<detail>
</detail>
</summary>

##### Bash

builtin quoting for recursion

### What about NT?

There is little support for quoting `cmd.exe` grammar.

Powershell is ubiqitious enough though...

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

## Homoplasies

### RAII

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
