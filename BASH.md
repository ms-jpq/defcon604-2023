# Bash Scripting

High level conceptual overview

## Control Flow

```
              GOLDEN PATH
-x-------x---------------x----------------->
 |       |               |
 die     die             die
```

## Portability

### `sh`

AKA `POSIX` shell, basically dont use this one for scripting, you are better off using `perl`.

Least amount of features, doesn't even have arrays.

Footguns all over.

### `bash v3`

MacOS is stuck on bashv3 for fear of being sued, will never change

### `bash v4+`

Important additions:

- Dictionaries

- `globstar`

- `readarray`

### `zsh`

Mostly superset of `bash`, missing `readarray`, 1 base indexed

Aside: when are languages 1 vs 0 base indexed?

Mostly MATH languages are 1 base indexed, i.e. Julia, Maple, R, Matlab, Mathematica, SASS, Wolfram, Fortran

### `bash (windows)`

... Separate talk

- Git

- WSL 2

- WSL 1

- Msys2

- Cygwin

---

# IO

## Arguments

```bash
# $0 $1 $2     $3  $4        $5   $6     $7  $8     $9 ...
curl -L --user ... --request POST --data ... -H=... -- https://...

# Note:
# There is set max limit of arguments ~ 1000
# `-*` is called a switch, switches with parameter can be inputted via =, or be followed by an seperate argument
# `--` stops parsing of `-*` as switches
# `$0` is the program name (not always there), useful for recursion & introspection
```

### BSD

MacOS, Alpine Linux, busybox, some `go` programs

```bash
-v -b -c=...
# can combine
-vbc=...
# the `=` is sometimes optional, if unambiguous
gcc -I/lib -I/lib2 ...
```

### GNU

Most Linux programs, most programs you install via Homebrew

Extension of the BSD style

```bash
--long-option --hi-my-name-is=...
```

### IBM

No switches!

Can't think of anything body else except `dd`, and random `QEMU` commands

```bash
dd if=... of=... bs=...
```

## Environmental Variables

You should be familiar with these

```bash
# Note, unless explicitly unset, environments are inherited by child processes
A=...
B=...
C=...
```

## File Descriptors

`argv` & `enviroin` are in general `ASCII`

`fd` transmits arbitrary binaries

```bash
# /dev/* might not always be present
# 0-2 will be though

/dev/null   # immediately return END OF FILE on read

/dev/stdin  # 0
/dev/stdout # 1
/dev/stderr # 2

# 3+ is free, and entirely optional
```

---

# Standard Environmental Variables

```bash
DISPLAY=:0                  # used under GUI environments, ie X11 and wayland. GUI programs will not work without this
EDITOR=nvim                 # invoked by CLIs for editing text
LANG=C.UTF-8                # current locale, can affect program output, sort order, text format, etc
LC_ALL=C.UTF-8              # ^^
PAGER=less                  # invoked by programs to paginate long outputs
PATH=/usr/sbin:/usr/bin:... # `:` separated directories to lookup bare program names
SHELL=zsh                   # current shell, invoked by third party like so (usually): $SHELL -c 'command'
TERM=xterm-256color         # used to determine terminal emulator capacity such as 256 / true colour support
TMPDIR=/tmp                 # default tmp directory, usually in memory mount
TZ=America/Vancouver        # <Continent>/<City> used to determine current timezone

# ... and much more
GIT_PAGER=
HOME=
LD_PRELOAD=
LESS=
LS_COLORS=
MANPAGER=
PATH_EXT=
SHLVL=
SSH_TTY=
TIME_STYLE=
USER=
XDG_=
```

## Aside, on Time

### No mention of countries

Why is `$TZ` continent + city? → flame wars

Fun fact, is Kosovo a country? Depends on where you live!

### Time Lord

- System time isn't monotonic!

- System time can slow down / speed up, jump forwards, travel backwards...

- NTP

     - chronyd
     - ntpd
     - systemd-timesyncd

- Why important?
     - Distributed systems: ordering of events
     - Crypto: validations

---

# FD IO

## Streaming

```bash
# pipelines are concurrent
concurrent_1 | concurrent_2 | concurrent_3 | ...
```

```bash
# pipelines are just FD centipedes
head | body | tail
# can redirect the FD onto other FD
command_1 2>&1
# can redirect the FD onto a file
command_1 > /filename
# can redirect file onto FD
command_1 < /filename
```

## Convention:

- FD `0` → Input

- FD `1` → Machine readable output

- FD `2` → Human readable output

## ASCII

```bash
# what does it mean to be a control char?
man -- ascii
```

### `<nul>`

