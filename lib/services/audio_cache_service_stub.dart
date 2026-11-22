import 'package:audioplayers/audioplayers.dart';
import '../core/config/api_config.dart';

class AudioCacheService {
  AudioCacheService._();

  static final AudioCacheService instance = AudioCacheService._();

  Future<Source?> resolvePlayableSource({
    required QuranReciter reciter,
    required int surahNumber,
    required int ayahNumber,
    required int globalAyahNumber,
  }) async {
    return UrlSource(
      ApiConfig.alQuranCloudAudioUrl(
        reciter: reciter,
        globalAyahNumber: globalAyahNumber,
      ),
    );
  }

  Future<void> prefetchAyah({
    required QuranReciter reciter,
    required int surahNumber,
    required int ayahNumber,
    required int globalAyahNumber,
  }) async {}

  Source fallbackUrlSource({
    required QuranReciter reciter,
    required int surahNumber,
    required int ayahNumber,
  }) {
    return UrlSource(
      ApiConfig.everyAyahAudioUrl(
        reciter: reciter,
        surahNumber: surahNumber,
        ayahNumber: ayahNumber,
      ),
    );
  }
}
