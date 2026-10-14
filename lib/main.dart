import 'dart:io';
import 'package:flutter/material.dart';
import 'package:window_manager/window_manager.dart';
import 'services/audio_monitor_service.dart';
import 'services/tray_and_window_service.dart';
import 'widgets/flyout_panel.dart';
import 'widgets/startup_splash_dialog.dart';

void main(List<String> args) async {
  WidgetsFlutterBinding.ensureInitialized();

  final bool startMinimized =
      args.contains('--minimized') || args.contains('--background');

  if (Platform.isWindows) {
    await windowManager.ensureInitialized();

    const initialSize = Size(440, 480);
    const windowOptions = WindowOptions(
      size: initialSize,
      center: true,
      backgroundColor: Colors.transparent,
      skipTaskbar: false,
      title: 'Vincco Headset Tester',
      titleBarStyle: TitleBarStyle.normal,
    );

    await windowManager.waitUntilReadyToShow(windowOptions, () async {
      if (startMinimized) {
        await windowManager.hide();
      } else {
        await windowManager.show();
        await windowManager.focus();
      }
    });

    // Iniciar servicios
    await AudioMonitorService().initialize();
    await TrayAndWindowService().initialize(startMinimized: startMinimized);
  }

  runApp(HeadsetTesterApp(startMinimized: startMinimized));
}

class HeadsetTesterApp extends StatelessWidget {
  final bool startMinimized;

  const HeadsetTesterApp({
    super.key,
    required this.startMinimized,
  });

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Vincco Headset Tester',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        brightness: Brightness.dark,
        scaffoldBackgroundColor: const Color(0xFF0F172A),
        colorScheme: const ColorScheme.dark(
          primary: Color(0xFF0EA5E9),
          secondary: Color(0xFF10B981),
          surface: Color(0xFF1E293B),
        ),
        fontFamily: 'Segoe UI',
      ),
      home: HeadsetTesterRoot(startMinimized: startMinimized),
    );
  }
}

class HeadsetTesterRoot extends StatefulWidget {
  final bool startMinimized;

  const HeadsetTesterRoot({
    super.key,
    required this.startMinimized,
  });

  @override
  State<HeadsetTesterRoot> createState() => _HeadsetTesterRootState();
}

class _HeadsetTesterRootState extends State<HeadsetTesterRoot> {
  late bool _showSplash;

  @override
  void initState() {
    super.initState();
    // Si se inicia minimizado (ej. inicio de Windows), saltar directo al modo flyout
    _showSplash = !widget.startMinimized;
  }

  void _onDismissSplash() {
    setState(() {
      _showSplash = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    if (_showSplash) {
      return StartupSplashDialog(
        onDismiss: _onDismissSplash,
      );
    }

    return const FlyoutPanel();
  }
}
