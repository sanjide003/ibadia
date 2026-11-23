export type TajweedRule =
  | 'none'
  | 'ghunnah'
  | 'idghamGhunnah'
  | 'idghamNoGhunnah'
  | 'ikhfa'
  | 'iqlab'
  | 'qalqalah'
  | 'madd'
  | 'silent';

export interface TajweedRuleMeta {
  rule: TajweedRule;
  nameEn: string;
  nameMl: string;
  nameAr: string;
  descEn: string;
  descMl: string;
  descAr: string;
  sampleAr: string;
  lightColor: string;
  darkColor: string;
}

export interface TajweedToken {
  text: string;
  rule: TajweedRule;
}

export const TAJWEED_LEGEND: TajweedRuleMeta[] = [
  {
    rule: 'ghunnah',
    nameEn: 'Ghunnah (Nasalization)',
    nameMl: 'ഗുന്ന (മൂക്കിലൂടെ മണിച്ചു നീട്ടൽ)',
    nameAr: 'غُنّة (نّ / مّ)',
    descEn: 'Noon or Meem with a Shaddah (نّ / مّ). Hold the nasal resonance clearly for 2 counts.',
    descMl: 'ശദ്ദ് ഉള്ള നൂൻ (نّ) അല്ലെങ്കിൽ മീം (مّ). മൂക്കിലൂടെ 2 ഹറകത്ത് അളവിൽ മണിച്ചു നിർത്തി ഉച്ചരിക്കുക.',
    descAr: 'نون أو ميم مشددة (نّ / مّ)، تُقرأ بغنة ظاهرة بمقدار حركتين.',
    sampleAr: 'إِنَّ · ثُمَّ',
    lightColor: '#0B7A43',
    darkColor: '#4ADE80',
  },
  {
    rule: 'idghamGhunnah',
    nameEn: 'Idgham with Ghunnah',
    nameMl: 'ഇദ്ഗാം ബി-ഗുന്ന (മണിച്ചു ലയിപ്പിക്കൽ)',
    nameAr: 'إدغام بغنة',
    descEn: 'Noon Sakinah or Tanween followed by ي ن م و (Yanmu). Merge smoothly with 2-count nasal sound.',
    descMl: 'സുകൂനുള്ള നൂനോ തൻവീനോ കഴിഞ്ഞ് (ي ن م و) വന്നാൽ മണിച്ചുകൊണ്ട് അടുത്ത അക്ഷരത്തിലേക്ക് ലയിപ്പിച്ചു വായിക്കുക.',
    descAr: 'نون ساكنة أو تنوين بعده أحد حروف (ينمو)، يُدغم مع غنة بمقدار حركتين.',
    sampleAr: 'مَن يَقُولُ · خَيْرٌ مِّن',
    lightColor: '#00796B',
    darkColor: '#2DD4BF',
  },
  {
    rule: 'idghamNoGhunnah',
    nameEn: 'Idgham without Ghunnah',
    nameMl: 'ഇദ്ഗാം ബിലാ ഗുന്ന (മണിക്കാതെ ലയിപ്പിക്കൽ)',
    nameAr: 'إدغام بلا غنة',
    descEn: 'Noon Sakinah or Tanween followed by ل or ر. Merge completely into the next letter without nasalization.',
    descMl: 'സുകൂനുള്ള നൂനോ തൻവീനോ കഴിഞ്ഞ് (ل, ر) വന്നാൽ മൂക്കിലൂടെ മണിക്കാതെ പൂർണ്ണമായി അടുത്ത അക്ഷരത്തിലേക്ക് ലയിപ്പിക്കുക.',
    descAr: 'نون ساكنة أو تنوين بعده (ل أو ر)، يُدغم إدغاماً كاملاً بدون غنة.',
    sampleAr: 'مِن رَّبِّهِمْ · هُدًى لِّلْمُتَّقِينَ',
    lightColor: '#558B2F',
    darkColor: '#A3E635',
  },
  {
    rule: 'ikhfa',
    nameEn: 'Ikhfa (Concealment)',
    nameMl: 'ഇഖ്ഫാ (മറച്ചു മണിച്ചു വായിക്കൽ)',
    nameAr: 'إخفاء حقيقي / شفوي',
    descEn: 'Noon Sakinah/Tanween before the 15 Ikhfa letters, or Meem Sakinah before ب. Hide softly with a 2-count nasal hum.',
    descMl: 'നൂൻ സാക്കിനോ തൻവീനോ ഇഖ്ഫാ അക്ഷരങ്ങൾക്ക് മുമ്പും, മീം സാക്കിൻ (ب) നു മുമ്പും വരുമ്പോൾ വ്യക്തമാക്കാതെ മറച്ചു 2 ഹറകത്ത് മണിച്ചു വായിക്കുക.',
    descAr: 'إخفاء النون الساكنة أو التنوين عند حروف الإخفاء الخمسة عشر، أو الميم الساكنة عند الباء بغنة حركتين.',
    sampleAr: 'مِن قَبْلِ · تَرْمِيهِم بِحِجَارَةٍ',
    lightColor: '#C62828',
    darkColor: '#FB7185',
  },
  {
    rule: 'iqlab',
    nameEn: 'Iqlab (Conversion)',
    nameMl: 'ഇഖ്‌ലാബ് (മീമായി മാറ്റി വായിക്കൽ)',
    nameAr: 'إقلاب',
    descEn: 'Noon Sakinah or Tanween followed by ب (Baa). Convert softly into a hidden Meem sound with 2-count Ghunnah.',
    descMl: 'സുകൂനുള്ള നൂനോ തൻവീനോ കഴിഞ്ഞ് (ب) വന്നാൽ ആ നൂനിനെ ചെറിയ മീം ശബ്ദമാക്കി 2 ഹറകത്ത് മണിച്ചു വായിക്കുക.',
    descAr: 'قلب النون الساكنة أو التنوين ميماً مخفاة عند حرف الباء مع غنة حركتين.',
    sampleAr: 'مِنۢ بَعْدِ · سَمِيعٌۢ بَصِيرٌ',
    lightColor: '#8E24AA',
    darkColor: '#D8B4FE',
  },
  {
    rule: 'qalqalah',
    nameEn: 'Qalqalah (Echoing Bounce)',
    nameMl: 'ഖൽഖല (പ്രതിധ്വനി / തട്ടി ഉച്ചരിക്കൽ)',
    nameAr: 'قلقلة (ق ط ب ج د)',
    descEn: 'Letters ق ط ب ج د carrying Sukoon (or stopped on at Ayah end). Pronounce with a crisp echoing bounce.',
    descMl: 'സുകൂനുള്ള (ق ط ب ج د) അക്ഷരങ്ങൾ വായിക്കുമ്പോൾ ചെറിയൊരു പ്രതിധ്വനിയോടെ (തട്ടി) വ്യക്തമായി ഉച്ചരിക്കുക.',
    descAr: 'حروف (قطب جد) الساكنة أو الموقوف عليها، تُنطق بنبرة اضطراب واهتزاز.',
    sampleAr: 'لَقَدْ · يَجْعَلُ · أَحَدْ',
    lightColor: '#1565C0',
    darkColor: '#60A5FA',
  },
  {
    rule: 'madd',
    nameEn: 'Madd (Elongation)',
    nameMl: 'മദ്ദ് (നീട്ടി വായിക്കൽ)',
    nameAr: 'مَدّ (4–6 حركات)',
    descEn: 'Elongated vowel sign (~ / آ / dagger Alif). Stretch smoothly for 4 to 6 counts as marked.',
    descMl: 'മദ്ദിന്റെ ചിഹ്നം (~ / آ) ഉള്ള ഭാഗങ്ങൾ നിയമപ്രകാരം 4 മുതൽ 6 ഹറകത്ത് വരെ നീട്ടി ഓതുക.',
    descAr: 'حرف مدّ تعلوه علامة المد (~) أو ألف خنجرية، يُمدّ 4 إلى 6 حركات.',
    sampleAr: 'السَّمَاءِ · الضَّالِّينَ · ذَٰلِكَ',
    lightColor: '#B45309',
    darkColor: '#FBBF24',
  },
  {
    rule: 'silent',
    nameEn: 'Silent / Lam Shamsiyyah',
    nameMl: 'ഉച്ചരിക്കാത്ത അക്ഷരം / ലാം ശംസിയ്യ',
    nameAr: 'حرف صامت / لام شمسية',
    descEn: 'Silent Hamzatul Wasl, silent Alif/Waw, or assimilated Lam Shamsiyyah. Bypass silently into the next sound.',
    descMl: 'ശബ്ദമില്ലാത്ത ഹംസതുൽ വസ്‌ൽ, ലാം ശംസിയ്യ പോലുള്ള അക്ഷരങ്ങൾ ഉച്ചരിക്കാതെ അടുത്ത അക്ഷരവുമായി ചേർത്തു വായിക്കുക.',
    descAr: 'همزة وصل أو لام شمسية أو حرف مدغم لا يُنطق، بل يُوصل مباشرة بما بعده.',
    sampleAr: 'ٱلشَّمْسُ · قَالُوا۟',
    lightColor: '#64748B',
    darkColor: '#94A3B8',
  },
];

