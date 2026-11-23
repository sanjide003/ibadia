import 'dart:convert';
import 'package:hive_ce_flutter/hive_flutter.dart';
import 'package:http/http.dart' as http;
import '../core/config/api_config.dart';
import '../models/surah_model.dart';
import 'hive_db.dart';

class QuranApiService {
  static const String _surahListCacheKey = 'cache_surah_list_v3';
  static List<SurahSummary>? _memSurahList;
  static final Map<int, SurahDetail> _memArabicCache = {};
  static final Map<String, List<String>> _memTranslationCache = {};
  static final Map<int, JuzDetail> _memJuzArabicCache = {};
  static final Map<String, List<String>> _memJuzTranslationCache = {};

  Future<Box<dynamic>> _cacheBox() async {
    await HiveDb.instance.ensureInitialized();
    return HiveDb.instance.quranCacheBox;
  }

  Future<List<SurahSummary>> fetchSurahList() async {
    if (_memSurahList != null) return _memSurahList!;

    final box = await _cacheBox();
    final cached = box.get(_surahListCacheKey) as String?;
    if (cached != null) {
      final decoded = jsonDecode(cached) as List<dynamic>;
      _memSurahList = decoded
          .map((e) => SurahSummary.fromJson(e as Map<String, dynamic>))
          .toList();
      return _memSurahList!;
    }

    final uri = Uri.parse('${ApiConfig.baseUrl}/surah');
    final response = await http
        .get(uri, headers: ApiConfig.buildHeaders())
        .timeout(const Duration(seconds: 20));

    if (response.statusCode != 200) {
      throw Exception('Failed to load Surahs (HTTP ${response.statusCode})');
    }

    final body = jsonDecode(response.body) as Map<String, dynamic>;
    final data = body['data'] as List<dynamic>;
    final surahs = data
        .map((e) => SurahSummary.fromJson(e as Map<String, dynamic>))
        .toList();

    _memSurahList = surahs;
    await box.put(
      _surahListCacheKey,
      jsonEncode(surahs.map((s) => s.toJson()).toList()),
    );
    return surahs;
  }

  /// Fetches ONLY Arabic text + the exact translation languages currently enabled.
  /// Every edition is cached in memory and Hive for instant offline loading.
  Future<SurahDetail> fetchSurahDetail({
    required int surahNumber,
    required List<String> requiredTranslations,
  }) async {
    final box = await _cacheBox();
    final baseData = await _fetchArabicBase(box, surahNumber);

    final Map<String, List<String>> loadedTranslations = {};
    if (requiredTranslations.isNotEmpty) {
      final futures = requiredTranslations.map((code) async {
        final texts = await _fetchTranslationEdition(box, surahNumber, code);
        return MapEntry(code, texts);
      });
      final entries = await Future.wait(futures);
      for (final entry in entries) {
        loadedTranslations[entry.key] = entry.value;
      }
    }

    return SurahDetail(
      summary: baseData.summary,
      ayahs: baseData.ayahs,
      translations: loadedTranslations,
    );
  }

