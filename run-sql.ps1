# run-sql.ps1 - send SQL to the Oracle container and print the result
# ASCII only on purpose: Windows PowerShell 5.1 reads a .ps1 as ANSI when it has no BOM,
# so any non-ASCII character inside this file would be decoded with the system codepage
# and can break string quoting at parse time.
#
# Usage:
#   .\run-sql.ps1 "SELECT * FROM product"
#   .\run-sql.ps1 -File sql\show_schema.sql
#   .\run-sql.ps1 -File sql\exercises\m03_where_order_andy.sql
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
$sqlRoot = Join-Path (Get-Location).Path "sql"

if ($File -ne "") {
    if (-not (Test-Path $File)) { Write-Host "File not found: $File"; exit 1 }
    $full = (Resolve-Path $File).Path
    if ($full.StartsWith($sqlRoot, [System.StringComparison]::OrdinalIgnoreCase)) {
        # File already lives under .\sql : map it straight into the container path.
        # Never copy, otherwise the repo accumulates duplicate copies under sql\.
        $rel = $full.Substring($sqlRoot.Length)
        $rel = $rel.Replace('\', '/').TrimStart('/')
        $sqlPath = "/sql/$rel"
    }
    else {
        $leaf = Split-Path $File -Leaf
        Copy-Item $File (Join-Path $sqlRoot $leaf) -Force
        $sqlPath = "/sql/$leaf"
    }
}
elseif ($Query -ne "") {
    $sqlPath = "/sql/_adhoc.sql"
    $head = "SET DEFINE OFF`r`nSET EXITCOMMIT OFF`r`nWHENEVER SQLERROR EXIT SQL.SQLCODE`r`nSET LINESIZE 200`r`nSET PAGESIZE 200`r`nSET FEEDBACK OFF`r`n"
    $body = $Query.Trim()
    if (-not $body.EndsWith(";")) { $body = "$body;" }
    $dest = Join-Path $sqlRoot "_adhoc.sql"
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
