import 'package:flutter/material.dart' show TextDirection;

class AppStrings {
  final String lang;
  const AppStrings(this.lang);

  bool get isRtl => lang == 'ar';
  TextDirection get textDirection => isRtl ? TextDirection.rtl : TextDirection.ltr;

  String _p(String en, String ml, String ar) {
    if (lang == 'ml') return ml;
    if (lang == 'ar') return ar;
    return en;
  }

  // Brand
  String get appTitle => _p('Ibadia', 'ഇബാദിയ', 'عبادية');
  String get appTagline => _p(
        'Quran, Prayer & Daily Adhkar',
        'ഖുർആൻ, നമസ്കാരം, ദൈനംദിന ദിക്റുകൾ',
        'القرآن والصلاة والأذكار اليومية',
      );

  // 3 Primary Bottom Navigation Tabs
  String get homeTab => _p('Home', 'ഹോം', 'الرئيسية');
  String get dashboardTab => homeTab;
  String get quranTab => _p('Quran', 'ഖുർആൻ', 'القرآن');
  String get featuresTab => _p('Features', 'ഫീച്ചറുകൾ', 'الميزات');
  String get settingsTab => _p('Settings', 'സെറ്റിംഗ്സ്', 'الإعدادات');
  String get backToHome => homeTab;

  // Quran Sub-tabs & Standalone Tool Tab Labels
  String get surahTabLabel => _p('Surah', 'സൂറത്ത്', 'السور');
  String get juzTabLabel => _p('Juz', 'ജുസ്അ്', 'الأجزاء');
  String get bookmarksTab => _p('Bookmarks', 'ബുക്ക്‌മാർക്ക്', 'المحفوظات');
  String get exportTab => _p('Export', 'എക്സ്പോർട്ട്', 'تصدير');
  String get prayerShortTab => _p('Prayer', 'നിസ്കാരം', 'الصلاة');
  String get hijriCalendarTab => _p('Hijri', 'ഹിജ്‌രി', 'الهجري');
  String get adhkarTab => _p('Adhkar', 'ദിക്ർ', 'الأذكار');
  String get tasbihTab => _p('Tasbih', 'തസ്ബീഹ്', 'تسبيح');
  String get names99Tab => _p('99 Names', '99 നാമങ്ങൾ', '٩٩ اسماً');

  String get lastRead => _p('Last Read', 'അവസാനം വായിച്ചത്', 'آخر قراءة');
  String get continueReading => _p('Continue Reading', 'വായന തുടരുക', 'متابعة القراءة');
  String get searchHint => _p(
        'Search Surah (e.g. Yaseen, Kahf, 36)...',
        'സൂറത്ത് തിരയുക (ഉദാ: Yaseen, Kahf, 36)...',
        'ابحث عن سورة (مثال: يس، الكهف، 36)...',
      );
  String get ayahsLabel => _p('Ayahs', 'ആയത്തുകൾ', 'آيات');
  String get ayahLabel => _p('Ayah', 'ആയത്ത്', 'آية');
  String get surahLabel => _p('Surah', 'സൂറത്ത്', 'سورة');
  String get pageLabel => _p('Page', 'പേജ്', 'صفحة');
  String get pagesLabel => _p('Pages', 'പേജുകൾ', 'صفحات');
  String get juzLabel => _p('Juz', 'ജുസ്അ്', 'جزء');
  String get loadError => _p(
        'Could not load data. Please check your internet connection.',
        'ഡാറ്റ ലോഡ് ചെയ്യാനായില്ല. ഇന്റർനെറ്റ് കണക്ഷൻ പരിശോധിക്കുക.',
        'تعذر تحميل البيانات. يرجى التحقق من اتصال الإنترنت.',
      );
  String get retry => _p('Retry', 'വീണ്ടും ശ്രമിക്കുക', 'إعادة المحاولة');
  String get noBookmarks => _p(
        'No bookmarks saved yet. Tap the bookmark icon on any Ayah or Surah to save it here.',
        'ഇതുവരെ ബുക്ക്‌മാർക്കുകൾ ഒന്നും സേവ് ചെയ്തിട്ടില്ല. ഏതെങ്കിലും ആയത്തിലോ സൂറത്തിലോ ബുക്ക്‌മാർക്ക് അമർത്തുക.',
        'لا توجد إشارات مرجعية محفوظة بعد.',
      );
  String get copiedAyah => _p('Ayah copied', 'ആയത്ത് കോപ്പി ചെയ്തു', 'تم نسخ الآية');
  String get bookmarkSaved => _p('Bookmark saved', 'ബുക്ക്‌മാർക്ക് സേവ് ചെയ്തു', 'تم حفظ الإشارة');
  String get bookmarkRemoved => _p('Bookmark removed', 'ബുക്ക്‌മാർക്ക് നീക്കം ചെയ്തു', 'تمت إزالة الإشارة');
  String get loadingNextSurah => _p('Loading next Surah...', 'അടുത്ത സൂറത്ത് ലോഡ് ചെയ്യുന്നു...', 'جاري تحميل السورة التالية...');
  String get loadingPrevSurah => _p('Loading previous Surah...', 'മുമ്പത്തെ സൂറത്ത് ലോഡ് ചെയ്യുന്നു...', 'جاري تحميل السورة السابقة...');
  String get loadPrevSurahBtn => _p('Load Previous Surah', 'മുമ്പത്തെ സൂറത്ത് വായിക്കുക', 'تحميل السورة السابقة');
  String get loadNextSurahBtn => _p('Load Next Surah', 'അടുത്ത സൂറത്ത് വായിക്കുക', 'تحميل السورة التالية');
  String get commonlyRecited => _p('Commonly Recited', 'പതിവായി ഓതുന്നവ', 'سور مختارة');
  String get searchSurah => _p('Search Surah', 'സൂറത്ത് തിരയുക', 'ابحث عن سورة');

