class AdhkarEntry {
  final String id;
  final String category; // 'morning' | 'evening' | 'after_salah' | 'daily_duas'
  final String titleEn;
  final String titleMl;
  final String arabic;
  final String translationEn;
  final String translationMl;
  final String reference;
  final int targetCount;

  const AdhkarEntry({
    required this.id,
    required this.category,
    required this.titleEn,
    required this.titleMl,
    required this.arabic,
    required this.translationEn,
    required this.translationMl,
    required this.reference,
    this.targetCount = 1,
  });

  String titleFor(String lang) {
    if (lang == 'ml') return titleMl;
    return titleEn;
  }

  String translationFor(String lang) {
    if (lang == 'ml') return translationMl;
    return translationEn;
  }
}

class TasbihPreset {
  final String id;
  final String arabic;
  final String titleEn;
  final String titleMl;
  final int defaultTarget;
  final bool isCustom;

  const TasbihPreset({
    required this.id,
    required this.arabic,
    required this.titleEn,
    required this.titleMl,
    this.defaultTarget = 33,
    this.isCustom = false,
  });

  String titleFor(String lang) {
    if (lang == 'ml') return titleMl;
    if (lang == 'ar') return arabic;
    return titleEn;
  }

  factory TasbihPreset.fromJson(Map<String, dynamic> json) => TasbihPreset(
        id: (json['id'] ?? '').toString(),
        arabic: (json['arabic'] ?? '').toString(),
        titleEn: (json['titleEn'] ?? '').toString(),
        titleMl: (json['titleMl'] ?? '').toString(),
        defaultTarget: (json['defaultTarget'] as num?)?.toInt() ?? 33,
        isCustom: json['isCustom'] as bool? ?? false,
      );

  Map<String, dynamic> toJson() => {
        'id': id,
        'arabic': arabic,
        'titleEn': titleEn,
        'titleMl': titleMl,
        'defaultTarget': defaultTarget,
        'isCustom': isCustom,
      };
}