export function metaForTajweedRule(rule: TajweedRule): TajweedRuleMeta | undefined {
  return TAJWEED_LEGEND.find((m) => m.rule === rule);
}

const _cache = new Map<string, TajweedToken[]>();
const MAX_CACHE = 1800;

const QALQALAH_LETTERS = new Set(['ق', 'ط', 'ب', 'ج', 'د']);
const IDGHAM_GHUNNAH_LETTERS = new Set(['ي', 'ن', 'م', 'و']);
const IDGHAM_NO_GHUNNAH_LETTERS = new Set(['ل', 'ر']);
const IKHFA_LETTERS = new Set([
  'ت', 'ث', 'ج', 'د', 'ذ', 'ز', 'س', 'ش', 'ص', 'ض', 'ط', 'ظ', 'ف', 'ق', 'ك',
]);
const SUN_LETTERS = new Set([
  'ت', 'ث', 'د', 'ذ', 'ر', 'ز', 'س', 'ش', 'ص', 'ض', 'ط', 'ظ', 'ل', 'ن',
]);
const RIGHT_JOINING_ONLY = new Set([
  'ا', 'أ', 'إ', 'آ', 'ٱ', 'د', 'ذ', 'ر', 'ز', 'و', 'ؤ', 'ة', 'ى',
]);

