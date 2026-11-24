import '../../models/islamic_features_model.dart';

class FeaturedSurahItem {
  final int number;
  final String en;
  final String ml;
  final String ar;

  const FeaturedSurahItem({
    required this.number,
    required this.en,
    required this.ml,
    required this.ar,
  });

  dynamic operator [](String key) {
    switch (key) {
      case 'number':
        return number;
      case 'en':
        return en;
      case 'ml':
        return ml;
      case 'ar':
        return ar;
      default:
        return null;
    }
  }
}

class JuzInfo {
  final int number;
  final String arabicName;
  final String openingCue;
  final int startSurah;
  final int startAyah;
  final int startPage;

  const JuzInfo({
    required this.number,
    required this.arabicName,
    required this.openingCue,
    required this.startSurah,
    required this.startAyah,
    required this.startPage,
  });
}

class QuranReciter {
  final String id;
  final String englishName;
  final String malayalamName;
  final String arabicName;
  final int cdnBitrate;
  final String everyAyahFolder;

  const QuranReciter({
    required this.id,
    required this.englishName,
    required this.malayalamName,
    required this.arabicName,
    required this.cdnBitrate,
    required this.everyAyahFolder,
  });

  String displayName(String lang) {
    if (lang == 'ml') return malayalamName;
    if (lang == 'ar') return arabicName;
    return englishName;
  }

  String alQuranCloudUrl(int globalAyahNumber) =>
      'https://cdn.islamic.network/quran/audio/$cdnBitrate/$id/$globalAyahNumber.mp3';

  String everyAyahUrl(int surahNumber, int ayahNumber) {
    final sss = surahNumber.toString().padLeft(3, '0');
    final aaa = ayahNumber.toString().padLeft(3, '0');
    return 'https://everyayah.com/data/$everyAyahFolder/$sss$aaa.mp3';
  }
}

class PrayerCalculationMethod {
  final int id;
  final String englishName;
  final String malayalamName;
  final String arabicName;

  const PrayerCalculationMethod({
    required this.id,
    required this.englishName,
    required this.malayalamName,
    required this.arabicName,
  });

  String displayName(String lang) {
    if (lang == 'ml') return malayalamName;
    if (lang == 'ar') return arabicName;
    return englishName;
  }
}

class CityPreset {
  final String city;
  final String country;
  final double latitude;
  final double longitude;

  const CityPreset({
    required this.city,
    required this.country,
    required this.latitude,
    required this.longitude,
  });
}

class AlarmSoundOption {
  final String id;
  final String englishName;
  final String malayalamName;
  final String arabicName;
  final String? remoteUrl;

  const AlarmSoundOption({
    required this.id,
    required this.englishName,
    required this.malayalamName,
    required this.arabicName,
    this.remoteUrl,
  });

  String displayName(String lang) {
    if (lang == 'ml') return malayalamName;
    if (lang == 'ar') return arabicName;
    return englishName;
  }
}

class ApiConfig {
  static const String quranBaseUrl = String.fromEnvironment(
    'QURAN_API_BASE_URL',
    defaultValue: 'https://api.alquran.cloud/v1',
  );
  static const String alAdhanBaseUrl = 'https://api.aladhan.com/v1';

  static const String arabicEdition = 'quran-uthmani';
  static const String englishTranslationEdition = 'en.sahih';
  static const String malayalamTranslationEdition = 'ml.abdulhameed';
  static const String arabicTafsirEdition = 'ar.muyassar';

