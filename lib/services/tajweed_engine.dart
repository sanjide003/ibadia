import 'package:flutter/material.dart';

enum TajweedRule {
  none,
  ghunnah,
  idghamGhunnah,
  idghamNoGhunnah,
  ikhfa,
  iqlab,
  qalqalah,
  madd,
  silent,
}

class TajweedRuleMeta {
  final TajweedRule rule;
  final String nameEn;
  final String nameMl;
  final String nameAr;
  final String descEn;
  final String descMl;
  final String descAr;
  final String sampleAr;
  final Color lightColor;
  final Color darkColor;

  const TajweedRuleMeta({
    required this.rule,
    required this.nameEn,
    required this.nameMl,
    required this.nameAr,
    required this.descEn,
    required this.descMl,
    required this.descAr,
    required this.sampleAr,
    required this.lightColor,
    required this.darkColor,
  });

  String titleFor(String lang) {
    switch (lang) {
      case 'ml':
        return nameMl;
      case 'ar':
        return nameAr;
      default:
        return nameEn;
    }
  }

  String descriptionFor(String lang) {
    switch (lang) {
      case 'ml':
        return descMl;
      case 'ar':
        return descAr;
      default:
        return descEn;
    }
  }

  Color colorFor(bool isDark) => isDark ? darkColor : lightColor;
}

class TajweedToken {
  final String text;
  final TajweedRule rule;

  const TajweedToken(this.text, this.rule);
}

