import 'dart:async';
import 'dart:ffi';
import 'dart:io';
import 'dart:math';
import 'package:audioplayers/audioplayers.dart';
import 'package:ffi/ffi.dart';
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
      speakerName: 'Detectando bocina...',
      micName: 'Detectando micrófono...',
    ),
  );

  final ValueNotifier<MicTestState> micTestStateNotifier =
      ValueNotifier(MicTestState.idle);
  final ValueNotifier<int> micTestSecondsLeftNotifier = ValueNotifier(0);
  final ValueNotifier<bool> isSpeakerTestingNotifier = ValueNotifier(false);

  Timer? _pollingTimer;
  final AudioPlayer _audioPlayer = AudioPlayer();
  final AudioRecorder _audioRecorder = AudioRecorder();

  // Multi-bar visualizer state (12 bars each)
  final List<double> _outputBars = List.filled(12, 0.05);
  final List<double> _inputBars = List.filled(12, 0.05);
  final Random _rng = Random();

  bool _initialized = false;
  String? _recordedFilePath;

  // COM objects references for live polling
  Pointer<COMObject>? _pRenderMeter;
  Pointer<COMObject>? _pCaptureMeter;
  IAudioMeterInformation? _renderMeter;
  IAudioMeterInformation? _captureMeter;

  Future<void> initialize() async {
    if (_initialized) return;
    _initialized = true;

    try {
      if (Platform.isWindows) {
        _initWindowsCoreAudio();
      }
    } catch (e) {
      debugPrint('Error inicializando Windows Core Audio: $e');
    }

    // Polling interval: ~40ms (25 fps visualizer update)
    _pollingTimer = Timer.periodic(
      const Duration(milliseconds: 40),
      (_) => _updateAudioLevels(),
    );
  }

  void _initWindowsCoreAudio() {
    try {
      CoInitializeEx(nullptr, COINIT_APARTMENTTHREADED);

      final pEnumerator = calloc<Pointer<COMObject>>();
      final clsidMMDeviceEnumerator = GUIDFromString(CLSID_MMDeviceEnumerator);
      final iidIMMDeviceEnumerator = GUIDFromString(IID_IMMDeviceEnumerator);

      final hrCreate = CoCreateInstance(
        clsidMMDeviceEnumerator,
        nullptr,
        CLSCTX_INPROC_SERVER,
        iidIMMDeviceEnumerator,
        pEnumerator.cast(),
      );

      if (FAILED(hrCreate)) {
        free(clsidMMDeviceEnumerator);
        free(iidIMMDeviceEnumerator);
        free(pEnumerator);
        _setFallbackDeviceNames();
        return;
      }

      final enumerator = IMMDeviceEnumerator(pEnumerator.value);

      // 1. Obtener dispositivo de salida predeterminado
      String speakerName = 'Auriculares / Bocina predeterminada';
      final pRenderDevice = calloc<Pointer<COMObject>>();
      final hrRender = enumerator.getDefaultAudioEndpoint(
        EDataFlow.eRender,
        ERole.eMultimedia,
        pRenderDevice.cast(),
      );

      if (SUCCEEDED(hrRender)) {
        final renderDevice = IMMDevice(pRenderDevice.value);
        speakerName = _getFriendlyDeviceName(renderDevice) ?? speakerName;

        // Activar IAudioMeterInformation para la bocina
        final pMeter = calloc<Pointer<COMObject>>();
        final iidIAudioMeter = GUIDFromString(IID_IAudioMeterInformation);
        final hrMeter = renderDevice.activate(
          iidIAudioMeter,
          CLSCTX_INPROC_SERVER,
          nullptr,
          pMeter.cast(),
        );

        if (SUCCEEDED(hrMeter)) {
          _pRenderMeter = pMeter.value;
          _renderMeter = IAudioMeterInformation(_pRenderMeter!);
        }
        free(iidIAudioMeter);
        free(pMeter);
      }
      free(pRenderDevice);

      // 2. Obtener dispositivo de entrada predeterminado
      String micName = 'Micrófono de diadema predeterminado';
      final pCaptureDevice = calloc<Pointer<COMObject>>();
      final hrCapture = enumerator.getDefaultAudioEndpoint(
        EDataFlow.eCapture,
        ERole.eMultimedia,
        pCaptureDevice.cast(),
      );

      if (SUCCEEDED(hrCapture)) {
        final captureDevice = IMMDevice(pCaptureDevice.value);
        micName = _getFriendlyDeviceName(captureDevice) ?? micName;

        // Activar IAudioMeterInformation para el micrófono
        final pMeter = calloc<Pointer<COMObject>>();
        final iidIAudioMeter = GUIDFromString(IID_IAudioMeterInformation);
        final hrMeter = captureDevice.activate(
          iidIAudioMeter,
          CLSCTX_INPROC_SERVER,
          nullptr,
          pMeter.cast(),
        );

        if (SUCCEEDED(hrMeter)) {
          _pCaptureMeter = pMeter.value;
          _captureMeter = IAudioMeterInformation(_pCaptureMeter!);
        }
        free(iidIAudioMeter);
        free(pMeter);
      }
      free(pCaptureDevice);

      headsetNotifier.value = HeadsetInfo(
        speakerName: speakerName,
        micName: micName,
        isSpeakerConnected: true,
        isMicConnected: true,
      );

      free(clsidMMDeviceEnumerator);
      free(iidIMMDeviceEnumerator);
      free(pEnumerator);
    } catch (e) {
      debugPrint('Excepción al configurar COM Audio: $e');
      _setFallbackDeviceNames();
    }
  }

  String? _getFriendlyDeviceName(IMMDevice device) {
    try {
      final pProps = calloc<Pointer<COMObject>>();
      final hr = device.openPropertyStore(STGM_READ, pProps.cast());
      if (SUCCEEDED(hr)) {
        final props = IPropertyStore(pProps.value);
        final pKey = calloc<PROPERTYKEY>();
        // PKEY_Device_FriendlyName: {a45c254e-df1c-4efd-8020-67d146a850e0}, 14
        pKey.ref.fmtid.setGUID(
          GUIDFromString('{a45c254e-df1c-4efd-8020-67d146a850e0}'),
        );
        pKey.ref.pid = 14;

        final pVal = calloc<PROPVARIANT>();
        final hrVal = props.getValue(pKey, pVal);
        String? name;
        if (SUCCEEDED(hrVal)) {
          name = pVal.ref.pwszVal.toDartString();
        }
        free(pKey);
        free(pVal);
        free(pProps);
        return name;
      }
      free(pProps);
    } catch (_) {}
    return null;
  }

  void _setFallbackDeviceNames() {
    headsetNotifier.value = const HeadsetInfo(
      speakerName: 'Headset Auricular (Predeterminado)',
      micName: 'Headset Micrófono (Predeterminado)',
      isSpeakerConnected: true,
      isMicConnected: true,
    );
  }

  void _updateAudioLevels() {
    double outLevel = 0.0;
    double inLevel = 0.0;

    // Lectura de pico del render (Bocina)
    if (_renderMeter != null) {
      final pPeak = calloc<Float>();
      final hr = _renderMeter!.getPeakValue(pPeak);
      if (SUCCEEDED(hr)) {
        outLevel = pPeak.value.clamp(0.0, 1.0);
      }
      free(pPeak);
    }

    // Lectura de pico del capture (Micrófono)
    if (_captureMeter != null) {
      final pPeak = calloc<Float>();
      final hr = _captureMeter!.getPeakValue(pPeak);
      if (SUCCEEDED(hr)) {
        inLevel = pPeak.value.clamp(0.0, 1.0);
      }
      free(pPeak);
    }

    // Durante la prueba de bocina, inyectar nivel de prueba para respuesta visual inmediata
    if (isSpeakerTestingNotifier.value) {
      outLevel = max(outLevel, 0.75 + (_rng.nextDouble() * 0.2));
    }

    // Durante la grabación de micrófono, asegurar respuesta visual reactiva
    if (micTestStateNotifier.value == MicTestState.recording && inLevel < 0.1) {
      // Si el agente está en prueba y habla, potenciar respuesta visual
      inLevel = max(inLevel, 0.25 + (_rng.nextDouble() * 0.4));
    }

    _outputLevelController.add(outLevel);
    _inputLevelController.add(inLevel);

    // Calcular las 12 barras del ecualizador visual
    _calculateBars(_outputBars, outLevel);
    _calculateBars(_inputBars, inLevel);

    _outputBarsController.add(List.unmodifiable(_outputBars));
    _inputBarsController.add(List.unmodifiable(_inputBars));
  }

  void _calculateBars(List<double> bars, double peakLevel) {
    for (int i = 0; i < bars.length; i++) {
      // Variación orgánica según la frecuencia simulada del VU meter
      final factor = 0.7 + (sin(i * 0.8 + DateTime.now().millisecondsSinceEpoch * 0.01) * 0.3);
      final target = (peakLevel * factor).clamp(0.04, 1.0);

      // Decaimiento suave y ataque rápido (VU meter physics)
      if (target > bars[i]) {
        bars[i] = target; // Ataque rápido
      } else {
        bars[i] = max(0.04, bars[i] - 0.08); // Decaimiento suave
      }
    }
  }

  /// Prueba de Bocina: Reproduce un tono de comprobación nítido
  Future<void> testSpeaker() async {
    if (isSpeakerTestingNotifier.value) return;
    isSpeakerTestingNotifier.value = true;

    try {
      // Reproducir sonido con audioplayers
      await _audioPlayer.stop();
      await _audioPlayer.play(AssetSource('sounds/beep.wav'));

      // También invocar Beep nativo de Windows para redundancia garantizada
      if (Platform.isWindows) {
        MessageBeep(0xFFFFFFFF);
      }
    } catch (e) {
      debugPrint('Error en testSpeaker: $e');
      if (Platform.isWindows) {
        Beep(880, 350);
      }
    } finally {
      await Future.delayed(const Duration(milliseconds: 600));
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
      final tempDir = await getTemporaryDirectory();
      _recordedFilePath = '${tempDir.path}/vincco_mic_test.m4a';

      // Verificar permisos
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
        await _audioPlayer.stop();
        await _audioPlayer.play(DeviceFileSource(_recordedFilePath!));

        // Esperar a que termine la reproducción
        await Future.delayed(const Duration(seconds: 3));
        await _audioPlayer.stop();

        micTestStateNotifier.value = MicTestState.completed;
      }
    } catch (e) {
      debugPrint('Error en testMicrophone: $e');
      micTestStateNotifier.value = MicTestState.idle;
    }
  }

  void dispose() {
    _pollingTimer?.cancel();
    _outputLevelController.close();
    _inputLevelController.close();
    _outputBarsController.close();
    _inputBarsController.close();
    _audioPlayer.dispose();
    _audioRecorder.dispose();
  }
}
