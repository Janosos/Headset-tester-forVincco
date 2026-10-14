@echo off
title Compilar Vincco Headset Tester Release
echo =====================================================================
echo  Compilando aplicacion para Windows en modo Release...
echo =====================================================================
flutter build windows --release
echo.
if %errorLevel% equ 0 (
    echo [EXITO] Compilacion Release completada.
    echo Ahora puedes ejecutar 'Instalar_Como_Administrador.bat' para instalarla.
) else (
    echo [ERROR] La compilacion fallo. Asegurate de haber ejecutado antes 'Configurar_Entorno_Administrador.bat'.
)
pause