  static const List<FeaturedSurahItem> featuredSurahs = [
    FeaturedSurahItem(number: 89, en: 'Al-Fajr', ml: 'അൽ-ഫജ്ർ', ar: 'الفجر'),
    FeaturedSurahItem(number: 109, en: 'Al-Kaafiroon', ml: 'അൽ-കാഫിറൂൻ', ar: 'الكافرون'),
    FeaturedSurahItem(number: 36, en: 'Yaseen', ml: 'യാസീൻ', ar: 'يس'),
    FeaturedSurahItem(number: 18, en: 'Al-Kahf', ml: 'അൽ-കഹ്ഫ്', ar: 'الكهف'),
    FeaturedSurahItem(number: 67, en: 'Al-Mulk', ml: 'അൽ-മുൽക്ക്', ar: 'الملك'),
    FeaturedSurahItem(number: 55, en: 'Ar-Rahman', ml: 'അർ-റഹ്മാൻ', ar: 'الرحمن'),
    FeaturedSurahItem(number: 56, en: 'Al-Waqiah', ml: 'അൽ-വാഖിഅ', ar: 'الواقعة'),
    FeaturedSurahItem(number: 32, en: 'As-Sajdah', ml: 'അസ്-സജ്ദ', ar: 'السجدة'),
    FeaturedSurahItem(number: 1, en: 'Al-Fatihah', ml: 'അൽ-ഫാതിഹ', ar: 'الفاتحة'),
    FeaturedSurahItem(number: 112, en: 'Al-Ikhlas', ml: 'അൽ-ഇഖ്‌ലാസ്', ar: 'الإخلاص'),
  ];

