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
      number: json['number'] as int,
      nameArabic: (json['name'] ?? '') as String,
      englishName: (json['englishName'] ?? '') as String,
      englishNameTranslation: (json['englishNameTranslation'] ?? '') as String,
      numberOfAyahs: (json['numberOfAyahs'] ?? 0) as int,
      revelationType: (json['revelationType'] ?? '') as String,
    );
  }

  Map<String, dynamic> toJson() => {
        'number': number,
        'name': nameArabic,
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
      numberInSurah: json['numberInSurah'] as int,
      globalNumber: json['globalNumber'] as int,
      arabicText: (json['arabicText'] ?? '') as String,
      juz: (json['juz'] ?? 1) as int,
      page: (json['page'] ?? 1) as int,
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
  /// Map of language code ('en', 'ml', 'ar') -> List of translation texts indexed by ayah order.
  final Map<String, List<String>> translations;

  const SurahDetail({
    required this.summary,
    required this.ayahs,
    this.translations = const {},
  });

  String translationAt(String langCode, int index) {
    final list = translations[langCode];
    if (list == null || index < 0 || index >= list.length) return '';
    return list[index];
  }
}

class JuzAyahEntry {
  final SurahSummary surah;
  final AyahItem ayah;

  const JuzAyahEntry({
    required this.surah,
    required this.ayah,
  });
}

class JuzDetail {
  final int juzNumber;
  final List<JuzAyahEntry> entries;
  final Map<String, List<String>> translations;

  const JuzDetail({
    required this.juzNumber,
    required this.entries,
    this.translations = const {},
  });

  String translationAt(String langCode, int index) {
    final list = translations[langCode];
    if (list == null || index < 0 || index >= list.length) return '';
    return list[index];
  }
}

enum ExportScope { range, surah, juz }

enum ExportPageSize { automatic, a4 }

enum ExportFormat { pdf, image }

class ExportAyahBlock {
  final int numberInSurah;
  final String arabicText;
  final Map<String, String> translations;

  const ExportAyahBlock({
    required this.numberInSurah,
    required this.arabicText,
    this.translations = const {},
  });
}

class ExportSurahSection {
  final SurahSummary summary;
  final bool showBanner;
  final bool showBismillah;
  final List<ExportAyahBlock> ayahs;

  const ExportSurahSection({
    required this.summary,
    this.showBanner = true,
    required this.showBismillah,
    required this.ayahs,
  });
}

class ExportPageData {
  final int pageIndex;
  final int totalPages;
  final String headerTitle;
  final String headerSubtitle;
  final List<ExportSurahSection> sections;

  const ExportPageData({
    required this.pageIndex,
    required this.totalPages,
    required this.headerTitle,
    required this.headerSubtitle,
    required this.sections,
  });
}

