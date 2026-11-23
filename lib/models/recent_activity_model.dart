import 'package:flutter/foundation.dart';

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
  bookmark,
  exportPdf,
  settings;

  static RecentActivityType fromName(String raw) {
    for (final v in values) {
      if (v.name == raw) return v;
    }
    return RecentActivityType.surah;
  }
}

@immutable
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
    switch (lang) {
      case 'ml':
        return titleMl.isNotEmpty ? titleMl : titleEn;
      case 'ar':
        return titleAr.isNotEmpty ? titleAr : titleEn;
      default:
        return titleEn;
    }
  }

  String subtitleFor(String lang) {
    switch (lang) {
      case 'ml':
        return subtitleMl.isNotEmpty ? subtitleMl : subtitleEn;
      case 'ar':
        return subtitleAr.isNotEmpty ? subtitleAr : subtitleEn;
      default:
        return subtitleEn;
    }
  }

  String timeAgoLabel(String lang) {
    final diff = DateTime.now().millisecondsSinceEpoch - timestampMs;
    if (diff < 60000) {
      return lang == 'ml'
          ? 'ഇപ്പോൾ'
          : (lang == 'ar' ? 'الآن' : 'Just now');
    }
    final mins = diff ~/ 60000;
    if (mins < 60) {
      return lang == 'ml'
          ? '$mins മി. മുമ്പ്'
          : (lang == 'ar' ? 'منذ $mins د' : '${mins}m ago');
    }
    final hrs = mins ~/ 60;
    if (hrs < 24) {
      return lang == 'ml'
          ? '$hrs മ. മുമ്പ്'
          : (lang == 'ar' ? 'منذ $hrs س' : '${hrs}h ago');
    }
    final days = hrs ~/ 24;
    return lang == 'ml'
        ? '$days ദി. മുമ്പ്'
        : (lang == 'ar' ? 'منذ $days ي' : '${days}d ago');
  }

  factory RecentActivityEntry.fromJson(Map<String, dynamic> json) {
    return RecentActivityEntry(
      id: (json['id'] ?? '') as String,
      type: RecentActivityType.fromName((json['type'] ?? 'surah') as String),
      titleEn: (json['titleEn'] ?? '') as String,
      titleMl: (json['titleMl'] ?? '') as String,
      titleAr: (json['titleAr'] ?? '') as String,
      subtitleEn: (json['subtitleEn'] ?? '') as String,
      subtitleMl: (json['subtitleMl'] ?? '') as String,
      subtitleAr: (json['subtitleAr'] ?? '') as String,
      timestampMs: (json['timestampMs'] as num?)?.toInt() ?? 0,
      surahNumber: (json['surahNumber'] as num?)?.toInt(),
      ayahNumber: (json['ayahNumber'] as num?)?.toInt(),
      featureSubTab: (json['featureSubTab'] as num?)?.toInt(),
      quranSubTab: (json['quranSubTab'] as num?)?.toInt(),
      asmaIndex: (json['asmaIndex'] as num?)?.toInt(),
    );
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
}