  static const List<JuzInfo> juzCatalog = [
    JuzInfo(number: 1, arabicName: 'الجزء الأول', openingCue: 'الفاتحة', startSurah: 1, startAyah: 1, startPage: 1),
    JuzInfo(number: 2, arabicName: 'الجزء الثاني', openingCue: 'سيقول السفهاء', startSurah: 2, startAyah: 142, startPage: 22),
    JuzInfo(number: 3, arabicName: 'الجزء الثالث', openingCue: 'تلك الرسل', startSurah: 2, startAyah: 253, startPage: 42),
    JuzInfo(number: 4, arabicName: 'الجزء الرابع', openingCue: 'كل الطعام', startSurah: 3, startAyah: 93, startPage: 62),
    JuzInfo(number: 5, arabicName: 'الجزء الخامس', openingCue: 'والمحصنات', startSurah: 4, startAyah: 24, startPage: 82),
    JuzInfo(number: 6, arabicName: 'الجزء السادس', openingCue: 'لا يحب الله الجهر بالسوء', startSurah: 4, startAyah: 148, startPage: 102),
    JuzInfo(number: 7, arabicName: 'الجزء السابع', openingCue: 'لتجدن أشد الناس', startSurah: 5, startAyah: 82, startPage: 121),
    JuzInfo(number: 8, arabicName: 'الجزء الثامن', openingCue: 'ولو أننا نزلنا', startSurah: 6, startAyah: 111, startPage: 142),
    JuzInfo(number: 9, arabicName: 'الجزء التاسع', openingCue: 'قال الملأ', startSurah: 7, startAyah: 88, startPage: 162),
    JuzInfo(number: 10, arabicName: 'الجزء العاشر', openingCue: 'واعلموا', startSurah: 8, startAyah: 41, startPage: 182),
    JuzInfo(number: 11, arabicName: 'الجزء الحادي عشر', openingCue: 'يعتذرون', startSurah: 9, startAyah: 93, startPage: 201),
    JuzInfo(number: 12, arabicName: 'الجزء الثاني عشر', openingCue: 'وما من دابة', startSurah: 11, startAyah: 6, startPage: 222),
    JuzInfo(number: 13, arabicName: 'الجزء الثالث عشر', openingCue: 'وما أبرئ', startSurah: 12, startAyah: 53, startPage: 242),
    JuzInfo(number: 14, arabicName: 'الجزء الرابع عشر', openingCue: 'ربما', startSurah: 15, startAyah: 1, startPage: 262),
    JuzInfo(number: 15, arabicName: 'الجزء الخامس عشر', openingCue: 'سبحان الذي', startSurah: 17, startAyah: 1, startPage: 282),
    JuzInfo(number: 16, arabicName: 'الجزء السادس عشر', openingCue: 'قال ألم', startSurah: 18, startAyah: 75, startPage: 302),
    JuzInfo(number: 17, arabicName: 'الجزء السابع عشر', openingCue: 'اقترب للناس', startSurah: 21, startAyah: 1, startPage: 322),
    JuzInfo(number: 18, arabicName: 'الجزء الثامن عشر', openingCue: 'قد أفلح', startSurah: 23, startAyah: 1, startPage: 342),
    JuzInfo(number: 19, arabicName: 'الجزء التاسع عشر', openingCue: 'وقال الذين', startSurah: 25, startAyah: 21, startPage: 362),
    JuzInfo(number: 20, arabicName: 'الجزء العشرون', openingCue: 'أمن خلق', startSurah: 27, startAyah: 56, startPage: 382),
    JuzInfo(number: 21, arabicName: 'الجزء الحادي والعشرون', openingCue: 'اتل ما أوحي', startSurah: 29, startAyah: 46, startPage: 402),
    JuzInfo(number: 22, arabicName: 'الجزء الثاني والعشرون', openingCue: 'ومن يقنت', startSurah: 33, startAyah: 31, startPage: 422),
    JuzInfo(number: 23, arabicName: 'الجزء الثالث والعشرون', openingCue: 'وما لي', startSurah: 36, startAyah: 28, startPage: 442),
    JuzInfo(number: 24, arabicName: 'الجزء الرابع والعشرون', openingCue: 'فمن أظلم', startSurah: 39, startAyah: 32, startPage: 462),
    JuzInfo(number: 25, arabicName: 'الجزء الخامس والعشرون', openingCue: 'إليه يرد', startSurah: 41, startAyah: 47, startPage: 482),
    JuzInfo(number: 26, arabicName: 'الجزء السادس والعشرون', openingCue: 'حم', startSurah: 46, startAyah: 1, startPage: 502),
    JuzInfo(number: 27, arabicName: 'الجزء السابع والعشرون', openingCue: 'قال فما خطبكم', startSurah: 51, startAyah: 31, startPage: 522),
    JuzInfo(number: 28, arabicName: 'الجزء الثامن والعشرون', openingCue: 'قد سمع الله', startSurah: 58, startAyah: 1, startPage: 542),
    JuzInfo(number: 29, arabicName: 'الجزء التاسع والعشرون', openingCue: 'تبارك الذي', startSurah: 67, startAyah: 1, startPage: 562),
    JuzInfo(number: 30, arabicName: 'الجزء الثلاثون', openingCue: 'عم يتساءلون', startSurah: 78, startAyah: 1, startPage: 582),
  ];

  static const List<QuranReciter> reciters = [
    QuranReciter(
      id: 'ar.alafasy',
      englishName: 'Mishary Rashid Alafasy',
      malayalamName: 'മിഷാരി റാഷിദ് അൽ-അഫാസി',
      arabicName: 'مشاري راشد العفاسي',
      cdnBitrate: 64,
      everyAyahFolder: 'Alafasy_64kbps',
    ),
    QuranReciter(
      id: 'ar.abdulbasitmurattal',
      englishName: 'Abdul Basit (Murattal)',
      malayalamName: 'അബ്ദുൽ ബാസിത് (മുറത്തൽ)',
      arabicName: 'عبد الباسط عبد الصمد (مرتل)',
      cdnBitrate: 64,
      everyAyahFolder: 'Abdul_Basit_Murattal_64kbps',
    ),
    QuranReciter(
      id: 'ar.husary',
      englishName: 'Mahmoud Khalil Al-Husary',
      malayalamName: 'മഹ്‌മൂദ് ഖലീൽ അൽ-ഹുസ്വരി',
      arabicName: 'محمود خليل الحصري',
      cdnBitrate: 128,
      everyAyahFolder: 'Husary_64kbps',
    ),
    QuranReciter(
      id: 'ar.minshawi',
      englishName: 'Mohamed Siddiq Al-Minshawi',
      malayalamName: 'മുഹമ്മദ് സിദ്ദീഖ് അൽ-മിൻഷാവി',
      arabicName: 'محمد صديق المنشاوي',
      cdnBitrate: 128,
      everyAyahFolder: 'Minshawy_Murattal_128kbps',
    ),
  ];