class TajweedEngine {
  static const List<TajweedRuleMeta> legend = [
    TajweedRuleMeta(
      rule: TajweedRule.ghunnah,
      nameEn: 'Ghunnah (Nasalization)',
      nameMl: 'ഗുന്ന (മൂക്കിലൂടെ മണിച്ചു നീട്ടൽ)',
      nameAr: 'غُنّة (نّ / مّ)',
      descEn:
          'Noon or Meem with a Shaddah (نّ / مّ). Hold the nasal resonance clearly for 2 counts.',
      descMl:
          'ശദ്ദ് ഉള്ള നൂൻ (نّ) അല്ലെങ്കിൽ മീം (مّ). മൂക്കിലൂടെ 2 ഹറകത്ത് അളവിൽ മണിച്ചു നിർത്തി ഉച്ചരിക്കുക.',
      descAr: 'نون أو ميم مشددة (نّ / مّ)، تُقرأ بغنة ظاهرة بمقدار حركتين.',
      sampleAr: 'إِنَّ · ثُمَّ',
      lightColor: Color(0xFF0B7A43),
      darkColor: Color(0xFF4ADE80),
    ),
    TajweedRuleMeta(
      rule: TajweedRule.idghamGhunnah,
      nameEn: 'Idgham with Ghunnah',
      nameMl: 'ഇദ്ഗാം ബി-ഗുന്ന (മണിച്ചു ലയിപ്പിക്കൽ)',
      nameAr: 'إدغام بغنة',
      descEn:
          'Noon Sakinah or Tanween followed by ي ن م و (Yanmu). Merge smoothly with 2-count nasal sound.',
      descMl:
          'സുകൂനുള്ള നൂനോ തൻവീനോ കഴിഞ്ഞ് (ي ن م و) വന്നാൽ മണിച്ചുകൊണ്ട് അടുത്ത അക്ഷരത്തിലേക്ക് ലയിപ്പിച്ചു വായിക്കുക.',
      descAr:
          'نون ساكنة أو تنوين بعده أحد حروف (ينمو)، يُدغم مع غنة بمقدار حركتين.',
      sampleAr: 'مَن يَقُولُ · خَيْرٌ مِّن',
      lightColor: Color(0xFF00796B),
      darkColor: Color(0xFF2DD4BF),
    ),
    TajweedRuleMeta(
      rule: TajweedRule.idghamNoGhunnah,
      nameEn: 'Idgham without Ghunnah',
      nameMl: 'ഇദ്ഗാം ബിലാ ഗുന്ന (മണിക്കാതെ ലയിപ്പിക്കൽ)',
      nameAr: 'إدغام بلا غنة',
      descEn:
          'Noon Sakinah or Tanween followed by ل or ر. Merge completely into the next letter without nasalization.',
      descMl:
          'സുകൂനുള്ള നൂനോ തൻവീനോ കഴിഞ്ഞ് (ل, ر) വന്നാൽ മൂക്കിലൂടെ മണിക്കാതെ പൂർണ്ണമായി അടുത്ത അക്ഷരത്തിലേക്ക് ലയിപ്പിക്കുക.',
      descAr: 'نون ساكنة أو تنوين بعده (ل أو ر)، يُدغم إدغاماً كاملاً بدون غنة.',
      sampleAr: 'مِن رَّبِّهِمْ · هُدًى لِّلْمُتَّقِينَ',
      lightColor: Color(0xFF558B2F),
      darkColor: Color(0xFFA3E635),
    ),
    TajweedRuleMeta(
      rule: TajweedRule.ikhfa,
      nameEn: 'Ikhfa (Concealment)',
      nameMl: 'ഇഖ്ഫാ (മറച്ചു മണിച്ചു വായിക്കൽ)',
      nameAr: 'إخفاء حقيقي / شفوي',
      descEn:
          'Noon Sakinah/Tanween before the 15 Ikhfa letters, or Meem Sakinah before ب. Hide softly with a 2-count nasal hum.',
      descMl:
          'നൂൻ സാക്കിനോ തൻവീനോ ഇഖ്ഫാ അക്ഷരങ്ങൾക്ക് മുമ്പും, മീം സാക്കിൻ (ب) നു മുമ്പും വരുമ്പോൾ വ്യക്തമാക്കാതെ മറച്ചു 2 ഹറകത്ത് മണിച്ചു വായിക്കുക.',
      descAr:
          'إخفاء النون الساكنة أو التنوين عند حروف الإخفاء الخمسة عشر، أو الميم الساكنة عند الباء بغنة حركتين.',
      sampleAr: 'مِن قَبْلِ · تَرْمِيهِم بِحِجَارَةٍ',
      lightColor: Color(0xFFC62828),
      darkColor: Color(0xFFFB7185),
    ),
    TajweedRuleMeta(
      rule: TajweedRule.iqlab,
      nameEn: 'Iqlab (Conversion)',
      nameMl: 'ഇഖ്‌ലാബ് (മീമായി മാറ്റി വായിക്കൽ)',
      nameAr: 'إقلاب',
      descEn:
          'Noon Sakinah or Tanween followed by ب (Baa). Convert softly into a hidden Meem sound with 2-count Ghunnah.',
      descMl:
          'സുകൂനുള്ള നൂനോ തൻവീനോ കഴിഞ്ഞ് (ب) വന്നാൽ ആ നൂനിനെ ചെറിയ മീം ശബ്ദമാക്കി 2 ഹറകത്ത് മണിച്ചു വായിക്കുക.',
      descAr:
          'قلب النون الساكنة أو التنوين ميماً مخفاة عند حرف الباء مع غنة حركتين.',
      sampleAr: 'مِنۢ بَعْدِ · سَمِيعٌۢ بَصِيرٌ',
      lightColor: Color(0xFF8E24AA),
      darkColor: Color(0xFFD8B4FE),
    ),
    TajweedRuleMeta(
      rule: TajweedRule.qalqalah,
      nameEn: 'Qalqalah (Echoing Bounce)',
      nameMl: 'ഖൽഖല (പ്രതിധ്വനി / തട്ടി ഉച്ചരിക്കൽ)',
      nameAr: 'قلقلة (ق ط ب ج د)',
      descEn:
          'Letters ق ط ب ج د carrying Sukoon (or stopped on at Ayah end). Pronounce with a crisp echoing bounce.',
      descMl:
          'സുകൂനുള്ള (ق ط ب ج د) അക്ഷരങ്ങൾ വായിക്കുമ്പോൾ ചെറിയൊരു പ്രതിധ്വനിയോടെ (തട്ടി) വ്യക്തമായി ഉച്ചരിക്കുക.',
      descAr: 'حروف (قطب جد) الساكنة أو الموقوف عليها، تُنطق بنبرة اضطراب واهتزاز.',
      sampleAr: 'لَقَدْ · يَجْعَلُ · أَحَدْ',
      lightColor: Color(0xFF1565C0),
      darkColor: Color(0xFF60A5FA),
    ),
    TajweedRuleMeta(
      rule: TajweedRule.madd,
      nameEn: 'Madd (Elongation)',
      nameMl: 'മദ്ദ് (നീട്ടി വായിക്കൽ)',
      nameAr: 'مَدّ (4–6 حركات)',
      descEn:
          'Elongated vowel sign (~ / آ / dagger Alif). Stretch smoothly for 4 to 6 counts as marked.',
      descMl:
          'മദ്ദിന്റെ ചിഹ്നം (~ / آ) ഉള്ള ഭാഗങ്ങൾ നിയമപ്രകാരം 4 മുതൽ 6 ഹറകത്ത് വരെ നീട്ടി ഓതുക.',
      descAr: 'حرف مدّ تعلوه علامة المد (~) أو ألف خنجرية، يُمدّ 4 إلى 6 حركات.',
      sampleAr: 'السَّمَاءِ · الضَّالِّينَ · ذَٰلِكَ',
      lightColor: Color(0xFFB45309),
      darkColor: Color(0xFFFBBF24),
    ),
    TajweedRuleMeta(
      rule: TajweedRule.silent,
      nameEn: 'Silent / Lam Shamsiyyah',
      nameMl: 'ഉച്ചരിക്കാത്ത അക്ഷരം / ലാം ശംസിയ്യ',
      nameAr: 'حرف صامت / لام شمسية',
      descEn:
          'Silent Hamzatul Wasl, silent Alif/Waw, or assimilated Lam Shamsiyyah. Bypass silently into the next sound.',
      descMl:
          'ശബ്ദമില്ലാത്ത ഹംസതുൽ വസ്‌ൽ, ലാം ശംസിയ്യ പോലുള്ള അക്ഷരങ്ങൾ ഉച്ചരിക്കാതെ അടുത്ത അക്ഷരവുമായി ചേർത്തു വായിക്കുക.',
      descAr:
          'همزة وصل أو لام شمسية أو حرف مدغم لا يُنطق، بل يُوصل مباشرة بما بعده.',
      sampleAr: 'ٱلشَّمْسُ · قَالُوا۟',
      lightColor: Color(0xFF64748B),
      darkColor: Color(0xFF94A3B8),
    ),
  ];

