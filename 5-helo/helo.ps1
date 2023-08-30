#!/usr/bin/env -S -- pwsh -NoProfile -NonInteractive

Set-StrictMode -Version 'Latest'
$ErrorActionPreference = 'Stop'
$PSStyle.OutputRendering = 'PlainText'

Set-Location -- $PSScriptRoot

$name = $MyInvocation.MyCommand
Write-Host -- "HELO :: VIA -- $name"
bat -- (Join-Path -- $PSScriptRoot $name)
if (!$?) { exit $LASTEXITCODE }
