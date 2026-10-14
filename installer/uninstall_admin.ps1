#Requires -RunAs
<#
.SYNOPSIS
    Desinstalador a nivel Administrador para Vincco Headset Tester.
#>

$ErrorActionPreference = "SilentlyContinue"

Write-Host "============================================================================" -ForegroundColor Cyan
Write-Host "   DESINSTALADOR DE VINCCO HEADSET TESTER" -ForegroundColor Cyan
Write-Host "============================================================================" -ForegroundColor Cyan
Write-Host ""

Write-Host "1. Deteniendo procesos activos..." -ForegroundColor Yellow
Get-Process -Name "headset_tester_vincco" | Stop-Process -Force

Write-Host "2. Eliminando clave de inicio de Windows en HKLM..." -ForegroundColor Yellow
Remove-ItemProperty -Path "HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Run" -Name "VinccoHeadsetTester" -Force

Write-Host "3. Eliminando accesos directos..." -ForegroundColor Yellow
Remove-Item -Path "$env:ProgramData\Microsoft\Windows\Start Menu\Programs\Vincco Headset Tester.lnk" -Force
Remove-Item -Path "$env:Public\Desktop\Vincco Headset Tester.lnk" -Force

Write-Host "4. Eliminando archivos de C:\Program Files\Vincco\HeadsetTester..." -ForegroundColor Yellow
Remove-Item -Path "C:\Program Files\Vincco\HeadsetTester" -Recurse -Force

Write-Host ""
Write-Host "============================================================================" -ForegroundColor Green
Write-Host "   DESINSTALACION COMPLETADA" -ForegroundColor Green
Write-Host "============================================================================" -ForegroundColor Green
Write-Host "Presiona cualquier tecla para cerrar..." -ForegroundColor Gray
$null = $Host.UI.RawUI.ReadKey("NoEcho,IncludeKeyDown")