```c
// C's main function
int main (int argc, char *argv[]) { ... }

// '\0' is THE delimiter
```

### `<bs>`

What do you think happens if you hit `<backspace>` on your keyboard?

### `<bel>`

```bash
sleep -- 3 && printf -- '\a'
```

### `<esc>`

```bash
# invisible, unless you pipe via `cat -e`
fire | command -- cat -e
```

```bash
pip3 install -- gay
gay --flag
```

```yaml
- ANSI-*
- OSC-*
```

### Whitespace

Informal text protocol, tabular data structure

```bash
# rows
$'\n'
# cols
$'\t' || ' '
```

```bash
# pretty print table
command | column -t
# sort by column 2
command | sort -k 2
# only print column 2
command | awk '{ print $2 }'
```

## UTF-\*

```
UTF-8    -> internet, unix
UTF-16   -> windows

other... -> Random countries, like japan or something
```

All of the human complexity, (badly ⇆ okishly) represented

Superset of ASCII

- emoji ⇉ variable byte length

- right to left

- context dependent (lol, imagine having to change how you read a book, depending on the text its printed on)

## Binary

Opaque, do not touch.

NOT safe to manipulate, lots of shell functions auto trim / add whitespaces.

Treat as input / output to other programs only.

---

# Syntax

## Shebang

```bash
#!/path/to/executable ARGUMENTS

#!/usr/bin/env -S A=.. B=.. program-name arg1 arg2 arg3 ...

man -- env
```

This means if `#` is a comment

## Expansion

```bash
$VARIABLE    ${VARIABLE}  # -> expands via `IFS` into `[...]`
"$VARIABLE" "${VARIABLE}" # -> "" quoting avoids expansion
```

## Quoting

```bash
printf -- '%q ' <xyz> <abc> ...
# python -> shlex
# ruby -> shellwords
```

## Globing

AKA `fnmatch`, most languages just compile globs into regular expressions

Note:

- Unless `dotglob` is turned on, files starting with `.` are ignored.

- Unless `nullglob` or `failglob` turned on, if a glob pattern does not match anything. The pattern becomes a _literal_.

     i.e. `*.png`, instead of expanding to `[]`, becomes `['*.png']`

- `bash` v4 added `globstar` where `**/*.xyz` pattern can be used to match recursively.

## Regular Expression

- POSIX

     Verbose and limited, ie `[[:space:]]` instead of `\s`, bash builtin

- Extended

     POSIX++, ignore. Usually if `Extended` is available, so is PCRE.

- PCRE (Perl Compatible Regular Expressions)

     Closest to modern js,rb,py et al.

     Has most features, ie lookahead, lookbehind, greedy / non-greedy etc.

---

# Jobs

What separates shell programming from other languages, is how often do you invoke other programs to perform tasks.

## Binaries

```yaml
# common
- coreutils # or BSD variant of
- busybox # basically BSD variable of `coreutils`
- moreutils,gettext,gawk,... #
- perl <- honourable mention # available almost anywhere bash is

# never use
- sed (just use perl)

# please use
- jq
```

## Branching

Recall the "Golden path"

### Exit codes

```bash
$? # <- last exit code

if <something>
then
  :
fi

while <something>
do
  :
done

until <something>
do
  :
done

# Almost all control structures in shell test against <something>'s last exitcode
#     0 -> True
# not 0 -> False

set -euo pipefail
# auto exit if exit code non-zero, auto exit if any pipe programs exit with non-zero, auto exit if any variable is undefined
# DOESNT ALWAYS WORK
```

### Complex control flow?

Just write it in another language

## Communication

`IO` limitations → can only be set up before process start.

### PID

```bash
$PPID -> parent

pstree
```

```yaml
# Really bad ID
- Not unique, can be recycled
- No way of knowing who your grandchildren are
- Children can make more children, and give them up for adoption -> daemons
- Children can be orphaned if you don't `wait` for them before you die
# Only linux has proper children control -> CGroups
```

### Signals

Like poking programs in the eye with a stick

Programs can choose how to respond to each signal, but doing so is really hard, so a lot of them will misbehave.

```bash
man -- signal
kill -s "$SIGNAL" -- "$PID"
```

#### Standard signals

```yaml
- SIGINT #  please stop      :: <ctrl-c>, ASCII 03, interactive stop
- SIGTERM # go kill yourself :: well behaved programs will clean up + exit
- SIGKILL # avada kedavra    :: instant death, zero cleanup
- SIGHUP #  bye!             :: sent by $SHELL upon termination, usually kills children
- SIGPIPE # cant touch this  :: sent by OS when writing to closed FD
```
