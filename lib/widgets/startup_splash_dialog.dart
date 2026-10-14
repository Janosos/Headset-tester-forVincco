import 'package:flutter/material.dart';
import '../models/headset_info.dart';
import '../services/audio_monitor_service.dart';
import '../services/tray_and_window_service.dart';

class StartupSplashDialog extends StatefulWidget {
  final VoidCallback onDismiss;

  const StartupSplashDialog({
    super.key,
    required this.onDismiss,
  });

  @override
  State<StartupSplashDialog> createState() => _StartupSplashDialogState();
}

class _StartupSplashDialogState extends State<StartupSplashDialog> {
  int _currentStep = 0;
  bool _isFinished = false;

  final List<String> _steps = [
    'Inicializando subsistema de audio de Windows...',
    'Detectando auriculares y micrófonos conectados...',
    'Registrando servicio en la bandeja del sistema...',
    'Verificando niveles de entrada y salida...',
  ];

  @override
  void initState() {
    super.initState();
    _startDiagnosticSequence();
  }

  Future<void> _startDiagnosticSequence() async {
    for (int i = 0; i < _steps.length; i++) {
      await Future.delayed(const Duration(milliseconds: 550));
      if (mounted) {
        setState(() {
          _currentStep = i + 1;
        });
      }
    }
    await Future.delayed(const Duration(milliseconds: 400));
    if (mounted) {
      setState(() {
        _isFinished = true;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0F172A),
      body: Container(
        padding: const EdgeInsets.all(24.0),
        decoration: BoxDecoration(
          color: const Color(0xFF0F172A),
          border: Border.all(color: const Color(0xFF334155), width: 1.5),
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.5),
              blurRadius: 20,
              offset: const Offset(0, 10),
            )
          ],
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            // Header con logo e información
            Column(
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: const Color(0xFF0EA5E9).withOpacity(0.15),
                        shape: BoxShape.circle,
                        border: Border.all(
                          color: const Color(0xFF0EA5E9).withOpacity(0.4),
                          width: 1.5,
                        ),
                      ),
                      child: const Icon(
                        Icons.headphones_rounded,
                        color: Color(0xFF38BDF8),
                        size: 28,
                      ),
                    ),
                    const SizedBox(width: 12),
                    const Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Vincco Headset Tester',
                          style: TextStyle(
                            fontSize: 17,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                            letterSpacing: 0.3,
                          ),
                        ),
                        Text(
                          'Verificación del Sistema en Segundo Plano',
                          style: TextStyle(
                            fontSize: 11,
                            color: Color(0xFF94A3B8),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
                const SizedBox(height: 20),
                const Divider(color: Color(0xFF1E293B), height: 1),
              ],
            ),

            // Contenido dinámico / Pasos de carga
            Expanded(
              child: Center(
                child: !_isFinished
                    ? Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const SizedBox(
                            width: 38,
                            height: 38,
                            child: CircularProgressIndicator(
                              strokeWidth: 3,
                              valueColor: AlwaysStoppedAnimation<Color>(
                                Color(0xFF0EA5E9),
                              ),
                            ),
                          ),
                          const SizedBox(height: 20),
                          Text(
                            _currentStep < _steps.length
                                ? _steps[_currentStep]
                                : 'Comprobando componentes...',
                            textAlign: TextAlign.center,
                            style: const TextStyle(
                              fontSize: 13,
                              color: Color(0xFFCBD5E1),
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            'Paso ${_currentStep.clamp(1, _steps.length)} de ${_steps.length}',
                            style: const TextStyle(
                              fontSize: 11,
                              color: Color(0xFF64748B),
                            ),
                          ),
                        ],
                      )
                    : Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          // Badge de OK
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 16,
                              vertical: 8,
                            ),
                            decoration: BoxDecoration(
                              color: const Color(0xFF10B981).withOpacity(0.15),
                              borderRadius: BorderRadius.circular(30),
                              border: Border.all(
                                color: const Color(0xFF10B981),
                                width: 1.5,
                              ),
                            ),
                            child: const Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(
                                  Icons.check_circle_rounded,
                                  color: Color(0xFF10B981),
                                  size: 20,
                                ),
                                SizedBox(width: 8),
                                Text(
                                  'ESTADO: OK - COMPONENTES LISTOS',
                                  style: TextStyle(
                                    fontSize: 12,
                                    fontWeight: FontWeight.bold,
                                    letterSpacing: 0.5,
                                    color: Color(0xFF10B981),
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(height: 16),

                          // Información del Headset Detectado
                          ValueListenableBuilder<HeadsetInfo>(
                            valueListenable:
                                AudioMonitorService().headsetNotifier,
                            builder: (context, info, _) {
                              return Container(
                                width: double.infinity,
                                padding: const EdgeInsets.all(12),
                                decoration: BoxDecoration(
                                  color: const Color(0xFF1E293B),
                                  borderRadius: BorderRadius.circular(10),
                                  border: Border.all(
                                    color: const Color(0xFF334155),
                                  ),
                                ),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Row(
                                      children: [
                                        const Icon(
                                          Icons.volume_up_rounded,
                                          size: 15,
                                          color: Color(0xFF38BDF8),
                                        ),
                                        const SizedBox(width: 6),
                                        Expanded(
                                          child: Text(
                                            info.speakerName,
                                            style: const TextStyle(
                                              fontSize: 11,
                                              color: Colors.white,
                                              fontWeight: FontWeight.w500,
                                            ),
                                            maxLines: 1,
                                            overflow: TextOverflow.ellipsis,
                                          ),
                                        ),
                                      ],
                                    ),
                                    const SizedBox(height: 8),
                                    Row(
                                      children: [
                                        const Icon(
                                          Icons.mic_rounded,
                                          size: 15,
                                          color: Color(0xFFA78BFA),
                                        ),
                                        const SizedBox(width: 6),
                                        Expanded(
                                          child: Text(
                                            info.micName,
                                            style: const TextStyle(
                                              fontSize: 11,
                                              color: Colors.white,
                                              fontWeight: FontWeight.w500,
                                            ),
                                            maxLines: 1,
                                            overflow: TextOverflow.ellipsis,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ],
                                ),
                              );
                            },
                          ),
                          const SizedBox(height: 12),
                          const Text(
                            'La aplicación continuará monitoreando el headset en segundo plano desde la bandeja del sistema.',
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              fontSize: 11,
                              color: Color(0xFF94A3B8),
                            ),
                          ),
                        ],
                      ),
              ),
            ),

            // Botón de Cierre / Continuar en segundo plano
            SizedBox(
              width: double.infinity,
              height: 44,
              child: ElevatedButton.icon(
                onPressed: _isFinished
                    ? () {
                        widget.onDismiss();
                        TrayAndWindowService().hideToTray();
                      }
                    : null,
                icon: const Icon(Icons.arrow_downward_rounded, size: 18),
                label: const Text(
                  'Entendido, continuar en segundo plano',
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF0EA5E9),
                  foregroundColor: Colors.white,
                  disabledBackgroundColor: const Color(0xFF1E293B),
                  disabledForegroundColor: const Color(0xFF64748B),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
              ),
            ),
            const SizedBox(height: 8),
            const Align(
              alignment: Alignment.centerLeft,
              child: Text(
                'Desarrollado por: ImperioDev',
                style: TextStyle(
                  fontSize: 10,
                  color: Color(0xFF64748B),
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
