class NiyyahVariant {
  final String role; // 'munfarid' | 'imam' | 'mamoom'
  final String labelEn;
  final String labelMl;
  final String labelAr;
  final String arabic;
  final String transliterationMl;
  final String meaningMl;
  final String meaningEn;
  final String audioPath;

  const NiyyahVariant({
    required this.role,
    required this.labelEn,
    required this.labelMl,
    required this.labelAr,
    required this.arabic,
    required this.transliterationMl,
    required this.meaningMl,
    required this.meaningEn,
    required this.audioPath,
  });

  String labelFor(String lang) {
    if (lang == 'ml') return labelMl;
    if (lang == 'ar') return labelAr;
    return labelEn;
  }

  String meaningFor(String lang) {
    if (lang == 'ml') return meaningMl;
    return meaningEn.isNotEmpty ? meaningEn : meaningMl;
  }

  factory NiyyahVariant.fromJson(Map<String, dynamic> json) => NiyyahVariant(
        role: (json['role'] ?? 'munfarid').toString(),
        labelEn: (json['labelEn'] ?? '').toString(),
        labelMl: (json['labelMl'] ?? '').toString(),
        labelAr: (json['labelAr'] ?? '').toString(),
        arabic: (json['arabic'] ?? '').toString(),
        transliterationMl: (json['transliterationMl'] ?? '').toString(),
        meaningMl: (json['meaningMl'] ?? '').toString(),
        meaningEn: (json['meaningEn'] ?? '').toString(),
        audioPath: (json['audioPath'] ?? '').toString(),
      );
}

class FardNiyyahPrayer {
  final String id;
  final String titleEn;
  final String titleMl;
  final String titleAr;
  final int rakaat;
  final List<NiyyahVariant> variants;

  const FardNiyyahPrayer({
    required this.id,
    required this.titleEn,
    required this.titleMl,
    required this.titleAr,
    required this.rakaat,
    required this.variants,
  });

  String titleFor(String lang) {
    if (lang == 'ml') return titleMl;
    if (lang == 'ar') return titleAr;
    return titleEn;
  }

  NiyyahVariant variantForRole(String role) {
    for (final v in variants) {
      if (v.role == role) return v;
    }
    return variants.first;
  }

  factory FardNiyyahPrayer.fromJson(Map<String, dynamic> json) {
    final rawVariants = (json['variants'] as List<dynamic>? ?? const []);
    return FardNiyyahPrayer(
      id: (json['id'] ?? '').toString(),
      titleEn: (json['titleEn'] ?? '').toString(),
      titleMl: (json['titleMl'] ?? '').toString(),
      titleAr: (json['titleAr'] ?? '').toString(),
      rakaat: (json['rakaat'] as num?)?.toInt() ?? 2,
      variants: rawVariants
          .whereType<Map<String, dynamic>>()
          .map(NiyyahVariant.fromJson)
          .toList(),
    );
  }
}

class SunnahNiyyahItem {
  final String id;
  final String titleEn;
  final String titleMl;
  final String titleAr;
  final String noteEn;
  final String noteMl;
  final String arabic;
  final String transliterationMl;
  final String meaningMl;
  final String meaningEn;
  final String audioPath;

  const SunnahNiyyahItem({
    required this.id,
    required this.titleEn,
    required this.titleMl,
    required this.titleAr,
    required this.noteEn,
    required this.noteMl,
    required this.arabic,
    required this.transliterationMl,
    required this.meaningMl,
    required this.meaningEn,
    required this.audioPath,
  });

  String titleFor(String lang) {
    if (lang == 'ml') return titleMl;
    if (lang == 'ar') return titleAr.isNotEmpty ? titleAr : titleEn;
    return titleEn;
  }

  String noteFor(String lang) => lang == 'ml' ? noteMl : noteEn;

  String meaningFor(String lang) =>
      lang == 'ml' ? meaningMl : (meaningEn.isNotEmpty ? meaningEn : meaningMl);

  factory SunnahNiyyahItem.fromJson(Map<String, dynamic> json) =>
      SunnahNiyyahItem(
        id: (json['id'] ?? '').toString(),
        titleEn: (json['titleEn'] ?? '').toString(),
        titleMl: (json['titleMl'] ?? '').toString(),
        titleAr: (json['titleAr'] ?? '').toString(),
        noteEn: (json['noteEn'] ?? '').toString(),
        noteMl: (json['noteMl'] ?? '').toString(),
        arabic: (json['arabic'] ?? '').toString(),
        transliterationMl: (json['transliterationMl'] ?? '').toString(),
        meaningMl: (json['meaningMl'] ?? '').toString(),
        meaningEn: (json['meaningEn'] ?? '').toString(),
        audioPath: (json['audioPath'] ?? '').toString(),
      );
}

