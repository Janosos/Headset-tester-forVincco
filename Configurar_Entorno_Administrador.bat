@echo off
:: Comprobar si se está ejecutando como Administrador
net session >nul 2>&1
if %errorLevel% neq 0 (
    echo [ERROR] Este script requiere permisos de Administrador.
    echo Por favor haz clic derecho sobre este archivo y selecciona "Ejecutar como administrador".
    pause
    exit /b 1
)

echo ============================================================================
echo   CONFIGURADOR DE ENTORNO WINDOWS PARA FLUTTER - VINCCO HEADSET TESTER
echo ============================================================================
echo.

echo 1. Activando Modo Desarrollador de Windows (Symlinks para plugins de Flutter)...
reg add "HKEY_LOCAL_MACHINE\SOFTWARE\Microsoft\Windows\CurrentVersion\AppModelUnlock" /t REG_DWORD /f /v "AllowDevelopmentWithoutDevLicense" /d 1
if %errorLevel% equ 0 (
    echo [OK] Modo Desarrollador activado correctamente.
) else (
    echo [ALERTA] No se pudo escribir la clave del registro.
)

echo.
echo 2. Instalando Visual Studio C++ Build Tools (Requerido para compilar Windows Desktop)...
echo    Descargando componentes necesarios. Por favor espera...
if not exist "%TEMP%\vs_BuildTools.exe" (
    powershell -Command "Invoke-WebRequest -Uri 'https://aka.ms/vs/17/release/vs_BuildTools.exe' -OutFile '$env:TEMP\vs_BuildTools.exe' -UseBasicParsing"
)

"%TEMP%\vs_BuildTools.exe" --passive --wait --norestart --add Microsoft.VisualStudio.Workload.VCTools --includeRecommended

echo.
echo ============================================================================
echo  [LISTO] Entorno configurado con exito.
echo ============================================================================
pause