  static QuranReciter reciterById(String id) {
    return reciters.firstWhere((r) => r.id == id, orElse: () => reciters.first);
  }

  static const List<String> fivePrayerKeys = ['fajr', 'dhuhr', 'asr', 'maghrib', 'isha'];

  static const List<AlarmSoundOption> alarmSounds = [
    AlarmSoundOption(
      id: 'adhan_alafasy',
      englishName: 'Adhan — Mishary Alafasy',
      malayalamName: 'ബാങ്ക് — മിശാരി അൽ-അഫാസി',
      arabicName: 'الأذان — مشاري العفاسي',
      remoteUrl: 'https://cdn.aladhan.com/audio/adhans/a4.mp3',
    ),
    AlarmSoundOption(
      id: 'adhan_nafees',
      englishName: 'Adhan — Ahmad al-Nafees',
      malayalamName: 'ബാങ്ക് — അഹ്‌മദ് അൽ-നഫീസ്',
      arabicName: 'الأذان — أحمد النفيس',
      remoteUrl: 'https://cdn.aladhan.com/audio/adhans/a1.mp3',
    ),
    AlarmSoundOption(
      id: 'alarm_tone',
      englishName: 'Alarm Tone (Device / Chime)',
      malayalamName: 'അലാറം ടോൺ (സാധാരണ ശബ്ദം)',
      arabicName: 'نغمة منبه',
    ),
  ];

  static AlarmSoundOption alarmSoundById(String id) {
    return alarmSounds.firstWhere((s) => s.id == id, orElse: () => alarmSounds.first);
  }

  static const List<PrayerCalculationMethod> prayerMethods = [
    PrayerCalculationMethod(id: 1, englishName: 'Karachi (UISK)', malayalamName: 'കറാച്ചി ഇസ്‌ലാമിക് സർവ്വകലാശാല', arabicName: 'جامعة العلوم الإسلامية بكراتشي'),
    PrayerCalculationMethod(id: 3, englishName: 'Muslim World League (MWL)', malayalamName: 'മുസ്‌ലിം വേൾഡ് ലീഗ്', arabicName: 'رابطة العالم الإسلامي'),
    PrayerCalculationMethod(id: 4, englishName: 'Umm Al-Qura, Makkah', malayalamName: 'ഉമ്മുൽ ഖുറ, മക്ക', arabicName: 'أم القرى، مكة المكرمة'),
    PrayerCalculationMethod(id: 2, englishName: 'ISNA (North America)', malayalamName: 'വടക്കേ അമേരിക്കൻ ഇസ്‌ലാമിക് സൊസൈറ്റി', arabicName: 'الجمعية الإسلامية لأمريكا الشمالية'),
    PrayerCalculationMethod(id: 5, englishName: 'Egyptian General Authority', malayalamName: 'ഈജിപ്ഷ്യൻ അതോറിറ്റി', arabicName: 'الهيئة المصرية العامة للمساحة'),
    PrayerCalculationMethod(id: 11, englishName: 'MUIS (Singapore)', malayalamName: 'സിംഗപ്പൂർ ഇസ്‌ലാമിക് കൗൺസിൽ', arabicName: 'مجلس الشؤون الإسلامية في سنغافورة'),
    PrayerCalculationMethod(id: 15, englishName: 'Moonsighting Committee', malayalamName: 'മൂൺസൈറ്റിംഗ് കമ്മിറ്റി', arabicName: 'لجنة تحري الهلال'),
  ];

