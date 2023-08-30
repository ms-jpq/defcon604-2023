#!/usr/bin/env -S -- dotnet fsi --gui-

open System
open System.Diagnostics

Environment.CurrentDirectory <- __SOURCE_DIRECTORY__

printfn "HELO :: VIA -- %s" __SOURCE_FILE__

do
    use proc = Process.Start("bat", [ "--"; __SOURCE_FILE__ ])
    proc.WaitForExit()
    assert (proc.ExitCode = 0)