  static TajweedRuleMeta? metaFor(TajweedRule rule) {
    for (final m in legend) {
      if (m.rule == rule) return m;
    }
    return null;
  }

  static final Map<String, List<TajweedToken>> _cache = {};
  static const int _maxCacheSize = 1800;

  static const Set<String> _qalqalahLetters = {'ق', 'ط', 'ب', 'ج', 'د'};
  static const Set<String> _idghamGhunnahLetters = {'ي', 'ن', 'م', 'و'};
  static const Set<String> _idghamNoGhunnahLetters = {'ل', 'ر'};
  static const Set<String> _ikhfaLetters = {
    'ت', 'ث', 'ج', 'د', 'ذ', 'ز', 'س', 'ش', 'ص', 'ض', 'ط', 'ظ', 'ف', 'ق', 'ك',
  };
  static const Set<String> _sunLetters = {
    'ت', 'ث', 'د', 'ذ', 'ر', 'ز', 'س', 'ش', 'ص', 'ض', 'ط', 'ظ', 'ل', 'ن',
  };
  // Right-joining only (do NOT connect to following letter, so split after them needs no ZWJ)
  static const Set<String> _rightJoiningOnly = {
    'ا', 'أ', 'إ', 'آ', 'ٱ', 'د', 'ذ', 'ر', 'ز', 'و', 'ؤ', 'ة', 'ى',
  };

  static bool _isCombiningMark(int cp) {
    return (cp >= 0x064B && cp <= 0x065F) || // Fathatan .. Hamza below
        cp == 0x0670 || // Dagger Alif
        (cp >= 0x06D6 && cp <= 0x06ED); // Quranic marks / small high meem / sukun
  }

  static bool _isArabicLetter(int cp) {
    return (cp >= 0x0621 && cp <= 0x064A) || cp == 0x0671;
  }