function isCombiningMark(cp: number): boolean {
  return (
    (cp >= 0x064b && cp <= 0x065f) ||
    cp === 0x0670 ||
    (cp >= 0x06d6 && cp <= 0x06ed)
  );
}

function isArabicLetter(cp: number): boolean {
  return (cp >= 0x0621 && cp <= 0x064a) || cp === 0x0671;
}

interface Cluster {
  base: string;
  marks: string;
  full: string;
  isLetter: boolean;
}

function extractClusters(text: string): Cluster[] {
  const cps = Array.from(text);
  const clusters: Cluster[] = [];
  let i = 0;
  while (i < cps.length) {
    const base = cps[i];
    const baseCp = base.codePointAt(0) ?? 0;
    i++;
    let marks = '';
    while (i < cps.length && isCombiningMark(cps[i].codePointAt(0) ?? 0)) {
      marks += cps[i];
      i++;
    }
    clusters.push({
      base,
      marks,
      full: base + marks,
      isLetter: isArabicLetter(baseCp),
    });
  }
  return clusters;
}

export function parseAyahTajweed(text: string): TajweedToken[] {
  if (!text) return [];
  const hit = _cache.get(text);
  if (hit) return hit;

  const clusters = extractClusters(text);
  const rules: TajweedRule[] = new Array(clusters.length).fill('none');

  const hasSukun = (m: string) => m.includes('\u0652') || m.includes('\u06e1');
  const hasShaddah = (m: string) => m.includes('\u0651');
  const hasTanween = (m: string) =>
    m.includes('\u064b') || m.includes('\u064c') || m.includes('\u064d');
  const hasAnyVowel = (m: string) =>
    m.includes('\u064e') ||
    m.includes('\u064f') ||
    m.includes('\u0650') ||
    hasTanween(m) ||
    hasSukun(m);
  const hasMaddSign = (m: string) => m.includes('\u0653') || m.includes('\u0670');
  const hasSmallMeem = (m: string) => m.includes('\u06e2') || m.includes('\u06ed');

  const nextLetterIndex = (from: number): number | null => {
    for (let j = from + 1; j < clusters.length; j++) {
      if (clusters[j].isLetter) return j;
    }
    return null;
  };

  const nextWordInitialLetterIndex = (from: number): number | null => {
    for (let j = from + 1; j < clusters.length; j++) {
      if (clusters[j].isLetter) {
        if (
          (clusters[j].base === 'ٱ' || clusters[j].base === 'ا') &&
          j + 1 < clusters.length &&
          clusters[j + 1].isLetter
        ) {
          continue;
        }
        return j;
      }
    }
    return null;
  };

  for (let i = 0; i < clusters.length; i++) {
    const c = clusters[i];
    if (!c.isLetter) continue;
    const b = c.base;
    const m = c.marks;

    if (b === 'ٱ' || m.includes('\u06df')) {
      rules[i] = 'silent';
      continue;
    }

    if (b === 'ل' && !hasAnyVowel(m)) {
      const nextIdx = nextLetterIndex(i);
      if (
        nextIdx !== null &&
        SUN_LETTERS.has(clusters[nextIdx].base) &&
        hasShaddah(clusters[nextIdx].marks)
      ) {
        rules[i] = 'silent';
        continue;
      }
    }

    if (b === 'آ' || hasMaddSign(m)) {
      rules[i] = 'madd';
      continue;
    }

    if ((b === 'ن' || b === 'م') && hasShaddah(m)) {
      rules[i] = 'ghunnah';
      continue;
    }

    if (hasSmallMeem(m)) {
      rules[i] = 'iqlab';
      continue;
    }

    const isNoonSakin =
      b === 'ن' && (hasSukun(m) || (!hasAnyVowel(m) && !hasShaddah(m)));
    const isTanween = hasTanween(m);

    if (isNoonSakin || isTanween) {
      const nextIdx = nextWordInitialLetterIndex(i);
      if (nextIdx !== null) {
        const nextChar = clusters[nextIdx].base;
        if (nextChar === 'ب') {
          rules[i] = 'iqlab';
          continue;
        } else if (IDGHAM_GHUNNAH_LETTERS.has(nextChar)) {
          rules[i] = 'idghamGhunnah';
          continue;
        } else if (IDGHAM_NO_GHUNNAH_LETTERS.has(nextChar)) {
          rules[i] = 'idghamNoGhunnah';
          continue;
        } else if (IKHFA_LETTERS.has(nextChar)) {
          rules[i] = 'ikhfa';
          continue;
        }
      }
    }

    const isMeemSakin =
      b === 'م' && (hasSukun(m) || (!hasAnyVowel(m) && !hasShaddah(m)));
    if (isMeemSakin) {
      const nextIdx = nextWordInitialLetterIndex(i);
      if (nextIdx !== null) {
        const nextChar = clusters[nextIdx].base;
        if (nextChar === 'ب') {
          rules[i] = 'ikhfa';
          continue;
        } else if (nextChar === 'م') {
          rules[i] = 'idghamGhunnah';
          continue;
        }
      }
    }

    if (QALQALAH_LETTERS.has(b)) {
      const isLastLetterOfAyah = nextLetterIndex(i) === null;
      if (hasSukun(m) || (isLastLetterOfAyah && !hasShaddah(m))) {
        rules[i] = 'qalqalah';
        continue;
      }
    }
  }

  const tokens: TajweedToken[] = [];
  if (clusters.length === 0) return tokens;

  let activeRule = rules[0];
  let buf = clusters[0].full;

  for (let i = 1; i < clusters.length; i++) {
    const r = rules[i];
    const prevCluster = clusters[i - 1];
    const curCluster = clusters[i];

    if (r === activeRule) {
      buf += curCluster.full;
    } else {
      const connectsLeft =
        prevCluster.isLetter &&
        curCluster.isLetter &&
        !RIGHT_JOINING_ONLY.has(prevCluster.base);

      let completedText = buf;
      if (connectsLeft && !completedText.endsWith('\u200d')) {
        completedText += '\u200d';
      }
      tokens.push({ text: completedText, rule: activeRule });

      buf = (connectsLeft ? '\u200d' : '') + curCluster.full;
      activeRule = r;
    }
  }

  if (buf.length > 0) {
    tokens.push({ text: buf, rule: activeRule });
  }

  if (_cache.size >= MAX_CACHE) _cache.clear();
  _cache.set(text, tokens);
  return tokens;
}
