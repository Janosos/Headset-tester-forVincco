#Requires -RunAs
<#
.SYNOPSIS
    Instalador a nivel Administrador para Vincco Headset Tester.
.DESCRIPTION
    Instala la aplicación en C:\Program Files\Vincco\HeadsetTester,
    la registra en HKLM\...\Run para ejecutarse al iniciar Windows,
    crea accesos directos y lanza la aplicación en segundo plano.
#>

$ErrorActionPreference = "Stop"

Write-Host "============================================================================" -ForegroundColor Cyan
Write-Host "   INSTALADOR DE VINCCO HEADSET TESTER (NIVEL ADMINISTRADOR)" -ForegroundColor Cyan
Write-Host "============================================================================" -ForegroundColor Cyan
Write-Host ""

$installDir = "C:\Program Files\Vincco\HeadsetTester"
$sourceDir = Resolve-Path "$PSScriptRoot\..\build\windows\x64\runner\Release" -ErrorAction SilentlyContinue

if (-not $sourceDir -or -not (Test-Path "$sourceDir\headset_tester_vincco.exe")) {
    $sourceDir = Resolve-Path "$PSScriptRoot\..\build\windows\x64\runner\Debug" -ErrorAction SilentlyContinue
}

# 1. Detener proceso anterior si está corriendo
Write-Host "[1/5] Verificando instancias activas..." -ForegroundColor Yellow
Get-Process -Name "headset_tester_vincco" -ErrorAction SilentlyContinue | Stop-Process -Force -ErrorAction SilentlyContinue
Start-Sleep -Milliseconds 500

# 2. Crear directorio de destino
Write-Host "[2/5] Creando directorio de instalacion en: $installDir" -ForegroundColor Yellow
if (-not (Test-Path $installDir)) {
    New-Item -ItemType Directory -Path $installDir -Force | Out-Null
}

# 3. Copiar archivos si existen en la compilación
if ($sourceDir -and (Test-Path "$sourceDir\headset_tester_vincco.exe")) {
    Write-Host "[3/5] Copiando archivos de aplicacion desde $sourceDir..." -ForegroundColor Yellow
    Copy-Item -Path "$sourceDir\*" -Destination $installDir -Recurse -Force
} else {
    Write-Host "[ALERTA] No se ha encontrado la compilacion todavia en build/windows." -ForegroundColor Yellow
    Write-Host "         Copiando archivos de soporte. Recuerda compilar con 'flutter build windows --release'." -ForegroundColor DarkGray
    Copy-Item -Path "$PSScriptRoot\..\assets" -Destination $installDir -Recurse -Force -ErrorAction SilentlyContinue
}

# 4. Registrar en Inicio de Windows a nivel Administrador (HKLM)
Write-Host "[4/5] Registrando inicio automatico en el Registro de Windows (HKLM)..." -ForegroundColor Yellow
$regPath = "HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Run"
$exePath = "`"$installDir\headset_tester_vincco.exe`" --background"

Set-ItemProperty -Path $regPath -Name "VinccoHeadsetTester" -Value $exePath -Force
Write-Host "      Clave agregada: $regPath -> VinccoHeadsetTester" -ForegroundColor Green

# 5. Crear accesos directos
Write-Host "[5/5] Creando accesos directos (Menu Inicio y Escritorio)..." -ForegroundColor Yellow
$wsh = New-Object -ComObject WScript.Shell

# Acceso directo en Menú Inicio de todos los usuarios
$startMenuPath = "$env:ProgramData\Microsoft\Windows\Start Menu\Programs\Vincco Headset Tester.lnk"
$shortcut = $wsh.CreateShortcut($startMenuPath)
$shortcut.TargetPath = "$installDir\headset_tester_vincco.exe"
$shortcut.WorkingDirectory = $installDir
$shortcut.Description = "Vincco Headset Tester - Monitoreo de Audio"
$shortcut.Save()

# Iniciar aplicación en segundo plano
if (Test-Path "$installDir\headset_tester_vincco.exe") {
    Write-Host "Iniciando la aplicacion en segundo plano..." -ForegroundColor Cyan
    Start-Process -FilePath "$installDir\headset_tester_vincco.exe" -ArgumentList "--background" -WorkingDirectory $installDir
}

Write-Host ""
Write-Host "============================================================================" -ForegroundColor Green
Write-Host "   INSTALACION COMPLETADA CON EXITO A NIVEL ADMINISTRADOR" -ForegroundColor Green
Write-Host "============================================================================" -ForegroundColor Green
Write-Host "La aplicacion se ejecutara automaticamente cada vez que inicie el equipo." -ForegroundColor White
Write-Host "Presiona cualquier tecla para finalizar..." -ForegroundColor Gray
$null = $Host.UI.RawUI.ReadKey("NoEcho,IncludeKeyDown")
