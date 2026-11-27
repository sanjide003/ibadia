import 'dart:convert';

import 'package:http/http.dart' as http;

import '../core/config/api_config.dart';
import '../models/surah_model.dart';
import 'hive_db.dart';
import 'tajweed_engine.dart';

class QuranApiService {
  static List<SurahSummary>? _memSurahList;
  static final Map<int, ({SurahSummary summary, List<AyahItem> ayahs})>
      _memArabicSurah = {};
  static final Map<String, List<String>> _memSurahTranslations = {};
  static final Map<int, List<JuzAyahEntry>> _memJuzArabic = {};
  static final Map<String, List<String>> _memJuzTranslations = {};

  static const String _bismillahPrefix =
      'بِسْمِ ٱللَّهِ ٱلرَّحْمَٰنِ ٱلرَّحِيمِ ';

  static final RegExp _bismillahTaggedPrefix = RegExp(
    r'^بِسْمِ\s+\[[^\]]+\]للَّهِ\s+\[[^\]]+\]\[[^\]]+\]رَّحْمَ\[[^\]]+\]نِ\s+\[[^\]]+\]\[[^\]]+\]رَّح\[[^\]]+\]مِ\s*',
  );

  static const String _surahListCacheKey = 'cache_surah_list_v3';

  String _stripBismillahIfNeeded(
    String rawText, {
    required int surahNumber,
    required int ayahInSurah,
  }) {
    if (surahNumber == 1 || surahNumber == 9 || ayahInSurah != 1) {
      return rawText;
    }
    if (rawText.startsWith(_bismillahPrefix)) {
      return rawText.substring(_bismillahPrefix.length).trim();
    }
    final match = _bismillahTaggedPrefix.matchAsPrefix(rawText);
    if (match != null) {
      return rawText.substring(match.end).trim();
    }
    return rawText;
  }

  Future<Map<String, dynamic>> _getSurahPayloadWithFallback(
    int surahNumber,
  ) async {
    try {
      final uri = Uri.parse(
        '${ApiConfig.quranBaseUrl}/surah/$surahNumber/${ApiConfig.tajweedArabicEdition}',
      );
      final res = await http.get(uri).timeout(const Duration(seconds: 25));
      if (res.statusCode >= 200 && res.statusCode < 300) {
        final body = jsonDecode(res.body) as Map<String, dynamic>;
        final data = body['data'];
        if (data is Map && (data['ayahs'] as List?)?.isNotEmpty == true) {
          return {'data': Map<String, dynamic>.from(data), 'isTajweed': true};
        }
      }
    } catch (_) {}

    final uri = Uri.parse(
      '${ApiConfig.quranBaseUrl}/surah/$surahNumber/${ApiConfig.arabicEdition}',
    );
    final res = await http.get(uri).timeout(const Duration(seconds: 25));
    if (res.statusCode < 200 || res.statusCode >= 300) {
      throw Exception(
        'Failed to load Surah $surahNumber (HTTP ${res.statusCode})',
      );
    }
    final body = jsonDecode(res.body) as Map<String, dynamic>;
    return {
      'data': Map<String, dynamic>.from(body['data'] as Map),
      'isTajweed': false,
    };
  }

  Future<Map<String, dynamic>> _getJuzPayloadWithFallback(
    int juzNumber,
  ) async {
    try {
      final uri = Uri.parse(
        '${ApiConfig.quranBaseUrl}/juz/$juzNumber/${ApiConfig.tajweedArabicEdition}',
      );
      final res = await http.get(uri).timeout(const Duration(seconds: 25));
      if (res.statusCode >= 200 && res.statusCode < 300) {
        final body = jsonDecode(res.body) as Map<String, dynamic>;
        final data = body['data'];
        if (data is Map && (data['ayahs'] as List?)?.isNotEmpty == true) {
          return {'data': Map<String, dynamic>.from(data), 'isTajweed': true};
        }
      }
    } catch (_) {}

    final uri = Uri.parse(
      '${ApiConfig.quranBaseUrl}/juz/$juzNumber/${ApiConfig.arabicEdition}',
    );
    final res = await http.get(uri).timeout(const Duration(seconds: 25));
    if (res.statusCode < 200 || res.statusCode >= 300) {
      throw Exception('Failed Juz $juzNumber (HTTP ${res.statusCode})');
    }
    final body = jsonDecode(res.body) as Map<String, dynamic>;
    return {
      'data': Map<String, dynamic>.from(body['data'] as Map),
      'isTajweed': false,
    };
  }