class NiyyahBundle {
  final List<FardNiyyahPrayer> fardPrayers;
  final List<SunnahNiyyahItem> sunnahPrayers;

  const NiyyahBundle({
    required this.fardPrayers,
    required this.sunnahPrayers,
  });

  factory NiyyahBundle.fromJson(Map<String, dynamic> json) {
    return NiyyahBundle(
      fardPrayers: (json['fardPrayers'] as List<dynamic>? ?? const [])
          .whereType<Map<String, dynamic>>()
          .map(FardNiyyahPrayer.fromJson)
          .toList(),
      sunnahPrayers: (json['sunnahPrayers'] as List<dynamic>? ?? const [])
          .whereType<Map<String, dynamic>>()
          .map(SunnahNiyyahItem.fromJson)
          .toList(),
    );
  }
}

class SalahCondition {
  final String id;
  final String titleEn;
  final String titleMl;
  final String descEn;
  final String descMl;

  const SalahCondition({
    required this.id,
    required this.titleEn,
    required this.titleMl,
    required this.descEn,
    required this.descMl,
  });

  String titleFor(String lang) => lang == 'ml' ? titleMl : titleEn;
  String descFor(String lang) => lang == 'ml' ? descMl : descEn;

  factory SalahCondition.fromJson(Map<String, dynamic> json) => SalahCondition(
        id: (json['id'] ?? '').toString(),
        titleEn: (json['titleEn'] ?? '').toString(),
        titleMl: (json['titleMl'] ?? '').toString(),
        descEn: (json['descEn'] ?? '').toString(),
        descMl: (json['descMl'] ?? '').toString(),
      );
}

class SalahRukn {
  final int order;
  final String titleEn;
  final String titleMl;

  const SalahRukn({
    required this.order,
    required this.titleEn,
    required this.titleMl,
  });

  String titleFor(String lang) => lang == 'ml' ? titleMl : titleEn;

  factory SalahRukn.fromJson(Map<String, dynamic> json) => SalahRukn(
        order: (json['order'] as num?)?.toInt() ?? 1,
        titleEn: (json['titleEn'] ?? '').toString(),
        titleMl: (json['titleMl'] ?? '').toString(),
      );
}

class SalahStep {
  final int order;
  final String postureEn;
  final String postureMl;
  final bool isFard;
  final String titleEn;
  final String titleMl;
  final String noteEn;
  final String noteMl;
  final String arabic;
  final String transliterationMl;
  final String meaningMl;
  final String meaningEn;
  final String audioPath;

  const SalahStep({
    required this.order,
    required this.postureEn,
    required this.postureMl,
    required this.isFard,
    required this.titleEn,
    required this.titleMl,
    required this.noteEn,
    required this.noteMl,
    required this.arabic,
    required this.transliterationMl,
    required this.meaningMl,
    required this.meaningEn,
    required this.audioPath,
  });

  String titleFor(String lang) => lang == 'ml' ? titleMl : titleEn;
  String postureFor(String lang) => lang == 'ml' ? postureMl : postureEn;
  String noteFor(String lang) => lang == 'ml' ? noteMl : noteEn;
  String meaningFor(String lang) =>
      lang == 'ml' ? meaningMl : (meaningEn.isNotEmpty ? meaningEn : meaningMl);

  factory SalahStep.fromJson(Map<String, dynamic> json) => SalahStep(
        order: (json['order'] as num?)?.toInt() ?? 1,
        postureEn: (json['postureEn'] ?? '').toString(),
        postureMl: (json['postureMl'] ?? '').toString(),
        isFard: json['isFard'] == true,
        titleEn: (json['titleEn'] ?? '').toString(),
        titleMl: (json['titleMl'] ?? '').toString(),
        noteEn: (json['noteEn'] ?? '').toString(),
        noteMl: (json['noteMl'] ?? '').toString(),
        arabic: (json['arabic'] ?? '').toString(),
        transliterationMl: (json['transliterationMl'] ?? '').toString(),
        meaningMl: (json['meaningMl'] ?? '').toString(),
        meaningEn: (json['meaningEn'] ?? '').toString(),
        audioPath: (json['audioPath'] ?? '').toString(),
      );
}

class SalahGuideBundle {
  final List<SalahCondition> conditions;
  final List<SalahRukn> arkan;
  final List<SalahStep> steps;

  const SalahGuideBundle({
    required this.conditions,
    required this.arkan,
    required this.steps,
  });

