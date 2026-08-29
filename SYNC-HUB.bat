@echo off
title SideloadHub - Sync GitHub uniquement
cd /d "%~dp0"
powershell -NoProfile -ExecutionPolicy Bypass -File ".\server\Sync-GitHubApps.ps1"
pause