  Future<SurahDetail> _fetchArabicBase(
    Box<dynamic> box,
    int surahNumber,
  ) async {
    final memHit = _memArabicCache[surahNumber];
    if (memHit != null) return memHit;

    final cacheKey = 'cache_ar_v3_$surahNumber';
    final cached = box.get(cacheKey) as String?;
    if (cached != null) {
      final decoded = jsonDecode(cached) as Map<String, dynamic>;
      final detail = SurahDetail(
        summary:
            SurahSummary.fromJson(decoded['summary'] as Map<String, dynamic>),
        ayahs: (decoded['ayahs'] as List<dynamic>)
            .map((e) => AyahItem.fromJson(e as Map<String, dynamic>))
            .toList(),
      );
      _memArabicCache[surahNumber] = detail;
      return detail;
    }

    final res = await http
        .get(
          Uri.parse(
            '${ApiConfig.baseUrl}/surah/$surahNumber/${ApiConfig.arabicEdition}',
          ),
          headers: ApiConfig.buildHeaders(),
        )
        .timeout(const Duration(seconds: 20));

    if (res.statusCode != 200) {
      throw Exception('Failed to load Surah $surahNumber');
    }

    final arData = (jsonDecode(res.body) as Map<String, dynamic>)['data']
        as Map<String, dynamic>;
    final summary = SurahSummary.fromJson(arData);
    final rawAyahs = arData['ayahs'] as List<dynamic>;

    final ayahs = rawAyahs.map((item) {
      final map = item as Map<String, dynamic>;
      String text = (map['text'] ?? '') as String;
      // Strip leading Bismillah from Ayah 1 of Surahs other than 1 and 9
      if (surahNumber != 1 &&
          surahNumber != 9 &&
          (map['numberInSurah'] as int) == 1) {
        const bismillahPrefix = 'بِسْمِ ٱللَّهِ ٱلرَّحْمَٰنِ ٱلرَّحِيمِ ';
        if (text.startsWith(bismillahPrefix)) {
          text = text.substring(bismillahPrefix.length).trim();
        }
      }
      return AyahItem(
        numberInSurah: map['numberInSurah'] as int,
        globalNumber: map['number'] as int,
        arabicText: text,
        juz: (map['juz'] ?? 1) as int,
        page: (map['page'] ?? 1) as int,
      );
    }).toList();

    await box.put(
      cacheKey,
      jsonEncode({
        'summary': summary.toJson(),
        'ayahs': ayahs.map((a) => a.toJson()).toList(),
      }),
    );

    final detail = SurahDetail(summary: summary, ayahs: ayahs);
    _memArabicCache[surahNumber] = detail;
    return detail;
  }

  Future<List<String>> _fetchTranslationEdition(
    Box<dynamic> box,
    int surahNumber,
    String langCode,
  ) async {
    final cacheKey = 'cache_tr_v3_${surahNumber}_$langCode';
    final memHit = _memTranslationCache[cacheKey];
    if (memHit != null) return memHit;

    final cached = box.get(cacheKey) as String?;
    if (cached != null) {
      final list = (jsonDecode(cached) as List<dynamic>)
          .map((e) => e.toString())
          .toList();
      _memTranslationCache[cacheKey] = list;
      return list;
    }

    final edition = _editionForCode(langCode);
    final res = await http
        .get(
          Uri.parse('${ApiConfig.baseUrl}/surah/$surahNumber/$edition'),
          headers: ApiConfig.buildHeaders(),
        )
        .timeout(const Duration(seconds: 20));

    if (res.statusCode != 200) {
      return const [];
    }

    final data = (jsonDecode(res.body) as Map<String, dynamic>)['data']
        as Map<String, dynamic>;
    final texts = (data['ayahs'] as List<dynamic>)
        .map((e) => ((e as Map<String, dynamic>)['text'] ?? '') as String)
        .toList();

    _memTranslationCache[cacheKey] = texts;
    await box.put(cacheKey, jsonEncode(texts));
    return texts;
  }

  Future<JuzDetail> fetchJuzDetail({
    required int juzNumber,
    required List<String> requiredTranslations,
  }) async {
    final box = await _cacheBox();
    final baseData = await _fetchJuzArabic(box, juzNumber);

    final Map<String, List<String>> loadedTranslations = {};
    if (requiredTranslations.isNotEmpty) {
      final futures = requiredTranslations.map((code) async {
        final texts = await _fetchJuzTranslationEdition(box, juzNumber, code);
        return MapEntry(code, texts);
      });
      final entries = await Future.wait(futures);
      for (final entry in entries) {
        loadedTranslations[entry.key] = entry.value;
      }
    }

    return JuzDetail(
      juzNumber: juzNumber,
      entries: baseData.entries,
      translations: loadedTranslations,
    );
  }