  // Settings
  String get settings => _p('Settings', 'സെറ്റിംഗ്സ്', 'الإعدادات');
  String get quranSettingsTitle => _p('Quran Reader Settings', 'ഖുർആൻ റീഡർ സെറ്റിംഗ്സ്', 'إعدادات قراءة القرآن');
  String get featuresSettingsTitle => _p('Prayer Times, Alarms & Hijri', 'നിസ്കാരം, അലാറം & ഹിജ്‌രി സെറ്റിംഗ്സ്', 'إعدادات الصلاة والمنبهات');
  String get appLanguage => _p('App Language', 'ആപ്പ് ഭാഷ', 'لغة التطبيق');
  String get readingMode => _p('Reading Mode', 'വായനാ രീതി', 'وضع القراءة');
  String get modeMushaf => _p('Mushaf Page', 'പേജ് വ്യൂ (Mushaf)', 'صفحة مصحف');
  String get modeVerse => _p('Verse List', 'ആയത്ത് ലിസ്റ്റ്', 'قائمة الآيات');
  String get readingTheme => _p('Reading Theme', 'വായനാ തീം', 'مظهر القراءة');
  String get themeLight => _p('Light', 'ലൈറ്റ്', 'فاتح');
  String get themeSepia => _p('Sepia', 'സെപിയ', 'ورقي');
  String get themeDark => _p('Dark', 'ഡാർക്ക്', 'داكن');
  String get showTranslation => _p('Show Translation', 'പരിഭാഷ കാണിക്കുക', 'إظهار الترجمة');
  String get showTranslationDesc => _p(
        'Toggle translations on or off (Quran Arabic always stays visible)',
        'പരിഭാഷ ഓൺ/ഓഫ് ചെയ്യാം (അറബിക് ടെക്സ്റ്റ് എപ്പോഴും ഉണ്ടാകും)',
        'تفعيل أو إيقاف الترجمة (النص العربي للقرآن يظهر دائماً)',
      );
  String get translationLanguages => _p('Translation Languages', 'പരിഭാഷാ ഭാഷകൾ', 'لغات الترجمة');
  String get langEnglish => _p('English', 'ഇംഗ്ലീഷ് (English)', 'الإنجليزية');
  String get langMalayalam => _p('Malayalam', 'മലയാളം', 'المالايالامية');
  String get langArabicTafsir => _p('Arabic (Al-Muyassar)', 'അറബിക് (തഫ്സീർ അൽ-മുയസ്സർ)', 'العربية (التفسير الميسر)');
  String get arabicFontSize => _p('Arabic Font Size', 'അറബിക് ഫോണ്ട് സൈസ്', 'حجم الخط العربي');
  String get translationFontSize => _p('Translation Font Size', 'പരിഭാഷ ഫോണ്ട് സൈസ്', 'حجم خط الترجمة');
  String get autoScrollSpeed => _p('Auto-Scroll Speed', 'ഓട്ടോ-സ്ക്രോൾ വേഗത', 'سرعة التمرير التلقائي');
  String get autoScrollHint => _p(
        'Tap to Play/Pause, Drag anywhere, Long-press to adjust speed.',
        'ടാപ്പ് ചെയ്താൽ പ്ലേ/പോസ്, ഡ്രാഗ് ചെയ്താൽ മാറ്റാം, ലോങ്ങ് പ്രസ്സ് ചെയ്താൽ സ്പീഡ് മാറ്റാം.',
        'اضغط للتشغيل/الإيقاف، اسحب لأي مكان، واضغط مطولاً لتغيير السرعة.',
      );
  String get floatingControlsTipTitle => _p(
        'Auto-Scroll & Quick Reader Controls',
        'ഓട്ടോ-സ്ക്രോൾ & ക്വിക്ക് കൺട്രോളുകൾ',
        'التمرير التلقائي وأدوات القراءة السريعة',
      );
  String get resetButtonPos => _p('Reset Floating Button Position', 'ഫ്ലോട്ടിംഗ് ബട്ടൺ പഴയ സ്ഥലത്തേക്ക് മാറ്റുക', 'إعادة زر التمرير للموقع الافتراضي');
  String get pause => _p('Pause', 'പോസ്', 'إيقاف مؤقت');
  String get play => _p('Start', 'തുടങ്ങുക', 'تشغيل');
  String get done => _p('Done', 'ശരി', 'تم');
  String get closeLabel => _p('Close', 'അടയ്ക്കുക', 'إغلاق');
  String get autoSavedHint => _p('All changes save automatically', 'എല്ലാ മാറ്റങ്ങളും തനിയെ സേവ് ആകുന്നു', 'تُحفظ جميع التغييرات تلقائياً');
  String get fullSurahBadge => _p('Full Surah', 'പൂർണ്ണ സൂറത്ത്', 'سورة كاملة');
  String get bookmarkSurah => _p('Bookmark Surah', 'സൂറത്ത് ബുക്ക്‌മാർക്ക് ചെയ്യുക', 'حفظ السورة');

  // Home Feature Grid & Actions
  String get dashboardSearchHint => _p(
        'Search Surah, Prayer, 99 Names, Adhkar, Export...',
        'സൂറത്ത്, നമസ്കാരം, 99 നാമങ്ങൾ, ദിക്ർ, എക്സ്പോർട്ട് തിരയുക...',
        'ابحث عن سورة أو ميزة أو اسم أو ذكر...',
      );
  String get recentActivityTitle => _p('Recent Activity', 'സമീപകാല പ്രവർത്തനങ്ങൾ', 'النشاطات الأخيرة');
  String get recentActivityEmpty => _p(
        'Your recently opened Surahs, 99 Names, Adhkar and tools appear here automatically.',
        'നിങ്ങൾ തുറക്കുന്ന സൂറത്തുകളും ഫീച്ചറുകളും ഇവിടെ കാണാം.',
        'ستظهر السور والميزات التي تفتحها مؤخراً هنا تلقائياً.',
      );
  String get clearHistoryLabel => _p('Clear', 'മായ്ക്കുക', 'مسح');
    String get quickActionsTitle => _p('Features & Tools', 'ഫീച്ചറുകളും ടൂളുകളും', 'الأدوات والميزات');
  String get categoriesTitle => _p('Other Features', 'മറ്റ് ഫീച്ചറുകൾ', 'ميزات أخرى');
  String get noSearchResults => _p(
        'No matching Surah, tool, Name, or Dhikr found.',
        'യോജിച്ച സൂറത്തോ ഫീച്ചറോ നാമമോ കണ്ടെത്താനായില്ല.',
        'لم يتم العثور على نتائج مطابقة.',
      );
  String get actionReadQuran => _p('Read Quran', 'ഖുർആൻ വായന', 'قراءة القرآن');
  String get actionJuz => _p('Juz Index', 'ജുസ്അ്', 'الأجزاء');
  String get actionBookmarks => _p('Bookmarks', 'ബുക്ക്‌മാർക്ക്', 'المحفوظات');
  String get actionPrayer => _p('Prayer Times', 'നിസ്കാര സമയം', 'أوقات الصلاة');
  String get actionHijri => _p('Hijri Calendar', 'ഹിജ്‌രി കലണ്ടർ', 'التقويم الهجري');
  String get actionAutoSilent => _p('Auto-Silent DND', 'ഓട്ടോ സൈലന്റ്', 'الصامت التلقائي');
  String get actionAdhkar => _p('Adhkar & Duas', 'ദിക്ർ & ദുആ', 'الأذكار اليومية');
  String get actionCounter => _p('Tasbih Counter', 'തസ്ബീഹ് കൗണ്ടർ', 'العدّاد');
  String get actionNames99 => _p('99 Names', '99 നാമങ്ങൾ', 'أسماء الله');
  String get actionTajweed => _p('Tajweed Guide', 'തജ്‌വീദ് നിയമം', 'أحكام التجويد');
  String get actionExport => _p('Export PDF / PNG', 'എക്സ്പോർട്ട് PDF / PNG', 'تصدير PDF');
  String get actionIbadahGuide => _p('Ibadah & Salah', 'ഇബാദത്ത് & നിസ്കാരം', 'دليل الصلاة والعبادات');
  String get actionNiyyah => _p('Niyyah', 'നിയ്യത്ത്', 'النية');
  String get actionSalahGuide => _p('Salah Guide', 'സ്വലാത്ത് ഗൈഡ്', 'دليل الصلاة');
  String get actionRawatibSurahs => _p('Rawatib & Surahs', 'റവാതിബും സൂറത്തുകളും', 'الرواتب والسور');
  String get actionMayyithGuide => _p('Mayyith Guide', 'മയ്യിത്ത് ഗൈഡ്', 'دليل الجنازة');
  String get actionSettings => _p('Settings', 'സെറ്റിംഗ്സ്', 'الإعدادات');