  static List<TajweedToken> parseAyah(String text) {
    if (text.isEmpty) return const [];
    final cached = _cache[text];
    if (cached != null) return cached;

    final result = _computeTokens(text);
    if (_cache.length >= _maxCacheSize) {
      _cache.clear();
    }
    _cache[text] = result;
    return result;
  }

  static List<_Cluster> _extractClusters(String text) {
    final runes = text.runes.toList();
    final clusters = <_Cluster>[];
    int i = 0;
    while (i < runes.length) {
      final start = i;
      final base = String.fromCharCode(runes[i]);
      i++;
      final marks = StringBuffer();
      while (i < runes.length && _isCombiningMark(runes[i])) {
        marks.writeCharCode(runes[i]);
        i++;
      }
      clusters.add(
        _Cluster(
          base: base,
          marks: marks.toString(),
          full: text.substring(_runeToUtf16(runes, start), _runeToUtf16(runes, i)),
          isLetter: _isArabicLetter(base.runes.first),
          isWhitespace: base.trim().isEmpty,
        ),
      );
    }
    return clusters;
  }

  static int _runeToUtf16(List<int> runes, int runeIdx) {
    int offset = 0;
    for (int k = 0; k < runeIdx; k++) {
      offset += runes[k] > 0xFFFF ? 2 : 1;
    }
    return offset;
  }

