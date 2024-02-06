#!/usr/bin/env -S -- bash -Eeuo pipefail
//usr/bin/true; rustc --edition=2021 -o "${T:="$(mktemp)"}" -- "$0" && exec -a "$0" -- "$T" "$0" "$@"

#![deny(clippy::all, clippy::cargo, clippy::pedantic)]

use std::{
    backtrace::Backtrace,
    env::{args_os, set_current_dir},
    error::Error,
    path::PathBuf,
    process::Command,
};

fn main() -> Result<(), Box<dyn Error>> {
    let arg0 = args_os()
        .next()
        .map(PathBuf::from)
        .ok_or_else(|| format!("{}", Backtrace::capture()))?;
    let path = arg0.canonicalize()?;
    let parent = path
        .parent()
        .ok_or_else(|| format!("{}", Backtrace::capture()))?;

    set_current_dir(parent)?;
    println!("HELO :: VIA -- {}", arg0.display());

    let status = Command::new("bat").arg("--").arg(path).status()?;
    assert!(status.success());
    Ok(())
}
