import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import '../core/config/api_config.dart';
import '../models/surah_model.dart';

class QuranApiService {
  static const String _surahListCacheKey = 'cache_surah_list_v3';
  static List<SurahSummary>? _memSurahList;
  static final Map<int, SurahDetail> _memArabicCache = {};
  static final Map<String, List<String>> _memTranslationCache = {};

  Future<List<SurahSummary>> fetchSurahList() async {
    if (_memSurahList != null) return _memSurahList!;

    final prefs = await SharedPreferences.getInstance();
    final cached = prefs.getString(_surahListCacheKey);
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
    await prefs.setString(
      _surahListCacheKey,
      jsonEncode(surahs.map((s) => s.toJson()).toList()),
    );
    return surahs;
  }

  /// Fetches ONLY Arabic text + the exact translation languages currently enabled.
  /// Every edition is cached in memory and SharedPreferences for instant offline loading.
  Future<SurahDetail> fetchSurahDetail({
    required int surahNumber,
    required List<String> requiredTranslations,
  }) async {
    final prefs = await SharedPreferences.getInstance();
    final baseData = await _fetchArabicBase(prefs, surahNumber);

    final Map<String, List<String>> loadedTranslations = {};
    if (requiredTranslations.isNotEmpty) {
      final futures = requiredTranslations.map((code) async {
        final texts = await _fetchTranslationEdition(prefs, surahNumber, code);
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
    SharedPreferences prefs,
    int surahNumber,
  ) async {
    final memHit = _memArabicCache[surahNumber];
    if (memHit != null) return memHit;

    final cacheKey = 'cache_ar_v3_$surahNumber';
    final cached = prefs.getString(cacheKey);
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

    await prefs.setString(
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
    SharedPreferences prefs,
    int surahNumber,
    String langCode,
  ) async {
    final cacheKey = 'cache_tr_v3_${surahNumber}_$langCode';
    final memHit = _memTranslationCache[cacheKey];
    if (memHit != null) return memHit;

    final cached = prefs.getString(cacheKey);
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
    await prefs.setString(cacheKey, jsonEncode(texts));
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
