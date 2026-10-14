@echo off
setlocal
title Generar Instalador Setup.exe para Clientes - Vincco Headset Tester
echo ============================================================================
echo   GENERADOR DE INSTALADOR SETUP.EXE PARA CLIENTES
echo ============================================================================
echo.

set "ISCC_PATH=C:\Users\%USERNAME%\AppData\Local\Programs\Inno Setup 7\ISCC.exe"
if not exist "%ISCC_PATH%" (
    set "ISCC_PATH=C:\Program Files (x86)\Inno Setup 6\ISCC.exe"
)
if not exist "%ISCC_PATH%" (
    set "ISCC_PATH=C:\Program Files\Inno Setup 7\ISCC.exe"
)

echo [Paso 1/2] Compilando la aplicacion Flutter en modo Release para Windows...
call flutter build windows --release
if %errorLevel% neq 0 (
    echo.
    echo [ERROR] La compilacion fallo.
    echo Recuerda que en esta maquina de desarrollo se requiere Visual Studio C++
    echo y el Modo Desarrollador activado.
    pause
    exit /b %errorLevel%
)

echo.
echo [Paso 2/2] Empaquetando en un instalador Setup.exe con Inno Setup...
if not exist "dist" mkdir dist

"%ISCC_PATH%" "%~dp0installer\setup.iss"
if %errorLevel% equ 0 (
    echo.
    echo ============================================================================
    echo  [EXITO] Instalador generado en:
    echo  dist\VinccoHeadsetTester_Setup.exe
    echo ============================================================================
    echo Este archivo 'VinccoHeadsetTester_Setup.exe' es el unico que se envia al cliente.
    echo Al ejecutarlo, pedira permisos de Administrador y se instalara sin requerir
    echo Modo Desarrollador ni ninguna otra herramienta en la computadora del cliente.
    echo.
) else (
    echo [ERROR] No se pudo generar el instalador Setup.exe.
)

pause
