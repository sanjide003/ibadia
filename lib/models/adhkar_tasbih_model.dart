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
    required this.targetCount,
  });
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
    required this.defaultTarget,
    this.isCustom = false,
  });

  Map<String, dynamic> toJson() => {
        'id': id,
        'arabic': arabic,
        'titleEn': titleEn,
        'titleMl': titleMl,
        'defaultTarget': defaultTarget,
        'isCustom': isCustom,
      };

  factory TasbihPreset.fromJson(Map<String, dynamic> json) {
    return TasbihPreset(
      id: (json['id'] ?? '').toString(),
      arabic: (json['arabic'] ?? '').toString(),
      titleEn: (json['titleEn'] ?? '').toString(),
      titleMl: (json['titleMl'] ?? '').toString(),
      defaultTarget: (json['defaultTarget'] as num?)?.toInt() ?? 33,
      isCustom: json['isCustom'] == true,
    );
  }
}

class TasbihStoredState {
  final String selectedId;
  final String dateKey;
  final int currentCount;
  final int todayTotal;
  final int lifetimeTotal;
  final int cyclesCompleted;
  final Map<String, int> targets;
  final bool vibrateOnTap;
  final bool tapAnywhere;

  const TasbihStoredState({
    required this.selectedId,
    required this.dateKey,
    required this.currentCount,
    required this.todayTotal,
    required this.lifetimeTotal,
    required this.cyclesCompleted,
    required this.targets,
    required this.vibrateOnTap,
    required this.tapAnywhere,
  });

  factory TasbihStoredState.initial(String todayKey) {
    return TasbihStoredState(
      selectedId: 'tasbih_subhanallah',
      dateKey: todayKey,
      currentCount: 0,
      todayTotal: 0,
      lifetimeTotal: 0,
      cyclesCompleted: 0,
      targets: const {},
      vibrateOnTap: true,
      tapAnywhere: true,
    );
  }

  TasbihStoredState copyWith({
    String? selectedId,
    String? dateKey,
    int? currentCount,
    int? todayTotal,
    int? lifetimeTotal,
    int? cyclesCompleted,
    Map<String, int>? targets,
    bool? vibrateOnTap,
    bool? tapAnywhere,
  }) {
    return TasbihStoredState(
      selectedId: selectedId ?? this.selectedId,
      dateKey: dateKey ?? this.dateKey,
      currentCount: currentCount ?? this.currentCount,
      todayTotal: todayTotal ?? this.todayTotal,
      lifetimeTotal: lifetimeTotal ?? this.lifetimeTotal,
      cyclesCompleted: cyclesCompleted ?? this.cyclesCompleted,
      targets: targets ?? this.targets,
      vibrateOnTap: vibrateOnTap ?? this.vibrateOnTap,
      tapAnywhere: tapAnywhere ?? this.tapAnywhere,
    );
  }

  Map<String, dynamic> toJson() => {
        'selectedId': selectedId,
        'dateKey': dateKey,
        'currentCount': currentCount,
        'todayTotal': todayTotal,
        'lifetimeTotal': lifetimeTotal,
        'cyclesCompleted': cyclesCompleted,
        'targets': targets,
        'vibrateOnTap': vibrateOnTap,
        'tapAnywhere': tapAnywhere,
      };

  factory TasbihStoredState.fromJson(Map<String, dynamic> json, String todayKey) {
    final storedDate = (json['dateKey'] ?? '').toString();
    final rawTargets = (json['targets'] as Map?) ?? {};
    final targets = <String, int>{};
    rawTargets.forEach((k, v) {
      if (v is num) targets[k.toString()] = v.toInt();
    });
    return TasbihStoredState(
      selectedId: (json['selectedId'] ?? 'tasbih_subhanallah').toString(),
      dateKey: todayKey,
      currentCount: (json['currentCount'] as num?)?.toInt() ?? 0,
      todayTotal: storedDate == todayKey ? ((json['todayTotal'] as num?)?.toInt() ?? 0) : 0,
      lifetimeTotal: (json['lifetimeTotal'] as num?)?.toInt() ?? 0,
      cyclesCompleted: (json['cyclesCompleted'] as num?)?.toInt() ?? 0,
      targets: targets,
      vibrateOnTap: json['vibrateOnTap'] is bool ? json['vibrateOnTap'] as bool : true,
      tapAnywhere: json['tapAnywhere'] is bool ? json['tapAnywhere'] as bool : true,
    );
  }
}

class AsmaulHusnaItem {
  final int number;
  final String arabic;
  final String transliteration;
  final String englishMeaning;
  final String malayalamMeaning;
  final String arabicMeaning;
  final String reflectionEn;
  final String reflectionMl;

  const AsmaulHusnaItem({
    required this.number,
    required this.arabic,
    required this.transliteration,
    required this.englishMeaning,
    required this.malayalamMeaning,
    required this.arabicMeaning,
    required this.reflectionEn,
    required this.reflectionMl,
  });
}
