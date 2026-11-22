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
  String savedToGallery(int count) => _pick(
        'Saved $count image(s) to Gallery (Al-Quran)',
        '$count ഇമേജ് ഗ്യാലറിയിൽ (Al-Quran) സേവ് ചെയ്തു',
        'تم حفظ $count صورة في المعرض (Al-Quran)',
      );
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

  // Mushaf Header, Whole-Surah Bookmark & Compact Settings Tip
  String get fullSurahBadge =>
      _pick('Full Surah', 'പൂർണ്ണ സൂറത്ത്', 'سورة كاملة');
  String get bookmarkSurah => _pick(
        'Bookmark Surah',
        'സൂറത്ത് ബുക്ക്‌മാർക്ക് ചെയ്യുക',
        'حفظ السورة',
      );
  String get floatingControlsTipTitle => _pick(
        'Speed & Font Size Controls',
        'സ്പീഡും ഫോണ്ട് സൈസും മാറ്റാൻ',
        'التحكم بالسرعة وحجم الخط',
      );
  String get floatingControlsTipDesc => _pick(
        'Long-press the floating Play button in the reader to adjust Auto-Scroll Speed and Arabic / Translation font sizes.',
        'റീഡറിലെ ഫ്ലോട്ടിംഗ് പ്ലേ ബട്ടണിൽ ലോങ്-പ്രസ് ചെയ്താൽ ഓട്ടോ-സ്ക്രോൾ വേഗതയും അറബിക് / പരിഭാഷ ഫോണ്ട് സൈസും എളുപ്പത്തിൽ മാറ്റാം.',
        'اضغط مطولاً على زر التشغيل العائم أثناء القراءة لتعديل سرعة التمرير التلقائي وحجم الخط العربي والترجمة.',
      );

  // Home Surah & Juz Tab Redesign
  String get commonlyRecited => _pick(
        'Commonly Recited',
        'പതിവായി ഓതുന്നവ',
        'سور مختارة',
      );
  String get searchSurah => _pick(
        'Search Surah',
        'സൂറത്ത് തിരയുക',
        'ابحث عن سورة',
      );
  String get surahTabLabel => _pick('Surah', 'സൂറത്ത്', 'السور');
  String get juzTabLabel => _pick('Juz', 'ജുസ്അ്', 'الأجزاء');

  // Web PWA Install, Offline Banner & Android APK Download
  String get installApp => _pick(
        'Install App',
        'ആപ്പ് ഇൻസ്റ്റാൾ ചെയ്യുക',
        'تثبيت التطبيق',
      );
  String get installAppDesc => _pick(
        'Add Al-Quran to your home screen for quick offline access',
        'വേഗത്തിലുള്ള വായനയ്ക്കായി ഫോൺ/കമ്പ്യൂട്ടർ ഹോം സ്ക്രീനിലേക്ക് ചേർക്കുക',
        'أضف التطبيق إلى الشاشة الرئيسية للوصول السريع بدون إنترنت',
      );
  String get installOnIosTitle => _pick(
        'Install on iPhone / iPad',
        'iPhone / iPad-ൽ ഇൻസ്റ്റാൾ ചെയ്യാൻ',
        'التثبيت على iPhone / iPad',
      );
  String get installOnIosSteps => _pick(
        '1. Tap the Share button in Safari.\n2. Scroll down and tap "Add to Home Screen".',
        '1. Safari ബ്രൗസറിലെ Share ബട്ടൺ ക്ലിക്ക് ചെയ്യുക.\n2. താഴേക്ക് സ്ക്രോൾ ചെയ്ത് "Add to Home Screen" തിരഞ്ഞെടുക്കുക.',
        '1. اضغط على زر المشاركة في متصفح Safari.\n2. مرر للأسفل واضغط على "إضافة إلى الشاشة الرئيسية".',
      );
  String get downloadAndroidApk => _pick(
        'Download Android APK',
        'Android APK ഡൗൺലോഡ് ചെയ്യുക',
        'تحميل تطبيق أندرويد (APK)',
      );
  String get downloadAndroidApkDesc => _pick(
        'Install the native Android package (Al-Quran.apk)',
        'ആൻഡ്രോയിഡ് ഫോണിനായുള്ള Al-Quran.apk ആപ്പ് ഇൻസ്റ്റാൾ ചെയ്യാം',
        'تثبيت حزمة تطبيق الأندرويد الأصلية (Al-Quran.apk)',
      );
  String get apkSetupTitle => _pick(
        'Android APK Release',
        'Android APK ഡൗൺലോഡ്',
        'إصدار تطبيق أندرويد',
      );
  String get apkSetupDesc => _pick(
        'Direct 1-tap APK download turns on automatically once this repository is pushed to GitHub & published on Vercel (GitHub Releases hosts Al-Quran.apk automatically). You can still share the live web app link right now!',
        'ഈ പ്രോജക്റ്റ് GitHub-ലേക്ക് Push ചെയ്ത് Vercel-ൽ പബ്ലിഷ് ചെയ്യുന്നതോടെ GitHub Releases വഴി Al-Quran.apk ഇവിടെ നിന്ന് നേരിട്ട് 1-ടാപ്പിൽ ഡൗൺലോഡ് ആകും. ഇപ്പോൾ തന്നെ വെബ് ആപ്പ് ലിങ്ക് മറ്റുള്ളവർക്ക് ഷെയർ ചെയ്യാവുന്നതാണ്!',
        'يتم تفعيل التحميل المباشر تلقائياً بمجرد رفع المشروع على GitHub ونشره على Vercel. يمكنك مشاركة رابط الموقع الآن!',
      );
  String get shareApp => _pick(
        'Share App',
        'ആപ്പ് ഷെയർ ചെയ്യുക',
        'مشاركة التطبيق',
      );
  String get shareAppCopied => _pick(
        'App link copied to clipboard',
        'ആപ്പ് ലിങ്ക് കോപ്പി ചെയ്തു',
        'تم نسخ رابط التطبيق',
      );
  String get offlineBanner => _pick(
        'Offline Mode — Cached Surahs remain available',
        'ഓഫ്‌ലൈൻ മോഡ് — സേവ് ചെയ്ത സൂറത്തുകൾ ഇപ്പോഴും വായിക്കാം',
        'وضع عدم الاتصال — السور المحفوظة متاحة للقراءة',
      );
  String get closeLabel => _pick('Close', 'അടയ്ക്കുക', 'إغلاق');

  // App Updates (1-Click Self-Update for Android APK & Web PWA)
  String get checkForUpdates => _pick(
        'Check for Updates',
        'അപ്ഡേറ്റ് പരിശോധിക്കുക',
        'التحقق من التحديثات',
      );
  String get checkingUpdates => _pick(
        'Checking for updates...',
        'അപ്ഡേറ്റുകൾ പരിശോധിക്കുന്നു...',
        'جاري التحقق من التحديثات...',
      );
  String get updateAvailableTitle => _pick(
        'New Update Available',
        'പുതിയ അപ്ഡേറ്റ് ലഭ്യമാണ്',
        'يتوفر تحديث جديد',
      );
  String updateAvailableDesc(String version, int buildNo) => _pick(
        'Version $version (Build #$buildNo) is ready. Tap Update Now to jump directly to the latest version while keeping all your bookmarks and settings safe.',
        'പുതിയ വേർഷൻ $version (Build #$buildNo) ഇപ്പോൾ ലഭ്യമാണ്. "ഇപ്പോൾ അപ്ഡേറ്റ് ചെയ്യുക" ക്ലിക്ക് ചെയ്താൽ നിങ്ങളുടെ ബുക്ക്‌മാർക്കുകളും സെറ്റിംഗ്സും നഷ്ടപ്പെടാതെ ഒറ്റ ക്ലിക്കിൽ ഏറ്റവും പുതിയ വേർഷനിലേക്ക് മാറാം.',
        'الإصدار الجديد $version (Build #$buildNo) متاح الآن. اضغط على التحديث الآن للانتقال مباشرة إلى أحدث إصدار مع الحفاظ على إشاراتك وإعداداتك.',
      );
  String get updateNow => _pick(
        'Update Now',
        'ഇപ്പോൾ അപ്ഡേറ്റ് ചെയ്യുക',
        'التحديث الآن',
      );
  String get updateLater => _pick('Later', 'പിന്നീട്', 'لاحقاً');
  String get updateAvailableBadge =>
      _pick('Update Ready', 'അപ്ഡേറ്റ് ഉണ്ട്', 'تحديث متاح');
  String get downloadingUpdate => _pick(
        'Downloading latest update...',
        'ഏറ്റവും പുതിയ അപ്ഡേറ്റ് ഡൗൺലോഡ് ചെയ്യുന്നു...',
        'جاري تنزيل أحدث تحديث...',
      );
  String get installingUpdate => _pick(
        'Opening Android installer...',
        'ഇൻസ്റ്റാളർ തുറക്കുന്നു...',
        'جاري فتح مثبت التطبيق...',
      );
  String get installDownloadedApk => _pick(
        'Install Update',
        'അപ്ഡേറ്റ് ഇൻസ്റ്റാൾ ചെയ്യുക',
        'تثبيت التحديث',
      );
  String get allowInstallPermissionTitle => _pick(
        'Allow App Installs',
        'ഇൻസ്റ്റാൾ അനുമതി നൽകുക',
        'السماح بتثبيت التطبيقات',
      );
  String get allowInstallPermissionDesc => _pick(
        'Enable "Allow from this source" in Android Settings, then come back and tap Install Update.',
        'തുറന്നുവന്ന ഫോൺ സെറ്റിംഗ്സിൽ "Allow from this source" ഓൺ ആക്കുക. അതിനുശേഷം തിരികെ വന്ന് "അപ്ഡേറ്റ് ഇൻസ്റ്റാൾ ചെയ്യുക" ക്ലിക്ക് ചെയ്യുക.',
        'فعّل خيار السماح بتثبيت التطبيقات من هذا المصدر في الإعدادات ثم عد واضغط على تثبيت التحديث.',
      );
  String get downloadInBrowser => _pick(
        'Download in Browser',
        'ബ്രൗസറിൽ ഡൗൺലോഡ് ചെയ്യുക',
        'التحميل عبر المتصفح',
      );
  String get upToDateMessage => _pick(
        'You are already on the latest version.',
        'നിങ്ങൾ ഇപ്പോൾ തന്നെ ഏറ്റവും പുതിയ വേർഷൻ ആണ് ഉപയോഗിക്കുന്നത്.',
        'أنت تستخدم أحدث إصدار بالفعل.',
      );
  String get updateCheckUnavailable => _pick(
        'Could not check for updates right now. Please verify your internet connection.',
        'ഇപ്പോൾ അപ്ഡേറ്റ് പരിശോധിക്കാനായില്ല. ഇന്റർനെറ്റ് കണക്ഷൻ പരിശോധിക്കുക.',
        'تعذر التحقق من التحديثات الآن. يرجى التحقق من اتصال الإنترنت.',
      );

  // Audio Recitation & Reciter Selection
  String get reciter => _pick('Reciter', 'ഖാരിഅ് (Reciter)', 'القارئ');
  String get reciterSubtitle => _pick(
        'Choose your Quran recitation voice',
        'ഖുർആൻ പാരായണം ചെയ്യുന്ന ഖാരിഇനെ തിരഞ്ഞെടുക്കുക',
        'اختر صوت قارئ القرآن الكريم',
      );
  String get playAyah => _pick('Play Ayah', 'ആയത്ത് കേൾക്കുക', 'تشغيل الآية');
  String get pauseAyah =>
      _pick('Pause recitation', 'പാരായണം നിർത്തുക', 'إيقاف مؤقت');
  String get resumeAyah =>
      _pick('Resume recitation', 'തുടർന്ന് കേൾക്കുക', 'استئناف التلاوة');
  String get previousAyah =>
      _pick('Previous Ayah', 'മുമ്പത്തെ ആയത്ത്', 'الآية السابقة');
  String get nextAyah =>
      _pick('Next Ayah', 'അടുത്ത ആയത്ത്', 'الآية التالية');
  String get closePlayer =>
      _pick('Close player', 'പ്ലെയർ അടയ്ക്കുക', 'إغلاق المشغل');
  String get audioLoadError => _pick(
        'Could not play audio. Tap retry.',
        'ഓഡിയോ പ്ലേ ചെയ്യാനായില്ല. വീണ്ടും ശ്രമിക്കുക.',
        'تعذر تشغيل الصوت. اضغط لإعادة المحاولة.',
      );

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
