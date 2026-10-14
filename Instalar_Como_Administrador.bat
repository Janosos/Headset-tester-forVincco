@echo off
title Instalar Vincco Headset Tester como Administrador
echo Solicitando permisos de Administrador...
powershell -Command "Start-Process powershell -ArgumentList '-ExecutionPolicy Bypass -NoProfile -File \"\"%~dp0installer\install_admin.ps1\"\"' -Verb RunAs"