  factory SalahGuideBundle.fromJson(Map<String, dynamic> json) {
    return SalahGuideBundle(
      conditions: (json['conditions'] as List<dynamic>? ?? const [])
          .whereType<Map<String, dynamic>>()
          .map(SalahCondition.fromJson)
          .toList(),
      arkan: (json['arkan'] as List<dynamic>? ?? const [])
          .whereType<Map<String, dynamic>>()
          .map(SalahRukn.fromJson)
          .toList(),
      steps: (json['steps'] as List<dynamic>? ?? const [])
          .whereType<Map<String, dynamic>>()
          .map(SalahStep.fromJson)
          .toList(),
    );
  }
}

class RawatibItem {
  final int rakaat;
  final bool isMuakkadah;
  final String timingEn;
  final String timingMl;
  final String noteEn;
  final String noteMl;
  final String arabic;
  final String transliterationMl;
  final String meaningMl;
  final String audioPath;

  const RawatibItem({
    required this.rakaat,
    required this.isMuakkadah,
    required this.timingEn,
    required this.timingMl,
    required this.noteEn,
    required this.noteMl,
    required this.arabic,
    required this.transliterationMl,
    required this.meaningMl,
    required this.audioPath,
  });

  String timingFor(String lang) => lang == 'ml' ? timingMl : timingEn;
  String noteFor(String lang) => lang == 'ml' ? noteMl : noteEn;

  factory RawatibItem.fromJson(Map<String, dynamic> json) => RawatibItem(
        rakaat: (json['rakaat'] as num?)?.toInt() ?? 2,
        isMuakkadah: json['isMuakkadah'] == true,
        timingEn: (json['timingEn'] ?? '').toString(),
        timingMl: (json['timingMl'] ?? '').toString(),
        noteEn: (json['noteEn'] ?? '').toString(),
        noteMl: (json['noteMl'] ?? '').toString(),
        arabic: (json['arabic'] ?? '').toString(),
        transliterationMl: (json['transliterationMl'] ?? '').toString(),
        meaningMl: (json['meaningMl'] ?? '').toString(),
        audioPath: (json['audioPath'] ?? '').toString(),
      );
}

class PrayerRawatibGroup {
  final String prayerId;
  final String prayerEn;
  final String prayerMl;
  final List<RawatibItem> before;
  final List<RawatibItem> after;

  const PrayerRawatibGroup({
    required this.prayerId,
    required this.prayerEn,
    required this.prayerMl,
    required this.before,
    required this.after,
  });

  String prayerFor(String lang) => lang == 'ml' ? prayerMl : prayerEn;

  int get totalRakaat {
    int sum = 0;
    for (final b in before) {
      sum += b.rakaat;
    }
    for (final a in after) {
      sum += a.rakaat;
    }
    return sum;
  }

  factory PrayerRawatibGroup.fromJson(Map<String, dynamic> json) {
    return PrayerRawatibGroup(
      prayerId: (json['prayerId'] ?? '').toString(),
      prayerEn: (json['prayerEn'] ?? '').toString(),
      prayerMl: (json['prayerMl'] ?? '').toString(),
      before: (json['before'] as List<dynamic>? ?? const [])
          .whereType<Map<String, dynamic>>()
          .map(RawatibItem.fromJson)
          .toList(),
      after: (json['after'] as List<dynamic>? ?? const [])
          .whereType<Map<String, dynamic>>()
          .map(RawatibItem.fromJson)
          .toList(),
    );
  }
}

class SurahReferenceItem {
  final int surahNumber;
  final String nameEn;
  final String nameMl;
  final String nameAr;
  final String rakaahTagEn;
  final String rakaahTagMl;

  const SurahReferenceItem({
    required this.surahNumber,
    required this.nameEn,
    required this.nameMl,
    required this.nameAr,
    required this.rakaahTagEn,
    required this.rakaahTagMl,
  });

  String nameFor(String lang) {
    if (lang == 'ml') return nameMl;
    if (lang == 'ar') return nameAr;
    return nameEn;
  }

  String tagFor(String lang) => lang == 'ml' ? rakaahTagMl : rakaahTagEn;

  factory SurahReferenceItem.fromJson(Map<String, dynamic> json) =>
      SurahReferenceItem(
        surahNumber: (json['surahNumber'] as num?)?.toInt() ?? 1,
        nameEn: (json['nameEn'] ?? '').toString(),
        nameMl: (json['nameMl'] ?? '').toString(),
        nameAr: (json['nameAr'] ?? '').toString(),
        rakaahTagEn: (json['rakaahTagEn'] ?? '').toString(),
        rakaahTagMl: (json['rakaahTagMl'] ?? '').toString(),
      );
}

