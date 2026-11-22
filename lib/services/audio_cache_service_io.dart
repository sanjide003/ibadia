import 'dart:async';
import 'dart:io';

import 'package:audioplayers/audioplayers.dart';
import 'package:http/http.dart' as http;
import '../core/config/api_config.dart';

/// Native (Android/IO) low-data audio cache service.
/// Stores played Ayahs in a bounded 80 MB LRU cache directory so replaying
/// or seeking never re-downloads bytes, and deduplicates in-flight requests.
class AudioCacheService {
  AudioCacheService._();

  static final AudioCacheService instance = AudioCacheService._();

  static const int _maxCacheBytes = 80 * 1024 * 1024;
  static const int _targetAfterPruneBytes = 64 * 1024 * 1024;
  static const int _minValidAudioBytes = 512;

  final Map<String, Future<File?>> _inFlight = {};
  Directory? _cacheDir;
  int _writesSincePrune = 0;

  Future<Directory> _ensureCacheDir() async {
    final existing = _cacheDir;
    if (existing != null && await existing.exists()) {
      return existing;
    }
    final dir = Directory('${Directory.systemTemp.path}/alquran_audio_cache_v1');
    if (!await dir.exists()) {
      await dir.create(recursive: true);
    }
    _cacheDir = dir;
    return dir;
  }

  String _cacheKey(String reciterId, int surahNumber, int ayahNumber) {
    final safeReciter = reciterId.replaceAll(RegExp(r'[^a-zA-Z0-9._-]'), '_');
    return '${safeReciter}_${surahNumber}_$ayahNumber';
  }

  Future<Source?> resolvePlayableSource({
    required QuranReciter reciter,
    required int surahNumber,
    required int ayahNumber,
    required int globalAyahNumber,
  }) async {
    final file = await _getOrFetchFile(
      reciter: reciter,
      surahNumber: surahNumber,
      ayahNumber: ayahNumber,
      globalAyahNumber: globalAyahNumber,
    );
    if (file == null) return null;
    return DeviceFileSource(file.path);
  }

  Future<void> prefetchAyah({
    required QuranReciter reciter,
    required int surahNumber,
    required int ayahNumber,
    required int globalAyahNumber,
  }) async {
    try {
      await _getOrFetchFile(
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

  Future<File?> _getOrFetchFile({
    required QuranReciter reciter,
    required int surahNumber,
    required int ayahNumber,
    required int globalAyahNumber,
  }) async {
    final dir = await _ensureCacheDir();
    final key = _cacheKey(reciter.id, surahNumber, ayahNumber);
    final targetFile = File('${dir.path}/$key.mp3');

    if (await targetFile.exists()) {
      final size = await targetFile.length();
      if (size >= _minValidAudioBytes) {
        unawaited(
          targetFile.setLastModified(DateTime.now()).catchError((_) => targetFile),
        );
        return targetFile;
      }
      try {
        await targetFile.delete();
      } catch (_) {}
    }

    final existingInFlight = _inFlight[key];
    if (existingInFlight != null) {
      return existingInFlight;
    }

    final future = _downloadToCache(
      targetFile: targetFile,
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

  Future<File?> _downloadToCache({
    required File targetFile,
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

    List<int>? bytes = await _tryFetchBytes(primaryUrl);
    bytes ??= await _tryFetchBytes(fallbackUrl);
    if (bytes == null || bytes.length < _minValidAudioBytes) {
      return null;
    }

    final tmpFile = File('${targetFile.path}.tmp');
    try {
      await tmpFile.writeAsBytes(bytes, flush: true);
      if (await targetFile.exists()) {
        await targetFile.delete();
      }
      await tmpFile.rename(targetFile.path);

      _writesSincePrune++;
      if (_writesSincePrune >= 12) {
        _writesSincePrune = 0;
        unawaited(_pruneCacheIfNeeded());
      }
      return targetFile;
    } catch (_) {
      try {
        if (await tmpFile.exists()) await tmpFile.delete();
      } catch (_) {}
      return null;
    }
  }

  Future<List<int>?> _tryFetchBytes(String url) async {
    try {
      final res = await http
          .get(Uri.parse(url))
          .timeout(const Duration(seconds: 15));
      if (res.statusCode == 200 && res.bodyBytes.length >= _minValidAudioBytes) {
        return res.bodyBytes;
      }
    } catch (_) {}
    return null;
  }

  Future<void> _pruneCacheIfNeeded() async {
    try {
      final dir = _cacheDir;
      if (dir == null || !await dir.exists()) return;
      final entities = await dir.list().toList();
      final files = <(File file, int size, DateTime modified)>[];
      int totalBytes = 0;

      for (final entity in entities) {
        if (entity is! File || !entity.path.endsWith('.mp3')) continue;
        final stat = await entity.stat();
        totalBytes += stat.size;
        files.add((entity, stat.size, stat.modified));
      }

      if (totalBytes <= _maxCacheBytes) return;

      files.sort((a, b) => a.$3.compareTo(b.$3));
      for (final entry in files) {
        if (totalBytes <= _targetAfterPruneBytes) break;
        try {
          await entry.$1.delete();
          totalBytes -= entry.$2;
        } catch (_) {}
      }
    } catch (_) {}
  }
}