  // Daily Spotlight Cards on Home
  String get dailyNameTitle => _p('Name of Allah', 'അല്ലാഹുവിന്റെ നാമം', 'من أسماء الله الحسنى');
  String get dailyTajweedTitle => _p('Tajweed Rule Highlight', 'ഇന്നത്തെ തജ്‌വീദ് നിയമം', 'قاعدة تجويد اليوم');
  String get viewMeaningBtn => _p('View Meaning', 'അർത്ഥം കാണുക', 'عرض المعنى');
  String get exploreRuleBtn => _p('Explore Rules', 'നിയമങ്ങൾ കാണുക', 'استعراض القواعد');

  // 99 Names Dual View
  String get names99Title => _p('99 Names of Allah', 'അല്ലാഹുവിന്റെ 99 നാമങ്ങൾ', 'أسماء الله الحسنى');
  String get names99Subtitle => _p('Asmaul Husna', 'അസ്മാഉൽ ഹുസ്ന', '٩٩ اسماً');
  String get names99GridMode => _p('Arabic Grid', 'അറബിക് ഗ്രിഡ്', 'جدول عربي');
  String get names99ListMode => _p('Detailed List', 'വിശദമായ ലിസ്റ്റ്', 'قائمة مع المعاني');
  String get names99SearchHint => _p(
        'Search number, Arabic, English, or Malayalam...',
        'നമ്പർ, അറബിക്, ഇംഗ്ലീഷ്, മലയാളം തിരയുക...',
        'ابحث بالرقم أو الاسم أو المعنى...',
      );
  String get names99Studied => _p('Studied', 'പഠിച്ചത്', 'تمت دراسته');
  String get names99MarkStudied => _p('Mark as Studied', 'പഠിച്ചതായി അടയാളപ്പെടുത്തുക', 'تحديد كمدروس');
  String get names99GridHint => _p(
        'Tap any Arabic name to view transliteration, meanings & reflection',
        'അർത്ഥവും വിശദീകരണവും കാണാൻ ഏതെങ്കിലും നാമത്തിൽ ടാപ്പ് ചെയ്യുക',
        'اضغط على أي اسم لعرض معانيه وتفاصيله',
      );
  String get meaningEnglishLabel => _p('English Meaning', 'ഇംഗ്ലീഷ് അർത്ഥം', 'المعنى بالإنجليزية');
  String get meaningMalayalamLabel => _p('Malayalam Meaning', 'മലയാളം അർത്ഥം', 'المعنى بالمالايالامية');
  String get meaningArabicLabel => _p('Arabic Explanation', 'അറബിക് വിശദീകരണം', 'الشرح بالعربية');
  String get reflectionLabel => _p('Reflection', 'ആശയം / വിവരണം', 'التدبر والتأمل');
  String get copiedNameNotice => _p('Copied to clipboard', 'കോപ്പി ചെയ്തു', 'تم النسخ');
  String get previousLabel => _p('Previous', 'മുമ്പത്തേത്', 'السابق');
  String get nextLabel => _p('Next', 'അടുത്തത്', 'التالي');

  // Tajweed Guide & Legends
  String get tajweedGuideTitle => _p('Tajweed Color Guide', 'തജ്‌വീദ് കളർ ഗൈഡ്', 'دليل ألوان التجويد');
  String get tajweedColorCoding => _p('Tajweed Color Coding', 'തജ്‌വീദ് കളർ കോഡിംഗ്', 'ألوان التجويد');
  String get tajweedRuleHeader => _p('Tajweed Rules', 'തജ്‌വീദ് നിയമങ്ങൾ', 'أحكام التجويد');
  String get tajweedExamplesLabel => _p('Examples from Quran', 'ഖുർആനിലെ ഉദാഹരണങ്ങൾ', 'أمثلة من القرآن');
  String get tajweedFullGuideBtn => _p('Open Full Tajweed Guide', 'പൂർണ്ണ തജ്‌വീദ് ഗൈഡ് തുറക്കുക', 'فتح دليل التجويد الكامل');
  String get tajweedLegendShort => _p('Tajweed Colors', 'തജ്‌വീദ് നിറങ്ങൾ', 'ألوان التجويد');
  String get tajweedTapHint => _p('Tap rule for details', 'വിവരങ്ങൾക്ക് ടാപ്പ് ചെയ്യുക', 'اضغط للتفاصيل');

  // Audio Recitation
  String get reciter => _p('Reciter', 'ഖാരിഅ് (Reciter)', 'القارئ');
  String get playAyah => _p('Play Ayah', 'ആയത്ത് കേൾക്കുക', 'تشغيل الآية');
  String get pauseAyah => _p('Pause recitation', 'പാരായണം നിർത്തുക', 'إيقاف مؤقت');
  String get resumeAyah => _p('Resume recitation', 'തുടർന്ന് കേൾക്കുക', 'استئناف التلاوة');
  String get previousAyah => _p('Previous Ayah', 'മുമ്പത്തെ ആയത്ത്', 'الآية السابقة');
  String get nextAyah => _p('Next Ayah', 'അടുത്ത ആയത്ത്', 'الآية التالية');
  String get closePlayer => _p('Close player', 'പ്ലെയർ അടയ്ക്കുക', 'إغلاق المشغل');
  String get repeatAyah => _p('Repeat Ayah', 'ആയത്ത് ആവർത്തിക്കുക', 'تكرار الآية');
  String get audioLoadError => _p('Could not play audio. Try again.', 'ഓഡിയോ പ്ലേ ചെയ്യാനായില്ല.', 'تعذر تشغيل الصوت.');

  // Export
  String get exportTitle => _p('Export Quran (PDF & PNG)', 'ഖുർആൻ എക്സ്പോർട്ട് (PDF / PNG)', 'تصدير القرآن');
  String get exportScope => _p('What to Export', 'എന്താണ് എക്സ്പോർട്ട് ചെയ്യേണ്ടത്', 'نطاق التصدير');
  String get scopeRange => _p('Ayah Range', 'ആയത്ത് റേഞ്ച്', 'نطاق آيات');
  String get scopeSurah => _p('Full Surah', 'പൂർണ്ണ സൂറത്ത്', 'سورة كاملة');
  String get scopeJuz => _p('Full Juz', 'പൂർണ്ണ ജുസ്അ്', 'جزء كامل');
  String get selectSurah => _p('Select Surah', 'സൂറത്ത് തിരഞ്ഞെടുക്കുക', 'اختر السورة');
  String get selectJuz => _p('Select Juz', 'ജുസ്അ് തിരഞ്ഞെടുക്കുക', 'اختر الجزء');
  String get fromAyah => _p('From Ayah', 'തുടങ്ങുന്ന ആയത്ത്', 'من الآية');
  String get toAyah => _p('To Ayah', 'അവസാനിക്കുന്ന ആയത്ത്', 'إلى الآية');
  String get pageSize => _p('Page Size', 'പേജ് സൈസ്', 'حجم الصفحة');
  String get sizeAutomatic => _p('Mobile Card', 'മൊബൈൽ കാർഡ്', 'بطاقة جوال');
  String get sizeA4 => _p('A4 Print', 'A4 പ്രിന്റ്', 'A4 للطباعة');
  String get exportFormat => _p('Format', 'ഫോർമാറ്റ്', 'الصيغة');
  String get formatPdf => _p('PDF Document', 'PDF ഡോക്യുമെന്റ്', 'ملف PDF');
  String get formatImage => _p('Image (PNG)', 'ഇമേജ് (PNG)', 'صورة PNG');
  String get includeTranslation => _p('Include Translation', 'പരിഭാഷ ഉൾപ്പെടുത്തുക', 'تضمين الترجمة');
  String get generatePreview => _p('Preview & Export', 'പ്രിവ്യൂ കാണുക', 'معاينة وتصدير');
  String get exportPreview => _p('Export Preview', 'എക്സ്പോർട്ട് പ്രിവ്യൂ', 'معاينة التصدير');
  String get preparingPages => _p('Preparing pages...', 'പേജുകൾ തയ്യാറാക്കുന്നു...', 'جاري تجهيز الصفحات...');
  String get download => _p('Download', 'ഡൗൺലോഡ്', 'تنزيل');
  String get share => _p('Share', 'ഷെയർ', 'مشاركة');
  String get exportSuccess => _p('Export ready and downloaded', 'വിജയകരമായി സേവ് ചെയ്തു', 'تم التصدير بنجاح');
  String get savedToGallery => _p('Saved to device gallery', 'ഗാലറിയിലേക്ക് സേവ് ചെയ്തു', 'تم الحفظ في المعرض');
  String get exportError => _p('Export failed. Please try again.', 'എക്സ്പോർട്ട് പരാജയപ്പെട്ടു. വീണ്ടും ശ്രമിക്കുക.', 'فشل التصدير. حاول مرة أخرى.');
  String get invalidAyahRange => _p('Enter a valid Ayah range', 'ശരിയായ ആയത്ത് നമ്പറുകൾ നൽകുക', 'أدخل نطاق آيات صحيح');