class RecommendedSurahGroup {
  final String occasionEn;
  final String occasionMl;
  final String reasonEn;
  final String reasonMl;
  final List<SurahReferenceItem> surahs;

  const RecommendedSurahGroup({
    required this.occasionEn,
    required this.occasionMl,
    required this.reasonEn,
    required this.reasonMl,
    required this.surahs,
  });

  String occasionFor(String lang) => lang == 'ml' ? occasionMl : occasionEn;
  String reasonFor(String lang) => lang == 'ml' ? reasonMl : reasonEn;

  factory RecommendedSurahGroup.fromJson(Map<String, dynamic> json) {
    return RecommendedSurahGroup(
      occasionEn: (json['occasionEn'] ?? '').toString(),
      occasionMl: (json['occasionMl'] ?? '').toString(),
      reasonEn: (json['reasonEn'] ?? '').toString(),
      reasonMl: (json['reasonMl'] ?? '').toString(),
      surahs: (json['surahs'] as List<dynamic>? ?? const [])
          .whereType<Map<String, dynamic>>()
          .map(SurahReferenceItem.fromJson)
          .toList(),
    );
  }
}

class SunnahAndSurahsBundle {
  final List<PrayerRawatibGroup> rawatib;
  final List<RecommendedSurahGroup> recommendedSurahs;

  const SunnahAndSurahsBundle({
    required this.rawatib,
    required this.recommendedSurahs,
  });

  factory SunnahAndSurahsBundle.fromJson(Map<String, dynamic> json) {
    return SunnahAndSurahsBundle(
      rawatib: (json['rawatib'] as List<dynamic>? ?? const [])
          .whereType<Map<String, dynamic>>()
          .map(PrayerRawatibGroup.fromJson)
          .toList(),
      recommendedSurahs:
          (json['recommendedSurahs'] as List<dynamic>? ?? const [])
              .whereType<Map<String, dynamic>>()
              .map(RecommendedSurahGroup.fromJson)
              .toList(),
    );
  }
}

class MayyithPrepStage {
  final String id;
  final String titleEn;
  final String titleMl;
  final List<String> pointsEn;
  final List<String> pointsMl;
  final String? arabic;
  final String? transliterationMl;
  final String? meaningMl;
  final String? audioPath;

  const MayyithPrepStage({
    required this.id,
    required this.titleEn,
    required this.titleMl,
    required this.pointsEn,
    required this.pointsMl,
    this.arabic,
    this.transliterationMl,
    this.meaningMl,
    this.audioPath,
  });

  String titleFor(String lang) => lang == 'ml' ? titleMl : titleEn;
  List<String> pointsFor(String lang) => lang == 'ml' ? pointsMl : pointsEn;

  factory MayyithPrepStage.fromJson(Map<String, dynamic> json) =>
      MayyithPrepStage(
        id: (json['id'] ?? '').toString(),
        titleEn: (json['titleEn'] ?? '').toString(),
        titleMl: (json['titleMl'] ?? '').toString(),
        pointsEn: (json['pointsEn'] as List<dynamic>? ?? const [])
            .map((e) => e.toString())
            .toList(),
        pointsMl: (json['pointsMl'] as List<dynamic>? ?? const [])
            .map((e) => e.toString())
            .toList(),
        arabic: json['arabic']?.toString(),
        transliterationMl: json['transliterationMl']?.toString(),
        meaningMl: json['meaningMl']?.toString(),
        audioPath: json['audioPath']?.toString(),
      );
}

class MayyithNiyyahItem {
  final String id;
  final String titleEn;
  final String titleMl;
  final String arabic;
  final String transliterationMl;
  final String meaningMl;
  final String meaningEn;
  final String audioPath;

  const MayyithNiyyahItem({
    required this.id,
    required this.titleEn,
    required this.titleMl,
    required this.arabic,
    required this.transliterationMl,
    required this.meaningMl,
    required this.meaningEn,
    required this.audioPath,
  });

  String titleFor(String lang) => lang == 'ml' ? titleMl : titleEn;
  String meaningFor(String lang) =>
      lang == 'ml' ? meaningMl : (meaningEn.isNotEmpty ? meaningEn : meaningMl);

  factory MayyithNiyyahItem.fromJson(Map<String, dynamic> json) =>
      MayyithNiyyahItem(
        id: (json['id'] ?? '').toString(),
        titleEn: (json['titleEn'] ?? '').toString(),
        titleMl: (json['titleMl'] ?? '').toString(),
        arabic: (json['arabic'] ?? '').toString(),
        transliterationMl: (json['transliterationMl'] ?? '').toString(),
        meaningMl: (json['meaningMl'] ?? '').toString(),
        meaningEn: (json['meaningEn'] ?? '').toString(),
        audioPath: (json['audioPath'] ?? '').toString(),
      );
}

