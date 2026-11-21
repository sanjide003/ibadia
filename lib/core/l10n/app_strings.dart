import 'package:flutter/material.dart';

class AppStrings {
  final String lang; // 'en' | 'ml' | 'ar'

  const AppStrings(this.lang);

  bool get isRtl => lang == 'ar';
  TextDirection get textDirection =>
      isRtl ? TextDirection.rtl : TextDirection.ltr;

  String get appTitle => _pick('Al-Quran', 'അൽ-ഖുർആൻ', 'القرآن الكريم');
  String get surahsTab => _pick('Surahs', 'സൂറത്തുകൾ', 'السور');
  String get bookmarksTab => _pick('Bookmarks', 'ബുക്ക്‌മാർക്ക്', 'المحفوظات');
  String get settings => _pick('Settings', 'സെറ്റിംഗ്സ്', 'الإعدادات');
  String get lastRead => _pick('Last Read', 'അവസാനം വായിച്ചത്', 'آخر قراءة');
  String get searchHint => _pick(
        'Search Surah (e.g. Yaseen, Kahf, 36)...',
        'സൂറത്ത് തിരയുക (ഉദാ: Yaseen, Kahf, 36)...',
        'ابحث عن سورة (مثال: يس، الكهف، 36)...',
      );
  String get ayahsLabel => _pick('Ayahs', 'ആയത്തുകൾ', 'آيات');
  String get ayahLabel => _pick('Ayah', 'ആയത്ത്', 'آية');
  String get surahLabel => _pick('Surah', 'സൂറത്ത്', 'سورة');
  String get pageLabel => _pick('Page', 'പേജ്', 'صفحة');
  String get juzLabel => _pick('Juz', 'ജുസ്അ്', 'جزء');
  String get loadError => _pick(
        'Could not load data.\nPlease check your internet connection.',
        'ഡാറ്റ ലോഡ് ചെയ്യാനായില്ല.\nഇന്റർനെറ്റ് കണക്ഷൻ പരിശോധിക്കുക.',
        'تعذر تحميل البيانات.\nيرجى التحقق من اتصال الإنترنت.',
      );
  String get retry => _pick('Retry', 'വീണ്ടും ശ്രമിക്കുക', 'إعادة المحاولة');
  String get noBookmarks => _pick(
        'No bookmarks saved yet.',
        'ഇതുവരെ ബുക്ക്‌മാർക്കുകൾ ഒന്നും സേവ് ചെയ്തിട്ടില്ല.',
        'لا توجد إشارات مرجعية محفوظة بعد.',
      );
  String get copiedAyah =>
      _pick('Ayah copied', 'ആയത്ത് കോപ്പി ചെയ്തു', 'تم نسخ الآية');
  String get bookmarkSaved =>
      _pick('Bookmark saved', 'ബുക്ക്‌മാർക്ക് സേവ് ചെയ്തു', 'تم حفظ الإشارة');
  String get bookmarkRemoved => _pick(
        'Bookmark removed',
        'ബുക്ക്‌മാർക്ക് നീക്കം ചെയ്തു',
        'تمت إزالة الإشارة',
      );
  String get loadingNextSurah => _pick(
        'Loading next Surah...',
        'അടുത്ത സൂറത്ത് ലോഡ് ചെയ്യുന്നു...',
        'جاري تحميل السورة التالية...',
      );
  String get loadingPrevSurah => _pick(
        'Loading previous Surah...',
        'മുമ്പത്തെ സൂറത്ത് ലോഡ് ചെയ്യുന്നു...',
        'جاري تحميل السورة السابقة...',
      );