  // Prayer Times, Hijri & DND
  String get locationLabel => _p('Location', 'ലൊക്കേഷൻ', 'الموقع');
  String get useGps => _p('Use GPS', 'GPS ഉപയോഗിക്കുക', 'استخدام GPS');
  String get gpsFetching => _p('Fetching GPS location...', 'GPS എടുക്കുന്നു...', 'جاري تحديد الموقع...');
  String get gpsPermissionError => _p(
        'Location permission denied. Enable location access or select a city.',
        'ലൊക്കേഷൻ അനുമതി ലഭിച്ചില്ല. സിറ്റി തിരഞ്ഞെടുക്കുകയോ അനുമതി നൽകുകയോ ചെയ്യുക.',
        'تم رفض إذن الموقع. يرجى التفعيل أو اختيار المدينة.',
      );
  String get gpsServiceDisabled => _p(
        'Location service (GPS) is turned off on this device.',
        'ഫോണിൽ GPS / ലൊക്കേഷൻ ഓഫ് ആണ്.',
        'خدمة الموقع متوقفة في الجهاز.',
      );
  String get changeCity => _p('Change City', 'നഗരം മാറ്റുക', 'تغيير المدينة');
  String get cityFieldLabel => _p('City', 'നഗരം', 'المدينة');
  String get countryFieldLabel => _p('Country', 'രാജ്യം', 'الدولة');
  String get popularCities => _p('Quick Cities', 'പ്രധാന നഗരങ്ങൾ', 'مدن سريعة');
  String get applyLabel => _p('Apply', 'സെറ്റ് ചെയ്യുക', 'تطبيق');
  String get cancelLabel => _p('Cancel', 'റദ്ദാക്കുക', 'إلغاء');
  String get calculationMethod => _p('Calculation Method', 'കാൽക്കുലേഷൻ മെത്തേഡ്', 'طريقة الحساب');
  String get asrSchool => _p('Asr Juristic School', 'അസർ മദ്ഹബ്', 'مذهب العصر');
  String get schoolShafi => _p('Shafi / Standard', 'ശാഫിഈ (Standard)', 'الشافعي / الجمهور');
  String get schoolHanafi => _p('Hanafi', 'ഹനഫി', 'الحنفي');
  String get tuneMinutes => _p('Masjid Time Tune (Minutes)', 'പള്ളി സമയ ക്രമീകരണം (മിനിറ്റ്)', 'تعديل الدقائق حسب المسجد');
  String get resetTune => _p('Reset Tune', 'റീസെറ്റ്', 'إعادة ضبط');
  String get nextPrayerLabel => _p('Next Prayer', 'അടുത്ത നമസ്കാരം', 'الصلاة القادمة');
  String get remainingLabel => _p('in', 'ശേഷം', 'بعد');
  String get refreshLabel => _p('Refresh', 'അപ്ഡേറ്റ്', 'تحديث');
  String get todayLabel => _p('Today', 'ഇന്ന്', 'اليوم');
  String get offlineCachedNote => _p('Offline cached', 'ഓഫ്‌ലൈൻ ക്യാഷ്', 'محفوظ بدون إنترنت');
  String get fajrName => _p('Fajr', 'ഫജ്ർ', 'الفجر');
  String get sunriseName => _p('Sunrise', 'സൂര്യോദയം', 'الشروق');
  String get dhuhrName => _p('Dhuhr', 'ളുഹർ', 'الظهر');
  String get asrName => _p('Asr', 'അസർ', 'العصر');
  String get maghribName => _p('Maghrib', 'മഗ്‌രിബ്', 'المغرب');
  String get ishaName => _p('Isha', 'ഇശാഅ്', 'العشاء');
  String get adhanLabel => _p('Adhan', 'ബാങ്ക്', 'الأذان');
  String get iqamahLabel => _p('Iqamah', 'ഇഖാമത്ത്', 'الإقامة');
  String get alarmLabel => _p('Alarm', 'അലാറം', 'المنبه');
  String get alarmOffLabel => _p('Alarm Off', 'അലാറം ഓഫ്', 'المنبه متوقف');
  String get editScheduleLabel => _p('Edit Iqamah & Alarm', 'ഇഖാമത്തും അലാറവും ക്രമീകരിക്കുക', 'تعديل الإقامة والمنبه');
  String get prayerAlarmsTitle => _p('Prayer Alarms & Auto-Silent', 'നിസ്കാര അലാറവും ഓട്ടോ സൈലന്റും', 'منبهات الصلاة والصامت التلقائي');
  String get masterAlarmToggle => _p('Enable Prayer Alarms', 'നിസ്കാര അലാറം ഓൺ ആക്കുക', 'تفعيل منبهات الصلاة');
  String get masterAlarmDesc => _p(
        'Trigger Adhan or alert sound reliably even when phone is locked',
        'ഫോൺ ലോക്ക് ആയാലും ബാങ്കും അലാറവും കൃത്യസമയത്ത് പ്രവർത്തിക്കും',
        'تشغيل الأذان أو المنبه بدقة حتى عند قفل الهاتف',
      );
  String get prayerReminderRinging => _p('Prayer Time Reminder', 'നിസ്കാര സമയ ഓർമ്മപ്പെടുത്തൽ', 'تذكير وقت الصلاة');
  String get alarmSoundSettings => _p('Alarm Sound & Volume', 'അലാറം സൗണ്ട് ക്രമീകരണം', 'صوت المنبه ومستواه');
  String get alarmSoundTypeLabel => _p('Alarm Sound', 'അലാറം ശബ്ദം', 'نغمة المنبه');
  String get alarmVibrateLabel => _p('Vibrate with Alarm', 'അലാറത്തിനൊപ്പം വൈബ്രേഷൻ', 'الاهتزاز مع المنبه');
  String get alarmVolumeLabel => _p('Alarm Volume', 'ശബ്ദത്തിന്റെ അളവ്', 'مستوى الصوت');
  String get previewSoundLabel => _p('Test Sound', 'സൗണ്ട് കേൾക്കുക', 'تجربة الصوت');
  String get stopSoundLabel => _p('Stop', 'നിർത്തുക', 'إيقاف');
  String get iqamahGapLabel => _p('Iqamah Delay (min after Adhan)', 'ഇഖാമത്ത് സമയം (ബാങ്കിന് ശേഷം മിനിറ്റ്)', 'وقت الإقامة (دقائق بعد الأذان)');
  String get alarmRefLabel => _p('Alarm Timing', 'അലാറം എപ്പോൾ?', 'توقيت المنبه');
  String get beforeAdhanOption => _p('Before Adhan', 'ബാങ്കിന് മുമ്പ്', 'قبل الأذان');
  String get relativeToIqamahOption => _p('Before / After Iqamah', 'ഇഖാമത്തിന് മുമ്പ് / ശേഷം', 'قبل / بعد الإقامة');
  String get atIqamahTime => _p('Exactly at Iqamah', 'ഇഖാമത്ത് സമയത്ത് തന്നെ', 'عند وقت الإقامة تماماً');
  String get minutesBeforeLabel => _p('Minutes before Adhan', 'ബാങ്കിന് എത്ര മിനിറ്റ് മുമ്പ്', 'دقائق قبل الأذان');
  String get offsetFromIqamahLabel => _p('Offset from Iqamah (min)', 'ഇഖാമത്തിൽ നിന്നുള്ള വ്യത്യാസം (മിനിറ്റ്)', 'الفرق عن الإقامة (دقائق)');
  String get minutesUnitShort => _p('min', 'മിനിറ്റ്', 'د');
  String safetyBufferNote(String nextBoundary, String limitTime) => _p(
        'Clamped before $nextBoundary ($limitTime) to keep prayer windows clean.',
        'അടുത്ത സമയം ($nextBoundary - $limitTime) കവിയാത്ത രീതിയിൽ ക്രമീകരിച്ചിരിക്കുന്നു.',
        'مقيد قبل $nextBoundary ($limitTime) للحفاظ على أوقات الصلوات.',
      );
  String get dismissTodayAlarm => _p("Dismiss Today's Alarm", 'ഇന്നത്തെ അലാറം ഓഫ് ചെയ്യുക', 'إيقاف منبه اليوم');
  String get dismissedTodayLabel => _p('Off today', 'ഇന്ന് ഓഫ്', 'متوقف اليوم');
  String get dismissOnlyNote => _p(
        'Mutes today only — tomorrow’s schedule stays active automatically.',
        'ഇന്നത്തേക്ക് മാത്രം ഓഫ് ആകും — നാളെ തനിയെ പ്രവർത്തിക്കും.',
        'يتوقف لليوم فقط — ويعود تلقائياً غداً.',
      );
  String get autoSilentTitle => _p('Auto-Silent (DND) during Prayer', 'നിസ്കാര സമയത്ത് ഓട്ടോ സൈലന്റ് (DND)', 'الوضع الصامت التلقائي وقت الصلاة');
  String get autoSilentDesc => _p(
        'Switches phone to Do Not Disturb from Iqamah time and restores previous sound cleanly after the selected duration.',
        'ഇഖാമത്ത് സമയത്ത് ഫോൺ തനിയെ സൈലന്റ് (DND) ആകുകയും നിശ്ചിത സമയത്തിന് ശേഷം പഴയപടിയാക്കുകയും ചെയ്യും.',
        'يحول الهاتف إلى وضع عدم الإزعاج تلقائياً عند الإقامة ويعيد الصوت تلقائياً بعد انتهاء المدة.',
      );
  String get autoSilentDurationLabel => _p('Silent Duration from Iqamah', 'സൈലന്റ് സമയം (മിനിറ്റ്)', 'مدة الصامت من الإقامة');
  String get dndPermissionGranted => _p('Do Not Disturb policy active', 'DND അനുമതി സജ്ജമാണ്', 'صلاحية عدم الإزعاج مفعّلة');
  String get dndPermissionNeeded => _p('Allow DND Policy Access on Android', 'ഫോണിൽ DND അനുമതി നൽകുക', 'مطلوب صلاحية عدم الإزعاج');
  String get exactAlarmNeeded => _p('Allow Exact Alarms on Android', 'കൃത്യ സമയ അലാറത്തിന് അനുമതി നൽകുക', 'مطلوب صلاحية المنبه الدقيق');
  String get grantDndPermissionBtn => _p('Grant DND Access', 'അനുമതി നൽകുക', 'منح الصلاحية');
  String get grantExactAlarmBtn => _p('Allow Exact Alarms', 'അനുമതി നൽകുക', 'تفعيل الدقة');
  String get restoreSoundNowBtn => _p('Restore Sound Now', 'സൗണ്ട് പഴയപടിയാക്കുക', 'إعادة الصوت الآن');
  String get dndActiveNowBanner => _p('Auto-Silent DND Active Right Now', 'ഇപ്പോൾ ഓട്ടോ സൈലന്റ് (DND) ഓൺ ആണ്', 'الوضع الصامت مفعّل الآن');
  String get dndActiveBanner => dndActiveNowBanner;
  String get autoSilentWebNote => _p(
        'Auto-Silent preference syncs immediately to Android APK native alarms & DND engine.',
        'ഈ സെറ്റിംഗ്സ് തനിയെ സേവ് ആകുകയും Android APK DND എഞ്ചിനിലേക്ക് സിങ്ക് ചെയ്യുകയും ചെയ്യുന്നു.',
        'تُحفظ الإعدادات تلقائياً وتُزامن مع محرك DND في تطبيق أندرويد.',
      );
  String get autoSilentPrayersLabel => _p('Prayers for Auto-Silent', 'ഓട്ടോ-സൈലന്റ് വേണ്ട നമസ്കാരങ്ങൾ', 'الصلوات المفعّلة للصامت');
  String get hijriCalendarTitle => _p('Hijri Calendar', 'ഹിജ്രി കലണ്ടർ', 'التقويم الهجري');
  String get hijriAdjustment => _p('Moon Adjustment (-1 / 0 / +1)', 'മാസപ്പിറവി മാറ്റം (-1 / 0 / +1)', 'تعديل الهلال');
  String get dayMinusOne => _p('-1 Day', '-1 ദിവസം', '-1 يوم');
  String get dayZero => _p('Default (0)', 'സാധാരണ (0)', 'افتراضي (0)');
  String get dayPlusOne => _p('+1 Day', '+1 ദിവസം', '+1 يوم');

