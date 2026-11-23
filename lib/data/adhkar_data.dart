import '../models/adhkar_tasbih_model.dart';

class AdhkarCatalog {
  static const List<String> categoryKeys = [
    'morning',
    'evening',
    'after_salah',
    'daily_duas',
  ];

  static const List<AdhkarEntry> entries = [
    // -------------------------------------------------------------------------
    // MORNING ADHKAR
    // -------------------------------------------------------------------------
    AdhkarEntry(
      id: 'am_ayat_kursi',
      category: 'morning',
      titleEn: 'Ayat al-Kursi',
      titleMl: 'ആയത്തുൽ കുർസി',
      arabic:
          'اللَّهُ لَا إِلَٰهَ إِلَّا هُوَ الْحَيُّ الْقَيُّومُ ۚ لَا تَأْخُذُهُ سِنَةٌ وَلَا نَوْمٌ ۚ لَّهُ مَا فِي السَّمَاوَاتِ وَمَا فِي الْأَرْضِ ۗ مَن ذَا الَّذِي يَشْفَعُ عِندَهُ إِلَّا بِإِذْنِهِ ۚ يَعْلَمُ مَا بَيْنَ أَيْدِيهِمْ وَمَا خَلْفَهُمْ ۖ وَلَا يُحِيطُونَ بِشَيْءٍ مِّنْ عِلْمِهِ إِلَّا بِمَا شَاءَ ۚ وَسِعَ كُرْسِيُّهُ السَّمَاوَاتِ وَالْأَرْضَ ۖ وَلَا يَئُودُهُ حِفْظُهُمَا ۚ وَهُوَ الْعَلِيُّ الْعَظِيمُ',
      translationEn:
          'Allah — there is no deity except Him, the Ever-Living, the Sustainer of existence. Neither drowsiness overtakes Him nor sleep. His is whatever is in the heavens and whatever is on the earth.',
      translationMl:
          'അല്ലാഹു അല്ലാതെ മറ്റൊരു ആരാധ്യനില്ല. അവൻ എന്നെന്നും ജീവിച്ചിരിക്കുന്നവനും സർവ്വനിയന്താവുമാണ്. മയക്കമോ ഉറക്കമോ അവനെ ബാധിക്കുകയില്ല. ആകാശഭൂമികളിലുള്ളതെല്ലാം അവന്റേതാണ്.',
      reference: 'Al-Baqarah 2:255 · Al-Hakim',
      targetCount: 1,
    ),
    AdhkarEntry(
      id: 'am_three_quls',
      category: 'morning',
      titleEn: 'Al-Ikhlas, Al-Falaq & An-Nas',
      titleMl: 'സൂറത്ത് ഇഖ്‌ലാസ്, ഫലഖ്, നാസ്',
      arabic:
          'قُلْ هُوَ اللَّهُ أَحَدٌ ۝ قُلْ أَعُوذُ بِرَبِّ الْفَلَقِ ۝ قُلْ أَعُوذُ بِرَبِّ النَّاسِ',
      translationEn:
          'Recite Surah Al-Ikhlas, Surah Al-Falaq, and Surah An-Nas three times each morning for complete sufficiency and protection.',
      translationMl:
          'രാവിലെ മൂന്ന് പ്രാവശ്യം വീതം ഖുൽ ഹുവല്ലാഹു അഹദ്, ഖുൽ അഊദു ബിറബ്ബിൽ ഫലഖ്, ഖുൽ അഊദു ബിറബ്ബിന്നാസ് എന്നിവ ഓതുക; എല്ലാ വിഷമങ്ങളിൽ നിന്നും സംരക്ഷണം ലഭിക്കും.',
      reference: 'Abu Dawud · At-Tirmidhi',
      targetCount: 3,
    ),
    AdhkarEntry(
      id: 'am_asbahna',
      category: 'morning',
      titleEn: 'Morning Praise & Sovereignty',
      titleMl: 'പ്രഭാത സ്തുതിയും തവക്കുലും',
      arabic:
          'أَصْبَحْنَا وَأَصْبَحَ الْمُلْكُ لِلَّهِ، وَالْحَمْدُ لِلَّهِ، لَا إِلَٰهَ إِلَّا اللَّهُ وَحْدَهُ لَا شَرِيكَ لَهُ، لَهُ الْمُلْكُ وَلَهُ الْحَمْدُ وَهُوَ عَلَىٰ كُلِّ شَيْءٍ قَدِيرٌ',
      translationEn:
          'We have reached the morning and all sovereignty belongs to Allah. All praise is for Allah. None has the right to be worshipped except Allah alone; He has power over all things.',
      translationMl:
          'ഞങ്ങളും സർവ്വാധിപത്യവും അല്ലാഹുവിന്റെതായ പ്രഭാതത്തിലേക്ക് പ്രവേശിച്ചിരിക്കുന്നു. സർവ്വസ്തുതിയും അല്ലാഹുവിന്. അവനല്ലാതെ ആരാധ്യനില്ല, അവൻ സർവ്വശക്തനാണ്.',
      reference: 'Sahih Muslim 2723',
      targetCount: 1,
    ),
    AdhkarEntry(
      id: 'am_sayyid_istighfar',
      category: 'morning',
      titleEn: 'Master Supplication for Forgiveness',
      titleMl: 'സയ്യിദുൽ ഇസ്തിഗ്ഫാർ (പാപമോചന പ്രാർത്ഥന)',
      arabic:
          'اللَّهُمَّ أَنْتَ رَبِّي لَا إِلَٰهَ إِلَّا أَنْتَ، خَلَقْتَنِي وَأَنَا عَبْدُكَ، وَأَنَا عَلَىٰ عَهْدِكَ وَوَعْدِكَ مَا اسْتَطَعْتُ، أَعُوذُ بِكَ مِنْ شَرِّ مَا صَنَعْتُ، أَبُوءُ لَكَ بِنِعْمَتِكَ عَلَيَّ، وَأَبُوءُ بِذَنْبِي فَاغْفِرْ لِي فَإِنَّهُ لَا يَغْفِرُ الذُّنُوبَ إِلَّا أَنْتَ',
      translationEn:
          'O Allah, You are my Lord, none has the right to be worshipped except You. You created me and I am Your servant. I acknowledge Your favor upon me and confess my sin, so forgive me, for none forgives sins except You.',
      translationMl:
          'അല്ലാഹുവേ, നീ എന്റെ രക്ഷിതാവാണ്; നീയല്ലാതെ ആരാധ്യനില്ല. നീ എന്നെ സൃഷ്ടിച്ചു, ഞാൻ നിന്റെ അടിമയാണ്. നീ എനിക്ക് നൽകിയ അനുഗ്രഹങ്ങളും എന്റെ തെറ്റുകളും ഞാൻ ഏറ്റുപറയുന്നു. എനിക്ക് പൊറുത്തുതരേണമേ.',
      reference: 'Sahih al-Bukhari 6306',
      targetCount: 1,
    ),
    AdhkarEntry(
      id: 'am_bismillah_protect',
      category: 'morning',
      titleEn: 'Shield From All Harm',
      titleMl: 'എല്ലാ ഉപദ്രവങ്ങളിൽ നിന്നും കാവൽ',
      arabic:
          'بِسْمِ اللَّهِ الَّذِي لَا يَضُرُّ مَعَ اسْمِهِ شَيْءٌ فِي الْأَرْضِ وَلَا فِي السَّمَاءِ وَهُوَ السَّمِيعُ الْعَلِيمُ',
      translationEn:
          'In the Name of Allah, with whose Name nothing on earth or in heaven can cause harm, and He is the All-Hearing, All-Knowing.',
      translationMl:
          'ആകാശത്തോ ഭൂമിയിലോ ഉള്ള യാതൊന്നിനും തന്റെ നാമത്തോടൊപ്പം ഉപദ്രവം ചെയ്യാൻ കഴിയാത്ത അല്ലാഹുവിന്റെ നാമത്തിൽ (ഞാൻ രാവിലെ ആക്കുന്നു). അവൻ എല്ലാം കേൾക്കുന്നവനും അറിയുന്നവനുമാണ്.',
      reference: 'Abu Dawud · At-Tirmidhi',
      targetCount: 3,
    ),
    AdhkarEntry(
      id: 'am_raditu',
      category: 'morning',
      titleEn: 'Contentment With Allah & Islam',
      titleMl: 'അല്ലാഹുവിനെയും ഇസ്‌ലാമിനെയും തൃപ്തിപ്പെടൽ',
      arabic:
          'رَضِيتُ بِاللَّهِ رَبًّا، وَبِالْإِسْلَامِ دِينًا، وَبِمُحَمَّدٍ صَلَّى اللَّهُ عَلَيْهِ وَسَلَّمَ نَبِيًّا',
      translationEn:
          'I am pleased with Allah as my Lord, with Islam as my religion, and with Muhammad (peace be upon him) as my Prophet.',
      translationMl:
          'അല്ലാഹുവിനെ രക്ഷിതാവായും ഇസ്‌ലാമിനെ മതമായും മുഹമ്മദ് നബി(സ)യെ പ്രവാചകനായും ഞാൻ തൃപ്തിപ്പെട്ടിരിക്കുന്നു.',
      reference: 'Ahmad · Abu Dawud',
      targetCount: 3,
    ),
    AdhkarEntry(
      id: 'am_hasbi_allah',
      category: 'morning',
      titleEn: 'Sufficiency of Allah',
      titleMl: 'എനിക്ക് അല്ലാഹു മതി',
      arabic:
          'حَسْبِيَ اللَّهُ لَا إِلَٰهَ إِلَّا هُوَ عَلَيْهِ تَوَكَّلْتُ وَهُوَ رَبُّ الْعَرْشِ الْعَظِيمِ',
      translationEn:
          'Allah is sufficient for me; there is no deity except Him. Upon Him I rely, and He is the Lord of the Mighty Throne.',
      translationMl:
          'എനിക്ക് അല്ലാഹു മതി; അവനല്ലാതെ മറ്റൊരു ആരാധ്യനില്ല. അവനിലാണ് ഞാൻ ഭരമേൽപ്പിച്ചിരിക്കുന്നത്. അവൻ മഹത്തായ അർശിന്റെ നാഥനാണ്.',
      reference: 'Abu Dawud 5081',
      targetCount: 7,
    ),
    AdhkarEntry(
      id: 'am_subhanallah_bihamdih',
      category: 'morning',
      titleEn: 'Tasbih & Praise',
      titleMl: 'തസ്ബീഹും സ്തുതിയും',
      arabic: 'سُبْحَانَ اللَّهِ وَبِحَمْدِهِ',
      translationEn: 'Glory be to Allah and praise be to Him.',
      translationMl: 'അല്ലാഹു എത്രയോ പരിശുദ്ധൻ! അവന് സർവ്വസ്തുതിയും.',
      reference: 'Sahih Muslim 2692',
      targetCount: 100,
    ),

    // -------------------------------------------------------------------------
    // EVENING ADHKAR
    // -------------------------------------------------------------------------
    AdhkarEntry(
      id: 'pm_ayat_kursi',
      category: 'evening',
      titleEn: 'Ayat al-Kursi',
      titleMl: 'ആയത്തുൽ കുർസി',
      arabic:
          'اللَّهُ لَا إِلَٰهَ إِلَّا هُوَ الْحَيُّ الْقَيُّومُ ۚ لَا تَأْخُذُهُ سِنَةٌ وَلَا نَوْمٌ ۚ لَّهُ مَا فِي السَّمَاوَاتِ وَمَا فِي الْأَرْضِ',
      translationEn:
          'Recite Ayat al-Kursi every evening for divine protection throughout the night until morning.',
      translationMl:
          'വൈകുന്നേരം ആയത്തുൽ കുർസി ഓതിയാൽ പ്രഭാതം വരെ അല്ലാഹുവിന്റെ സംരക്ഷണം ലഭിക്കുന്നതാണ്.',
      reference: 'Al-Baqarah 2:255 · Al-Hakim',
      targetCount: 1,
    ),
    AdhkarEntry(
      id: 'pm_three_quls',
      category: 'evening',
      titleEn: 'Al-Ikhlas, Al-Falaq & An-Nas',
      titleMl: 'സൂറത്ത് ഇഖ്‌ലാസ്, ഫലഖ്, നാസ്',
      arabic:
          'قُلْ هُوَ اللَّهُ أَحَدٌ ۝ قُلْ أَعُوذُ بِرَبِّ الْفَلَقِ ۝ قُلْ أَعُوذُ بِرَبِّ النَّاسِ',
      translationEn:
          'Recite the three Quls three times each evening for safety from every evil and hardship.',
      translationMl:
          'വൈകുന്നേരം മൂന്ന് പ്രാവശ്യം വീതം ഇഖ്‌ലാസ്, ഫലഖ്, നാസ് സൂറത്തുകൾ ഓതുക.',
      reference: 'Abu Dawud · At-Tirmidhi',
      targetCount: 3,
    ),
    AdhkarEntry(
      id: 'pm_amsayna',
      category: 'evening',
      titleEn: 'Evening Praise & Sovereignty',
      titleMl: 'സായാഹ്ന സ്തുതിയും തവക്കുലും',
      arabic:
          'أَمْسَيْنَا وَأَمْسَى الْمُلْكُ لِلَّهِ، وَالْحَمْدُ لِلَّهِ، لَا إِلَٰهَ إِلَّا اللَّهُ وَحْدَهُ لَا شَرِيكَ لَهُ، لَهُ الْمُلْكُ وَلَهُ الْحَمْدُ وَهُوَ عَلَىٰ كُلِّ شَيْءٍ قَدِيرٌ',
      translationEn:
          'We have reached the evening and all sovereignty belongs to Allah. Praise be to Allah. None has the right to be worshipped except Allah alone; He has power over all things.',
      translationMl:
          'ഞങ്ങളും സർവ്വാധിപത്യവും അല്ലാഹുവിന്റേതായ സായാഹ്നത്തിലേക്ക് പ്രവേശിച്ചിരിക്കുന്നു. സർവ്വസ്തുതിയും അല്ലാഹുവിന്.',
      reference: 'Sahih Muslim 2723',
      targetCount: 1,
    ),
    AdhkarEntry(
      id: 'pm_audhu_bikalimat',
      category: 'evening',
      titleEn: 'Protection From Evil Creation',
      titleMl: 'സൃഷ്ടികളുടെ ദോഷത്തിൽ നിന്നും അഭയം',
      arabic:
          'أَعُوذُ بِكَلِمَاتِ اللَّهِ التَّامَّاتِ مِنْ شَرِّ مَا خَلَقَ',
      translationEn:
          'I seek refuge in the perfect words of Allah from the evil of what He has created.',
      translationMl:
          'അല്ലാഹു സൃഷ്ടിച്ചവയുടെ ഉപദ്രവങ്ങളിൽ നിന്നും അവന്റെ പരിപൂർണ്ണമായ വചനങ്ങൾ കൊണ്ട് ഞാൻ അഭയം തേടുന്നു.',
      reference: 'Sahih Muslim 2708',
      targetCount: 3,
    ),
    AdhkarEntry(
      id: 'pm_bismillah_protect',
      category: 'evening',
      titleEn: 'Shield From All Harm',
      titleMl: 'എല്ലാ ഉപദ്രവങ്ങളിൽ നിന്നും കാവൽ',
      arabic:
          'بِسْمِ اللَّهِ الَّذِي لَا يَضُرُّ مَعَ اسْمِهِ شَيْءٌ فِي الْأَرْضِ وَلَا فِي السَّمَاءِ وَهُوَ السَّمِيعُ الْعَلِيمُ',
      translationEn:
          'In the Name of Allah, with whose Name nothing on earth or in heaven can cause harm, and He is the All-Hearing, All-Knowing.',
      translationMl:
          'ആകാശഭൂമികളിലുള്ള യാതൊന്നിനും ഉപദ്രവിക്കാൻ കഴിയാത്ത അല്ലാഹുവിന്റെ നാമത്തിൽ. അവൻ എല്ലാം കേൾക്കുന്നവനും അറിയുന്നവനുമാണ്.',
      reference: 'Abu Dawud · At-Tirmidhi',
      targetCount: 3,
    ),
    AdhkarEntry(
      id: 'pm_sayyid_istighfar',
      category: 'evening',
      titleEn: 'Master Supplication for Forgiveness',
      titleMl: 'സയ്യിദുൽ ഇസ്തിഗ്ഫാർ',
      arabic:
          'اللَّهُمَّ أَنْتَ رَبِّي لَا إِلَٰهَ إِلَّا أَنْتَ، خَلَقْتَنِي وَأَنَا عَبْدُكَ، وَأَنَا عَلَىٰ عَهْدِكَ وَوَعْدِكَ مَا اسْتَطَعْتُ، أَعُوذُ بِكَ مِنْ شَرِّ مَا صَنَعْتُ، أَبُوءُ لَكَ بِنِعْمَتِكَ عَلَيَّ، وَأَبُوءُ بِذَنْبِي فَاغْفِرْ لِي فَإِنَّهُ لَا يَغْفِرُ الذُّنُوبَ إِلَّا أَنْتَ',
      translationEn:
          'O Allah, You are my Lord, none has the right to be worshipped except You. I confess my sins and acknowledge Your grace; forgive me.',
      translationMl:
          'അല്ലാഹുവേ, നീ എന്റെ രക്ഷിതാവാണ്. നീയല്ലാതെ ആരാധ്യനില്ല. എന്റെ പാപങ്ങൾ പൊറുത്തുതരേണമേ.',
      reference: 'Sahih al-Bukhari 6306',
      targetCount: 1,
    ),
    AdhkarEntry(
      id: 'pm_ya_hayyu',
      category: 'evening',
      titleEn: 'Seeking Rectification of Affairs',
      titleMl: 'കാര്യങ്ങളെല്ലാം നന്നാക്കിത്തരാൻ പ്രാർത്ഥന',
      arabic:
          'يَا حَيُّ يَا قَيُّومُ بِرَحْمَتِكَ أَسْتَغِيثُ أَصْلِحْ لِي شَأْنِي كُلَّهُ وَلَا تَكِلْنِي إِلَىٰ نَفْسِي طَرْفَةَ عَيْنٍ',
      translationEn:
          'O Ever-Living, O Sustainer, in Your mercy I seek relief; rectify all my affairs and do not leave me to myself even for the blink of an eye.',
      translationMl:
          'എന്നെന്നും ജീവിച്ചിരിക്കുന്നവനും സർവ്വനിയന്താവുമായ അല്ലാഹുവേ, നിന്റെ കാരുണ്യത്താൽ ഞാൻ സഹായം തേടുന്നു. എന്റെ എല്ലാ കാര്യങ്ങളും നന്നാക്കിത്തരേണമേ; കണ്ണിമവെട്ടുന്ന നേരം പോലും എന്നെ എന്റെ സ്വന്തം ഇഷ്ടത്തിന് വിട്ടേക്കരുതേ.',
      reference: 'An-Nasa\'i · Al-Hakim',
      targetCount: 1,
    ),

    // -------------------------------------------------------------------------
    // AFTER-SALAH ADHKAR
    // -------------------------------------------------------------------------
    AdhkarEntry(
      id: 'salah_istighfar',
      category: 'after_salah',
      titleEn: 'Istighfar After Salam',
      titleMl: 'സലാം വീട്ടിയ ഉടനെയുള്ള ഇസ്തിഗ്ഫാർ',
      arabic: 'أَسْتَغْفِرُ اللَّهَ',
      translationEn: 'I seek the forgiveness of Allah.',
      translationMl: 'ഞാൻ അല്ലാഹുവിനോട് പാപമോചനം തേടുന്നു.',
      reference: 'Sahih Muslim 591',
      targetCount: 3,
    ),
    AdhkarEntry(
      id: 'salah_salam',
      category: 'after_salah',
      titleEn: 'Allahumma Antas-Salam',
      titleMl: 'അല്ലാഹുമ്മ അൻതസ്സലാം',
      arabic:
          'اللَّهُمَّ أَنْتَ السَّلَامُ وَمِنْكَ السَّلَامُ، تَبَارَكْتَ يَا ذَا الْجَلَالِ وَالْإِكْرَامِ',
      translationEn:
          'O Allah, You are Peace and from You comes peace. Blessed are You, O Possessor of Majesty and Honor.',
      translationMl:
          'അല്ലാഹുവേ, നീയാണ് സമാധാനം; നിന്നിൽ നിന്നാണ് സമാധാനം ഉണ്ടാകുന്നത്. പ്രതാപവാനും ആദരണീയനുമായവനേ, നീ അനുഗ്രഹപൂർണ്ണനാണ്.',
      reference: 'Sahih Muslim 591',
      targetCount: 1,
    ),
    AdhkarEntry(
      id: 'salah_subhanallah',
      category: 'after_salah',
      titleEn: 'Tasbih (SubhanAllah)',
      titleMl: 'സുബ്ഹാനല്ലാഹ് (33 തവണ)',
      arabic: 'سُبْحَانَ اللَّهِ',
      translationEn: 'Glory be to Allah.',
      translationMl: 'അല്ലാഹു എത്രയോ പരിശുദ്ധൻ.',
      reference: 'Sahih Muslim 597',
      targetCount: 33,
    ),
    AdhkarEntry(
      id: 'salah_alhamdulillah',
      category: 'after_salah',
      titleEn: 'Tahmid (Alhamdulillah)',
      titleMl: 'അൽഹംദുലില്ലാഹ് (33 തവണ)',
      arabic: 'الْحَمْدُ لِلَّهِ',
      translationEn: 'All praise is due to Allah.',
      translationMl: 'സർവ്വസ്തുതിയും അല്ലാഹുവിന്.',
      reference: 'Sahih Muslim 597',
      targetCount: 33,
    ),
    AdhkarEntry(
      id: 'salah_allahuakbar',
      category: 'after_salah',
      titleEn: 'Takbir (Allahu Akbar)',
      titleMl: 'അല്ലാഹു അക്ബർ (33 തവണ)',
      arabic: 'اللَّهُ أَكْبَرُ',
      translationEn: 'Allah is the Greatest.',
      translationMl: 'അല്ലാഹു ഏറ്റവും മഹാനാണ്.',
      reference: 'Sahih Muslim 597',
      targetCount: 33,
    ),
    AdhkarEntry(
      id: 'salah_complete_100',
      category: 'after_salah',
      titleEn: 'Completing the Hundredth',
      titleMl: 'നൂറാമത്തെ ദിക്ർ (തൗഹീദ്)',
      arabic:
          'لَا إِلَٰهَ إِلَّا اللَّهُ وَحْدَهُ لَا شَرِيكَ لَهُ، لَهُ الْمُلْكُ وَلَهُ الْحَمْدُ وَهُوَ عَلَىٰ كُلِّ شَيْءٍ قَدِيرٌ',
      translationEn:
          'None has the right to be worshipped except Allah alone, without partner; to Him belongs all sovereignty and praise, and He is Omnipotent.',
      translationMl:
          'ഏകനായ അല്ലാഹു അല്ലാതെ ആരാധ്യനില്ല. അവന് പങ്കുകാരില്ല. അധികാരവും സ്തുതിയും അവനാണ്; അവൻ സർവ്വശക്തനാണ്.',
      reference: 'Sahih Muslim 597',
      targetCount: 1,
    ),
    AdhkarEntry(
      id: 'salah_help_worship',
      category: 'after_salah',
      titleEn: 'Dua for Gratitude & Excellence in Worship',
      titleMl: 'ദിക്റിലും ശുക്റിലും സഹായം തേടൽ',
      arabic:
          'اللَّهُمَّ أَعِنِّي عَلَىٰ ذِكْرِكَ وَشُكْرِكَ وَحُسْنِ عِبَادَتِكَ',
      translationEn:
          'O Allah, help me to remember You, to give thanks to You, and to worship You in the best of manners.',
      translationMl:
          'അല്ലാഹുവേ, നിന്നെ സ്മരിക്കാനും നിനക്ക് നന്ദി കാണിക്കാനും നിന്നെ ഏറ്റവും നന്നായി ആരാധിക്കാനും എന്നെ സഹായിക്കേണമേ.',
      reference: 'Abu Dawud 1522',
      targetCount: 1,
    ),

    // -------------------------------------------------------------------------
    // DAILY DUAS (HISNUL MUSLIM)
    // -------------------------------------------------------------------------
    AdhkarEntry(
      id: 'dua_sleep',
      category: 'daily_duas',
      titleEn: 'Before Sleeping',
      titleMl: 'ഉറങ്ങാൻ കിടക്കുമ്പോൾ',
      arabic: 'بِاسْمِكَ اللَّهُمَّ أَمُوتُ وَأَحْيَا',
      translationEn: 'In Your name, O Allah, I die and I live.',
      translationMl: 'അല്ലാഹുവേ, നിന്റെ നാമത്തിൽ ഞാൻ മരിക്കുകയും ജീവിക്കുകയും ചെയ്യുന്നു.',
      reference: 'Sahih al-Bukhari 6324',
      targetCount: 1,
    ),
    AdhkarEntry(
      id: 'dua_wake',
      category: 'daily_duas',
      titleEn: 'Upon Waking Up',
      titleMl: 'ഉറക്കത്തിൽ നിന്ന് ഉണരുമ്പോൾ',
      arabic:
          'الْحَمْدُ لِلَّهِ الَّذِي أَحْيَانَا بَعْدَ مَا أَمَاتَنَا وَإِلَيْهِ النُّشُورُ',
      translationEn:
          'All praise is for Allah who gave us life after having taken it from us, and unto Him is the resurrection.',
      translationMl:
          'നമ്മെ മരിപ്പിച്ചതിനുശേഷം (ഉറക്കിയതിനുശേഷം) വീണ്ടും ജീവിപ്പിച്ച അല്ലാഹുവിനാണ് സർവ്വസ്തുതിയും. അവനിലേക്കാണ് പുനരുത്ഥാനം.',
      reference: 'Sahih al-Bukhari 6312',
      targetCount: 1,
    ),
    AdhkarEntry(
      id: 'dua_leave_home',
      category: 'daily_duas',
      titleEn: 'Leaving the Home',
      titleMl: 'വീട്ടിൽ നിന്ന് പുറത്തിറങ്ങുമ്പോൾ',
      arabic:
          'بِسْمِ اللَّهِ، تَوَكَّلْتُ عَلَى اللَّهِ، وَلَا حَوْلَ وَلَا قُوَّةَ إِلَّا بِاللَّهِ',
      translationEn:
          'In the name of Allah, I place my trust in Allah; there is no might and no power except by Allah.',
      translationMl:
          'അല്ലാഹുവിന്റെ നാമത്തിൽ, ഞാൻ അല്ലാഹുവിൽ ഭരമേൽപ്പിക്കുന്നു. അല്ലാഹുവിനെക്കൊണ്ടല്ലാതെ യാതൊരു കഴിവോ ശക്തിയോ ഇല്ല.',
      reference: 'Abu Dawud · At-Tirmidhi',
      targetCount: 1,
    ),
    AdhkarEntry(
      id: 'dua_enter_mosque',
      category: 'daily_duas',
      titleEn: 'Entering the Mosque',
      titleMl: 'പള്ളിയിൽ പ്രവേശിക്കുമ്പോൾ',
      arabic: 'اللَّهُمَّ افْتَحْ لِي أَبْوَابَ رَحْمَتِكَ',
      translationEn: 'O Allah, open the gates of Your mercy for me.',
      translationMl: 'അല്ലാഹുവേ, നിന്റെ കാരുണ്യത്തിന്റെ കവാടങ്ങൾ എനിക്കായി തുറന്നുതരേണമേ.',
      reference: 'Sahih Muslim 713',
      targetCount: 1,
    ),
    AdhkarEntry(
      id: 'dua_leave_mosque',
      category: 'daily_duas',
      titleEn: 'Leaving the Mosque',
      titleMl: 'പള്ളിയിൽ നിന്ന് പുറത്തിറങ്ങുമ്പോൾ',
      arabic: 'اللَّهُمَّ إِنِّي أَسْأَلُكَ مِنْ فَضْلِكَ',
      translationEn: 'O Allah, I ask You from Your bounty.',
      translationMl: 'അല്ലാഹുവേ, നിന്റെ അനുഗ്രഹത്തിൽ നിന്ന് ഞാൻ ചോദിക്കുന്നു.',
      reference: 'Sahih Muslim 713',
      targetCount: 1,
    ),
    AdhkarEntry(
      id: 'dua_after_meal',
      category: 'daily_duas',
      titleEn: 'After Finishing a Meal',
      titleMl: 'ഭക്ഷണത്തിന് ശേഷം',
      arabic:
          'الْحَمْدُ لِلَّهِ الَّذِي أَطْعَمَنِي هَٰذَا وَرَزَقَنِيهِ مِنْ غَيْرِ حَوْلٍ مِنِّي وَلَا قُوَّةٍ',
      translationEn:
          'Praise be to Allah who has fed me this and provided it for me without any might or power on my part.',
      translationMl:
          'എന്റെ യാതൊരു ശക്തിയോ കഴിവോ കൂടാതെ എനിക്ക് ഈ ആഹാരം നൽകുകയും ഉപജീവനമാക്കുകയും ചെയ്ത അല്ലാഹുവിനാണ് സർവ്വസ്തുതിയും.',
      reference: 'Abu Dawud · At-Tirmidhi',
      targetCount: 1,
    ),
    AdhkarEntry(
      id: 'dua_travel',
      category: 'daily_duas',
      titleEn: 'When Beginning Travel',
      titleMl: 'യാത്ര പുറപ്പെടുമ്പോൾ',
      arabic:
          'سُبْحَانَ الَّذِي سَخَّرَ لَنَا هَٰذَا وَمَا كُنَّا لَهُ مُقْرِنِينَ ۝ وَإِنَّا إِلَىٰ رَبِّنَا لَمُنقَلِبُونَ',
      translationEn:
          'Glory be to Him who has subjected this to us, and we could never have it by our efforts; surely to our Lord we shall return.',
      translationMl:
          'ഇതിനെ ഞങ്ങൾക്ക് കീഴ്പ്പെടുത്തിത്തന്ന അല്ലാഹു എത്ര പരിശുദ്ധൻ! ഞങ്ങൾക്ക് സ്വന്തമായി ഇതിന് കഴിയുമായിരുന്നില്ല. തീർച്ചയായും ഞങ്ങളുടെ റബ്ബിലേക്ക് തന്നെ ഞങ്ങൾ മടങ്ങുന്നവരാണ്.',
      reference: 'Az-Zukhruf 43:13-14 · Muslim',
      targetCount: 1,
    ),
    AdhkarEntry(
      id: 'dua_anxiety',
      category: 'daily_duas',
      titleEn: 'Relief From Anxiety & Debt',
      titleMl: 'ദുഃഖത്തിൽ നിന്നും കടബാധ്യതയിൽ നിന്നും മോചനം',
      arabic:
          'اللَّهُمَّ إِنِّي أَعُوذُ بِكَ مِنَ الْهَمِّ وَالْحَزَنِ، وَالْعَجْزِ وَالْكَسَلِ، وَالْبُخْلِ وَالْجُبْنِ، وَضَلَعِ الدَّيْنِ وَغَلَبَةِ الرِّجَالِ',
      translationEn:
          'O Allah, I seek refuge in You from anxiety and sorrow, weakness and laziness, miserliness and cowardice, the burden of debts and oppression.',
      translationMl:
          'അല്ലാഹുവേ, ദുഃഖം, വ്യസനം, അശക്തി, അലസത, പിശുക്ക്, ഭീരുത്വം, കടഭാരം, ജനങ്ങളുടെ ആധിപത്യം എന്നിവയിൽ നിന്ന് നിന്നോട് ഞാൻ അഭയം തേടുന്നു.',
      reference: 'Sahih al-Bukhari 6369',
      targetCount: 1,
    ),
    AdhkarEntry(
      id: 'dua_parents',
      category: 'daily_duas',
      titleEn: 'Dua for Parents',
      titleMl: 'മാതാപിതാക്കൾക്ക് വേണ്ടിയുള്ള പ്രാർത്ഥന',
      arabic: 'رَّبِّ ارْحَمْهُمَا كَمَا رَبَّيَانِي صَغِيرًا',
      translationEn:
          'My Lord, have mercy upon them as they brought me up when I was small.',
      translationMl:
          'എന്റെ രക്ഷിതാവേ, ചെറുപ്പത്തിൽ അവർ എന്നെ വളർത്തിപ്പോറ്റിയത് പോലെ അവർ ഇരുവർക്കും നീ കരുണ ചെയ്യേണമേ.',
      reference: 'Al-Isra 17:24',
      targetCount: 1,
    ),
    AdhkarEntry(
      id: 'dua_knowledge',
      category: 'daily_duas',
      titleEn: 'Beneficial Knowledge & Provision',
      titleMl: 'ഉപകാരപ്രദമായ അറിവിനും ഹലാലായ റിസ്ഖിനും',
      arabic:
          'اللَّهُمَّ إِنِّي أَسْأَلُكَ عِلْمًا نَافِعًا، وَرِزْقًا طَيِّبًا، وَعَمَلًا مُتَقَبَّلًا',
      translationEn:
          'O Allah, I ask You for beneficial knowledge, pure provision, and deeds that are accepted.',
      translationMl:
          'അല്ലാഹുവേ, പ്രയോജനപ്രദമായ അറിവും വിശിഷ്ടമായ ഉപജീവനവും സ്വീകരിക്കപ്പെടുന്ന സൽകർമ്മവും ഞാൻ നിന്നോട് ചോദിക്കുന്നു.',
      reference: 'Ibn Majah 925',
      targetCount: 1,
    ),
    AdhkarEntry(
      id: 'dua_hasanah',
      category: 'daily_duas',
      titleEn: 'Goodness in Both Worlds',
      titleMl: 'ഇഹത്തിലും പരത്തിലും നന്മയ്ക്കായി',
      arabic:
          'رَبَّنَا آتِنَا فِي الدُّنْيَا حَسَنَةً وَفِي الْآخِرَةِ حَسَنَةً وَقِنَا عَذَابَ النَّارِ',
      translationEn:
          'Our Lord, grant us good in this world and good in the Hereafter, and protect us from the punishment of the Fire.',
      translationMl:
          'ഞങ്ങളുടെ രക്ഷിതാവേ, ഇഹലോകത്തും പരലോകത്തും ഞങ്ങൾക്ക് നീ നന്മ നൽകേണമേ; നരകശിക്ഷയിൽ നിന്ന് ഞങ്ങളെ കാക്കേണമേ.',
      reference: 'Al-Baqarah 2:201',
      targetCount: 1,
    ),
  ];