  // Settings labels
  String get appLanguage => _pick('App Language', 'ആപ്പ് ഭാഷ', 'لغة التطبيق');
  String get readingMode =>
      _pick('Reading Mode', 'വായനാ രീതി (Mode)', 'وضع القراءة');
  String get modeMushaf =>
      _pick('Mushaf Page', 'പേജ് വ്യൂ (Mushaf)', 'صفحة مصحف');
  String get modeVerse =>
      _pick('Verse List', 'ആയത്ത് ലിസ്റ്റ്', 'قائمة الآيات');
  String get readingTheme => _pick('Reading Theme', 'വായനാ തീം', 'مظهر القراءة');
  String get themeLight => _pick('Light', 'ലൈറ്റ്', 'فاتح');
  String get themeSepia => _pick('Sepia', 'സെപിയ', 'ورقي');
  String get themeDark => _pick('Dark', 'ഡാർക്ക്', 'داكن');
  String get showTranslation =>
      _pick('Show Translation', 'പരിഭാഷ കാണിക്കുക', 'إظهار الترجمة');
  String get showTranslationDesc => _pick(
        'Toggle translations on or off (Quran Arabic always stays visible)',
        'പരിഭാഷ ഓൺ/ഓഫ് ചെയ്യാം (അറബിക് ടെക്സ്റ്റ് എപ്പോഴും ഉണ്ടാകും)',
        'تفعيل أو إيقاف الترجمة (النص العربي للقرآن يظهر دائماً)',
      );
  String get translationLanguages => _pick(
        'Translation Languages (Select 1 or more)',
        'പരിഭാഷാ ഭാഷകൾ (ഒന്നോ അതിലധികമോ തിരഞ്ഞെടുക്കാം)',
        'لغات الترجمة (اختر لغة أو أكثر)',
      );
  String get langEnglish => _pick('English', 'ഇംഗ്ലീഷ് (English)', 'الإنجليزية');
  String get langMalayalam =>
      _pick('Malayalam', 'മലയാളം', 'المالايالامية (Malayalam)');
  String get langArabicTafsir => _pick(
        'Arabic (Al-Muyassar)',
        'അറബിക് (തഫ്സീർ അൽ-മുയസ്സർ)',
        'العربية (التفسير الميسر)',
      );
  String get arabicFontSize =>
      _pick('Arabic Font Size', 'അറബിക് ഫോണ്ട് സൈസ്', 'حجم الخط العربي');
  String get translationFontSize => _pick(
        'Translation Font Size',
        'പരിഭാഷ ഫോണ്ട് സൈസ്',
        'حجم خط الترجمة',
      );
  String get autoScrollSpeed =>
      _pick('Auto-Scroll Speed', 'ഓട്ടോ-സ്ക്രോൾ വേഗത', 'سرعة التمرير التلقائي');
  String get autoScrollHint => _pick(
        'Tap to Play/Pause, Drag anywhere, Long-press to change speed.',
        'ടാപ്പ് ചെയ്താൽ പ്ലേ/പോസ്, ഡ്രാഗ് ചെയ്ത് എവിടെയും വെക്കാം, ലോങ്ങ് പ്രസ്സ് ചെയ്താൽ സ്പീഡ് മാറ്റാം.',
        'اضغط للتشغيل/الإيقاف، اسحب لأي مكان، واضغط مطولاً لتغيير السرعة.',
      );
  String get resetButtonPos => _pick(
        'Reset Floating Button Position',
        'ഫ്ലോട്ടിംഗ് ബട്ടൺ പഴയ സ്ഥലത്തേക്ക് മാറ്റുക',
        'إعادة زر التمرير للموقع الافتراضي',
      );
  String get pause => _pick('Pause', 'പോസ്', 'إيقاف مؤقت');
  String get play => _pick('Start', 'തുടങ്ങുക', 'تشغيل');
  String get done => _pick('Done', 'ശരി', 'تم');

