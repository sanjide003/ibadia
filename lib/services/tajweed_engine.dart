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

  Color colorFor(bool isDark) => isDark ? darkColor : lightColor;

  String titleFor(String lang) {
    if (lang == 'ml') return nameMl;
    if (lang == 'ar') return nameAr;
    return nameEn;
  }

  String descriptionFor(String lang) {
    if (lang == 'ml') return descMl;
    if (lang == 'ar') return descAr;
    return descEn;
  }
}

class TajweedToken {
  final String text;
  final TajweedRule rule;

  const TajweedToken(this.text, this.rule);
}

class _TajweedCluster {
  final String base;
  final String marks;
  final String full;
  final bool isLetter;

  const _TajweedCluster({
    required this.base,
    required this.marks,
    required this.full,
    required this.isLetter,
  });
}

class TajweedEngine {
  const TajweedEngine._();

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
          'Noon Sakinah or Tanween followed by ي ن م و (Yanmu), or Meem Sakinah followed by م. Merge smoothly with 2-count nasal sound.',
      descMl:
          'സുകൂനുള്ള നൂനോ തൻവീനോ കഴിഞ്ഞ് (ي ن م و) വന്നാലോ, മീം സാക്കിന് ശേഷം (م) വന്നാലോ മണിച്ചുകൊണ്ട് ലയിപ്പിച്ചു വായിക്കുക.',
      descAr:
          'نون ساكنة أو تنوين بعده أحد حروف (ينمو)، أو ميم ساكنة بعدها ميم، يُدغم مع غنة بمقدار حركتين.',
      sampleAr: 'مَن يَقُولُ · خَيْرٌ مِّن · لَهُم مَّغْفِرَةٌ',
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
      descAr: 'قلب النون الساكنة أو التنوين ميماً مخفاة عند حرف الباء مع غنة حركتين.',
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
      nameEn: 'Madd (4–6 Counts)',
      nameMl: 'മദ്ദ് (4–6 ഹറകത്ത് നീട്ടി വായിക്കൽ)',
      nameAr: 'مَدّ (4–6 حركات)',
      descEn:
          'Obligatory or permitted long Madd (~ / آ). Stretch smoothly for 4 to 6 counts as marked.',
      descMl:
          'മദ്ദിന്റെ ചിഹ്നം (~ / آ) ഉള്ള ഭാഗങ്ങൾ നിയമപ്രകാരം 4 മുതൽ 6 ഹറകത്ത് വരെ നീട്ടി ഓതുക.',
      descAr: 'حرف مدّ تعلوه علامة المد (~) أو مدّ لازم، يُمدّ 4 إلى 6 حركات.',
      sampleAr: 'السَّمَآءِ · الضَّآلِّينَ · بِمَآ',
      lightColor: Color(0xFFB45309),
      darkColor: Color(0xFFFBBF24),
    ),
    TajweedRuleMeta(
      rule: TajweedRule.silent,
      nameEn: 'Silent / Lam Shamsiyyah',
      nameMl: 'ഉച്ചരിക്കാത്ത അക്ഷരം / ലാം ശംസിയ്യ',
      nameAr: 'حرف صامت / لام شمسية',
      descEn:
          'Silent Hamzatul Wasl, silent Alif/Waw, Lam Shamsiyyah, or assimilated silent letters. Bypass silently into the next sound.',
      descMl:
          'ശബ്ദമില്ലാത്ത ഹംസതുൽ വസ്‌ൽ, ലാം ശംസിയ്യ, ലയിപ്പിക്കപ്പെടുന്ന അക്ഷരങ്ങൾ എന്നിവ ഉച്ചരിക്കാതെ അടുത്ത അക്ഷരവുമായി ചേർത്തു വായിക്കുക.',
      descAr: 'همزة وصل أو لام شمسية أو حرف مدغم لا يُنطق، بل يُوصل مباشرة بما بعده.',
      sampleAr: 'ٱلشَّمْسُ · قَالُوا۟',
      lightColor: Color(0xFF64748B),
      darkColor: Color(0xFF94A3B8),
    ),
  ];

  static TajweedRuleMeta? metaForRule(TajweedRule rule) {
    for (final m in legend) {
      if (m.rule == rule) return m;
    }
    return null;
  }

  static final Map<String, List<TajweedToken>> _cache = {};
  static const int _maxCache = 1800;

  static final RegExp _tagOpenRegex = RegExp(r'\[([a-z])(?::\d+)?\[');

  static const Set<String> _qalqalahLetters = {'ق', 'ط', 'ب', 'ج', 'د'};
  static const Set<String> _idghamGhunnahLetters = {'ي', 'ن', 'م', 'و'};
  static const Set<String> _idghamNoGhunnahLetters = {'ل', 'ر'};
  static const Set<String> _ikhfaLetters = {
    'ت',
    'ث',
    'ج',
    'د',
    'ذ',
    'ز',
    'س',
    'ش',
    'ص',
    'ض',
    'ط',
    'ظ',
    'ف',
    'ق',
    'ك',
  };
  static const Set<String> _sunLetters = {
    'ت',
    'ث',
    'د',
    'ذ',
    'ر',
    'ز',
    'س',
    'ش',
    'ص',
    'ض',
    'ط',
    'ظ',
    'ل',
    'ن',
  };
  static const Set<String> _rightJoiningOnly = {
    'ا',
    'أ',
    'إ',
    'آ',
    'ٱ',
    'د',
    'ذ',
    'ر',
    'ز',
    'و',
    'ؤ',
    'ة',
    'ى',
  };

  static bool hasTajweedMarkup(String text) =>
      text.contains('[') && _tagOpenRegex.hasMatch(text);

  /// Strips all official `quran-tajweed` bracket annotations `[code[:id][...]]`
  /// (including nested tags and stray delimiter brackets) to return pure Arabic text.
  static String stripMarkup(String text) {
    if (!text.contains('[') && !text.contains(']')) return text;
    final out = StringBuffer();
    var i = 0;
    while (i < text.length) {
      final ch = text[i];
      if (ch == '[') {
        final match = _tagOpenRegex.matchAsPrefix(text, i);
        if (match != null) {
          i = match.end;
          continue;
        }
        i++;
        continue;
      }
      if (ch == ']') {
        i++;
        continue;
      }
      out.write(ch);
      i++;
    }
    return out.toString();
  }

  static TajweedRule _ruleForTagCode(String code) {
    switch (code) {
      case 'g':
        return TajweedRule.ghunnah;
      case 'a':
      case 'w':
        return TajweedRule.idghamGhunnah;
      case 'u':
        return TajweedRule.idghamNoGhunnah;
      case 'f':
      case 'c':
        return TajweedRule.ikhfa;
      case 'i':
        return TajweedRule.iqlab;
      case 'q':
        return TajweedRule.qalqalah;
      case 'o':
      case 'm':
        return TajweedRule.madd;
      case 'h':
      case 'l':
      case 's':
      case 'd':
      case 'b':
        return TajweedRule.silent;
      case 'n':
      case 'p':
      default:
        return TajweedRule.none;
    }
  }

  static bool _isCombiningMark(int cp) {
    if (cp == 0x06DD || cp == 0x06DE || cp == 0x06E9) return false;
    return (cp >= 0x064B && cp <= 0x065F) ||
        cp == 0x0670 ||
        (cp >= 0x06D6 && cp <= 0x06ED);
  }

  static bool _isArabicLetter(int cp) {
    return (cp >= 0x0621 && cp <= 0x064A) || cp == 0x0671 || cp == 0x0672;
  }

  static List<_TajweedCluster> _extractClusters(String text) {
    final runes = text.runes.toList();
    final clusters = <_TajweedCluster>[];
    var i = 0;
    while (i < runes.length) {
      final baseCp = runes[i];
      final base = String.fromCharCode(baseCp);
      i++;
      final marksBuf = StringBuffer();
      while (i < runes.length && _isCombiningMark(runes[i])) {
        marksBuf.writeCharCode(runes[i]);
        i++;
      }
      final marks = marksBuf.toString();
      clusters.add(
        _TajweedCluster(
          base: base,
          marks: marks,
          full: '$base$marks',
          isLetter: _isArabicLetter(baseCp),
        ),
      );
    }
    return clusters;
  }

  static bool _hasSukun(String m) =>
      m.contains('\u0652') || m.contains('\u06E1');

  static bool _hasShaddah(String m) => m.contains('\u0651');

  static bool _hasTanween(String m) =>
      m.contains('\u064B') || m.contains('\u064C') || m.contains('\u064D');

  static bool _hasAnyVowel(String m) =>
      m.contains('\u064E') ||
      m.contains('\u064F') ||
      m.contains('\u0650') ||
      _hasTanween(m) ||
      _hasSukun(m);

  // Only true 4-6 count Maddah (~) sign (exclude 2-count Dagger Alif \u0670).
  static bool _hasMaddSign(String m) => m.contains('\u0653');

  static int? _nextLetterIndex(List<_TajweedCluster> clusters, int from) {
    for (var j = from + 1; j < clusters.length; j++) {
      if (clusters[j].isLetter) return j;
    }
    return null;
  }

  static ({int index, bool crossedWordBoundary})? _nextConsonantTarget(
    List<_TajweedCluster> clusters,
    int from, {
    required bool skipTanweenSeatAlif,
  }) {
    var crossedBoundary = false;
    for (var j = from + 1; j < clusters.length; j++) {
      final c = clusters[j];
      if (!c.isLetter) {
        crossedBoundary = true;
        continue;
      }
      if (skipTanweenSeatAlif &&
          !crossedBoundary &&
          (c.base == 'ا' || c.base == 'ى') &&
          !_hasAnyVowel(c.marks) &&
          (j + 1 >= clusters.length || !clusters[j + 1].isLetter)) {
        continue;
      }
      return (index: j, crossedWordBoundary: crossedBoundary);
    }
    return null;
  }

  static List<TajweedToken> _buildTokensFromClusters(
    List<_TajweedCluster> clusters,
    List<TajweedRule> rules,
  ) {
    if (clusters.isEmpty) return const [];

    final tokens = <TajweedToken>[];
    var activeRule = rules[0];
    final buf = StringBuffer(clusters[0].full);

    for (var i = 1; i < clusters.length; i++) {
      final r = rules[i];
      final prevCluster = clusters[i - 1];
      final curCluster = clusters[i];

      if (r == activeRule) {
        buf.write(curCluster.full);
      } else {
        final connectsLeft = prevCluster.isLetter &&
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

  static List<TajweedToken> _tokenizeTagged(String text) {
    final stack = <TajweedRule>[];
    final taggedChars = <({int cp, String ch, TajweedRule rule})>[];

    var i = 0;
    while (i < text.length) {
      final unit = text.codeUnitAt(i);
      if (unit == 0x5B /* '[' */) {
        final match = _tagOpenRegex.matchAsPrefix(text, i);
        if (match != null) {
          stack.add(_ruleForTagCode(match.group(1)!));
          i = match.end;
          continue;
        }
        // Preserve balanced stack if an unmatched stray '[' appears.
        stack.add(stack.isEmpty ? TajweedRule.none : stack.last);
        i++;
        continue;
      }
      if (unit == 0x5D /* ']' */) {
        if (stack.isNotEmpty) {
          stack.removeLast();
        }
        i++;
        continue;
      }

      // Handle UTF-16 surrogate pairs cleanly if present.
      int cp;
      String ch;
      if (unit >= 0xD800 && unit <= 0xDBFF && i + 1 < text.length) {
        final nextUnit = text.codeUnitAt(i + 1);
        if (nextUnit >= 0xDC00 && nextUnit <= 0xDFFF) {
          cp = 0x10000 + ((unit - 0xD800) << 10) + (nextUnit - 0xDC00);
          ch = text.substring(i, i + 2);
          i += 2;
        } else {
          cp = unit;
          ch = text[i];
          i++;
        }
      } else {
        cp = unit;
        ch = text[i];
        i++;
      }

      taggedChars.add((
        cp: cp,
        ch: ch,
        rule: stack.isEmpty ? TajweedRule.none : stack.last,
      ));
    }

    if (taggedChars.isEmpty) return const [];

    // Group into base-letter grapheme clusters so no TextSpan ever starts with
    // an isolated combining diacritic.
    final clusters = <_TajweedCluster>[];
    final rules = <TajweedRule>[];
    var j = 0;
    while (j < taggedChars.length) {
      final base = taggedChars[j];
      final marksBuf = StringBuffer();
      var k = j + 1;
      while (k < taggedChars.length && _isCombiningMark(taggedChars[k].cp)) {
        marksBuf.write(taggedChars[k].ch);
        k++;
      }
      final marks = marksBuf.toString();
      clusters.add(
        _TajweedCluster(
          base: base.ch,
          marks: marks,
          full: '${base.ch}$marks',
          isLetter: _isArabicLetter(base.cp),
        ),
      );
      rules.add(base.rule);
      j = k;
    }

    return _buildTokensFromClusters(clusters, rules);
  }

  static List<TajweedToken> _tokenizeHeuristic(String text) {
    final clusters = _extractClusters(text);
    if (clusters.isEmpty) return const [];

    final rules = List<TajweedRule>.filled(clusters.length, TajweedRule.none);
    var seenLetter = false;

    for (var i = 0; i < clusters.length; i++) {
      final c = clusters[i];
      if (!c.isLetter) continue;
      final isFirstLetter = !seenLetter;
      seenLetter = true;

      final b = c.base;
      final m = c.marks;

      // Hamzatul Wasl is only silent mid-stream (not when starting the ayah on it),
      // and small high rounded zero (\u06DF) marks silent letters (e.g. واْ).
      if ((b == 'ٱ' && !isFirstLetter) || m.contains('\u06DF')) {
        rules[i] = TajweedRule.silent;
        continue;
      }

      if (b == 'ل' && !_hasAnyVowel(m)) {
        final nextIdx = _nextLetterIndex(clusters, i);
        if (nextIdx != null &&
            _sunLetters.contains(clusters[nextIdx].base) &&
            _hasShaddah(clusters[nextIdx].marks)) {
          rules[i] = TajweedRule.silent;
          continue;
        }
      }

      if (b == 'آ' || _hasMaddSign(m)) {
        rules[i] = TajweedRule.madd;
        continue;
      }

      if ((b == 'ن' || b == 'م') && _hasShaddah(m)) {
        rules[i] = TajweedRule.ghunnah;
        continue;
      }

      final isNoonSakin =
          b == 'ن' && (_hasSukun(m) || (!_hasAnyVowel(m) && !_hasShaddah(m)));
      final isTanween = _hasTanween(m);

      if (isNoonSakin || isTanween) {
        final target = _nextConsonantTarget(
          clusters,
          i,
          skipTanweenSeatAlif: isTanween,
        );
        if (target != null) {
          final nextChar = clusters[target.index].base;
          final crossed = target.crossedWordBoundary;
          if (nextChar == 'ب') {
            rules[i] = TajweedRule.iqlab;
            continue;
          } else if (_idghamGhunnahLetters.contains(nextChar)) {
            // Izhar Mutlaq: Noon Sakinah before ي or و inside the same word
            // (الدُّنْيَا، بُنْيَانٌ، قِنْوَانٌ، صِنْوَانٌ) is NOT Idgham.
            if (isNoonSakin &&
                !crossed &&
                (nextChar == 'ي' || nextChar == 'و')) {
              continue;
            }
            rules[i] = TajweedRule.idghamGhunnah;
            continue;
          } else if (_idghamNoGhunnahLetters.contains(nextChar)) {
            if (crossed || isTanween) {
              rules[i] = TajweedRule.idghamNoGhunnah;
              continue;
            }
          } else if (_ikhfaLetters.contains(nextChar)) {
            rules[i] = TajweedRule.ikhfa;
            continue;
          }
        }
      }

      final isMeemSakin =
          b == 'م' && (_hasSukun(m) || (!_hasAnyVowel(m) && !_hasShaddah(m)));
      if (isMeemSakin) {
        final target = _nextConsonantTarget(
          clusters,
          i,
          skipTanweenSeatAlif: false,
        );
        if (target != null) {
          final nextChar = clusters[target.index].base;
          if (nextChar == 'ب') {
            rules[i] = TajweedRule.ikhfa;
            continue;
          } else if (nextChar == 'م') {
            rules[i] = TajweedRule.idghamGhunnah;
            continue;
          }
        }
      }

      if (_qalqalahLetters.contains(b)) {
        final isLastLetterOfAyah = _nextLetterIndex(clusters, i) == null;
        if (_hasSukun(m) || (isLastLetterOfAyah && !_hasShaddah(m))) {
          rules[i] = TajweedRule.qalqalah;
          continue;
        }
      }
    }

    return _buildTokensFromClusters(clusters, rules);
  }

  static List<TajweedToken> tokenize(
    String text, {
    bool? isTaggedSource,
  }) {
    if (text.isEmpty) return const [];
    final useTagged = isTaggedSource ?? hasTajweedMarkup(text);
    final cacheKey = '${useTagged ? 'T' : 'H'}:$text';
    final hit = _cache[cacheKey];
    if (hit != null) return hit;

    final tokens = useTagged
        ? _tokenizeTagged(text)
        : _tokenizeHeuristic(text);

    if (_cache.length >= _maxCache) {
      _cache.clear();
    }
    _cache[cacheKey] = tokens;
    return tokens;
  }
}