  String _editionForCode(String code) {
    if (code == 'ml') return ApiConfig.malayalamTranslationEdition;
    if (code == 'ar') return ApiConfig.arabicTafsirEdition;
    return ApiConfig.englishTranslationEdition;
  }

  Future<List<SurahSummary>> fetchSurahList() async {
    if (_memSurahList != null && _memSurahList!.isNotEmpty) {
      return _memSurahList!;
    }

    await HiveDb.instance.ensureInitialized();
    final box = HiveDb.instance.quranCacheBox;
    final rawCached = box.get(_surahListCacheKey);
    if (rawCached is String && rawCached.isNotEmpty) {
      try {
        final decoded = jsonDecode(rawCached) as List<dynamic>;
        final list = decoded
            .whereType<Map>()
            .map((e) => SurahSummary.fromJson(Map<String, dynamic>.from(e)))
            .toList();
        if (list.isNotEmpty) {
          _memSurahList = list;
          return list;
        }
      } catch (_) {}
    }

    final uri = Uri.parse('${ApiConfig.quranBaseUrl}/surah');
    final res = await http.get(uri).timeout(const Duration(seconds: 20));
    if (res.statusCode < 200 || res.statusCode >= 300) {
      throw Exception('Failed to load Surah list (HTTP ${res.statusCode})');
    }

    final body = jsonDecode(res.body) as Map<String, dynamic>;
    final rawList = (body['data'] as List<dynamic>? ?? const []);
    final surahs = rawList
        .whereType<Map>()
        .map((e) => SurahSummary.fromJson(Map<String, dynamic>.from(e)))
        .toList();

    _memSurahList = surahs;
    await box.put(
      _surahListCacheKey,
      jsonEncode(surahs.map((s) => s.toJson()).toList()),
    );
    return surahs;
  }

  Future<({SurahSummary summary, List<AyahItem> ayahs})> _fetchArabicSurah(
    int surahNumber,
  ) async {
    final mem = _memArabicSurah[surahNumber];
    if (mem != null) return mem;

    await HiveDb.instance.ensureInitialized();
    final box = HiveDb.instance.quranCacheBox;
    final key = 'cache_surah_ar_v4_$surahNumber';
    final rawCached = box.get(key);
    if (rawCached is String && rawCached.isNotEmpty) {
      try {
        final decoded = jsonDecode(rawCached) as Map<String, dynamic>;
        final summary = SurahSummary.fromJson(
          Map<String, dynamic>.from(decoded['summary'] as Map),
        );
        final ayahs = (decoded['ayahs'] as List<dynamic>)
            .whereType<Map>()
            .map((e) => AyahItem.fromJson(Map<String, dynamic>.from(e)))
            .toList();
        if (ayahs.isNotEmpty) {
          final payload = (summary: summary, ayahs: ayahs);
          _memArabicSurah[surahNumber] = payload;
          return payload;
        }
      } catch (_) {}
    }

    final fetched = await _getSurahPayloadWithFallback(surahNumber);
    final d = fetched['data'] as Map<String, dynamic>;
    final isTajweedEdition = fetched['isTajweed'] == true;
    final summary = SurahSummary.fromJson(d);
    final rawAyahs = (d['ayahs'] as List<dynamic>? ?? const []);
    final ayahs = rawAyahs.whereType<Map>().map((raw) {
      final m = Map<String, dynamic>.from(raw);
      final numInSurah = (m['numberInSurah'] as num?)?.toInt() ?? 1;
      final rawText = _stripBismillahIfNeeded(
        (m['text'] ?? '').toString(),
        surahNumber: surahNumber,
        ayahInSurah: numInSurah,
      );
      final cleanText = isTajweedEdition
          ? TajweedEngine.stripMarkup(rawText)
          : rawText;
      return AyahItem(
        numberInSurah: numInSurah,
        globalNumber: (m['number'] as num?)?.toInt() ?? 1,
        arabicText: cleanText,
        tajweedTaggedText: isTajweedEdition ? rawText : null,
        juz: (m['juz'] as num?)?.toInt() ?? 1,
        page: (m['page'] as num?)?.toInt() ?? 1,
      );
    }).toList();

    final payload = (summary: summary, ayahs: ayahs);
    _memArabicSurah[surahNumber] = payload;
    await box.put(
      key,
      jsonEncode({
        'summary': summary.toJson(),
        'ayahs': ayahs.map((a) => a.toJson()).toList(),
      }),
    );
    return payload;
  }

