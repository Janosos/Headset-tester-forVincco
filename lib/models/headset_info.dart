/// Representa el estado y metadatos de los dispositivos de audio (Headset).
class HeadsetInfo {
  final String speakerName;
  final String micName;
  final bool isSpeakerConnected;
  final bool isMicConnected;
  final double speakerVolume; // 0.0 to 1.0
  final double micVolume; // 0.0 to 1.0
  final bool isSpeakerMuted;
  final bool isMicMuted;

  const HeadsetInfo({
    required this.speakerName,
    required this.micName,
    this.isSpeakerConnected = true,
    this.isMicConnected = true,
    this.speakerVolume = 1.0,
    this.micVolume = 1.0,
    this.isSpeakerMuted = false,
    this.isMicMuted = false,
  });

  bool get isFullyReady => isSpeakerConnected && isMicConnected;

  HeadsetInfo copyWith({
    String? speakerName,
    String? micName,
    bool? isSpeakerConnected,
    bool? isMicConnected,
    double? speakerVolume,
    double? micVolume,
    bool? isSpeakerMuted,
    bool? isMicMuted,
  }) {
    return HeadsetInfo(
      speakerName: speakerName ?? this.speakerName,
      micName: micName ?? this.micName,
      isSpeakerConnected: isSpeakerConnected ?? this.isSpeakerConnected,
      isMicConnected: isMicConnected ?? this.isMicConnected,
      speakerVolume: speakerVolume ?? this.speakerVolume,
      micVolume: micVolume ?? this.micVolume,
      isSpeakerMuted: isSpeakerMuted ?? this.isSpeakerMuted,
      isMicMuted: isMicMuted ?? this.isMicMuted,
    );
  }
}
