import 'dart:async';
import 'dart:collection';
import 'dart:typed_data';

import 'package:audioplayers/audioplayers.dart';
import 'package:http/http.dart' as http;
import '../core/config/api_config.dart';

/// Web low-data audio cache service.
/// Keeps played Ayahs in a bounded in-memory LRU byte cache (served as Data URI
/// so repeated playback uses 0 bytes) and deduplicates in-flight fetches.
/// Falls back to direct streaming `UrlSource` if browser CORS blocks XHR/fetch.
class AudioCacheService {
  AudioCacheService._();

  static final AudioCacheService instance = AudioCacheService._();

  static const int _maxEntries = 48;
  static const int _maxBytes = 25 * 1024 * 1024;
  static const int _minValidAudioBytes = 512;

  final LinkedHashMap<String, Uint8List> _memCache =
      LinkedHashMap<String, Uint8List>();
  int _memTotalBytes = 0;
  final Map<String, Future<Uint8List?>> _inFlight = {};

  String _cacheKey(String reciterId, int surahNumber, int ayahNumber) =>
      '$reciterId:$surahNumber:$ayahNumber';

  Future<Source?> resolvePlayableSource({
    required QuranReciter reciter,
    required int surahNumber,
    required int ayahNumber,
    required int globalAyahNumber,
  }) async {
    final cachedBytes = await _getOrFetchBytes(
      reciter: reciter,
      surahNumber: surahNumber,
      ayahNumber: ayahNumber,
      globalAyahNumber: globalAyahNumber,
    );
    if (cachedBytes != null) {
      return UrlSource(
        Uri.dataFromBytes(cachedBytes, mimeType: 'audio/mpeg').toString(),
      );
    }

    // If fetch was blocked by browser CORS, <audio src> streaming still works cleanly.
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
  }) async {
    try {
      await _getOrFetchBytes(
        reciter: reciter,
        surahNumber: surahNumber,
        ayahNumber: ayahNumber,
        globalAyahNumber: globalAyahNumber,
      );
    } catch (_) {}
  }

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

  Future<Uint8List?> _getOrFetchBytes({
    required QuranReciter reciter,
    required int surahNumber,
    required int ayahNumber,
    required int globalAyahNumber,
  }) async {
    final key = _cacheKey(reciter.id, surahNumber, ayahNumber);
    final existing = _memCache.remove(key);
    if (existing != null) {
      _memCache[key] = existing;
      return existing;
    }

    final inFlight = _inFlight[key];
    if (inFlight != null) {
      return inFlight;
    }

    final future = _fetchAndCacheBytes(
      key: key,
      reciter: reciter,
      surahNumber: surahNumber,
      ayahNumber: ayahNumber,
      globalAyahNumber: globalAyahNumber,
    );
    _inFlight[key] = future;
    try {
      return await future;
    } finally {
      if (_inFlight[key] == future) {
        _inFlight.remove(key);
      }
    }
  }

  Future<Uint8List?> _fetchAndCacheBytes({
    required String key,
    required QuranReciter reciter,
    required int surahNumber,
    required int ayahNumber,
    required int globalAyahNumber,
  }) async {
    final primaryUrl = ApiConfig.alQuranCloudAudioUrl(
      reciter: reciter,
      globalAyahNumber: globalAyahNumber,
    );
    final fallbackUrl = ApiConfig.everyAyahAudioUrl(
      reciter: reciter,
      surahNumber: surahNumber,
      ayahNumber: ayahNumber,
    );

    Uint8List? bytes = await _tryHttpGet(primaryUrl);
    bytes ??= await _tryHttpGet(fallbackUrl);
    if (bytes == null || bytes.length < _minValidAudioBytes) {
      return null;
    }

    _insertLru(key, bytes);
    return bytes;
  }

  Future<Uint8List?> _tryHttpGet(String url) async {
    try {
      final res = await http
          .get(Uri.parse(url))
          .timeout(const Duration(seconds: 12));
      if (res.statusCode == 200 && res.bodyBytes.length >= _minValidAudioBytes) {
        return res.bodyBytes;
      }
    } catch (_) {}
    return null;
  }

  void _insertLru(String key, Uint8List bytes) {
    final prev = _memCache.remove(key);
    if (prev != null) {
      _memTotalBytes -= prev.length;
    }
    _memCache[key] = bytes;
    _memTotalBytes += bytes.length;

    while (_memCache.length > _maxEntries || _memTotalBytes > _maxBytes) {
      if (_memCache.isEmpty) break;
      final oldestKey = _memCache.keys.first;
      final removed = _memCache.remove(oldestKey);
      if (removed != null) {
        _memTotalBytes -= removed.length;
      }
    }
  }
}