class MayyithTakbirStep {
  final int takbirNumber;
  final String titleEn;
  final String titleMl;
  final String noteEn;
  final String noteMl;
  final String arabic;
  final String transliterationMl;
  final String meaningMl;
  final String meaningEn;
  final String audioPath;

  const MayyithTakbirStep({
    required this.takbirNumber,
    required this.titleEn,
    required this.titleMl,
    required this.noteEn,
    required this.noteMl,
    required this.arabic,
    required this.transliterationMl,
    required this.meaningMl,
    required this.meaningEn,
    required this.audioPath,
  });

  String titleFor(String lang) => lang == 'ml' ? titleMl : titleEn;
  String noteFor(String lang) => lang == 'ml' ? noteMl : noteEn;
  String meaningFor(String lang) =>
      lang == 'ml' ? meaningMl : (meaningEn.isNotEmpty ? meaningEn : meaningMl);

  factory MayyithTakbirStep.fromJson(Map<String, dynamic> json) =>
      MayyithTakbirStep(
        takbirNumber: (json['takbirNumber'] as num?)?.toInt() ?? 1,
        titleEn: (json['titleEn'] ?? '').toString(),
        titleMl: (json['titleMl'] ?? '').toString(),
        noteEn: (json['noteEn'] ?? '').toString(),
        noteMl: (json['noteMl'] ?? '').toString(),
        arabic: (json['arabic'] ?? '').toString(),
        transliterationMl: (json['transliterationMl'] ?? '').toString(),
        meaningMl: (json['meaningMl'] ?? '').toString(),
        meaningEn: (json['meaningEn'] ?? '').toString(),
        audioPath: (json['audioPath'] ?? '').toString(),
      );
}

class MayyithBurialItem {
  final String id;
  final String titleEn;
  final String titleMl;
  final String noteEn;
  final String noteMl;
  final String arabic;
  final String transliterationMl;
  final String meaningMl;
  final String audioPath;

  const MayyithBurialItem({
    required this.id,
    required this.titleEn,
    required this.titleMl,
    required this.noteEn,
    required this.noteMl,
    required this.arabic,
    required this.transliterationMl,
    required this.meaningMl,
    required this.audioPath,
  });

  String titleFor(String lang) => lang == 'ml' ? titleMl : titleEn;
  String noteFor(String lang) => lang == 'ml' ? noteMl : noteEn;

  factory MayyithBurialItem.fromJson(Map<String, dynamic> json) =>
      MayyithBurialItem(
        id: (json['id'] ?? '').toString(),
        titleEn: (json['titleEn'] ?? '').toString(),
        titleMl: (json['titleMl'] ?? '').toString(),
        noteEn: (json['noteEn'] ?? '').toString(),
        noteMl: (json['noteMl'] ?? '').toString(),
        arabic: (json['arabic'] ?? '').toString(),
        transliterationMl: (json['transliterationMl'] ?? '').toString(),
        meaningMl: (json['meaningMl'] ?? '').toString(),
        audioPath: (json['audioPath'] ?? '').toString(),
      );
}

class MayyithGuideBundle {
  final List<MayyithPrepStage> preparationStages;
  final List<MayyithNiyyahItem> niyyah;
  final List<MayyithTakbirStep> takbirs;
  final List<MayyithBurialItem> burialAndTalqeen;

  const MayyithGuideBundle({
    required this.preparationStages,
    required this.niyyah,
    required this.takbirs,
    required this.burialAndTalqeen,
  });

  factory MayyithGuideBundle.fromJson(Map<String, dynamic> json) {
    return MayyithGuideBundle(
      preparationStages:
          (json['preparationStages'] as List<dynamic>? ?? const [])
              .whereType<Map<String, dynamic>>()
              .map(MayyithPrepStage.fromJson)
              .toList(),
      niyyah: (json['niyyah'] as List<dynamic>? ?? const [])
          .whereType<Map<String, dynamic>>()
          .map(MayyithNiyyahItem.fromJson)
          .toList(),
      takbirs: (json['takbirs'] as List<dynamic>? ?? const [])
          .whereType<Map<String, dynamic>>()
          .map(MayyithTakbirStep.fromJson)
          .toList(),
      burialAndTalqeen:
          (json['burialAndTalqeen'] as List<dynamic>? ?? const [])
              .whereType<Map<String, dynamic>>()
              .map(MayyithBurialItem.fromJson)
              .toList(),
    );
  }
}
