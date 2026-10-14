# Vincco Headset Tester 🎧

Aplicación de escritorio para Windows construida en Flutter diseñada para centros de llamadas y entornos de soporte. Monitorea en segundo plano el estado de los auriculares/diademas (bocina y micrófono) de manera visual y en tiempo real, permitiendo identificar al instante si un problema de audio es del dispositivo físico o del equipo del usuario, sin configuraciones complejas.

## Características Principales

- **Ejecución silenciosa en segundo plano (System Tray)**:
  - Funciona discretamente en el área de notificación de Windows.
  - Al hacer **clic izquierdo / clic principal** sobre el icono en la bandeja: despliega una ventana compacta tipo *Flyout* en la esquina inferior derecha (justo encima de la barra de tareas).
  - Al hacer **clic derecho**: menú contextual con la única opción de **"Salir"**.
- **Monitoreo visual en tiempo real**:
  - **Líneas/barras dinámicas de audio (VU Meter)** tanto para el micrófono como para los auriculares.
  - Si el usuario habla o entra sonido, las barras de voz se mueven de inmediato.
  - Si el usuario reproduce audio o recibe una llamada, las barras de bocina se mueven en tiempo real.
- **Herramientas de Comprobación Rápida**:
  - **Probar Bocina**: Reproduce un tono de confirmación (*beep*) nítido para verificar la salida de sonido.
  - **Probar Micrófono (Auto-reproducción)**: Graba 3 segundos de la voz del usuario y la retransmite instantáneamente a los auriculares para verificar calidad, volumen y ausencia de estática.
- **Ventana de Diagnóstico Inicial**:
  - Al iniciar la app por primera vez, muestra una pantalla de bienvenida que carga y comprueba los componentes de audio y el hardware conectado.
  - Al finalizar, muestra el estado **OK** y ofrece el botón **"Entendido, continuar en segundo plano"** para ocultar la ventana y permanecer en la bandeja.
- **Instalación a Nivel Administrador e Inicio Automático con Windows**:
  - Scripts automatizados para instalar en `C:\Program Files\Vincco\HeadsetTester`.
  - Registro de inicio automático en `HKLM\SOFTWARE\Microsoft\Windows\CurrentVersion\Run` con bandera `--background`.

---

## Estructura del Proyecto

```text
├── assets/
│   ├── icons/            # Iconos de la aplicación y bandeja del sistema
│   └── sounds/           # Tonos de audio de prueba (beep.wav)
├── installer/
│   ├── install_admin.ps1 # Script PowerShell de instalación con permisos de Administrador
│   └── uninstall_admin.ps1 # Script PowerShell de desinstalación
├── lib/
│   ├── models/           # Modelos de datos (HeadsetInfo)
│   ├── services/
│   │   ├── audio_monitor_service.dart # Servicio COM / Core Audio y medidores de pico en tiempo real
│   │   └── tray_and_window_service.dart # Gestión de la bandeja del sistema y posicionamiento Flyout
│   ├── widgets/
│   │   ├── audio_visualizer_bars.dart # Ecualizador visual / VU meter reactivo
│   │   ├── flyout_panel.dart          # Panel flotante de monitoreo y pruebas
│   │   └── startup_splash_dialog.dart # Ventana de carga y diagnóstico inicial (OK)
│   └── main.dart         # Punto de entrada y orquestador de modos de ejecución
├── Configurar_Entorno_Administrador.bat # Habilita Modo Desarrollador e instala VS C++ Build Tools
├── Compilar_Release.bat                # Compila el ejecutable Release para Windows
├── Instalar_Como_Administrador.bat     # Instala la aplicación y configura inicio con Windows
└── Desinstalar.bat                     # Desinstala la aplicación del sistema
```

---

## Requisitos de Compilación y Configuración

1. **Requisitos previos**:
   - Flutter SDK (Canal Stable).
   - Visual Studio Build Tools con la carga de trabajo *Desktop development with C++*.
   - Modo Desarrollador de Windows activo (para soporte de symlinks de plugins en Windows).

2. **Paso 1: Configurar el Entorno**:
   - Haz clic derecho sobre `Configurar_Entorno_Administrador.bat` y selecciona **"Ejecutar como administrador"**.
   - Esto activará el modo desarrollador e instalará las herramientas de compilación de C++.

3. **Paso 2: Compilar**:
   - Ejecuta `Compilar_Release.bat` (o el comando `flutter build windows --release`).

4. **Paso 3: Instalar como Administrador**:
   - Haz doble clic en `Instalar_Como_Administrador.bat`.
   - Se creará la entrada de inicio automático en Windows (`HKLM`) para que corra siempre al arrancar el equipo.

---

## Repositorio

- Repositorio remoto: `https://github.com/Janosos/Headset-tester-forVincco`
