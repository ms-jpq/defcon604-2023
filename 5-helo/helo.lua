#!/usr/bin/env -S -- lua -W --

local file = arg[0]
print("HELO :: VIA -- " .. file:match([[.*/(.+%.lua)]]))
local pf =
  assert(io.popen("bat --color=always --decorations=always -- " .. file, "r"))
local data = assert(pf:read("*a"))
pf:close()
print(data)
