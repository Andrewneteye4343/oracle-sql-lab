# run-sql.ps1 - send SQL to the Oracle container and print the result
# ASCII only on purpose: Windows PowerShell 5.1 reads a .ps1 as ANSI when it has no BOM,
# so any non-ASCII character inside this file would be decoded with the system codepage
# and can break string quoting at parse time.
#
# Usage:
#   .\run-sql.ps1 "SELECT * FROM product"
#   .\run-sql.ps1 -File sql\show_schema.sql
#   .\run-sql.ps1 "SELECT COUNT(*) FROM process_event WHERE out_ts IS NULL"
#
# SET EXITCOMMIT OFF: SQL*Plus commits pending DML on EXIT by default, so an ad-hoc
# UPDATE would silently persist. Turn it off so uncommitted changes roll back.
#
# Why bash -lc: PowerShell treats a leading @ as a splatting operator, so sqlplus '@file'
# arguments are passed inside a bash string instead.
param(
    [Parameter(Position = 0)][string]$Query = "",
    [string]$File = "",
    [string]$User = "sqluser",
    [string]$Pass = "SqlDev#2026",
    [string]$Pdb  = "FREEPDB1"
)

$ErrorActionPreference = "Stop"
Set-Location (Split-Path -Parent $MyInvocation.MyCommand.Path)

if ($File -ne "") {
    if (-not (Test-Path $File)) { Write-Host "File not found: $File"; exit 1 }
    $leaf = Split-Path $File -Leaf
    $dest = Join-Path (Get-Location) "sql\$leaf"
    if ((Resolve-Path $File).Path -ne $dest) { Copy-Item $File $dest -Force }
    $sqlPath = "/sql/$leaf"
}
elseif ($Query -ne "") {
    $sqlPath = "/sql/_adhoc.sql"
    $head = "SET DEFINE OFF`r`nSET EXITCOMMIT OFF`r`nWHENEVER SQLERROR EXIT SQL.SQLCODE`r`nSET LINESIZE 200`r`nSET PAGESIZE 200`r`nSET FEEDBACK OFF`r`n"
    $body = $Query.Trim()
    if (-not $body.EndsWith(";")) { $body = "$body;" }
    $dest = Join-Path (Get-Location) "sql\_adhoc.sql"
    $enc = New-Object System.Text.UTF8Encoding($false)
    [System.IO.File]::WriteAllText($dest, $head + $body + "`r`nEXIT`r`n", $enc)
}
else {
    Write-Host 'Usage: .\run-sql.ps1 "SELECT * FROM product"'
    Write-Host '       .\run-sql.ps1 -File sql\show_schema.sql'
    exit 1
}

$inner = "sqlplus -s '$User/$Pass@//localhost:1521/$Pdb' '@$sqlPath'"
docker compose exec -T oracle bash -lc $inner
if ($LASTEXITCODE -ne 0) { Write-Host "sqlplus exited with code $LASTEXITCODE" }