  Future<JuzDetail> _fetchJuzArabic(
    Box<dynamic> box,
    int juzNumber,
  ) async {
    final memHit = _memJuzArabicCache[juzNumber];
    if (memHit != null) return memHit;

    final cacheKey = 'cache_juz_ar_v3_$juzNumber';
    final cached = box.get(cacheKey) as String?;
    if (cached != null) {
      final decoded = jsonDecode(cached) as List<dynamic>;
      final entries = decoded.map((item) {
        final m = item as Map<String, dynamic>;
        return JuzAyahEntry(
          surah: SurahSummary.fromJson(m['surah'] as Map<String, dynamic>),
          ayah: AyahItem.fromJson(m['ayah'] as Map<String, dynamic>),
        );
      }).toList();
      final detail = JuzDetail(juzNumber: juzNumber, entries: entries);
      _memJuzArabicCache[juzNumber] = detail;
      return detail;
    }

    final res = await http
        .get(
          Uri.parse(
            '${ApiConfig.baseUrl}/juz/$juzNumber/${ApiConfig.arabicEdition}',
          ),
          headers: ApiConfig.buildHeaders(),
        )
        .timeout(const Duration(seconds: 25));

    if (res.statusCode != 200) {
      throw Exception('Failed to load Juz $juzNumber');
    }

    final juzData = (jsonDecode(res.body) as Map<String, dynamic>)['data']
        as Map<String, dynamic>;
    final rawAyahs = juzData['ayahs'] as List<dynamic>;

    final entries = rawAyahs.map((item) {
      final map = item as Map<String, dynamic>;
      final surahMap = map['surah'] as Map<String, dynamic>;
      final surah = SurahSummary.fromJson(surahMap);
      final numInSurah = map['numberInSurah'] as int;
      String text = (map['text'] ?? '') as String;

      if (surah.number != 1 && surah.number != 9 && numInSurah == 1) {
        const bismillahPrefix = 'بِسْمِ ٱللَّهِ ٱلرَّحْمَٰنِ ٱلرَّحِيمِ ';
        if (text.startsWith(bismillahPrefix)) {
          text = text.substring(bismillahPrefix.length).trim();
        }
      }

      final ayah = AyahItem(
        numberInSurah: numInSurah,
        globalNumber: map['number'] as int,
        arabicText: text,
        juz: (map['juz'] ?? juzNumber) as int,
        page: (map['page'] ?? 1) as int,
      );
      return JuzAyahEntry(surah: surah, ayah: ayah);
    }).toList();

    await box.put(
      cacheKey,
      jsonEncode(
        entries
            .map(
              (e) => {
                'surah': e.surah.toJson(),
                'ayah': e.ayah.toJson(),
              },
            )
            .toList(),
      ),
    );

    final detail = JuzDetail(juzNumber: juzNumber, entries: entries);
    _memJuzArabicCache[juzNumber] = detail;
    return detail;
  }

  Future<List<String>> _fetchJuzTranslationEdition(
    Box<dynamic> box,
    int juzNumber,
    String langCode,
  ) async {
    final cacheKey = 'cache_juz_tr_v3_${juzNumber}_$langCode';
    final memHit = _memJuzTranslationCache[cacheKey];
    if (memHit != null) return memHit;

    final cached = box.get(cacheKey) as String?;
    if (cached != null) {
      final list = (jsonDecode(cached) as List<dynamic>)
          .map((e) => e.toString())
          .toList();
      _memJuzTranslationCache[cacheKey] = list;
      return list;
    }

    final edition = _editionForCode(langCode);
    final res = await http
        .get(
          Uri.parse('${ApiConfig.baseUrl}/juz/$juzNumber/$edition'),
          headers: ApiConfig.buildHeaders(),
        )
        .timeout(const Duration(seconds: 25));

    if (res.statusCode != 200) {
      return const [];
    }

    final data = (jsonDecode(res.body) as Map<String, dynamic>)['data']
        as Map<String, dynamic>;
    final texts = (data['ayahs'] as List<dynamic>)
        .map((e) => ((e as Map<String, dynamic>)['text'] ?? '') as String)
        .toList();

    _memJuzTranslationCache[cacheKey] = texts;
    await box.put(cacheKey, jsonEncode(texts));
    return texts;
  }

  String _editionForCode(String code) {
    switch (code) {
      case 'ml':
        return ApiConfig.malayalamTranslationEdition;
      case 'ar':
        return ApiConfig.arabicTafsirEdition;
      case 'en':
      default:
        return ApiConfig.englishTranslationEdition;
    }
  }
}
