; Script de Inno Setup para Vincco Headset Tester
; Genera un instalador profesional (Setup.exe) que pide permisos de Administrador,
; instala la app en Program Files y la registra en el inicio de Windows (HKLM\...\Run).
; IMPORTANTE: Las computadoras de los clientes NO requieren Modo Desarrollador ni Visual Studio.

#define MyAppName "Vincco Headset Tester"
#define MyAppVersion "1.0.0"
#define MyAppPublisher "Vincco Operaciones"
#define MyAppExeName "headset_tester_vincco.exe"
#define MyAppAssocName "Vincco Headset Tester"

[Setup]
AppId={{5E98B4B8-0F14-4690-B8B7-7E9D40F08B9C}
AppName={#MyAppName}
AppVersion={#MyAppVersion}
AppPublisher={#MyAppPublisher}
DefaultDirName={autopf}\Vincco\HeadsetTester
DefaultGroupName={#MyAppName}
DisableProgramGroupPage=yes
; Requiere permisos de Administrador al ejecutarse en la computadora del cliente
PrivilegesRequired=admin
PrivilegesRequiredOverridesAllowed=dialog
OutputDir=..\dist
OutputBaseFilename=VinccoHeadsetTester_Setup
SetupIconFile=..\assets\icons\tray_icon.ico
Compression=lzma2/ultra64
SolidCompression=yes
WizardStyle=modern
CloseApplications=yes
RestartApplications=no

[Languages]
Name: "spanish"; MessagesFile: "compiler:Languages\Spanish.isl"

[Tasks]
Name: "desktopicon"; Description: "{cm:CreateDesktopIcon}"; GroupDescription: "{cm:AdditionalIcons}"
Name: "autostart"; Description: "Ejecutar automáticamente al iniciar Windows"; GroupDescription: "Configuración de inicio:"

[Files]
; Archivos binarios compilados de la aplicación (Release)
Source: "..\build\windows\x64\runner\Release\*"; DestDir: "{app}"; Flags: ignoreversion recursesubdirs createallsubdirs

[Icons]
Name: "{group}\{#MyAppName}"; Filename: "{app}\{#MyAppExeName}"
Name: "{group}\{cm:UninstallProgram,{#MyAppName}}"; Filename: "{uninstallexe}"
Name: "{autodesktop}\{#MyAppName}"; Filename: "{app}\{#MyAppExeName}"; Tasks: desktopicon

[Registry]
; Registrar en Inicio automático para TODOS los usuarios a nivel Administrador
Root: HKLM; Subkey: "SOFTWARE\Microsoft\Windows\CurrentVersion\Run"; ValueType: string; ValueName: "VinccoHeadsetTester"; ValueData: """{app}\{#MyAppExeName}"" --background"; Flags: uninsdeletevalue; Tasks: autostart

[Run]
; Iniciar inmediatamente en segundo plano tras finalizar la instalación
Filename: "{app}\{#MyAppExeName}"; Parameters: "--background"; Flags: nowait postinstall skipifsilent; Description: "Iniciar Vincco Headset Tester ahora en segundo plano"

[UninstallRun]
; Detener la aplicación antes de desinstalar
Filename: "taskkill"; Parameters: "/F /IM {#MyAppExeName}"; Flags: runhidden
