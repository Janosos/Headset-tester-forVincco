@echo off
title Desinstalar Vincco Headset Tester
echo Solicitando permisos de Administrador...
powershell -Command "Start-Process powershell -ArgumentList '-ExecutionPolicy Bypass -NoProfile -File \"\"%~dp0installer\uninstall_admin.ps1\"\"' -Verb RunAs"
