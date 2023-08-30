#!/usr/bin/env -S -- Rscript

argv <- commandArgs()
location <- argv[4]
if (!startsWith(location, "--file=")) {
  stop()
}

file <- sub("^--file=", "", location)
script <- normalizePath(file)

setwd(dirname(file))
cat(paste0("HELO :: VIA -- ", basename(file), "\n"))

if (system2(c("bat", "--", script)) != 0) {
  stop()
}
