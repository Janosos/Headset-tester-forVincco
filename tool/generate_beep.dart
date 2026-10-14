import 'dart:io';
import 'dart:math';
import 'dart:typed_data';

void main() {
  const sampleRate = 44100;
  const duration = 0.4; // 400ms
  const freq = 880.0; // A5 tone
  final totalSamples = (sampleRate * duration).round();
  final subchunk2Size = totalSamples * 2;
  final chunkSize = 36 + subchunk2Size;

  final buffer = BytesBuilder();
  // RIFF header
  buffer.add('RIFF'.codeUnits);
  final headerByteData = ByteData(4)..setUint32(0, chunkSize, Endian.little);
  buffer.add(headerByteData.buffer.asUint8List());
  buffer.add('WAVE'.codeUnits);
  buffer.add('fmt '.codeUnits);
  final fmtSubchunkSize = ByteData(4)..setUint32(0, 16, Endian.little);
  buffer.add(fmtSubchunkSize.buffer.asUint8List());

  final fmtByteData = ByteData(16)
    ..setUint16(0, 1, Endian.little)  // AudioFormat = PCM (2 bytes)
    ..setUint16(2, 1, Endian.little)  // NumChannels = 1 (2 bytes)
    ..setUint32(4, sampleRate, Endian.little) // SampleRate (4 bytes)
    ..setUint32(8, sampleRate * 2, Endian.little) // ByteRate (4 bytes)
    ..setUint16(12, 2, Endian.little) // BlockAlign (2 bytes)
    ..setUint16(14, 16, Endian.little); // BitsPerSample (2 bytes)
  buffer.add(fmtByteData.buffer.asUint8List());

  // data chunk
  buffer.add('data'.codeUnits);
  final dataByteData = ByteData(4)..setUint32(0, subchunk2Size, Endian.little);
  buffer.add(dataByteData.buffer.asUint8List());

  final pcmData = ByteData(totalSamples * 2);
  for (var i = 0; i < totalSamples; i++) {
    final t = i / sampleRate;
    var fade = 1.0;
    if (i < 500) {
      fade = i / 500.0;
    } else if (i > totalSamples - 500) {
      fade = (totalSamples - i) / 500.0;
    }
    final sample = (sin(2 * pi * freq * t) * 22000 * fade).round().clamp(-32768, 32767);
    pcmData.setInt16(i * 2, sample, Endian.little);
  }
  buffer.add(pcmData.buffer.asUint8List());

  final outFile = File('assets/sounds/beep.wav');
  outFile.parent.createSync(recursive: true);
  outFile.writeAsBytesSync(buffer.toBytes());
  print('WAV generated: ${outFile.path} (${outFile.lengthSync()} bytes)');
}
