#!/usr/bin/env -S -- node

import { deepEqual } from "node:assert/strict";
import { spawnSync } from "node:child_process";
import { dirname, relative } from "node:path";
import { chdir, cwd } from "node:process";
import { fileURLToPath } from "node:url";

const file = fileURLToPath(import.meta.url);
const dir = dirname(file);

chdir(dir);
console.log(`HELO :: VIA -- ${relative(cwd(), file)}`);

const { error, status, signal } = spawnSync("bat", ["--", file], {
  stdio: "inherit",
});

if (error) {
  throw error;
} else {
  deepEqual(0, status ?? -(signal ?? -1));
}