  static List<TajweedToken> _computeTokens(String text) {
    final clusters = _extractClusters(text);
    final rules = List<TajweedRule>.filled(clusters.length, TajweedRule.none);

    bool hasSukun(String m) =>
        m.contains('\u0652') || m.contains('\u06E1'); // Sukun or Uthmani jazm
    bool hasShaddah(String m) => m.contains('\u0651');
    bool hasTanween(String m) =>
        m.contains('\u064B') || m.contains('\u064C') || m.contains('\u064D');
    bool hasAnyVowel(String m) =>
        m.contains('\u064E') ||
        m.contains('\u064F') ||
        m.contains('\u0650') ||
        m.contains('\u064B') ||
        m.contains('\u064C') ||
        m.contains('\u064D') ||
        hasSukun(m);
    bool hasMaddSign(String m) => m.contains('\u0653') || m.contains('\u0670');
    bool hasSmallMeem(String m) => m.contains('\u06E2') || m.contains('\u06ED');

    int? nextLetterIndex(int from) {
      for (int j = from + 1; j < clusters.length; j++) {
        if (clusters[j].isLetter) return j;
      }
      return null;
    }

    int? nextWordInitialLetterIndex(int from) {
      for (int j = from + 1; j < clusters.length; j++) {
        if (clusters[j].isLetter) {
          // Skip silent Alif Wasl at the beginning of next word if any (e.g. ال...)
          if (clusters[j].base == 'ٱ' || clusters[j].base == 'ا') {
            if (j + 1 < clusters.length && clusters[j + 1].isLetter) {
              continue;
            }
          }
          return j;
        }
      }
      return null;
    }

    for (int i = 0; i < clusters.length; i++) {
      final c = clusters[i];
      if (!c.isLetter) continue;

      final b = c.base;
      final m = c.marks;

      // 1. Silent Hamzatul Wasl / Silent zero-circle Alif/Waw (ـو۟ / ٱ)
      if (b == 'ٱ' || m.contains('\u06DF')) {
        rules[i] = TajweedRule.silent;
        continue;
      }

      // 2. Lam Shamsiyyah (ل without vowel followed by sun letter with Shaddah)
      if (b == 'ل' && !hasAnyVowel(m)) {
        final nextIdx = nextLetterIndex(i);
        if (nextIdx != null &&
            _sunLetters.contains(clusters[nextIdx].base) &&
            hasShaddah(clusters[nextIdx].marks)) {
          rules[i] = TajweedRule.silent;
          continue;
        }
      }

      // 3. Explicit Maddah (~) or Madd Alif Ā (آ) or Dagger Alif (ـٰ)
      if (b == 'آ' || hasMaddSign(m)) {
        // Skip coloring Dagger Alif in Allah/Bismillah minor spots? Keeping all explicit madd/dagger visible helps learners!
        rules[i] = TajweedRule.madd;
        continue;
      }

      // 4. Ghunnah (نّ / مّ with Shaddah)
      if ((b == 'ن' || b == 'م') && hasShaddah(m)) {
        rules[i] = TajweedRule.ghunnah;
        continue;
      }

      // 5. Iqlab marker explicit (small meem ۢ / ۭ)
      if (hasSmallMeem(m)) {
        rules[i] = TajweedRule.iqlab;
        continue;
      }

      // 6. Noon Sakinah or Tanween rules
      final bool isNoonSakin =
          b == 'ن' && (hasSukun(m) || (!hasAnyVowel(m) && !hasShaddah(m)));
      final bool isTanween = hasTanween(m);

      if (isNoonSakin || isTanween) {
        final nextIdx = nextWordInitialLetterIndex(i);
        if (nextIdx != null) {
          final nextChar = clusters[nextIdx].base;
          if (nextChar == 'ب') {
            rules[i] = TajweedRule.iqlab;
            continue;
          } else if (_idghamGhunnahLetters.contains(nextChar)) {
            rules[i] = TajweedRule.idghamGhunnah;
            continue;
          } else if (_idghamNoGhunnahLetters.contains(nextChar)) {
            rules[i] = TajweedRule.idghamNoGhunnah;
            continue;
          } else if (_ikhfaLetters.contains(nextChar)) {
            rules[i] = TajweedRule.ikhfa;
            continue;
          }
        }
      }

      // 7. Meem Sakinah before ب (Ikhfa Shafawi) or م (Idgham Shafawi)
      final bool isMeemSakin =
          b == 'م' && (hasSukun(m) || (!hasAnyVowel(m) && !hasShaddah(m)));
      if (isMeemSakin) {
        final nextIdx = nextWordInitialLetterIndex(i);
        if (nextIdx != null) {
          final nextChar = clusters[nextIdx].base;
          if (nextChar == 'ب') {
            rules[i] = TajweedRule.ikhfa;
            continue;
          } else if (nextChar == 'م') {
            rules[i] = TajweedRule.idghamGhunnah;
            continue;
          }
        }
      }

      // 8. Qalqalah (ق ط ب ج د with Sukun, or last letter of ayah without shaddah)
      if (_qalqalahLetters.contains(b)) {
        final bool isLastLetterOfAyah = nextLetterIndex(i) == null;
        if (hasSukun(m) || (isLastLetterOfAyah && !hasShaddah(m))) {
          rules[i] = TajweedRule.qalqalah;
          continue;
        }
      }
    }

    // Merge consecutive clusters sharing the same rule, inserting ZWJ (\u200D)
    // across intra-word rule boundaries when dual-joining letters touch so Arabic stays ligatured.
    final tokens = <TajweedToken>[];
    if (clusters.isEmpty) return tokens;

    TajweedRule activeRule = rules[0];
    final buf = StringBuffer(clusters[0].full);

    for (int i = 1; i < clusters.length; i++) {
      final r = rules[i];
      final prevCluster = clusters[i - 1];
      final curCluster = clusters[i];

      if (r == activeRule) {
        buf.write(curCluster.full);
      } else {
        final bool connectsLeft = prevCluster.isLetter &&
            curCluster.isLetter &&
            !_rightJoiningOnly.contains(prevCluster.base);

        var completedText = buf.toString();
        if (connectsLeft && !completedText.endsWith('\u200D')) {
          completedText = '$completedText\u200D';
        }
        tokens.add(TajweedToken(completedText, activeRule));

        buf.clear();
        if (connectsLeft) {
          buf.write('\u200D');
        }
        buf.write(curCluster.full);
        activeRule = r;
      }
    }

    if (buf.isNotEmpty) {
      tokens.add(TajweedToken(buf.toString(), activeRule));
    }

    return tokens;
  }
}

class _Cluster {
  final String base;
  final String marks;
  final String full;
  final bool isLetter;
  final bool isWhitespace;

  const _Cluster({
    required this.base,
    required this.marks,
    required this.full,
    required this.isLetter,
    required this.isWhitespace,
  });
}
