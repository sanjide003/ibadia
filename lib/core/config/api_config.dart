class ApiConfig {
  static const String baseUrl = String.fromEnvironment(
    'QURAN_API_BASE_URL',
    defaultValue: 'https://api.alquran.cloud/v1',
  );

  static const String apiKey = String.fromEnvironment(
    'QURAN_API_KEY',
    defaultValue: '',
  );

  static const String arabicEdition = 'quran-uthmani';
  static const String englishTranslationEdition = 'en.sahih';
  static const String malayalamTranslationEdition = 'ml.abdulhameed';
  static const String arabicTafsirEdition = 'ar.muyassar';

  /// Curated important Surahs for Commonly Recited calligraphy cards.
  static const List<Map<String, dynamic>> featuredSurahs = [
    {'number': 89, 'en': 'Al-Fajr', 'ml': 'അൽ-ഫജ്ർ', 'ar': 'الفجر'},
    {'number': 109, 'en': 'Al-Kaafiroon', 'ml': 'അൽ-കാഫിറൂൻ', 'ar': 'الكافرون'},
    {'number': 36, 'en': 'Yaseen', 'ml': 'യാസീൻ', 'ar': 'يس'},
    {'number': 18, 'en': 'Al-Kahf', 'ml': 'അൽ-കഹ്ഫ്', 'ar': 'الكهف'},
    {'number': 67, 'en': 'Al-Mulk', 'ml': 'അൽ-മുൽക്ക്', 'ar': 'الملك'},
    {'number': 55, 'en': 'Ar-Rahman', 'ml': 'അർ-റഹ്മാൻ', 'ar': 'الرحمن'},
    {'number': 56, 'en': 'Al-Waqiah', 'ml': 'അൽ-വാഖിഅ', 'ar': 'الواقعة'},
    {'number': 32, 'en': 'As-Sajdah', 'ml': 'അസ്-സജ്ദ', 'ar': 'السجدة'},
    {'number': 1, 'en': 'Al-Fatihah', 'ml': 'അൽ-ഫാതിഹ', 'ar': 'الفاتحة'},
    {'number': 112, 'en': 'Al-Ikhlas', 'ml': 'അൽ-ഇഖ്‌ലാസ്', 'ar': 'الإخلاص'},
  ];

  static const List<JuzInfo> juzCatalog = [
    JuzInfo(1, 'الجزء الأول', 'الفاتحة', 1, 1, 1),
    JuzInfo(2, 'الجزء الثاني', 'سيقول السفهاء', 2, 142, 22),
    JuzInfo(3, 'الجزء الثالث', 'تلك الرسل', 2, 253, 42),
    JuzInfo(4, 'الجزء الرابع', 'كل الطعام', 3, 93, 62),
    JuzInfo(5, 'الجزء الخامس', 'والمحصنات', 4, 24, 82),
    JuzInfo(6, 'الجزء السادس', 'لا يحب الله الجهر بالسوء', 4, 148, 102),
    JuzInfo(7, 'الجزء السابع', 'لتجدن أشد الناس', 5, 82, 121),
    JuzInfo(8, 'الجزء الثامن', 'ولو أننا نزلنا', 6, 111, 142),
    JuzInfo(9, 'الجزء التاسع', 'قال الملأ', 7, 88, 162),
    JuzInfo(10, 'الجزء العاشر', 'واعلموا', 8, 41, 182),
    JuzInfo(11, 'الجزء الحادي عشر', 'يعتذرون', 9, 93, 201),
    JuzInfo(12, 'الجزء الثاني عشر', 'وما من دابة', 11, 6, 222),
    JuzInfo(13, 'الجزء الثالث عشر', 'وما أبرئ', 12, 53, 242),
    JuzInfo(14, 'الجزء الرابع عشر', 'ربما', 15, 1, 262),
    JuzInfo(15, 'الجزء الخامس عشر', 'سبحان الذي', 17, 1, 282),
    JuzInfo(16, 'الجزء السادس عشر', 'قال ألم', 18, 75, 302),
    JuzInfo(17, 'الجزء السابع عشر', 'اقترب للناس', 21, 1, 322),
    JuzInfo(18, 'الجزء الثامن عشر', 'قد أفلح', 23, 1, 342),
    JuzInfo(19, 'الجزء التاسع عشر', 'وقال الذين', 25, 21, 362),
    JuzInfo(20, 'الجزء العشرون', 'أمن خلق', 27, 56, 382),
    JuzInfo(21, 'الجزء الحادي والعشرون', 'اتل ما أوحي', 29, 46, 402),
    JuzInfo(22, 'الجزء الثاني والعشرون', 'ومن يقنت', 33, 31, 422),
    JuzInfo(23, 'الجزء الثالث والعشرون', 'وما لي', 36, 28, 442),
    JuzInfo(24, 'الجزء الرابع والعشرون', 'فمن أظلم', 39, 32, 462),
    JuzInfo(25, 'الجزء الخامس والعشرون', 'إليه يرد', 41, 47, 482),
    JuzInfo(26, 'الجزء السادس والعشرون', 'حم', 46, 1, 502),
    JuzInfo(27, 'الجزء السابع والعشرون', 'قال فما خطبكم', 51, 31, 522),
    JuzInfo(28, 'الجزء الثامن والعشرون', 'قد سمع الله', 58, 1, 542),
    JuzInfo(29, 'الجزء التاسع والعشرون', 'تبارك الذي', 67, 1, 562),
    JuzInfo(30, 'الجزء الثلاثون', 'عم يتساءلون', 78, 1, 582),
  ];

  static Map<String, String> buildHeaders() {
    final headers = <String, String>{
      'Accept': 'application/json',
    };
    if (apiKey.isNotEmpty) {
      headers['Authorization'] = 'Bearer $apiKey';
      headers['x-api-key'] = apiKey;
    }
    return headers;
  }

  /// Converts Western digits to Arabic-Indic numerals for Mushaf Ayah markers.
  static String toArabicNumber(int number) {
    const digits = ['٠', '١', '٢', '٣', '٤', '٥', '٦', '٧', '٨', '٩'];
    return number
        .toString()
        .split('')
        .map((ch) => digits[int.parse(ch)])
        .join();
  }

  /// Formats an inline Quranic end-of-ayah ornament like ﴿١﴾.
  static String ayahEndMarker(int number) => ' ﴿${toArabicNumber(number)}﴾ ';
}

class JuzInfo {
  final int number;
  final String arabicName;
  final String openingCue;
  final int startSurah;
  final int startAyah;
  final int startPage;

  const JuzInfo(
    this.number,
    this.arabicName,
    this.openingCue,
    this.startSurah,
    this.startAyah,
    this.startPage,
  );
}
