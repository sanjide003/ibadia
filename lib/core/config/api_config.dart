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

  /// Curated important Surahs for horizontal quick-access bar.
  static const List<Map<String, dynamic>> featuredSurahs = [
    {'number': 36, 'en': 'Yaseen', 'ml': 'യാസീൻ', 'ar': 'يس'},
    {'number': 18, 'en': 'Al-Kahf', 'ml': 'അൽ-കഹ്ഫ്', 'ar': 'الكهف'},
    {'number': 67, 'en': 'Al-Mulk', 'ml': 'അൽ-മുൽക്ക്', 'ar': 'الملك'},
    {'number': 56, 'en': 'Al-Waqiah', 'ml': 'അൽ-വാഖിഅ', 'ar': 'الواقعة'},
    {'number': 55, 'en': 'Ar-Rahman', 'ml': 'അർ-റഹ്മാൻ', 'ar': 'الرحمن'},
    {'number': 32, 'en': 'As-Sajdah', 'ml': 'അസ്-സജ്ദ', 'ar': 'السجدة'},
    {'number': 44, 'en': 'Ad-Dukhan', 'ml': 'അദ്-ദുഖാൻ', 'ar': 'الدخان'},
    {'number': 73, 'en': 'Al-Muzzammil', 'ml': 'അൽ-മുസ്സമ്മിൽ', 'ar': 'المزمل'},
    {'number': 1, 'en': 'Al-Fatihah', 'ml': 'അൽ-ഫാതിഹ', 'ar': 'الفاتحة'},
    {'number': 112, 'en': 'Al-Ikhlas', 'ml': 'അൽ-ഇഖ്‌ലാസ്', 'ar': 'الإخلاص'},
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