  // Home Widget Promo Card
  String get homeWidgetTitle => _p('Android Home Screen Widget', 'ഹോം സ്ക്രീൻ വിജറ്റ് (Widget)', 'أداة الشاشة الرئيسية');
  String get homeWidgetDesc => _p(
        'Add Ibadia Prayer Times & Hijri Date directly to your Android home screen.',
        'നിസ്കാര സമയവും ഹിജ്‌രി തീയതിയും ഫോണിന്റെ ഹോം സ്ക്രീനിൽ ചേർക്കാം.',
        'أضف أوقات الصلاة والتاريخ الهجري إلى شاشة هاتفك الرئيسية.',
      );

  // Adhkar & Tasbih
  String get morningAdhkar => _p('Morning', 'രാവിലെ', 'الصباح');
  String get eveningAdhkar => _p('Evening', 'വൈകിട്ട്', 'المساء');
  String get afterSalahAdhkar => _p('After Salah', 'നിസ്കാര ശേഷം', 'بعد الصلاة');
  String get dailyDuasCategory => _p('Daily Duas', 'നിത്യ ദുആകൾ', 'أدعية يومية');
  String get allAdhkarLabel => _p('All', 'എല്ലാം', 'الكل');
  String get favoritesOnlyLabel => _p('Favorites', 'പ്രിയപ്പെട്ടവ', 'المفضلة');
  String get resetTodayProgress => _p('Reset Progress', 'റീസെറ്റ്', 'إعادة التصفير');
  String get completedLabel => _p('Completed', 'പൂർത്തിയായി', 'مكتمل');
  String get hisnulMuslimNote => _p(
        'Offline Hisnul Muslim & Prophetic Adhkar — Tap card to count',
        'ഓഫ്‌ലൈൻ ഹിസ്നുൽ മുസ്‌ലിം ദിക്റുകളും ദുആകളും — എണ്ണാൻ ടാപ്പ് ചെയ്യുക',
        'حصن المسلم وأذكار يومية بدون إنترنت',
      );
  String get tasbihTitle => _p('Digital Tasbih Counter', 'തസ്ബീഹ് കൗണ്ടർ', 'المسبحة الرقمية');
  String get tapToCount => _p('Tap circle to count', 'എണ്ണാൻ ടാപ്പ് ചെയ്യുക', 'اضغط للعد');
  String get tapAnywhereLabel => _p('Tap Anywhere Zone', 'എവിടെയും ടാപ്പ് മോഡ്', 'منطقة الضغط الواسعة');
  String get tapAnywhereHint => _p(
        'Tap anywhere on the counter screen without looking',
        'സ്ക്രീനിൽ നോക്കാതെ എവിടെയും ടാപ്പ് ചെയ്ത് എണ്ണാം',
        'اضغط في أي مكان على الشاشة للعد',
      );
  String get targetLabel => _p('Target', 'ലക്ഷ്യം', 'الهدف');
  String get unlimitedLabel => _p('Free', 'അൺലിമിറ്റഡ്', 'مفتوح');
  String get todayTotalLabel => _p('Today', 'ഇന്ന്', 'اليوم');
  String get lifetimeTotalLabel => _p('Total', 'ആകെ', 'الإجمالي');
  String get addCustomDhikr => _p('Add Custom Dhikr', 'പുതിയ ദിക്ർ ചേർക്കുക', 'إضافة ذكر مخصص');
  String get customDhikrName => _p('Dhikr Name / Transliteration', 'ദിക്ർ പേര്', 'اسم الذكر');
  String get customDhikrArabic => _p('Arabic Text (optional)', 'അറബിക് ടെക്സ്റ്റ് (നിർബന്ധമില്ല)', 'النص العربي (اختياري)');
  String get deleteCustomLabel => _p('Delete', 'ഒഴിവാക്കുക', 'حذف');
  String get vibrateOnTapLabel => _p('Haptic Vibration', 'വൈബ്രേഷൻ', 'الاهتزاز');
  String get resetCycleLabel => _p('Reset Cycle', 'റീസെറ്റ്', 'تصفير');