  Future<List<String>> _fetchSurahTranslation(
    int surahNumber,
    String code,
  ) async {
    final memKey = '${surahNumber}_$code';
    final mem = _memSurahTranslations[memKey];
    if (mem != null) return mem;

    await HiveDb.instance.ensureInitialized();
    final box = HiveDb.instance.quranCacheBox;
    final cacheKey = 'cache_surah_tr_v3_${surahNumber}_$code';
    final rawCached = box.get(cacheKey);
    if (rawCached is String && rawCached.isNotEmpty) {
      try {
        final decoded = jsonDecode(rawCached) as List<dynamic>;
        final list = decoded.map((e) => e.toString()).toList();
        _memSurahTranslations[memKey] = list;
        return list;
      } catch (_) {}
    }

    try {
      final edition = _editionForCode(code);
      final uri = Uri.parse(
        '${ApiConfig.quranBaseUrl}/surah/$surahNumber/$edition',
      );
      final res = await http.get(uri).timeout(const Duration(seconds: 25));
      if (res.statusCode < 200 || res.statusCode >= 300) return const [];
      final body = jsonDecode(res.body) as Map<String, dynamic>;
      final data = body['data'] as Map<String, dynamic>?;
      final ayahs = (data?['ayahs'] as List<dynamic>? ?? const []);
      final texts = ayahs
          .whereType<Map>()
          .map((a) => (a['text'] ?? '').toString())
          .toList();
      _memSurahTranslations[memKey] = texts;
      await box.put(cacheKey, jsonEncode(texts));
      return texts;
    } catch (_) {
      return const [];
    }
  }

  Future<SurahDetail> fetchSurahDetail({
    required int surahNumber,
    required List<String> requiredTranslations,
  }) async {
    final base = await _fetchArabicSurah(surahNumber);
    final translations = <String, List<String>>{};

    if (requiredTranslations.isNotEmpty) {
      final uniqueCodes = requiredTranslations.toSet().toList();
      final results = await Future.wait(
        uniqueCodes.map(
          (code) async => MapEntry(
            code,
            await _fetchSurahTranslation(surahNumber, code),
          ),
        ),
      );
      for (final entry in results) {
        translations[entry.key] = entry.value;
      }
    }

    return SurahDetail(
      summary: base.summary,
      ayahs: base.ayahs,
      translations: translations,
    );
  }