  static const List<TasbihPreset> defaultTasbihPresets = [
    TasbihPreset(
      id: 'tasbih_subhanallah',
      arabic: 'سُبْحَانَ اللَّهِ',
      titleEn: 'SubhanAllah',
      titleMl: 'സുബ്ഹാനല്ലാഹ്',
      defaultTarget: 33,
    ),
    TasbihPreset(
      id: 'tasbih_alhamdulillah',
      arabic: 'الْحَمْدُ لِلَّهِ',
      titleEn: 'Alhamdulillah',
      titleMl: 'അൽഹംദുലില്ലാഹ്',
      defaultTarget: 33,
    ),
    TasbihPreset(
      id: 'tasbih_allahuakbar',
      arabic: 'اللَّهُ أَكْبَرُ',
      titleEn: 'Allahu Akbar',
      titleMl: 'അല്ലാഹു അക്ബർ',
      defaultTarget: 33,
    ),
    TasbihPreset(
      id: 'tasbih_istighfar',
      arabic: 'أَسْتَغْفِرُ اللَّهَ',
      titleEn: 'Astaghfirullah',
      titleMl: 'അസ്തഗ്ഫിറുല്ലാഹ്',
      defaultTarget: 100,
    ),
    TasbihPreset(
      id: 'tasbih_salawat',
      arabic: 'اللَّهُمَّ صَلِّ عَلَىٰ مُحَمَّدٍ',
      titleEn: 'Salawat upon the Prophet',
      titleMl: 'സ്വലാത്ത്',
      defaultTarget: 100,
    ),
    TasbihPreset(
      id: 'tasbih_tahlil',
      arabic: 'لَا إِلَٰهَ إِلَّا اللَّهُ',
      titleEn: 'La ilaha illallah',
      titleMl: 'ലാ ഇലാഹ ഇല്ലല്ലാഹ്',
      defaultTarget: 100,
    ),
  ];
}
