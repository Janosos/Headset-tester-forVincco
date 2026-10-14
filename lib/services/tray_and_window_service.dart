import 'dart:io';
import 'package:flutter/material.dart';
import 'package:screen_retriever/screen_retriever.dart';
import 'package:tray_manager/legacy.dart';
import 'package:window_manager/window_manager.dart';

class TrayAndWindowService with TrayListener, WindowListener {
  static final TrayAndWindowService _instance =
      TrayAndWindowService._internal();
  factory TrayAndWindowService() => _instance;
  TrayAndWindowService._internal();

  bool _isFlyoutMode = false;
  bool get isFlyoutMode => _isFlyoutMode;

  final ValueNotifier<bool> isWindowVisibleNotifier = ValueNotifier(true);

  Future<void> initialize({bool startMinimized = false}) async {
    trayManager.addListener(this);
    windowManager.addListener(this);

    // Configurar icono en la bandeja del sistema
    final iconPath = Platform.isWindows
        ? 'assets/icons/tray_icon.ico'
        : 'assets/icons/tray_icon.png';

    await trayManager.setIcon(iconPath);
    await trayManager.setToolTip('Headset Tester Vincco - Monitoreo Activo');

    // Menú contextual para clic derecho: ÚNICAMENTE "Salir"
    final menu = Menu(
      items: [
        MenuItem(
          key: 'exit_app',
          label: 'Salir',
          onClick: (_) => exitApp(),
        ),
      ],
    );
    await trayManager.setContextMenu(menu);

    if (startMinimized) {
      await hideToTray();
    }
  }

  /// Cambia la ventana a modo Flyout (pequeña y ubicada en la esquina inferior derecha)
  Future<void> switchToFlyoutMode() async {
    _isFlyoutMode = true;

    try {
      final primaryDisplay = await screenRetriever.getPrimaryDisplay();
      final screenWidth = primaryDisplay.size.width;
      final screenHeight = primaryDisplay.size.height;

      const flyoutWidth = 360.0;
      const flyoutHeight = 520.0;

      // Colocar justo arriba del área de notificación (bandeja de Windows)
      final x = screenWidth - flyoutWidth - 16;
      final y = screenHeight - flyoutHeight - 60; // Dejar espacio para la barra de tareas

      await windowManager.setSize(const Size(flyoutWidth, flyoutHeight));
      await windowManager.setPosition(Offset(x, y));
      await windowManager.setResizable(false);
      await windowManager.setAlwaysOnTop(true);
      await windowManager.setTitleBarStyle(TitleBarStyle.hidden);
    } catch (e) {
      debugPrint('Error posicionando flyout: $e');
    }
  }

  /// Oculta la ventana y la envía a segundo plano en la bandeja
  Future<void> hideToTray() async {
    await switchToFlyoutMode();
    await windowManager.hide();
    isWindowVisibleNotifier.value = false;
  }

  /// Alterna entre mostrar y ocultar la ventana tipo flyout al hacer clic en el icono de la bandeja
  Future<void> toggleFlyout() async {
    final isVisible = await windowManager.isVisible();
    if (isVisible) {
      await windowManager.hide();
      isWindowVisibleNotifier.value = false;
    } else {
      await switchToFlyoutMode();
      await windowManager.show();
      await windowManager.focus();
      isWindowVisibleNotifier.value = true;
    }
  }

  @override
  void onTrayIconMouseDown() {
    // Clic principal (izquierdo): abrir / cerrar la ventana pequeña
    toggleFlyout();
  }

  @override
  void onTrayMenuItemClick(MenuItem menuItem) {
    if (menuItem.key == 'exit_app') {
      exitApp();
    }
  }

  void exitApp() {
    trayManager.removeListener(this);
    windowManager.removeListener(this);
    trayManager.destroy();
    windowManager.destroy();
    exit(0);
  }

  void dispose() {
    trayManager.removeListener(this);
    windowManager.removeListener(this);
  }
}