  // Kahf & PWA/Updater
  String get kahfReminderTitle => _p('Surah Al-Kahf Weekly Reminder', 'സൂറത്തുൽ കഹ്ഫ് ഓർമ്മപ്പെടുത്തൽ', 'تذكير سورة الكهف');
  String get kahfReminderDesc => _p(
        'Weekly Thursday night & Friday morning gentle reminder to read Surah Al-Kahf.',
        'വ്യാഴാഴ്ച രാത്രിയും വെള്ളിയാഴ്ച രാവിലെയും സൂറത്തുൽ കഹ്ഫ് ഓർമ്മപ്പെടുത്തൽ.',
        'تذكير أسبوعي لقراءة سورة الكهف ليلة وصباح الجمعة.',
      );
  String get kahfThuLabel => _p('Thursday Evening', 'വ്യാഴാഴ്ച രാത്രി', 'مساء الخميس');
  String get kahfFriLabel => _p('Friday Morning', 'വെള്ളിയാഴ്ച രാവിലെ', 'صباح الجمعة');
  String get kahfBannerTitle => _p("Jumu'ah — Surah Al-Kahf", 'ജുമുഅ — സൂറത്തുൽ കഹ്ഫ്', 'تذكير الجمعة — سورة الكهف');
  String get kahfBannerDesc => _p(
        'Illuminate the space between two Fridays by reciting Surah Al-Kahf.',
        'രണ്ട് ജുമുഅകൾക്കിടയിൽ പ്രകാശം ലഭിക്കാൻ സൂറത്തുൽ കഹ്ഫ് പാരായണം ചെയ്യുക.',
        'اقرأ سورة الكهف ليضيء لك ما بين الجمعتين.',
      );
  String get kahfOpenSurahBtn => _p('Read Surah Al-Kahf', 'സൂറത്തുൽ കഹ്ഫ് ഓതുക', 'اقرأ سورة الكهف');
  String get testKahfReminder => _p('Test Reminder', 'ടെസ്റ്റ് നോട്ടിഫിക്കേഷൻ', 'تجربة التذكير');
  String get kahfTestWebFeedback => _p(
        'Surah Al-Kahf reminder preview is active.',
        'സൂറത്തുൽ കഹ്ഫ് ഓർമ്മപ്പെടുത്തൽ സജ്ജമാണ്.',
        'تذكير سورة الكهف جاهز.',
      );
  String get kahfNotifTitle => _p('Ibadia • Surah Al-Kahf', 'ഇബാദിയ • സൂറത്തുൽ കഹ്ഫ്', 'عبادية • سورة الكهف');
  String get kahfNotifBody => _p(
        "It's blessed Jumu'ah time — take a few minutes to recite Surah Al-Kahf.",
        'അനുഗ്രഹീതമായ ജുമുഅ സമയമാണ് — സൂറത്തുൽ കഹ്ഫ് പാരായണം ചെയ്യുക.',
        'وقت الجمعة المبارك — اقرأ سورة الكهف.',
      );

