#!/usr/bin/env -S -- kotlinc -script
import java.io.File
import java.lang.ProcessBuilder.Redirect

val cmd = System.getProperty("sun.java.command")
val path = cmd.split(" ").last()

println("HELO :: VIA -- ${File(path).name}")
println("cannot into chdir")

val proc =
    ProcessBuilder("bat", "--", path)
        .redirectOutput(Redirect.INHERIT)
        .redirectError(Redirect.INHERIT)
        .start()

assert(proc.waitFor() == 0)