  // Export labels
  String get exportTab => _pick('Export', 'എക്സ്പോർട്ട്', 'تصدير');
  String get exportTitle =>
      _pick('Export Quran', 'ഖുർആൻ എക്സ്പോർട്ട്', 'تصدير القرآن');
  String get exportScope =>
      _pick('What to Export', 'എന്താണ് എക്സ്പോർട്ട് ചെയ്യേണ്ടത്', 'نطاق التصدير');
  String get scopeRange =>
      _pick('Ayah Range', 'ആയത്ത് റേഞ്ച്', 'نطاق آيات');
  String get scopeSurah =>
      _pick('Full Surah', 'പൂർണ്ണ സൂറത്ത്', 'سورة كاملة');
  String get scopeJuz => _pick('Full Juz', 'പൂർണ്ണ ജുസ്അ്', 'جزء كامل');
  String get selectSurah =>
      _pick('Select Surah', 'സൂറത്ത് തിരഞ്ഞെടുക്കുക', 'اختر السورة');
  String get selectJuz =>
      _pick('Select Juz', 'ജുസ്അ് തിരഞ്ഞെടുക്കുക', 'اختر الجزء');
  String get fromAyah =>
      _pick('From Ayah', 'തുടങ്ങുന്ന ആയത്ത്', 'من الآية');
  String get toAyah =>
      _pick('To Ayah', 'അവസാനിക്കുന്ന ആയത്ത്', 'إلى الآية');
  String get pageSize => _pick('Page Size', 'പേജ് സൈസ്', 'حجم الصفحة');
  String get sizeAutomatic =>
      _pick('Automatic', 'ഓട്ടോമാറ്റിക്', 'تلقائي');
  String get sizeAutomaticDesc => _pick(
        'Mobile-friendly width with normal readable text',
        'മൊബൈൽ സ്ക്രീനിന് അനുയോജ്യമായ നോർമൽ ടെക്സ്റ്റ് സൈസ്',
        'حجم مناسب لشاشة الجوال بخط واضح ومريح',
      );
  String get sizeA4 => _pick('A4', 'A4', 'A4');
  String get exportFormat => _pick('Format', 'ഫോർമാറ്റ്', 'الصيغة');
  String get formatPdf => _pick('PDF', 'PDF', 'PDF');
  String get formatImage =>
      _pick('Image (PNG)', 'ഇമേജ് (PNG)', 'صورة (PNG)');
  String get includeTranslation =>
      _pick('Include Translation', 'പരിഭാഷ ഉൾപ്പെടുത്തുക', 'تضمين الترجمة');
  String get generatePreview =>
      _pick('Preview & Export', 'പ്രിവ്യൂ കാണുക', 'معاينة وتصدير');
  String get exportPreview =>
      _pick('Export Preview', 'എക്സ്പോർട്ട് പ്രിവ്യൂ', 'معاينة التصدير');
  String get download => _pick('Download', 'ഡൗൺലോഡ്', 'تنزيل');
  String get share => _pick('Share', 'ഷെയർ', 'مشاركة');
  String get preparingPages =>
      _pick('Preparing pages...', 'പേജുകൾ തയ്യാറാക്കുന്നു...', 'جاري تجهيز الصفحات...');
  String get exportSuccess =>
      _pick('Saved successfully', 'വിജയകരമായി സേവ് ചെയ്തു', 'تم الحفظ بنجاح');
  String get exportError => _pick(
        'Export failed. Please try again.',
        'എക്സ്പോർട്ട് ചെയ്യാനായില്ല. വീണ്ടും ശ്രമിക്കുക.',
        'فشل التصدير. يرجى المحاولة مرة أخرى.',
      );
  String get invalidAyahRange => _pick(
        'Enter a valid Ayah range',
        'ശരിയായ ആയത്ത് നമ്പറുകൾ നൽകുക',
        'أدخل نطاق آيات صحيح',
      );
  String get pagesLabel => _pick('Pages', 'പേജുകൾ', 'صفحات');

  String revelationLabel(String raw) {
    final lower = raw.toLowerCase();
    if (lower.contains('mecc') || lower.contains('makk')) {
      return _pick('Meccan', 'മക്കി', 'مكية');
    }
    return _pick('Medinan', 'മദനി', 'مدنية');
  }

  String _pick(String en, String ml, String ar) {
    switch (lang) {
      case 'ml':
        return ml;
      case 'ar':
        return ar;
      default:
        return en;
    }
  }
}
