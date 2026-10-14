import 'package:flutter/material.dart';
import '../models/headset_info.dart';
import '../services/audio_monitor_service.dart';
import '../services/tray_and_window_service.dart';
import 'audio_visualizer_bars.dart';

class FlyoutPanel extends StatelessWidget {
  const FlyoutPanel({super.key});

  @override
  Widget build(BuildContext context) {
    final audioService = AudioMonitorService();

    return Scaffold(
      backgroundColor: const Color(0xFF0B132B),
      body: Container(
        decoration: BoxDecoration(
          color: const Color(0xFF0B132B),
          border: Border.all(color: const Color(0xFF1E293B), width: 1.5),
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.6),
              blurRadius: 24,
              offset: const Offset(0, 8),
            )
          ],
        ),
        child: Column(
          children: [
            // Barra superior personalizada con botón de ocultar
            _buildHeader(context),

            // Contenido desplazable / organizado
            Expanded(
              child: SingleChildScrollView(
                physics: const BouncingScrollPhysics(),
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                child: Column(
                  children: [
                    // Estado General del Headset
                    _buildDeviceStatusCard(audioService),
                    const SizedBox(height: 12),

                    // Tarjeta de Bocina / Auricular
                    _buildSpeakerCard(audioService),
                    const SizedBox(height: 12),

                    // Tarjeta de Micrófono
                    _buildMicCard(audioService),
                  ],
                ),
              ),
            ),

            // Pie de página con botón de ocultar a la bandeja
            _buildFooter(),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: const BoxDecoration(
        color: Color(0xFF141F36),
        borderRadius: BorderRadius.only(
          topLeft: Radius.circular(14),
          topRight: Radius.circular(14),
        ),
        border: Border(bottom: BorderSide(color: Color(0xFF1E293B), width: 1)),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            children: [
              Container(
                width: 8,
                height: 8,
                decoration: const BoxDecoration(
                  color: Color(0xFF10B981),
                  shape: BoxShape.circle,
                  boxShadow: [
                    BoxShadow(
                      color: Color(0xFF10B981),
                      blurRadius: 6,
                    )
                  ],
                ),
              ),
              const SizedBox(width: 8),
              const Text(
                'Vincco Headset Tester',
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                  letterSpacing: 0.3,
                ),
              ),
            ],
          ),
          IconButton(
            onPressed: () => TrayAndWindowService().hideToTray(),
            icon: const Icon(
              Icons.close_rounded,
              color: Color(0xFF94A3B8),
              size: 18,
            ),
            splashRadius: 16,
            padding: EdgeInsets.zero,
            constraints: const BoxConstraints(minWidth: 26, minHeight: 26),
            tooltip: 'Ocultar a la bandeja',
          ),
        ],
      ),
    );
  }

  Widget _buildDeviceStatusCard(AudioMonitorService audioService) {
    return ValueListenableBuilder<HeadsetInfo>(
      valueListenable: audioService.headsetNotifier,
      builder: (context, info, _) {
        return Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          decoration: BoxDecoration(
            color: const Color(0xFF172554).withOpacity(0.4),
            borderRadius: BorderRadius.circular(10),
            border: Border.all(
              color: const Color(0xFF1E3A8A).withOpacity(0.5),
            ),
          ),
          child: const Row(
            children: [
              Icon(
                Icons.check_circle_outline_rounded,
                color: Color(0xFF38BDF8),
                size: 16,
              ),
              SizedBox(width: 8),
              Expanded(
                child: Text(
                  'Monitoreo activo en segundo plano',
                  style: TextStyle(
                    fontSize: 11,
                    color: Color(0xFFBAE6FD),
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildSpeakerCard(AudioMonitorService audioService) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: const Color(0xFF111C33),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFF1E293B)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(6),
                decoration: BoxDecoration(
                  color: const Color(0xFF0284C7).withOpacity(0.2),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Icon(
                  Icons.headphones_rounded,
                  color: Color(0xFF38BDF8),
                  size: 17,
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: ValueListenableBuilder<HeadsetInfo>(
                  valueListenable: audioService.headsetNotifier,
                  builder: (context, info, _) {
                    return Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'BOCINA / AURICULAR',
                          style: TextStyle(
                            fontSize: 10,
                            fontWeight: FontWeight.bold,
                            color: Color(0xFF94A3B8),
                            letterSpacing: 0.5,
                          ),
                        ),
                        Text(
                          info.speakerName,
                          style: const TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                            color: Colors.white,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    );
                  },
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),

          // Visualizador en vivo de la Bocina
          AudioVisualizerBars(
            barsStream: audioService.outputBarsStream,
            levelStream: audioService.outputLevelStream,
            label: 'NIVEL DE SALIDA EN TIEMPO REAL',
            gradientColors: const [
              Color(0xFF0284C7),
              Color(0xFF38BDF8),
              Color(0xFF10B981),
            ],
            activeGlowColor: const Color(0xFF38BDF8),
          ),
          const SizedBox(height: 10),

          // Botón Probar Bocina
          ValueListenableBuilder<bool>(
            valueListenable: audioService.isSpeakerTestingNotifier,
            builder: (context, isTesting, _) {
              return SizedBox(
                width: double.infinity,
                height: 34,
                child: OutlinedButton.icon(
                  onPressed: isTesting ? null : () => audioService.testSpeaker(),
                  icon: isTesting
                      ? const SizedBox(
                          width: 13,
                          height: 13,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: Color(0xFF38BDF8),
                          ),
                        )
                      : const Icon(Icons.volume_up_rounded, size: 16),
                  label: Text(
                    isTesting ? 'Reproduciendo Beep...' : 'Probar Bocina (Beep)',
                    style: const TextStyle(fontSize: 11.5, fontWeight: FontWeight.bold),
                  ),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: const Color(0xFF38BDF8),
                    side: BorderSide(
                      color: isTesting
                          ? const Color(0xFF38BDF8)
                          : const Color(0xFF0284C7).withOpacity(0.6),
                      width: 1,
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                    backgroundColor: isTesting
                        ? const Color(0xFF0284C7).withOpacity(0.15)
                        : Colors.transparent,
                  ),
                ),
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _buildMicCard(AudioMonitorService audioService) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: const Color(0xFF111C33),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFF1E293B)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(6),
                decoration: BoxDecoration(
                  color: const Color(0xFF8B5CF6).withOpacity(0.2),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Icon(
                  Icons.mic_rounded,
                  color: Color(0xFFA78BFA),
                  size: 17,
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: ValueListenableBuilder<HeadsetInfo>(
                  valueListenable: audioService.headsetNotifier,
                  builder: (context, info, _) {
                    return Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'MICRÓFONO',
                          style: TextStyle(
                            fontSize: 10,
                            fontWeight: FontWeight.bold,
                            color: Color(0xFF94A3B8),
                            letterSpacing: 0.5,
                          ),
                        ),
                        Text(
                          info.micName,
                          style: const TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                            color: Colors.white,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    );
                  },
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),

          // Visualizador en vivo del Micrófono
          AudioVisualizerBars(
            barsStream: audioService.inputBarsStream,
            levelStream: audioService.inputLevelStream,
            label: 'NIVEL DE ENTRADA / VOZ EN VIVO',
            gradientColors: const [
              Color(0xFF7C3AED),
              Color(0xFFA78BFA),
              Color(0xFFEC4899),
            ],
            activeGlowColor: const Color(0xFFA78BFA),
          ),
          const SizedBox(height: 10),

          // Botón Probar Micrófono (Grabación y loopback)
          ValueListenableBuilder<MicTestState>(
            valueListenable: audioService.micTestStateNotifier,
            builder: (context, state, _) {
              final isRecording = state == MicTestState.recording;
              final isPlaying = state == MicTestState.playingBack;
              final isBusy = isRecording || isPlaying;

              String buttonText = 'Probar Micrófono (Auto-reproducir voz)';
              if (isRecording) {
                buttonText = 'Grabando voz... habla ahora';
              } else if (isPlaying) {
                buttonText = 'Escuchando tu voz en bocina...';
              } else if (state == MicTestState.completed) {
                buttonText = 'Prueba OK - Repetir prueba';
              }

              return Column(
                children: [
                  SizedBox(
                    width: double.infinity,
                    height: 34,
                    child: OutlinedButton.icon(
                      onPressed: isBusy ? null : () => audioService.testMicrophone(),
                      icon: isBusy
                          ? const SizedBox(
                              width: 13,
                              height: 13,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                color: Color(0xFFA78BFA),
                              ),
                            )
                          : const Icon(Icons.mic_none_rounded, size: 16),
                      label: Text(
                        buttonText,
                        style: const TextStyle(
                          fontSize: 11.5,
                          fontWeight: FontWeight.bold,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: const Color(0xFFA78BFA),
                        side: BorderSide(
                          color: isBusy
                              ? const Color(0xFFA78BFA)
                              : const Color(0xFF8B5CF6).withOpacity(0.6),
                          width: 1,
                        ),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                        backgroundColor: isBusy
                            ? const Color(0xFF8B5CF6).withOpacity(0.15)
                            : Colors.transparent,
                      ),
                    ),
                  ),
                  if (isRecording) ...[
                    const SizedBox(height: 4),
                    ValueListenableBuilder<int>(
                      valueListenable: audioService.micTestSecondsLeftNotifier,
                      builder: (context, sec, _) {
                        return Text(
                          'Di "Hola probando" - Grabando ($sec s)...',
                          style: const TextStyle(
                            fontSize: 10,
                            color: Color(0xFFF472B6),
                            fontWeight: FontWeight.w600,
                          ),
                        );
                      },
                    ),
                  ],
                ],
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _buildFooter() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
      decoration: const BoxDecoration(
        color: Color(0xFF0F172A),
        borderRadius: BorderRadius.only(
          bottomLeft: Radius.circular(14),
          bottomRight: Radius.circular(14),
        ),
        border: Border(top: BorderSide(color: Color(0xFF1E293B), width: 1)),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          const Text(
            'v1.0 • Vincco Operaciones',
            style: TextStyle(
              fontSize: 10,
              color: Color(0xFF64748B),
            ),
          ),
          InkWell(
            onTap: () => TrayAndWindowService().hideToTray(),
            borderRadius: BorderRadius.circular(6),
            child: const Padding(
              padding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              child: Row(
                children: [
                  Icon(
                    Icons.arrow_downward_rounded,
                    size: 13,
                    color: Color(0xFF94A3B8),
                  ),
                  SizedBox(width: 4),
                  Text(
                    'Ocultar',
                    style: TextStyle(
                      fontSize: 10.5,
                      color: Color(0xFF94A3B8),
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
