import 'dart:math' as math;
import 'dart:typed_data';

class NativeRingingAlarm {
  final String prayerKey;
  final String title;
  final String timeLabel;
  final String dateKey;

  const NativeRingingAlarm({
    required this.prayerKey,
    required this.title,
    required this.timeLabel,
    required this.dateKey,
  });

  factory NativeRingingAlarm.fromMap(Map<dynamic, dynamic> raw) {
    return NativeRingingAlarm(
      prayerKey: (raw['prayerKey'] ?? '').toString(),
      title: (raw['title'] ?? '').toString(),
      timeLabel: (raw['timeLabel'] ?? '').toString(),
      dateKey: (raw['dateKey'] ?? '').toString(),
    );
  }
}

/// Generates a clean harmonic WAV chime in memory for `alarm_tone` previews
/// and Web foreground reminders without external assets.
Uint8List buildSoftChimeWavBytes() {
  const sampleRate = 22050;
  const durationSec = 1.4;
  final numSamples = (sampleRate * durationSec).toInt();
  final byteData = ByteData(44 + numSamples * 2);

  void writeAscii(int offset, String s) {
    for (int i = 0; i < s.length; i++) {
      byteData.setUint8(offset + i, s.codeUnitAt(i));
    }
  }

  writeAscii(0, 'RIFF');
  byteData.setUint32(4, 36 + numSamples * 2, Endian.little);
  writeAscii(8, 'WAVE');
  writeAscii(12, 'fmt ');
  byteData.setUint32(16, 16, Endian.little); // PCM
  byteData.setUint16(20, 1, Endian.little); // Linear PCM
  byteData.setUint16(22, 1, Endian.little); // Mono
  byteData.setUint32(24, sampleRate, Endian.little);
  byteData.setUint32(28, sampleRate * 2, Endian.little);
  byteData.setUint16(32, 2, Endian.little);
  byteData.setUint16(34, 16, Endian.little);
  writeAscii(36, 'data');
  byteData.setUint32(40, numSamples * 2, Endian.little);

  // Two-note gentle chime: C5 (523.25 Hz) -> G5 (783.99 Hz)
  for (int i = 0; i < numSamples; i++) {
    final t = i / sampleRate;
    double sample = 0.0;
    if (t < 0.75) {
      final env = math.exp(-4.2 * t) * math.min(1.0, t / 0.015);
      sample += 0.55 *
          env *
          (math.sin(2 * math.pi * 523.25 * t) +
              0.35 * math.sin(2 * math.pi * 1046.5 * t));
    }
    if (t >= 0.35) {
      final t2 = t - 0.35;
      final env2 = math.exp(-3.4 * t2) * math.min(1.0, t2 / 0.015);
      sample += 0.65 *
          env2 *
          (math.sin(2 * math.pi * 783.99 * t2) +
              0.25 * math.sin(2 * math.pi * 1567.98 * t2));
    }
    final pcm = (sample.clamp(-0.95, 0.95) * 32767.0).round();
    byteData.setInt16(44 + i * 2, pcm, Endian.little);
  }

  return byteData.buffer.asUint8List();
}
