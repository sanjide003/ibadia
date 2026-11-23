
class SurahSummary {
  final int number;
  final String nameArabic;
  final String englishName;
  final String englishNameTranslation;
  final int numberOfAyahs;
  final String revelationType;

  const SurahSummary({
    required this.number,
    required this.nameArabic,
    required this.englishName,
    required this.englishNameTranslation,
    required this.numberOfAyahs,
    required this.revelationType,
  });

  factory SurahSummary.fromJson(Map<String, dynamic> json) {
    return SurahSummary(
      number: (json['number'] as num?)?.toInt() ?? 1,
      nameArabic: (json['nameArabic'] ?? json['name'] ?? '').toString(),
      englishName: (json['englishName'] ?? '').toString(),
      englishNameTranslation: (json['englishNameTranslation'] ?? '').toString(),
      numberOfAyahs: (json['numberOfAyahs'] as num?)?.toInt() ?? 0,
      revelationType: (json['revelationType'] ?? '').toString(),
    );
  }

  Map<String, dynamic> toJson() => {
        'number': number,
        'nameArabic': nameArabic,
        'englishName': englishName,
        'englishNameTranslation': englishNameTranslation,
        'numberOfAyahs': numberOfAyahs,
        'revelationType': revelationType,
      };
}

class AyahItem {
  final int numberInSurah;
  final int globalNumber;
  final String arabicText;
  final int juz;
  final int page;

  const AyahItem({
    required this.numberInSurah,
    required this.globalNumber,
    required this.arabicText,
    required this.juz,
    required this.page,
  });

  factory AyahItem.fromJson(Map<String, dynamic> json) {
    return AyahItem(
      numberInSurah: (json['numberInSurah'] as num?)?.toInt() ?? 1,
      globalNumber: (json['globalNumber'] ?? json['number'] as num?)?.toInt() ?? 1,
      arabicText: (json['arabicText'] ?? json['text'] ?? '').toString(),
      juz: (json['juz'] as num?)?.toInt() ?? 1,
      page: (json['page'] as num?)?.toInt() ?? 1,
    );
  }

  Map<String, dynamic> toJson() => {
        'numberInSurah': numberInSurah,
        'globalNumber': globalNumber,
        'arabicText': arabicText,
        'juz': juz,
        'page': page,
      };
}

class SurahDetail {
  final SurahSummary summary;
  final List<AyahItem> ayahs;
  final Map<String, List<String>> translations;

  const SurahDetail({
    required this.summary,
    required this.ayahs,
    required this.translations,
  });

  String translationAt(String code, int ayahIndex) {
    final list = translations[code];
    if (list == null || ayahIndex < 0 || ayahIndex >= list.length) return '';
    return list[ayahIndex];
  }
}

class JuzAyahEntry {
  final SurahSummary surah;
  final AyahItem ayah;

  const JuzAyahEntry({required this.surah, required this.ayah});

  factory JuzAyahEntry.fromJson(Map<String, dynamic> json) {
    return JuzAyahEntry(
      surah: SurahSummary.fromJson(Map<String, dynamic>.from(json['surah'] as Map)),
      ayah: AyahItem.fromJson(Map<String, dynamic>.from(json['ayah'] as Map)),
    );
  }

  Map<String, dynamic> toJson() => {
        'surah': surah.toJson(),
        'ayah': ayah.toJson(),
      };
}

class JuzDetail {
  final int juzNumber;
  final List<JuzAyahEntry> entries;
  final Map<String, List<String>> translations;

  const JuzDetail({
    required this.juzNumber,
    required this.entries,
    required this.translations,
  });

  String translationAt(String code, int entryIndex) {
    final list = translations[code];
    if (list == null || entryIndex < 0 || entryIndex >= list.length) return '';
    return list[entryIndex];
  }
}