  static const List<CityPreset> quickCities = [
    CityPreset(city: 'Kochi', country: 'India', latitude: 9.9312, longitude: 76.2673),
    CityPreset(city: 'Kozhikode', country: 'India', latitude: 11.2588, longitude: 75.7804),
    CityPreset(city: 'Malappuram', country: 'India', latitude: 11.051, longitude: 76.0711),
    CityPreset(city: 'Thiruvananthapuram', country: 'India', latitude: 8.5241, longitude: 76.9366),
    CityPreset(city: 'Thrissur', country: 'India', latitude: 10.5276, longitude: 76.2144),
    CityPreset(city: 'Kannur', country: 'India', latitude: 11.8745, longitude: 75.3704),
    CityPreset(city: 'Bengaluru', country: 'India', latitude: 12.9716, longitude: 77.5946),
    CityPreset(city: 'Chennai', country: 'India', latitude: 13.0827, longitude: 80.2707),
    CityPreset(city: 'Mumbai', country: 'India', latitude: 19.076, longitude: 72.8777),
    CityPreset(city: 'Makkah', country: 'Saudi Arabia', latitude: 21.3891, longitude: 39.8579),
    CityPreset(city: 'Madinah', country: 'Saudi Arabia', latitude: 24.5247, longitude: 39.5692),
    CityPreset(city: 'Dubai', country: 'UAE', latitude: 25.2048, longitude: 55.2708),
    CityPreset(city: 'Doha', country: 'Qatar', latitude: 25.2854, longitude: 51.531),
    CityPreset(city: 'Riyadh', country: 'Saudi Arabia', latitude: 24.7136, longitude: 46.6753),
  ];

  static const List<String> hijriMonthsEn = [
    'Muharram',
    'Safar',
    'Rabi al-Awwal',
    'Rabi al-Thani',
    'Jumada al-Ula',
    'Jumada al-Akhirah',
    'Rajab',
    "Sha'ban",
    'Ramadan',
    'Shawwal',
    "Dhu al-Qi'dah",
    'Dhu al-Hijjah',
  ];

  static const List<String> hijriMonthsMl = [
    'മുഹർറം',
    'സ്വഫർ',
    'റബീഉൽ അവ്വൽ',
    'റബീഉൽ ആഖിർ',
    'ജുമാദൽ ഊല',
    'ജുമാദൽ ആഖിറ',
    'റജബ്',
    'ശഅ്ബാൻ',
    'റമളാൻ',
    'ശവ്വാൽ',
    'ദുൽഖഅ്ദ',
    'ദുൽഹിജ്ജ',
  ];

  static const List<String> hijriMonthsAr = [
    'مُحَرَّم',
    'صَفَر',
    'رَبِيع الأَوَّل',
    'رَبِيع الثَّانِي',
    'جُمَادَى الأُولَى',
    'جُمَادَى الآخِرَة',
    'رَجَب',
    'شَعْبَان',
    'رَمَضَان',
    'شَوَّال',
    'ذُو القَعْدَة',
    'ذُو الحِجَّة',
  ];

  static Map<String, PrayerAlarmConfig> defaultPrayerConfigs() {
    return {
      for (final k in fivePrayerKeys)
        k: PrayerAlarmConfig(
          prayerKey: k,
          enabled: true,
          iqamahGapMinutes: 15,
          alarmRef: PrayerAlarmRef.beforeAdhan,
          alarmOffsetMinutes: 10,
        ),
    };
  }

  static String toArabicNumber(int number) {
    const digits = ['٠', '١', '٢', '٣', '٤', '٥', '٦', '٧', '٨', '٩'];
    return number.toString().split('').map((c) {
      final d = int.tryParse(c);
      return d != null ? digits[d] : c;
    }).join();
  }

  static String ayahEndMarker(int number) => ' ﴿${toArabicNumber(number)}﴾ ';
}