  Future<List<JuzAyahEntry>> _fetchJuzArabic(int juzNumber) async {
    final mem = _memJuzArabic[juzNumber];
    if (mem != null) return mem;

    await HiveDb.instance.ensureInitialized();
    final box = HiveDb.instance.quranCacheBox;
    final cacheKey = 'cache_juz_ar_v4_$juzNumber';
    final rawCached = box.get(cacheKey);
    if (rawCached is String && rawCached.isNotEmpty) {
      try {
        final decoded = jsonDecode(rawCached) as List<dynamic>;
        final list = decoded
            .whereType<Map>()
            .map((e) => JuzAyahEntry.fromJson(Map<String, dynamic>.from(e)))
            .toList();
        if (list.isNotEmpty) {
          _memJuzArabic[juzNumber] = list;
          return list;
        }
      } catch (_) {}
    }

    final fetched = await _getJuzPayloadWithFallback(juzNumber);
    final data = fetched['data'] as Map<String, dynamic>?;
    final isTajweedEdition = fetched['isTajweed'] == true;
    final rawAyahs = (data?['ayahs'] as List<dynamic>? ?? const []);

    final entries = rawAyahs.whereType<Map>().map((raw) {
      final m = Map<String, dynamic>.from(raw);
      final sMap = Map<String, dynamic>.from((m['surah'] as Map?) ?? {});
      final surah = SurahSummary.fromJson(sMap);
      final numInSurah = (m['numberInSurah'] as num?)?.toInt() ?? 1;
      final rawText = _stripBismillahIfNeeded(
        (m['text'] ?? '').toString(),
        surahNumber: surah.number,
        ayahInSurah: numInSurah,
      );
      final cleanText = isTajweedEdition
          ? TajweedEngine.stripMarkup(rawText)
          : rawText;
      return JuzAyahEntry(
        surah: surah,
        ayah: AyahItem(
          numberInSurah: numInSurah,
          globalNumber: (m['number'] as num?)?.toInt() ?? 1,
          arabicText: cleanText,
          tajweedTaggedText: isTajweedEdition ? rawText : null,
          juz: (m['juz'] as num?)?.toInt() ?? juzNumber,
          page: (m['page'] as num?)?.toInt() ?? 1,
        ),
      );
    }).toList();

    _memJuzArabic[juzNumber] = entries;
    await box.put(
      cacheKey,
      jsonEncode(entries.map((e) => e.toJson()).toList()),
    );
    return entries;
  }

  Future<List<String>> _fetchJuzTranslation(
    int juzNumber,
    String code,
  ) async {
    final memKey = '${juzNumber}_$code';
    final mem = _memJuzTranslations[memKey];
    if (mem != null) return mem;

    await HiveDb.instance.ensureInitialized();
    final box = HiveDb.instance.quranCacheBox;
    final cacheKey = 'cache_juz_tr_v3_${juzNumber}_$code';
    final rawCached = box.get(cacheKey);
    if (rawCached is String && rawCached.isNotEmpty) {
      try {
        final decoded = jsonDecode(rawCached) as List<dynamic>;
        final list = decoded.map((e) => e.toString()).toList();
        _memJuzTranslations[memKey] = list;
        return list;
      } catch (_) {}
    }

    try {
      final edition = _editionForCode(code);
      final uri = Uri.parse(
        '${ApiConfig.quranBaseUrl}/juz/$juzNumber/$edition',
      );
      final res = await http.get(uri).timeout(const Duration(seconds: 25));
      if (res.statusCode < 200 || res.statusCode >= 300) return const [];
      final body = jsonDecode(res.body) as Map<String, dynamic>;
      final data = body['data'] as Map<String, dynamic>?;
      final ayahs = (data?['ayahs'] as List<dynamic>? ?? const []);
      final texts = ayahs
          .whereType<Map>()
          .map((a) => (a['text'] ?? '').toString())
          .toList();
      _memJuzTranslations[memKey] = texts;
      await box.put(cacheKey, jsonEncode(texts));
      return texts;
    } catch (_) {
      return const [];
    }
  }

  Future<JuzDetail> fetchJuzDetail({
    required int juzNumber,
    required List<String> requiredTranslations,
  }) async {
    final entries = await _fetchJuzArabic(juzNumber);
    final translations = <String, List<String>>{};

    if (requiredTranslations.isNotEmpty) {
      final uniqueCodes = requiredTranslations.toSet().toList();
      final results = await Future.wait(
        uniqueCodes.map(
          (code) async => MapEntry(
            code,
            await _fetchJuzTranslation(juzNumber, code),
          ),
        ),
      );
      for (final entry in results) {
        translations[entry.key] = entry.value;
      }
    }

    return JuzDetail(
      juzNumber: juzNumber,
      entries: entries,
      translations: translations,
    );
  }
}
