import 'dart:async';
import 'dart:io';
import 'dart:math';
import 'package:audioplayers/audioplayers.dart';
import 'package:flutter/foundation.dart';
import 'package:path_provider/path_provider.dart';
import 'package:record/record.dart';
import 'package:win32/win32.dart';
import '../models/headset_info.dart';

enum MicTestState {
  idle,
  recording,
  playingBack,
  completed,
}

class AudioMonitorService {
  static final AudioMonitorService _instance = AudioMonitorService._internal();
  factory AudioMonitorService() => _instance;
  AudioMonitorService._internal();

  final _outputLevelController = StreamController<double>.broadcast();
  final _inputLevelController = StreamController<double>.broadcast();
  final _outputBarsController = StreamController<List<double>>.broadcast();
  final _inputBarsController = StreamController<List<double>>.broadcast();

  Stream<double> get outputLevelStream => _outputLevelController.stream;
  Stream<double> get inputLevelStream => _inputLevelController.stream;
  Stream<List<double>> get outputBarsStream => _outputBarsController.stream;
  Stream<List<double>> get inputBarsStream => _inputBarsController.stream;

  final ValueNotifier<HeadsetInfo> headsetNotifier = ValueNotifier(
    const HeadsetInfo(
      speakerName: 'Auriculares / Bocina Vincco (Activo)',
      micName: 'Micrófono de Headset Vincco (Activo)',
    ),
  );

  final ValueNotifier<MicTestState> micTestStateNotifier =
      ValueNotifier(MicTestState.idle);
  final ValueNotifier<int> micTestSecondsLeftNotifier = ValueNotifier(0);
  final ValueNotifier<bool> isSpeakerTestingNotifier = ValueNotifier(false);

  Timer? _pollingTimer;
  StreamSubscription<Amplitude>? _amplitudeSubscription;
  final AudioPlayer _audioPlayer = AudioPlayer();
  final AudioRecorder _audioRecorder = AudioRecorder();

  // Multi-bar visualizer state (12 barras)
  final List<double> _outputBars = List.filled(12, 0.05);
  final List<double> _inputBars = List.filled(12, 0.05);
  final Random _rng = Random();

  double _currentMicLevel = 0.0;
  double _currentSpeakerLevel = 0.0;
  bool _initialized = false;
  String? _recordedFilePath;

  Future<void> initialize() async {
    if (_initialized) return;
    _initialized = true;

    // Detectar dispositivos de audio conectados
    await _detectAudioDevices();

    // Iniciar escucha reactiva del micrófono
    await _startMicMonitoring();

    // Temporizador para actualizar la animación visual del VU meter (~30 fps)
    _pollingTimer = Timer.periodic(
      const Duration(milliseconds: 35),
      (_) => _updateAudioLevels(),
    );
  }

  Future<void> _detectAudioDevices() async {
    try {
      String speakerName = 'Auriculares / Bocina predeterminada';
      String micName = 'Micrófono de diadema predeterminado';

      // Consultar dispositivos de entrada mediante record
      final hasPerm = await _audioRecorder.hasPermission();
      if (hasPerm) {
        final devices = await _audioRecorder.listInputDevices();
        if (devices.isNotEmpty) {
          // Tomar el micrófono activo o el primer dispositivo detectado
          final first = devices.first;
          if (first.label.isNotEmpty) {
            micName = first.label;
            // Si el nombre indica auricular o headset, asociar también a la bocina
            if (first.label.toLowerCase().contains('headset') ||
                first.label.toLowerCase().contains('usb') ||
                first.label.toLowerCase().contains('auricular') ||
                first.label.toLowerCase().contains('hyperx') ||
                first.label.toLowerCase().contains('jbl')) {
              speakerName = 'Auricular ${first.label}';
            }
          }
        }
      }

      headsetNotifier.value = HeadsetInfo(
        speakerName: speakerName,
        micName: micName,
        isSpeakerConnected: true,
        isMicConnected: true,
      );
    } catch (e) {
      debugPrint('Error detectando dispositivos de audio: $e');
    }
  }

  Future<void> _startMicMonitoring() async {
    try {
      if (await _audioRecorder.hasPermission()) {
        // Iniciar flujo de monitoreo de amplitud
        final stream = await _audioRecorder.startStream(
          const RecordConfig(
            encoder: AudioEncoder.pcm16bits,
            sampleRate: 16000,
            numChannels: 1,
          ),
        );

        // Descartar bytes de streaming para no consumir memoria
        stream.listen((_) {});

        // Escuchar niveles continuos de amplitud
        _amplitudeSubscription = _audioRecorder
            .onAmplitudeChanged(const Duration(milliseconds: 50))
            .listen((amplitude) {
          // Amplitud dB suele oscilar entre -60 (silencio) y 0 (máximo)
          final db = amplitude.current;
          if (db > -60.0) {
            final normalized = ((db + 50.0) / 45.0).clamp(0.05, 1.0);
            _currentMicLevel = normalized;
          } else {
            _currentMicLevel = 0.04;
          }
        });
      }
    } catch (e) {
      debugPrint('Nota monitoreo de mic: $e');
    }
  }

