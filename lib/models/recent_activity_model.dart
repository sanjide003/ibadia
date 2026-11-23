enum RecentActivityType {
  surah,
  juz,
  prayer,
  hijri,
  adhkar,
  counter,
  asmaulHusna,
  tajweed,
  autoSilent,
  ibadah,
  bookmark,
  exportPdf,
  settings;

  static RecentActivityType fromRaw(dynamic raw) {
    final s = (raw ?? '').toString();
    switch (s) {
      case 'surah':
        return RecentActivityType.surah;
      case 'juz':
        return RecentActivityType.juz;
      case 'prayer':
        return RecentActivityType.prayer;
      case 'hijri':
        return RecentActivityType.hijri;
      case 'adhkar':
        return RecentActivityType.adhkar;
      case 'counter':
      case 'tasbih':
        return RecentActivityType.counter;
      case 'asmaulHusna':
      case 'names99':
        return RecentActivityType.asmaulHusna;
      case 'tajweed':
        return RecentActivityType.tajweed;
      case 'autoSilent':
        return RecentActivityType.autoSilent;
      case 'ibadah':
      case 'ibadah_guide':
        return RecentActivityType.ibadah;
      case 'bookmark':
        return RecentActivityType.bookmark;
      case 'exportPdf':
      case 'export':
        return RecentActivityType.exportPdf;
      case 'settings':
        return RecentActivityType.settings;
      default:
        return RecentActivityType.surah;
    }
  }
}

class RecentActivityEntry {
  static const int maxHistoryCount = 7;

  final String id;
  final RecentActivityType type;
  final String titleEn;
  final String titleMl;
  final String titleAr;
  final String subtitleEn;
  final String subtitleMl;
  final String subtitleAr;
  final int timestampMs;
  final int? surahNumber;
  final int? ayahNumber;
  final int? featureSubTab;
  final int? quranSubTab;
  final int? asmaIndex;

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
    this.featureSubTab,
    this.quranSubTab,
    this.asmaIndex,
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

  String timeAgoLabel(String lang) {
    final diffMs = DateTime.now().millisecondsSinceEpoch - timestampMs;
    if (diffMs < 60000) {
      if (lang == 'ml') return 'ഇപ്പോൾ';
      if (lang == 'ar') return 'الآن';
      return 'Now';
    }
    final mins = diffMs ~/ 60000;
    if (mins < 60) {
      if (lang == 'ml') return '$mins മി.';
      if (lang == 'ar') return '$minsد';
      return '${mins}m';
    }
    final hours = mins ~/ 60;
    if (hours < 24) {
      if (lang == 'ml') return '$hours മ.';
      if (lang == 'ar') return '$hoursس';
      return '${hours}h';
    }
    final days = hours ~/ 24;
    if (lang == 'ml') return '$days ദി.';
    if (lang == 'ar') return '$daysي';
    return '${days}d';
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'type': type.name,
        'titleEn': titleEn,
        'titleMl': titleMl,
        'titleAr': titleAr,
        'subtitleEn': subtitleEn,
        'subtitleMl': subtitleMl,
        'subtitleAr': subtitleAr,
        'timestampMs': timestampMs,
        if (surahNumber != null) 'surahNumber': surahNumber,
        if (ayahNumber != null) 'ayahNumber': ayahNumber,
        if (featureSubTab != null) 'featureSubTab': featureSubTab,
        if (quranSubTab != null) 'quranSubTab': quranSubTab,
        if (asmaIndex != null) 'asmaIndex': asmaIndex,
      };

  factory RecentActivityEntry.fromJson(Map<String, dynamic> json) {
    return RecentActivityEntry(
      id: (json['id'] ?? '').toString(),
      type: RecentActivityType.fromRaw(json['type']),
      titleEn: (json['titleEn'] ?? '').toString(),
      titleMl: (json['titleMl'] ?? '').toString(),
      titleAr: (json['titleAr'] ?? '').toString(),
      subtitleEn: (json['subtitleEn'] ?? '').toString(),
      subtitleMl: (json['subtitleMl'] ?? '').toString(),
      subtitleAr: (json['subtitleAr'] ?? '').toString(),
      timestampMs: (json['timestampMs'] as num?)?.toInt() ?? 0,
      surahNumber: (json['surahNumber'] as num?)?.toInt(),
      ayahNumber: (json['ayahNumber'] as num?)?.toInt(),
      featureSubTab: (json['featureSubTab'] as num?)?.toInt(),
      quranSubTab:
          ((json['quranSubTab'] ?? json['quranSubTabIndex']) as num?)?.toInt(),
      asmaIndex: (json['asmaIndex'] as num?)?.toInt(),
    );
  }
}
