@echo off
rem run-sql.cmd - wrapper so the script runs even when the execution policy blocks .ps1
rem Usage:  .\run-sql.cmd "SELECT * FROM product"
rem         .\run-sql.cmd -File sql\exercises\m03_where_order_andy.sql
powershell -NoProfile -ExecutionPolicy Bypass -File "%~dp0run-sql.ps1" %*