  void _updateAudioLevels() {
    double outLevel = _currentSpeakerLevel;
    double inLevel = _currentMicLevel;

    // Si estamos probando bocina, inyectar ondas visuales dinámicas
    if (isSpeakerTestingNotifier.value) {
      outLevel = 0.70 + (_rng.nextDouble() * 0.28);
    } else {
      outLevel = max(0.04, outLevel - 0.05);
    }
    _currentSpeakerLevel = outLevel;

    // Suavizar nivel de micrófono
    _currentMicLevel = max(0.04, _currentMicLevel - 0.03);

    _outputLevelController.add(outLevel);
    _inputLevelController.add(inLevel);

    // Calcular las 12 barras del ecualizador
    _calculateBars(_outputBars, outLevel);
    _calculateBars(_inputBars, inLevel);

    _outputBarsController.add(List.unmodifiable(_outputBars));
    _inputBarsController.add(List.unmodifiable(_inputBars));
  }

  void _calculateBars(List<double> bars, double peakLevel) {
    for (int i = 0; i < bars.length; i++) {
      final factor =
          0.65 + (sin(i * 0.85 + DateTime.now().millisecondsSinceEpoch * 0.015) * 0.35);
      final target = (peakLevel * factor).clamp(0.05, 1.0);

      if (target > bars[i]) {
        bars[i] = target; // Ataque rápido
      } else {
        bars[i] = max(0.05, bars[i] - 0.06); // Decaimiento suave
      }
    }
  }

  /// Prueba de Bocina: Reproduce un tono de comprobación nítido
  Future<void> testSpeaker() async {
    if (isSpeakerTestingNotifier.value) return;
    isSpeakerTestingNotifier.value = true;

    try {
      await _audioPlayer.stop();
      await _audioPlayer.play(AssetSource('sounds/beep.wav'));

      if (Platform.isWindows) {
        Beep(880, 250);
      }
    } catch (e) {
      debugPrint('Error en testSpeaker: $e');
      if (Platform.isWindows) {
        Beep(880, 300);
      }
    } finally {
      await Future.delayed(const Duration(milliseconds: 650));
      isSpeakerTestingNotifier.value = false;
    }
  }

  /// Prueba de Micrófono: Graba la voz del usuario durante 3 segundos
  /// y la reproduce inmediatamente en los auriculares para auto-verificación.
  Future<void> testMicrophone() async {
    if (micTestStateNotifier.value != MicTestState.idle &&
        micTestStateNotifier.value != MicTestState.completed) {
      return;
    }

    try {
      // Pausar temporalmente el monitor continuo
      await _amplitudeSubscription?.cancel();
      if (await _audioRecorder.isRecording()) {
        await _audioRecorder.stop();
      }

      final tempDir = await getTemporaryDirectory();
      _recordedFilePath = '${tempDir.path}/vincco_mic_test.m4a';

      if (await _audioRecorder.hasPermission()) {
        micTestStateNotifier.value = MicTestState.recording;
        micTestSecondsLeftNotifier.value = 3;

        await _audioRecorder.start(
          const RecordConfig(encoder: AudioEncoder.aacLc),
          path: _recordedFilePath!,
        );

        // Cuenta regresiva 3 segundos
        for (int i = 3; i > 0; i--) {
          micTestSecondsLeftNotifier.value = i;
          await Future.delayed(const Duration(seconds: 1));
        }

        await _audioRecorder.stop();

        // Modo reproducción de la propia voz grabada
        micTestStateNotifier.value = MicTestState.playingBack;
        _currentSpeakerLevel = 0.8;
        await _audioPlayer.stop();
        await _audioPlayer.play(DeviceFileSource(_recordedFilePath!));

        await Future.delayed(const Duration(seconds: 3));
        await _audioPlayer.stop();

        micTestStateNotifier.value = MicTestState.completed;
      }
    } catch (e) {
      debugPrint('Error en testMicrophone: $e');
      micTestStateNotifier.value = MicTestState.idle;
    } finally {
      // Reanudar monitoreo continuo
      await _startMicMonitoring();
    }
  }

  void dispose() {
    _pollingTimer?.cancel();
    _amplitudeSubscription?.cancel();
    _outputLevelController.close();
    _inputLevelController.close();
    _outputBarsController.close();
    _inputBarsController.close();
    _audioPlayer.dispose();
    _audioRecorder.dispose();
  }
}
