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
  String get repeatAyah =>
      _pick('Repeat Ayah', 'ആയത്ത് ആവർത്തിക്കുക', 'تكرار الآية');
  String get audioLoadError => _pick(
        'Could not play audio. Tap retry.',
        'ഓഡിയോ പ്ലേ ചെയ്യാനായില്ല. വീണ്ടും ശ്രമിക്കുക.',
        'تعذر تشغيل الصوت. اضغط لإعادة المحاولة.',
      );

  // Main Navigation & Sub-Tabs
  String get quranTab => _pick('Quran', 'ഖുർആൻ', 'القرآن');
  String get featuresTab => _pick('Features', 'ഫീച്ചേഴ്സ്', 'الميزات');
  String get prayerTimesTab =>
      _pick('Prayer Times', 'നമസ്കാരം', 'أوقات الصلاة');
  String get hijriCalendarTab =>
      _pick('Hijri', 'ഹിജ്രി', 'التقويم الهجري');

  // Contextual Settings Titles
  String get quranSettingsTitle =>
      _pick('Quran Settings', 'ഖുർആൻ സെറ്റിംഗ്സ്', 'إعدادات القرآن');
  String get featuresSettingsTitle =>
      _pick('Features Settings', 'ഫീച്ചേഴ്സ് സെറ്റിംഗ്സ്', 'إعدادات الميزات');

  // Prayer Times & Location
  String get locationLabel => _pick('Location', 'ലൊക്കേഷൻ', 'الموقع');
  String get useGps => _pick('Use GPS', 'GPS ഉപയോഗിക്കുക', 'استخدام GPS');
  String get gpsActiveLabel =>
      _pick('GPS Location', 'GPS ലൊക്കേഷൻ', 'موقع GPS');
  String get changeCity =>
      _pick('Change City', 'നഗരം മാറ്റുക', 'تغيير المدينة');
  String get cityFieldLabel => _pick('City', 'നഗരം', 'المدينة');
  String get countryFieldLabel => _pick('Country', 'രാജ്യം', 'الدولة');
  String get popularCities =>
      _pick('Quick Cities', 'പ്രധാന നഗരങ്ങൾ', 'مدن سريعة');
  String get applyLabel => _pick('Apply', 'സെറ്റ് ചെയ്യുക', 'تطبيق');
  String get cancelLabel => _pick('Cancel', 'റദ്ദാക്കുക', 'إلغاء');
  String get calculationMethod =>
      _pick('Calculation Method', 'കാൽക്കുലേഷൻ മെത്തേഡ്', 'طريقة الحساب');
  String get asrSchool => _pick('Asr Juristic School', 'അസർ മദ്ഹബ്', 'مذهب العصر');
  String get schoolShafi =>
      _pick('Shafi / Standard', 'ശാഫിഈ (Standard)', 'الشافعي / الجمهور');
  String get schoolHanafi => _pick('Hanafi', 'ഹനഫി', 'الحنفي');
  String get tuneMinutes => _pick(
        'Masjid Time Tune (Minutes)',
        'പള്ളി സമയ ക്രമീകരണം (മിനിറ്റ്)',
        'تعديل الدقائق حسب المسجد',
      );
  String get tuneShort => _pick('Tune Times', 'സമയം മാറ്റുക', 'تعديل الوقت');
  String get resetTune => _pick('Reset Tune', 'റീസെറ്റ്', 'إعادة ضبط');
  String get nextPrayerLabel =>
      _pick('Next Prayer', 'അടുത്ത നമസ്കാരം', 'الصلاة القادمة');
  String get remainingLabel => _pick('in', 'ശേഷം', 'بعد');
  String get refreshLabel => _pick('Refresh', 'അപ്ഡേറ്റ്', 'تحديث');
  String get offlineCachedNote =>
      _pick('Offline cached', 'ഓഫ്‌ലൈൻ ക്യാഷ്', 'محفوظ بدون إنترنت');
  String get gpsFetching =>
      _pick('Fetching GPS location...', 'GPS ലൊക്കേഷൻ എടുക്കുന്നു...', 'جاري تحديد الموقع...');
  String get gpsPermissionError => _pick(
        'Location permission denied. Showing city timings.',
        'ലൊക്കേഷൻ അനുമതി ലഭിച്ചില്ല. നഗര സമയം കാണിക്കുന്നു.',
        'تم رفض إذن الموقع. يتم عرض توقيت المدينة.',
      );
  String get gpsServiceDisabled => _pick(
        'Enable device GPS / Location services to update automatically.',
        'ഓട്ടോമാറ്റിക് ലൊക്കേഷനായി ഫോണിൽ GPS ഓൺ ചെയ്യുക.',
        'يرجى تفعيل خدمة الموقع على الجهاز.',
      );

  // Prayer Names
  String get fajrName => _pick('Fajr', 'ഫജ്ർ', 'الفجر');
  String get sunriseName => _pick('Sunrise', 'സൂര്യോദയം', 'الشروق');
  String get dhuhrName => _pick('Dhuhr', 'ളുഹർ', 'الظهر');
  String get asrName => _pick('Asr', 'അസർ', 'العصر');
  String get maghribName => _pick('Maghrib', 'മഗ്‌രിബ്', 'المغرب');
  String get ishaName => _pick('Isha', 'ഇശാഅ്', 'العشاء');

  // Adhan, Iqamah & Alarm System
  String get adhanLabel => _pick('Adhan', 'ബാങ്ക്', 'الأذان');
  String get iqamahLabel => _pick('Iqamah', 'ഇഖാമത്ത്', 'الإقامة');
  String get alarmLabel => _pick('Alarm', 'അലാറം', 'المنبه');
  String get prayerAlarmsTitle =>
      _pick('Prayer Alarms', 'നിസ്കാര അലാറം', 'منبهات الصلاة');
  String get masterAlarmToggle => _pick(
        'Enable Prayer Alarms',
        'നിസ്കാര അലാറം ഓൺ ആക്കുക',
        'تفعيل منبهات الصلاة',
      );
  String get masterAlarmDesc => _pick(
        'Turn all active prayer reminders on or off together',
        'അഞ്ച് നേരത്തെ അലാറങ്ങളും ഒരുമിച്ച് ഓൺ/ഓഫ് ചെയ്യാം',
        'تشغيل أو إيقاف جميع منبهات الصلوات معاً',
      );
  String get alarmSoundSettings =>
      _pick('Alarm Sound & Volume', 'അലാറം സൗണ്ട് ക്രമീകരണം', 'صوت المنبه ومستواه');
  String get alarmSoundTypeLabel =>
      _pick('Alarm Sound', 'അലാറം ശബ്ദം', 'صوت التنبيه');
  String get alarmVolumeLabel =>
      _pick('Alarm Volume', 'ശബ്ദത്തിന്റെ അളവ്', 'مستوى الصوت');
  String get alarmVibrateLabel =>
      _pick('Vibrate with Alarm', 'വൈബ്രേഷൻ', 'الاهتزاز مع المنبه');
  String get previewSoundLabel =>
      _pick('Test Sound', 'സൗണ്ട് കേൾക്കുക', 'تجربة الصوت');
  String get stopSoundLabel => _pick('Stop', 'നിർത്തുക', 'إيقاف');
  String get iqamahGapLabel => _pick(
        'Iqamah Delay (after Adhan)',
        'ഇഖാമത്ത് സമയം (ബാങ്കിന് ശേഷം)',
        'وقت الإقامة (بعد الأذان)',
      );
  String get alarmRefLabel =>
      _pick('Alarm Timing', 'അലാറം എപ്പോൾ?', 'توقيت المنبه');
  String get beforeAdhanOption =>
      _pick('Before Adhan', 'ബാങ്കിന് മുമ്പ്', 'قبل الأذان');
  String get relativeToIqamahOption =>
      _pick('Before / After Iqamah', 'ഇഖാമത്തിന് മുമ്പ് / ശേഷം', 'قبل / بعد الإقامة');
  String get minutesBeforeLabel =>
      _pick('Minutes before Adhan', 'ബാങ്കിന് എത്ര മിനിറ്റ് മുമ്പ്', 'دقائق قبل الأذان');
  String get offsetFromIqamahLabel => _pick(
        'Offset from Iqamah (- before / + after)',
        'ഇഖാമത്തിൽ നിന്നുള്ള വ്യത്യാസം (- മുമ്പ് / + ശേഷം)',
        'الفارق عن الإقامة (- قبل / + بعد)',
      );
  String get atIqamahTime => _pick('At Iqamah', 'ഇഖാമത്ത് സമയത്ത്', 'عند الإقامة');
  String safetyBufferNote(String nextName, String limitTime) => _pick(
        'Safety limit: stays at least 10 min before $nextName ($limitTime)',
        'സുരക്ഷാ പരിധി: അടുത്ത $nextName ബാങ്കിന് 10 മിനിറ്റ് മുമ്പ് വരെ ($limitTime)',
        'الحد الآمن: قبل أذان $nextName بـ 10 دقائق على الأقل ($limitTime)',
      );
  String get alarmOffLabel => _pick('Off', 'ഓഫ്', 'إيقاف');
  String get dismissedTodayLabel =>
      _pick('Off today', 'ഇന്ന് ഓഫ്', 'متوقف اليوم');
  String get dismissTodayAlarm => _pick(
        'Dismiss Today\'s Alarm',
        'ഇന്നത്തെ അലാറം ഓഫ് ചെയ്യുക',
        'إيقاف منبه اليوم',
      );
  String get dismissOnlyNote => _pick(
        'Turns off this prayer for today only. Tomorrow rings as scheduled.',
        'ഇന്നത്തെ ഈ നിസ്കാരത്തിന്റെ അലാറം മാത്രം ഓഫാകും. നാളെ വീണ്ടും അടിക്കും.',
        'يوقف تنبيه هذه الصلاة لليوم فقط، وسيعمل غداً كالمعتاد.',
      );
  String get prayerReminderRinging => _pick(
        'Prayer Reminder',
        'നിസ്കാര സമയ അറിയിപ്പ്',
        'تذكير الصلاة',
      );
  String get editScheduleLabel =>
      _pick('Edit Iqamah & Alarm', 'ഇഖാമത്തും അലാറവും മാറ്റുക', 'تعديل الإقامة والمنبه');
  String get minutesUnitShort => _pick('m', 'മി', 'د');

  // Hijri Calendar
  String get hijriCalendarTitle =>
      _pick('Hijri Calendar', 'ഹിജ്രി കലണ്ടർ', 'التقويم الهجري');
  String get hijriAdjustment => _pick(
        'Hijri Moon Adjustment',
        'മാസപ്പിറവി മാറ്റം (-1 / 0 / +1)',
        'تعديل التاريخ الهجري',
      );
  String get todayLabel => _pick('Today', 'ഇന്ന്', 'اليوم');
  String get selectedDayLabel =>
      _pick('Selected Date', 'തിരഞ്ഞെടുത്ത തീയതി', 'التاريخ المحدد');
  String get dayMinusOne => _pick('-1 Day', '-1 ദിവസം', '-1 يوم');
  String get dayZero => _pick('0 (Default)', '0 (സാധാരണ)', '0 (افتراضي)');
  String get dayPlusOne => _pick('+1 Day', '+1 ദിവസം', '+1 يوم');

  // Features Sub-Tabs (Short 1-word labels for clean 4-tab bar)
  String get prayerShortTab => _pick('Prayer', 'നമസ്കാരം', 'الصلاة');
  String get adhkarTab => _pick('Adhkar', 'ദിക്ർ', 'الأذكار');
  String get tasbihTab => _pick('Counter', 'കൗണ്ടർ', 'العدّاد');

  // Offline Daily Duas & Adhkar (Hisnul Muslim)
  String get morningAdhkar => _pick('Morning', 'രാവിലെ', 'الصباح');
  String get eveningAdhkar => _pick('Evening', 'വൈകിട്ട്', 'المساء');
  String get afterSalahAdhkar =>
      _pick('After Salah', 'നിസ്കാര ശേഷം', 'بعد الصلاة');
  String get dailyDuasCategory =>
      _pick('Daily Duas', 'നിത്യ ദുആകൾ', 'أدعية يومية');
  String get allAdhkarLabel => _pick('All', 'എല്ലാം', 'الكل');
  String get favoritesOnlyLabel => _pick('Favorites', 'പ്രിയപ്പെട്ടവ', 'المفضلة');
  String get resetTodayProgress =>
      _pick('Reset Progress', 'റീസെറ്റ്', 'إعادة التصفير');
  String get completedLabel => _pick('Completed', 'പൂർത്തിയായി', 'مكتمل');
  String get hisnulMuslimNote => _pick(
        'Offline Hisnul Muslim & Prophetic Adhkar — Tap card to count',
        'ഓഫ്‌ലൈൻ ഹിസ്നുൽ മുസ്‌ലിം ദിക്റുകളും ദുആകളും — എണ്ണാൻ കാർഡിൽ ടാപ്പ് ചെയ്യുക',
        'حصن المسلم وأذكار يومية بدون إنترنت — اضغط على البطاقة للعد',
      );
  String get noFavoriteAdhkar => _pick(
        'No favorite Adhkar saved yet. Tap the star icon on any Dhikr to save it here.',
        'പ്രിയപ്പെട്ട ദിക്റുകൾ ഒന്നും സേവ് ചെയ്തിട്ടില്ല. നക്ഷത്ര ഐക്കണിൽ ടാപ്പ് ചെയ്ത് സേവ് ചെയ്യാം.',
        'لا توجد أذكار مفضلة بعد. اضغط على أيقونة النجمة لحفظها هنا.',
      );

  // Digital Counter (Tasbih)
  String get tasbihTitle =>
      _pick('Counter', 'കൗണ്ടർ', 'العدّاد');
  String get tapToCount =>
      _pick('Tap circle to count', 'എണ്ണാൻ ടാപ്പ് ചെയ്യുക', 'اضغط هنا للتسبيح');
  String get tapAnywhereLabel =>
      _pick('Tap Anywhere', 'എവിടെയും ടാപ്പ്', 'الضغط بأي مكان');
  String get tapAnywhereHint => _pick(
        'Tap anywhere in this zone to count',
        'ഈ ഭാഗത്ത് എവിടെ തൊട്ടാലും എണ്ണും',
        'اضغط في أي مكان هنا للعد',
      );
  String get targetLabel => _pick('Target', 'ലക്ഷ്യം', 'الهدف');
  String get unlimitedLabel => _pick('Free', 'അൺലിമിറ്റഡ്', 'مفتوح');
  String get todayTotalLabel => _pick('Today', 'ഇന്ന്', 'اليوم');
  String get lifetimeTotalLabel => _pick('Total', 'ആകെ', 'الإجمالي');
  String get addCustomDhikr =>
      _pick('Add Custom Dhikr', 'പുതിയ ദിക്ർ ചേർക്കുക', 'إضافة ذكر مخصص');
  String get customDhikrArabic =>
      _pick('Arabic Text (optional)', 'അറബിക് ടെക്സ്റ്റ് (നിർബന്ധമില്ല)', 'النص العربي (اختياري)');
  String get customDhikrName =>
      _pick('Dhikr Title / Meaning', 'ദിക്ർ പേര് / അർത്ഥം', 'اسم الذكر / المعنى');
  String get vibrateOnTapLabel =>
      _pick('Haptic Vibration', 'ടാപ്പ് വൈബ്രേഷൻ', 'الاهتزاز عند الضغط');
  String get resetCycleLabel => _pick('Reset', 'റീസെറ്റ്', 'تصفير');
  String get deleteCustomLabel =>
      _pick('Remove Custom Dhikr', 'നീക്കം ചെയ്യുക', 'حذف الذكر');

  // Weekly Surah Al-Kahf Reminder
  String get kahfReminderTitle => _pick(
        'Surah Al-Kahf Weekly Reminder',
        'സൂറത്തുൽ കഹ്ഫ് ഓർമ്മപ്പെടുത്തൽ',
        'تذكير سورة الكهف الأسبوعي',
      );
  String get kahfReminderDesc => _pick(
        'Notifies every Thursday evening and Friday morning. Tap the notification to open Surah Al-Kahf directly.',
        'എല്ലാ വ്യാഴാഴ്ച വൈകുന്നേരവും വെള്ളിയാഴ്ച രാവിലെയും ഓർമ്മിപ്പിക്കും. നോട്ടിഫിക്കേഷനിൽ ടാപ്പ് ചെയ്താൽ നേരിട്ട് സൂറത്തുൽ കഹ്ഫ് തുറക്കാം.',
        'ينبّهك كل مساء خميس وصباح جمعة. اضغط على الإشعار لفتح سورة الكهف مباشرة.',
      );
  String get kahfThuLabel =>
      _pick('Thursday Evening', 'വ്യാഴാഴ്ച രാത്രി', 'مساء الخميس');
  String get kahfFriLabel =>
      _pick('Friday Morning', 'വെള്ളിയാഴ്ച രാവിലെ', 'صباح الجمعة');
  String get kahfNotifTitle => _pick(
        'Surah Al-Kahf Reminder',
        'സൂറത്തുൽ കഹ്ഫ് ഓതാൻ സമയമായി',
        'تذكير قراءة سورة الكهف',
      );
  String get kahfNotifBody => _pick(
        'Illuminate your Friday with Surah Al-Kahf. Tap to open Surah 18 directly.',
        'വെള്ളിയാഴ്ചയുടെ പ്രകാശത്തിനായി സൂറത്തുൽ കഹ്ഫ് പാരായണം ചെയ്യുക. തുറക്കാൻ ടാപ്പ് ചെയ്യുക.',
        'نورٌ بين الجمعتين — اضغط لفتح سورة الكهف مباشرة.',
      );
  String get kahfOpenSurahBtn => _pick(
        'Read Surah Al-Kahf',
        'സൂറത്തുൽ കഹ്ഫ് ഓതുക',
        'اقرأ سورة الكهف',
      );
  String get kahfBannerTitle => _pick(
        'Jumu\'ah Reminder — Surah Al-Kahf',
        'ജുമുഅ ഓർമ്മപ്പെടുത്തൽ — സൂറത്തുൽ കഹ്ഫ്',
        'تذكير الجمعة — سورة الكهف',
      );
  String get kahfBannerDesc => _pick(
        'Tap to open Surah Al-Kahf (Surah 18) directly',
        'സൂറത്തുൽ കഹ്ഫ് (18) നേരിട്ട് തുറന്ന് പാരായണം ചെയ്യാം',
        'اضغط لفتح سورة الكهف (18) مباشرة',
      );
  String get testKahfReminder => _pick(
        'Test Reminder Notification',
        'ടെസ്റ്റ് നോട്ടിഫിക്കേഷൻ കാണുക',
        'تجربة الإشعار',
      );
  String get changeTimeLabel =>
      _pick('Change Time', 'സമയം മാറ്റുക', 'تغيير الوقت');
  String get kahfTestWebFeedback => _pick(
        'Surah Al-Kahf reminder active! On Android APK it sends a scheduled notification tapping straight to Surah 18.',
        'സൂറത്തുൽ കഹ്ഫ് റിമൈൻഡർ സജ്ജമാണ്! Android ആപ്പിൽ വ്യാഴം/വെള്ളി ദിവസങ്ങളിൽ നേരിട്ട് നോട്ടിഫിക്കേഷൻ ലഭിക്കും.',
        'التذكير مفعّل! على تطبيق أندرويد يصلك إشعار مجدول يفتح السورة مباشرة.',
      );

  // Android Home Screen Widget Info
  String get homeWidgetTitle => _pick(
        'Home Screen Widget',
        'ഹോം സ്ക്രീൻ വിഡ്ജറ്റ്',
        'أداة الشاشة الرئيسية',
      );
  String get homeWidgetDesc => _pick(
        'Long-press your Android home screen -> Widgets -> "Al-Quran Prayer Times" to view next prayer & Hijri date live without opening the app.',
        'ആപ്പ് തുറക്കാതെ തന്നെ അടുത്ത നിസ്കാര സമയവും ഹിജ്‌രി തീയതിയും കാണാൻ ഫോൺ ഹോം സ്ക്രീനിൽ ലോങ്-പ്രസ് ചെയ്ത് Widgets -> "Al-Quran Prayer Times" ചേർക്കുക.',
        'اضغط مطولاً على شاشة هاتفك -> التطبيقات المصغرة -> "Al-Quran Prayer Times" لمتابعة الصلاة القادمة والتاريخ الهجري مباشرة.',
      );

  // Dashboard & Navigation
  String get dashboardTab => _pick('Dashboard', 'ഡാഷ്‌ബോർഡ്', 'الرئيسية');
  String get dashboardTitle => _pick('Dashboard', 'ഡാഷ്‌ബോർഡ്', 'لوحة التحكم');
  String get dashboardSearchHint => _pick(
        'Search Surah, features, 99 Names, or Adhkar...',
        'സൂറത്ത്, ഫീച്ചറുകൾ, 99 നാമങ്ങൾ, ദിക്ർ തിരയുക...',
        'ابحث عن سورة أو ميزة أو اسم أو ذكر...',
      );
  String get recentActivityTitle =>
      _pick('Recent Activity', 'സമീപകാല പ്രവർത്തനങ്ങൾ', 'النشاطات الأخيرة');
  String get recentActivityEmpty => _pick(
        'Your last 7 actions will appear here for quick access.',
        'നിങ്ങൾ അവസാനം ചെയ്ത 7 പ്രവർത്തനങ്ങൾ വേഗത്തിൽ തുറക്കാൻ ഇവിടെ കാണാം.',
        'ستظهر آخر 7 نشاطات قمت بها هنا للوصول السريع.',
      );
  String get clearHistoryLabel => _pick('Clear', 'മായ്ക്കുക', 'مسح');
  String get quickActionsTitle =>
      _pick('All Features & Tools', 'പ്രധാന വിഭാഗങ്ങൾ', 'جميع الأدوات');
  String get noSearchResults => _pick(
        'No matching Surah, tool, Name, or Dhikr found.',
        'യോജിച്ച സൂറത്തോ ഫീച്ചറോ നാമമോ കണ്ടെത്താനായില്ല.',
        'لم يتم العثور على نتائج مطابقة.',
      );

  // 12 Dashboard Grid Titles
  String get actionReadQuran => _pick('Read Quran', 'ഖുർആൻ വായന', 'قراءة القرآن');
  String get actionJuz => _pick('Juz Index', 'ജുസ്അ്', 'الأجزاء');
  String get actionBookmarks => _pick('Bookmarks', 'ബുക്ക്‌മാർക്ക്', 'المحفوظات');
  String get actionPrayer => _pick('Prayer Times', 'നിസ്കാര സമയം', 'أوقات الصلاة');
  String get actionHijri => _pick('Hijri Calendar', 'ഹിജ്‌രി കലണ്ടർ', 'التقويم الهجري');
  String get actionAutoSilent => _pick('Auto-Silent', 'ഓട്ടോ സൈലന്റ്', 'الصامت التلقائي');
  String get actionAdhkar => _pick('Daily Adhkar', 'ദിക്ർ & ദുആ', 'الأذكار اليومية');
  String get actionCounter => _pick('Counter', 'കൗണ്ടർ', 'العدّاد');
  String get actionNames99 => _pick('99 Names', '99 നാമങ്ങൾ', 'أسماء الله');
  String get actionTajweed => _pick('Tajweed Guide', 'തജ്‌വീദ് നിയമം', 'أحكام التجويد');
  String get actionExport => _pick('Export PDF', 'എക്സ്പോർട്ട്', 'تصدير PDF');
  String get actionSettings => _pick('Settings', 'സെറ്റിംഗ്സ്', 'الإعدادات');

  // Tajweed Color Coding
  String get tajweedGuideTitle =>
      _pick('Tajweed Color Guide', 'തജ്‌വീദ് കളർ ഗൈഡ്', 'دليل ألوان التجويد');
  String get tajweedLegendShort => _pick('Color Key', 'കളർ ഗൈഡ്', 'الألوان');
  String get tajweedTapHint => _pick(
        'Tajweed colors active · Tap any colored word to see its rule',
        'തജ്‌വീദ് നിറങ്ങൾ സജീവം · നിയമം കാണാൻ നിറമുള്ള ഭാഗത്ത് ടാപ്പ് ചെയ്യുക',
        'ألوان التجويد مفعّلة · اضغط على أي كلمة ملونة لعرض الحكم',
      );
  String get tajweedRuleHeader =>
      _pick('Tajweed Rule', 'തജ്‌വീദ് നിയമം', 'حكم التجويد');
  String get tajweedExamplesLabel =>
      _pick('Examples', 'ഉദാഹരണങ്ങൾ', 'أمثلة');
  String get tajweedFullGuideBtn => _pick(
        'Open Full Tajweed Color Guide',
        'മുഴുവൻ തജ്‌വീദ് കളർ ഗൈഡും കാണുക',
        'عرض دليل ألوان التجويد الكامل',
      );

  // 99 Names of Allah (Asmaul Husna)
  String get names99Tab => _pick('99 Names', 'നാമങ്ങൾ', 'الأسماء');
  String get names99Title => _pick(
        '99 Names of Allah (Asmaul Husna)',
        'അല്ലാഹുവിന്റെ 99 നാമങ്ങൾ (അസ്മാഉൽ ഹുസ്ന)',
        'أسماء الله الحسنى (99 اسماً)',
      );
  String get names99SearchHint => _pick(
        'Search by number, Arabic, English, or Malayalam...',
        'നമ്പർ, അറബിക്, ഇംഗ്ലീഷ് അല്ലെങ്കിൽ മലയാളം വഴി തിരയുക...',
        'ابحث بالرقم أو الاسم أو المعنى...',
      );
  String get meaningEnglishLabel =>
      _pick('English Meaning', 'ഇംഗ്ലീഷ് അർത്ഥം', 'المعنى بالإنجليزية');
  String get meaningMalayalamLabel =>
      _pick('Malayalam Meaning', 'മലയാളം അർത്ഥം', 'المعنى بالمالايالامية');
  String get reflectionLabel =>
      _pick('Reflection', 'ആശയം / വിവരണം', 'التدبر والتأمل');
  String get copiedNameNotice =>
      _pick('Copied to clipboard', 'കോപ്പി ചെയ്തു', 'تم النسخ');

  // Auto-Silent (DND) during Prayer
  String get autoSilentTitle => _pick(
        'Auto-Silent (DND) during Prayer',
        'നിസ്കാര സമയത്ത് ഓട്ടോ സൈലന്റ് (DND)',
        'الوضع الصامت التلقائي وقت الصلاة',
      );
  String get autoSilentDesc => _pick(
        'Automatically switches phone to Do Not Disturb from Iqamah time and restores previous sound after the selected duration.',
        'ഇഖാമത്ത് സമയത്ത് ഫോൺ തനിയെ സൈലന്റ് (DND) മോഡിലാക്കുകയും, നിശ്ചിത മിനിറ്റിന് ശേഷം പഴയപടിയാക്കുകയും ചെയ്യും.',
        'يحول الهاتف إلى وضع عدم الإزعاج تلقائياً عند الإقامة ويعيد الصوت كما كان بعد انتهاء المدة.',
      );
  String get autoSilentDurationLabel =>
      _pick('Silent Duration from Iqamah', 'ഇഖാമത്ത് മുതൽ സൈലന്റ് സമയം', 'مدة الصامت من الإقامة');
  String get dndPermissionGranted => _pick(
        'Do Not Disturb access granted',
        'DND അനുമതി നൽകിയിട്ടുണ്ട്',
        'تم منح صلاحية عدم الإزعاج',
      );
  String get dndPermissionNeeded => _pick(
        'DND Policy Access required to silence phone',
        'ഫോൺ സൈലന്റ് ആക്കാൻ DND അനുമതി ആവശ്യമാണ്',
        'مطلوب صلاحية عدم الإزعاج لتفعيل الصامت',
      );
  String get grantDndPermissionBtn =>
      _pick('Grant DND Access', 'അനുമതി നൽകുക', 'منح الصلاحية');
  String get dndActiveNowBanner => _pick(
        'Prayer Auto-Silent is currently active',
        'നിസ്കാര ഓട്ടോ-സൈലന്റ് ഇപ്പോൾ സജീവമാണ്',
        'وضع الصامت للصلاة مفعّل الآن',
      );
  String get restoreSoundNowBtn =>
      _pick('Restore Sound Now', 'സൗണ്ട് പഴയപടിയാക്കുക', 'إعادة الصوت الآن');
  String get autoSilentWebNote => _pick(
        'Your Auto-Silent preference (15 min default from Iqamah) is saved. System DND executes natively on the Android app.',
        'നിങ്ങളുടെ ഓട്ടോ-സൈലന്റ് സെറ്റിംഗ് സേവ് ചെയ്തിട്ടുണ്ട്. യഥാർത്ഥ ഫോൺ DND Android ആപ്പിലാണ് പ്രവർത്തിക്കുക.',
        'تم حفظ إعداد الصامت التلقائي. يعمل الوضع الصامت للنظام على تطبيق أندرويد.',
      );
  String get autoSilentPrayersLabel => _pick(
        'Prayers for Auto-Silent',
        'ഓട്ടോ-സൈലന്റ് വേണ്ട നമസ്കാരങ്ങൾ',
        'الصلوات المفعّلة للصامت',
      );
  String get exactAlarmNeeded => _pick(
        'Allow "Alarms & reminders" for exact Auto-Silent timing',
        'കൃത്യസമയത്ത് സൈലന്റ് ആകാൻ Alarms & reminders അനുമതി നൽകുക',
        'اسمح بصلاحية المنبهات والتذكيرات لتفعيل الصامت في وقته',
      );
  String get grantExactAlarmBtn => _pick(
        'Allow Exact Time',
        'അനുമതി നൽകുക',
        'السماح بالوقت الدقيق',
      );
  String get silentWindowPrefix =>
      _pick('Silent', 'സൈലന്റ്', 'صامت');
  String get dailyNameTitle => _pick(
        'Name of the Day · Asmaul Husna',
        'ഇന്നത്തെ നാമം · അസ്മാഉൽ ഹുസ്ന',
        'اسم اليوم من الأسماء الحسنى',
      );
  String get dailyTajweedTitle => _pick(
        'Daily Tajweed Rule',
        'ഇന്നത്തെ തജ്‌വീദ് നിയമം',
        'حكم التجويد اليومي',
      );
  String get categoriesTitle => _pick(
        'Categories',
        'മറ്റ് വിഭാഗങ്ങൾ',
        'التصنيفات والأقسام',
      );
  String get viewMeaningBtn => _pick(
        'View Details',
        'വിവരണം കാണുക',
        'عرض التفاصيل',
      );
  String get exploreRuleBtn => _pick(
        'Explore Rule',
        'നിയമം കാണുക',
        'عرض الحكم',
      );
  String get ruleLanguageLabel => _pick(
        'Explanation Language',
        'വിശദീകരണ ഭാഷ',
        'لغة الشرح',
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