  // PWA & Android Update Dialog
  String get installApp => _p('Install Ibadia App', 'ഇബാദിയ ഇൻസ്റ്റാൾ ചെയ്യുക', 'تثبيت تطبيق عبادية');
  String get downloadAndroidApk => _p('Download Android APK', 'Android APK ഡൗൺലോഡ്', 'تحميل تطبيق أندرويد');
  String get checkForUpdates => _p('Check for App Updates', 'പുതിയ അപ്ഡേറ്റ് പരിശോധിക്കുക', 'التحقق من التحديثات');
  String get shareApp => _p('Share App', 'ആപ്പ് ഷെയർ ചെയ്യുക', 'مشاركة التطبيق');
  String get shareAppCopied => _p('App link copied to clipboard', 'ആപ്പ് ലിങ്ക് കോപ്പി ചെയ്തു', 'تم نسخ رابط التطبيق');
  String get offlineBanner => _p(
        'Offline Mode — Cached Surahs & Adhkar remain available',
        'ഓഫ്‌ലൈൻ മോഡ് — സേവ് ചെയ്തവ ഇപ്പോഴും ലഭ്യമാണ്',
        'وضع عدم الاتصال — المحتوى المحفوظ متاح',
      );
  String get updateAvailableTitle => _p('App Update Available', 'പുതിയ അപ്ഡേറ്റ് ലഭ്യമാണ്', 'يتوفر تحديث جديد');
  String updateAvailableDesc(String version, int build) => _p(
        'Ibadia v$version (Build #$build) is ready with improvements and fixes.',
        'ഇബാദിയ v$version (#$build) അപ്ഡേറ്റ് ഇപ്പോൾ ഡൗൺലോഡ് ചെയ്യാം.',
        'يتوفر تحديث عبادية v$version (البناء #$build).',
      );
  String get updateNow => _p('Update Now', 'അപ്ഡേറ്റ് ചെയ്യുക', 'تحديث الآن');
  String get updateLater => _p('Later', 'പിന്നീട്', 'لاحقاً');
  String get updateAvailableBadge => _p('Update Ready', 'പുതിയ അപ്ഡേറ്റ്', 'تحديث');
  String get checkingUpdates => _p('Checking for updates...', 'അപ്ഡേറ്റ് പരിശോധിക്കുന്നു...', 'جاري التحقق...');
  String get upToDateMessage => _p('You are using the latest Ibadia version.', 'ഏറ്റവും പുതിയ പതിപ്പാണ് ഉപയോഗിക്കുന്നത്.', 'أنت تستخدم أحدث إصدار من عبادية.');
  String get updateCheckUnavailable => _p(
        'Unable to reach update server right now.',
        'അപ്ഡേറ്റ് പരിശോധിക്കാനായില്ല. ഇന്റർനെറ്റ് പരിശോധിക്കുക.',
        'تعذر الوصول لخادم التحديثات.',
      );
  String get downloadingUpdate => _p('Downloading update...', 'ഡൗൺലോഡ് ചെയ്യുന്നു...', 'جاري التنزيل...');
  String get installingUpdate => _p('Opening installer...', 'ഇൻസ്റ്റാളർ തുറക്കുന്നു...', 'جاري فتح المثبّت...');
  String get allowInstallPermissionTitle => _p('Allow App Installation', 'ഇൻസ്റ്റാൾ അനുമതി നൽകുക', 'السماح بتثبيت التطبيقات');
  String get allowInstallPermissionDesc => _p(
        'Allow Ibadia to install APK updates from unknown sources in Android Settings.',
        'അപ്ഡേറ്റ് ഇൻസ്റ്റാൾ ചെയ്യാൻ Android സെറ്റിംഗ്സിൽ അനുമതി നൽകുക.',
        'اسمح لتطبيق عبادية بتثبيت التحديثات من إعدادات أندرويد.',
      );
  String get installDownloadedApk => _p('Install Update Now', 'ഇൻസ്റ്റാൾ ചെയ്യുക', 'تثبيت الآن');
  String get downloadInBrowser => _p('Download via Browser', 'ബ്രൗസർ വഴി ഡൗൺലോഡ്', 'تنزيل عبر المتصفح');
  String get installOnIosTitle => _p('Install on iPhone / iPad', 'iPhone / iPad-ൽ ഇൻസ്റ്റാൾ ചെയ്യുക', 'التثبيت على iOS');
  String get installOnIosSteps => _p(
        'Tap the Share icon at the bottom of Safari, then select "Add to Home Screen".',
        'Safari-യുടെ താഴെയുള്ള Share ബട്ടണിൽ അമർത്തി "Add to Home Screen" തിരഞ്ഞെടുക്കുക.',
        'اضغط على زر المشاركة في Safari ثم اختر "إضافة إلى الشاشة الرئيسية".',
      );
  String get apkSetupTitle => _p('Android APK Download', 'Android APK ഡൗൺലോഡ്', 'تحميل ملف APK');
  String get apkSetupDesc => _p(
        'Download Ibadia APK directly for native Prayer Alarms & Auto-Silent DND.',
        'നിസ്കാര അലാറവും ഓട്ടോ-സൈലന്റും ലഭിക്കാൻ Ibadia APK ഡൗൺലോഡ് ചെയ്യുക.',
        'حمّل تطبيق عبادية APK للحصول على منبهات الصلاة والصامت التلقائي.',
      );
  String get appAndUpdatesTitle => _p('App & Updates', 'ആപ്പും അപ്ഡേറ്റുകളും', 'التطبيق والتحديثات');
  String get apkDownloadStarted => _p(
        'Starting Ibadia.apk download...',
        'Ibadia.apk ഡൗൺലോഡ് തുടങ്ങുന്നു...',
        'بدأ تنزيل Ibadia.apk...',
      );
  String get copyApkLink => _p('Copy APK Link', 'APK ലിങ്ക് കോപ്പി ചെയ്യുക', 'نسخ رابط APK');
  String get apkLinkCopied => _p('APK download link copied', 'APK ലിങ്ക് കോപ്പി ചെയ്തു', 'تم نسخ رابط APK');
  String get browserInstallTitle => _p('Install Ibadia App', 'ഇബാദിയ ആപ്പ് ഇൻസ്റ്റാൾ ചെയ്യുക', 'تثبيت تطبيق عبادية');
  String get browserInstallSteps => _p(
        'Open your browser menu (⋮ or Share) and select "Install App" or "Add to Home Screen".',
        'ബ്രൗസർ മെനു (⋮) തുറന്ന് "Install App" അല്ലെങ്കിൽ "Add to Home Screen" തിരഞ്ഞെടുക്കുക.',
        'افتح قائمة المتصفح واختر "تثبيت التطبيق" أو "إضافة إلى الشاشة الرئيسية".',
      );

  String prayerName(String key) {
    switch (key) {
      case 'fajr':
        return fajrName;
      case 'sunrise':
        return sunriseName;
      case 'dhuhr':
        return dhuhrName;
      case 'asr':
        return asrName;
      case 'maghrib':
        return maghribName;
      default:
        return ishaName;
    }
  }

  String revelationLabel(String raw) {
    final l = raw.toLowerCase();
    if (l.contains('mecc') || l.contains('makk')) {
      return _p('Meccan', 'മക്കി', 'مكية');
    }
    return _p('Medinan', 'മദനി', 'مدنية');
  }

  // Ibadah & Salah Complete Guide (Shafi'i Fiqh)
  String get ibadahGuideTitle => _p(
        'Ibadah & Salah Guide',
        'ഇബാദത്ത് & നിസ്കാര ഗൈഡ്',
        'دليل الصلاة والعبادات',
      );
  String get ibadahFiqhSubtitle => _p(
        'Shafi\'i Fiqh · Offline + Audio',
        'ശാഫിഈ മദ്ഹബ് · ഓഫ്‌ലൈൻ + ഓഡിയോ',
        'الفقه الشافعي · بدون إنترنت',
      );
  String get niyyahTabLabel => _p('Niyyah', 'നിയ്യത്ത്', 'النية');
  String get salahGuideTabLabel => _p('Salah', 'നിസ്കാരം', 'الصلاة');
  String get rawatibTabLabel => _p('Sunnah & Surahs', 'സുന്നത്ത് & സൂറത്തുകൾ', 'الرواتب والسور');
  String get mayyithTabLabel => _p('Mayyith', 'മയ്യിത്ത്', 'الجنازة');

  String get fardPrayersSection => _p('Fard Prayers (5 Daily)', 'ഫർള് നിസ്കാരങ്ങൾ (5 നേരം)', 'الصلوات المفروضة');
  String get sunnahPrayersSection => _p('Major Sunnah Prayers', 'പ്രധാന സുന്നത്ത് നിസ്കാരങ്ങൾ', 'صلوات النوافل');
  String get roleMunfarid => _p('Individual', 'ഒറ്റയ്ക്ക്', 'منفرداً');
  String get roleImam => _p('Imam', 'ഇമാം', 'إماماً');
  String get roleMamoom => _p('Ma\'moom', 'മഅ്മൂം', 'مأموماً');

