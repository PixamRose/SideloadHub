@echo off
title SideloadHub - Serveur LAN
cd /d "%~dp0"
powershell -NoProfile -ExecutionPolicy Bypass -File ".\server\Start-SideloadHub.ps1"
pause
