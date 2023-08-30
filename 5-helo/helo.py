#!/usr/bin/env -S -- PYTHONSAFEPATH= python3

from os import chdir
from pathlib import Path
from subprocess import run

file = Path(__file__).resolve()
chdir(file.parent)

print(f"HELO :: VIA -- {file.relative_to(Path.cwd())}")
run(("bat", "--", file)).check_returncode()