  String get shartChecklistTitle => _p(
        'Conditions Before Salah (Shart)',
        'നിസ്കാരത്തിന്റെ ശർത്വുകൾ (നിബന്ധനകൾ)',
        'شروط صحة الصلاة',
      );
  String get arkanSectionTitle => _p(
        '14 Pillars of Salah (Fard / Arkan)',
        'നിസ്കാരത്തിലെ 14 ഫർളുകൾ (അർക്കാൻ)',
        'أركان الصلاة الأربعة عشر',
      );
  String get stepByStepSalahTitle => _p(
        'Step-by-Step Salah Order (Takbir to Salam)',
        'നിസ്കാരത്തിന്റെ പൂർണ്ണ ക്രമം (തക്ബീർ മുതൽ സലാം വരെ)',
        'صفة الصلاة خطوة بخطوة',
      );
  String get resetChecklistLabel => _p('Reset', 'റീസെറ്റ്', 'إعادة ضبط');
  String get filterAll => _p('All', 'എല്ലാം', 'الكل');
  String get fardBadgeLabel => _p('Fard Pillar', 'ഫർള്', 'ركن / فرض');
  String get sunnahBadgeLabel => _p('Sunnah', 'സുന്നത്ത്', 'سنة');
  String get muakkadahBadgeLabel => _p('Mu\'akkadah', 'മുഅക്കദ', 'مؤكدة');
  String get ghairMuakkadahBadgeLabel => _p('Ghair Mu\'akkadah', 'ഗൈർ മുഅക്കദ', 'غير مؤكدة');

  String get rawatibScheduleTitle => _p(
        'Rawatib Sunnah Schedule',
        'റവാതിബ് സുന്നത്ത് നിസ്കാരങ്ങൾ',
        'السنن الرواتب',
      );
  String get beforePrayerLabel => _p('Before Fard', 'മുമ്പ്', 'قبلية');
  String get afterPrayerLabel => _p('After Fard', 'ശേഷം', 'بعدية');
  String get recommendedSurahsTitle => _p(
        'Recommended Surahs in Salah',
        'നിസ്കാരങ്ങളിൽ ഓതാൻ ഉത്തമമായ സൂറത്തുകൾ',
        'السور المستحبة في الصلاة',
      );
  String get openInQuranReader => _p('Read in Quran', 'ഖുർആനിൽ വായിക്കുക', 'قراءة في المصحف');

  String get mayyithPrepTitle => _p(
        'Preparation, Ghusl & Kafan',
        'തയ്യാറെടുപ്പ്, കുളിപ്പിക്കൽ & കഫൻ',
        'التجهيز والغسل والتكفين',
      );
  String get mayyithNiyyahTitle => _p(
        'Janazah Prayer Niyyah',
        'മയ്യിത്ത് നിസ്കാര നിയ്യത്ത്',
        'نيات صلاة الجنازة',
      );
  String get mayyithTakbirsTitle => _p(
        '4 Takbirs Order & Duas',
        '4 തക്ബീറുകളുടെ ക്രമവും ദുആകളും',
        'التكبيرات الأربع والأدعية',
      );
  String get mayyithBurialTitle => _p(
        'Burial (Dafn) & Talqeen Duas',
        'ഖബറടക്കം & തൽഖീൻ ദുആകൾ',
        'الدفن والدعاء عند القبر',
      );

  String get transliterationLabel => _p('Transliteration', 'ഉച്ചാരണം (മലയാളം)', 'النطق');
  String get meaningLabel => _p('Meaning', 'അർത്ഥം', 'المعنى');
  String get copiedTextNotice => _p('Copied to clipboard', 'കോപ്പി ചെയ്തു', 'تم النسخ');
  String get audioNotFoundMessage => _p(
        'Audio file not found yet. Add the MP3 file under assets/audio/ibadah/ to enable playback.',
        'ഓഡിയോ ഫയൽ ഇതുവരെ ചേർത്തിട്ടില്ല. പ്ലേ ചെയ്യാൻ MP3 ഫയൽ assets/audio/ibadah/ ഫോൾഡറിൽ ചേർക്കുക.',
        'ملف الصوت غير موجود بعد. أضف ملف MP3 في assets/audio/ibadah/.',
      );

  // Ibadah Settings & Summary Navigation
  String get ibadahSettingsTitle => _p(
        'Ibadah Display Settings',
        'ഇബാദത്ത് ഡിസ്പ്ലേ സെറ്റിംഗ്സ്',
        'إعدادات عرض العبادات',
      );
  String get ibadahSettingsDesc => _p(
        'Headings & Arabic appear by default. Turn on study aids below whenever needed.',
        'തലക്കെട്ടും അറബിക്കും എപ്പോഴും കാണാം. ആവശ്യാനുസരണം മറ്റ് വിവരങ്ങൾ ഓൺ ആക്കാം.',
        'تظهر العناوين والنص العربي افتراضياً. فعّل المساعدات أدناه عند الحاجة.',
      );
  String get malayalamHeadingsSetting => _p(
        'Malayalam Headings Always',
        'തലക്കെട്ടുകളും ശർത്വുകളും അർക്കാനും മലയാളത്തിൽ',
        'إظهار العناوين بالمالايالامية دائماً',
      );
  String get malayalamHeadingsDesc => _p(
        'Keep section titles, Shart & 14 Arkan in Malayalam even when app language is English',
        'ആപ്പ് ഭാഷ ഇംഗ്ലീഷ് ആണെങ്കിലും ശർത്വുകളും 14 അർക്കാനും മലയാളത്തിൽ നിലനിർത്തും',
        'إبقاء العناوين والشروط والأركان بالمالايالامية حتى مع اللغة الإنجليزية',
      );
  String get showTransliterationSetting => _p(
        'Show Malayalam Transliteration',
        'മലയാളം ഉച്ചാരണം കാണിക്കുക',
        'إظهار النطق بالمالايالامية',
      );
  String get showMeaningSetting => _p(
        'Show Meaning',
        'അർത്ഥം കാണിക്കുക',
        'إظهار المعنى',
      );
  String get showNotesSetting => _p(
        'Show Fiqh Notes',
        'ഫിഖ്ഹ് കുറിപ്പുകൾ കാണിക്കുക',
        'إظهار الملاحظات الفقهية',
      );
  String get showAudioSetting => _p(
        'Show Offline Audio Player',
        'ഓഫ്‌ലൈൻ ഓഡിയോ പ്ലെയർ കാണിക്കുക',
        'إظهار مشغل الصوت',
      );
  String get summaryTableTitle => _p(
        'Overview & Counts (Tap row to jump)',
        'ചുരുക്കവിവരണം & എണ്ണം (കാണാൻ ടാപ്പ് ചെയ്യുക)',
        'ملخص الأقسام والعدد (اضغط للانتقال)',
      );
  String get orderedChainTitle => _p(
        'Step Sequence Chain',
        'ക്രമീകൃത ശൃംഖല (ഓർഡർ)',
        'تسلسل الخطوات',
      );
  String get ibadahDisplayTip => _p(
        'Tip: Tap ⚙ at top-right to show Transliteration, Meaning, Notes or Audio.',
        'ടിപ്പ്: ഉച്ചാരണം, അർത്ഥം, കുറിപ്പുകൾ, ഓഡിയോ എന്നിവയ്ക്ക് മുകളിലെ ⚙ അമർത്തുക.',
        'ملاحظة: اضغط ⚙ في الأعلى لإظهار النطق أو المعنى أو الصوت.',
      );
}
