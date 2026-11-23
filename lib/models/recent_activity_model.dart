class RecentActivityEntry {
  final String id;
  final String type; // surah | juz | prayer | hijri | adhkar | tasbih | names99 | tajweed | export | autoSilent
  final String titleEn;
  final String titleMl;
  final String titleAr;
  final String subtitleEn;
  final String subtitleMl;
  final String subtitleAr;
  final int timestampMs;
  final int? surahNumber;
  final int? ayahNumber;
  final String? featureRoute;
  final int? quranSubTabIndex;

  const RecentActivityEntry({
    required this.id,
    required this.type,
    required this.titleEn,
    required this.titleMl,
    required this.titleAr,
    required this.subtitleEn,
    required this.subtitleMl,
    required this.subtitleAr,
    required this.timestampMs,
    this.surahNumber,
    this.ayahNumber,
    this.featureRoute,
    this.quranSubTabIndex,
  });

  String titleFor(String lang) {
    if (lang == 'ml') return titleMl;
    if (lang == 'ar') return titleAr;
    return titleEn;
  }

  String subtitleFor(String lang) {
    if (lang == 'ml') return subtitleMl;
    if (lang == 'ar') return subtitleAr;
    return subtitleEn;
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'type': type,
        'titleEn': titleEn,
        'titleMl': titleMl,
        'titleAr': titleAr,
        'subtitleEn': subtitleEn,
        'subtitleMl': subtitleMl,
        'subtitleAr': subtitleAr,
        'timestampMs': timestampMs,
        'surahNumber': surahNumber,
        'ayahNumber': ayahNumber,
        'featureRoute': featureRoute,
        'quranSubTabIndex': quranSubTabIndex,
      };

  factory RecentActivityEntry.fromJson(Map<String, dynamic> json) {
    return RecentActivityEntry(
      id: (json['id'] ?? '').toString(),
      type: (json['type'] ?? '').toString(),
      titleEn: (json['titleEn'] ?? '').toString(),
      titleMl: (json['titleMl'] ?? '').toString(),
      titleAr: (json['titleAr'] ?? '').toString(),
      subtitleEn: (json['subtitleEn'] ?? '').toString(),
      subtitleMl: (json['subtitleMl'] ?? '').toString(),
      subtitleAr: (json['subtitleAr'] ?? '').toString(),
      timestampMs: (json['timestampMs'] as num?)?.toInt() ?? 0,
      surahNumber: (json['surahNumber'] as num?)?.toInt(),
      ayahNumber: (json['ayahNumber'] as num?)?.toInt(),
      featureRoute: json['featureRoute']?.toString(),
      quranSubTabIndex: (json['quranSubTabIndex'] as num?)?.toInt(),
    );
  }
}
