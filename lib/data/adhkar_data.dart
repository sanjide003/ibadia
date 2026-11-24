import '../models/adhkar_tasbih_model.dart';

class AdhkarCatalog {
  const AdhkarCatalog._();

  static const List<String> categoryKeys = [
    'morning',
    'evening',
    'after_salah',
    'daily_duas',
  ];

  static const List<AdhkarEntry> entries = [
    // =========================================================================
    // 1. FROM THE QURAN (Surah Ayahs, Protection Surahs & Rabbana Duas)
    // =========================================================================
    AdhkarEntry(
      id: 'am_ayat_kursi',
      source: 'quran',
      category: 'morning',
      titleEn: 'Ayat al-Kursi (Al-Baqarah 2:255)',
      titleMl: 'ആയത്തുൽ കുർസി (അൽ-ബഖറ 2:255)',
      arabic:
          'اللَّهُ لَا إِلَٰهَ إِلَّا هُوَ الْحَيُّ الْقَيُّومُ ۚ لَا تَأْخُذُهُ سِنَةٌ وَلَا نَوْمٌ ۚ لَّهُ مَا فِي السَّمَاوَاتِ وَمَا فِي الْأَرْضِ ۗ مَن ذَا الَّذِي يَشْفَعُ عِندَهُ إِلَّا بِإِذْنِهِ ۚ يَعْلَمُ مَا بَيْنَ أَيْدِيهِمْ وَمَا خَلْفَهُمْ ۖ وَلَا يُحِيطُونَ بِشَيْءٍ مِّنْ عِلْمِهِ إِلَّا بِمَا شَاءَ ۚ وَسِعَ كُرْسِيُّهُ السَّمَاوَاتِ وَالْأَرْضَ ۖ وَلَا يَئُودُهُ حِفْظُهُمَا ۚ وَهُوَ الْعَلِيُّ الْعَظِيمُ',
      translationEn:
          'Allah — there is no deity except Him, the Ever-Living, the Sustainer of existence. Neither drowsiness overtakes Him nor sleep. To Him belongs whatever is in the heavens and whatever is on the earth. Who is it that can intercede with Him except by His permission? He knows what is before them and what will be after them, and they encompass not a thing of His knowledge except for what He wills. His Kursi extends over the heavens and the earth, and their preservation tires Him not. And He is the Most High, the Most Great.',
      translationMl:
          'അല്ലാഹു — അവനല്ലാതെ മറ്റൊരു ആരാധ്യനില്ല. അവൻ എന്നെന്നും ജീവിച്ചിരിക്കുന്നവനും സർവ്വനിയന്താവുമാണ്. മയക്കമോ ഉറക്കമോ അവനെ ബാധിക്കുകയില്ല. ആകാശഭൂമികളിലുള്ളതെല്ലാം അവന്റേതാണ്. അവന്റെ അനുമതിയില്ലാതെ അവന്റെ അടുക്കൽ ശുപാർശ ചെയ്യാൻ ആരാണുള്ളത്? അവരുടെ മുന്നിലുള്ളതും പിന്നിലുള്ളതും അവൻ അറിയുന്നു. അവൻ ഉദ്ദേശിക്കുന്നതല്ലാതെ അവന്റെ അറിവിൽ നിന്ന് യാതൊന്നും അവർക്ക് ഗ്രഹിക്കാൻ കഴിയില്ല. അവന്റെ കുർസി ആകാശഭൂമികളെ മുഴുവൻ ഉൾക്കൊള്ളുന്നു. അവ രണ്ടിനെയും സംരക്ഷിക്കുക എന്നത് അവന് ഒട്ടും ഭാരമുള്ളതല്ല. അവൻ അത്യുന്നതനും മഹാനുമാണ്.',
      reference: 'Al-Baqarah 2:255',
      targetCount: 1,
    ),
    AdhkarEntry(
      id: 'q_amanar_rasul',
      source: 'quran',
      category: 'evening',
      titleEn: 'Amanar-Rasul (Al-Baqarah 2:285–286)',
      titleMl: 'ആമന റസൂൽ (അൽ-ബഖറ 2:285–286)',
      arabic:
          'آمَنَ الرَّسُولُ بِمَا أُنزِلَ إِلَيْهِ مِن رَّبِّهِ وَالْمُؤْمِنُونَ ۚ كُلٌّ آمَنَ بِاللَّهِ وَمَلَائِكَتِهِ وَكُتُبِهِ وَرُسُلِهِ لَا نُفَرِّقُ بَيْنَ أَحَدٍ مِّن رُّسُلِهِ ۚ وَقَالُوا سَمِعْنَا وَأَطَعْنَا ۖ غُفْرَانَكَ رَبَّنَا وَإِلَيْكَ الْمَصِيرُ ۝ لَا يُكَلِّفُ اللَّهُ نَفْسًا إِلَّا وُسْعَهَا ۚ لَهَا مَا كَسَبَتْ وَعَلَيْهَا مَا اكْتَسَبَتْ ۗ رَبَّنَا لَا تُؤَاخِذْنَا إِن نَّسِينَا أَوْ أَخْطَأْنَا ۚ رَبَّنَا وَلَا تَحْمِلْ عَلَيْنَا إِصْرًا كَمَا حَمَلْتَهُ عَلَى الَّذِينَ مِن قَبْلِنَا ۚ رَبَّنَا وَلَا تُحَمِّلْنَا مَا لَا طَاقَةَ لَنَا بِهِ ۖ وَاعْفُ عَنَّا وَاغْفِرْ لَنَا وَارْحَمْنَا ۚ أَنتَ مَوْلَانَا فَانصُرْنَا عَلَى الْقَوْمِ الْكَافِرِينَ',
      translationEn:
          'The Messenger has believed in what was revealed to him from his Lord, and so have the believers. All of them have believed in Allah, His angels, His books, and His messengers, saying: "We make no distinction between any of His messengers." And they say: "We hear and we obey. Your forgiveness, our Lord, and to You is the final destination." Allah does not charge a soul except with that within its capacity. It will have the consequence of what good it has gained, and it will bear the consequence of what evil it has earned. "Our Lord, do not impose blame upon us if we forget or make a mistake. Our Lord, and lay not upon us a burden like that which You laid upon those before us. Our Lord, and burden us not with that which we have no ability to bear. And pardon us, and forgive us, and have mercy upon us. You are our protector, so give us victory over the disbelieving people."',
      translationMl:
          'റസൂലും സത്യവിശ്വാസികളും തങ്ങളുടെ രക്ഷിതാവിങ്കൽ നിന്ന് അവതരിപ്പിക്കപ്പെട്ടതിൽ വിശ്വസിച്ചിരിക്കുന്നു. അവരെല്ലാവരും അല്ലാഹുവിലും അവന്റെ മലക്കുകളിലും അവന്റെ വേദഗ്രന്ഥങ്ങളിലും അവന്റെ ദൂതന്മാരിലും വിശ്വസിച്ചിരിക്കുന്നു. അവന്റെ ദൂതന്മാരിൽ ഒരാൾക്കിടയിലും ഞങ്ങൾ വിവേചനം കൽപ്പിക്കുന്നില്ല; ഞങ്ങൾ കേൾക്കുകയും അനുസരിക്കുകയും ചെയ്തിരിക്കുന്നു; ഞങ്ങളുടെ രക്ഷിതാവേ, നിന്റെ പാപമോചനം ഞങ്ങൾ തേടുന്നു, നിന്നിലേക്കാണ് മടക്കം എന്നും അവർ പറയുന്നു. അല്ലാഹു ഒരാളോടും അയാളുടെ കഴിവിനപ്പുറം ഭാരം ചുമത്തുകയില്ല. ഓരോരുത്തർ പ്രവർത്തിച്ച നന്മയും തിന്മയും അവർക്ക് തന്നെയാണ്. ഞങ്ങളുടെ രക്ഷിതാവേ, ഞങ്ങൾ മറന്നുപോകുകയോ തെറ്റുപറ്റുകയോ ചെയ്താൽ ഞങ്ങളെ പിടികൂടരുതേ. മുൻഗാമികളുടെ മേൽ ചുമത്തിയത് പോലെയുള്ള ഭാരങ്ങൾ ഞങ്ങളുടെ മേൽ ചുമത്തരുതേ. ഞങ്ങൾക്ക് താങ്ങാൻ കഴിയാത്ത ഭാരം ഞങ്ങളെ വഹിപ്പിക്കരുതേ. ഞങ്ങൾക്ക് മാപ്പ് നൽകുകയും പൊറുത്തുതരികയും കരുണ ചെയ്യുകയും വേണമേ. നീയാണ് ഞങ്ങളുടെ യജമാനൻ; സത്യനിഷേധികൾക്കെതിരെ ഞങ്ങളെ സഹായിക്കേണമേ.',
      reference: 'Al-Baqarah 2:285–286 · Bukhari 5009',
      targetCount: 1,
    ),
    AdhkarEntry(
      id: 'q_law_anzalna',
      source: 'quran',
      category: 'morning',
      titleEn: 'Law Anzalna (Al-Hashr 59:21–24)',
      titleMl: 'ലൗ അൻസൽന (അൽ-ഹശ്ർ 59:21–24)',
      arabic:
          'لَوْ أَنزَلْنَا هَٰذَا الْقُرْآنَ عَلَىٰ جَبَلٍ لَّرَأَيْتَهُ خَاشِعًا مُّتَصَدِّعًا مِّنْ خَشْيَةِ اللَّهِ ۚ وَتِلْكَ الْأَمْثَالُ نَضْرِبُهَا لِلنَّاسِ لَعَلَّهُمْ يَتَفَكَّرُونَ ۝ هُوَ اللَّهُ الَّذِي لَا إِلَٰهَ إِلَّا هُوَ ۖ عَالِمُ الْغَيْبِ وَالشَّهَادَةِ ۖ هُوَ الرَّحْمَٰنُ الرَّحِيمُ ۝ هُوَ اللَّهُ الَّذِي لَا إِلَٰهَ إِلَّا هُوَ الْمَلِكُ الْقُدُّوسُ السَّلَامُ الْمُؤْمِنُ الْمُهَيْمِنُ الْعَزِيزُ الْجَبَّارُ الْمُتَكَبِّرُ ۚ سُبْحَانَ اللَّهِ عَمَّا يُشْرِكُونَ ۝ هُوَ اللَّهُ الْخَالِقُ الْبَارِئُ الْمُصَوِّرُ ۖ لَهُ الْأَسْمَاءُ الْحُسْنَىٰ ۚ يُسَبِّحُ لَهُ مَا فِي السَّمَاوَاتِ وَالْأَرْضِ ۖ وَهُوَ الْعَزِيزُ الْحَكِيمُ',
      translationEn:
          'If We had sent down this Quran upon a mountain, you would have seen it humbled and coming apart from fear of Allah. And these examples We present to the people that perhaps they will give thought. He is Allah, other than whom there is no deity, Knower of the unseen and the witnessed. He is the Entirely Merciful, the Especially Merciful. He is Allah, other than whom there is no deity, the Sovereign, the Pure, the Perfection, the Bestower of Faith, the Overseer, the Exalted in Might, the Compeller, the Superior. Exalted is Allah above whatever they associate with Him. He is Allah, the Creator, the Inventor, the Fashioner; to Him belong the best names. Whatever is in the heavens and earth is exalting Him. And He is the Exalted in Might, the Wise.',
      translationMl:
          'ഈ ഖുർആൻ നാം ഒരു പർവ്വതത്തിന്മേൽ അവതരിപ്പിച്ചിരുന്നെങ്കിൽ അല്ലാഹുവോടുള്ള ഭയത്താൽ അത് വിനയാന്വിതമാവുകയും പൊട്ടിപ്പിളരുകയും ചെയ്യുന്നത് നിനക്ക് കാണാമായിരുന്നു. ജനങ്ങൾ ചിന്തിക്കുവാൻ വേണ്ടി നാം ഈ ഉപമകൾ വിവരിക്കുന്നു. അവൻ അല്ലാഹുവാണ്; അവനല്ലാതെ ആരാധ്യനില്ല. അദൃശ്യവും ദൃശ്യവും അറിയുന്നവനും പരമകാരുണികനും കരുണാനിധിയുമാണ് അവൻ. അവൻ അല്ലാഹുവാണ്; രാജാധികാരിയും പരമപരിശുദ്ധനും സമാധാനദായകനും അഭയദായകനും സർവ്വശക്തനും പ്രതാപശാലിയും മഹോന്നതനുമാണ്. അവനോട് പങ്കുചേർക്കുന്നവയിൽ നിന്നെല്ലാം അല്ലാഹു എത്ര പരിശുദ്ധൻ! അവൻ സ്രഷ്ടാവും നിർമ്മാതാവും രൂപകൽപ്പന ചെയ്യുന്നവനുമാണ്. അവന് ഏറ്റവും ഉത്തമമായ നാമങ്ങളുണ്ട്. ആകാശഭൂമികളിലുള്ളതെല്ലാം അവനെ പ്രകീർത്തിക്കുന്നു. അവൻ പ്രതാപശാലിയും യുക്തിമാനുമാണ്.',
      reference: 'Al-Hashr 59:21–24',
      targetCount: 1,
    ),
    AdhkarEntry(
      id: 'am_three_quls',
      source: 'quran',
      category: 'morning',
      titleEn: 'Three Quls — Al-Ikhlas, Al-Falaq & An-Nas',
      titleMl: 'മൂന്ന് ഖുൽ സൂറത്തുകൾ (ഇഖ്‌ലാസ്, ഫലഖ്, നാസ്)',
      arabic:
          'بِسْمِ اللَّهِ الرَّحْمَٰنِ الرَّحِيمِ\n'
          'قُلْ هُوَ اللَّهُ أَحَدٌ ۝ اللَّهُ الصَّمَدُ ۝ لَمْ يَلِدْ وَلَمْ يُولَدْ ۝ وَلَمْ يَكُن لَّهُ كُفُوًا أَحَدٌ\n\n'
          'بِسْمِ اللَّهِ الرَّحْمَٰنِ الرَّحِيمِ\n'
          'قُلْ أَعُوذُ بِرَبِّ الْفَلَقِ ۝ مِن شَرِّ مَا خَلَقَ ۝ وَمِن شَرِّ غَاسِقٍ إِذَا وَقَبَ ۝ وَمِن شَرِّ النَّفَّاثَاتِ فِي الْعُقَدِ ۝ وَمِن شَرِّ حَاسِدٍ إِذَا حَسَدَ\n\n'
          'بِسْمِ اللَّهِ الرَّحْمَٰنِ الرَّحِيمِ\n'
          'قُلْ أَعُوذُ بِرَبِّ النَّاسِ ۝ مَلِكِ النَّاسِ ۝ إِلَٰهِ النَّاسِ ۝ مِن شَرِّ الْوَسْوَاسِ الْخَنَّاسِ ۝ الَّذِي يُوَسْوِسُ فِي صُدُورِ النَّاسِ ۝ مِنَ الْجِنَّةِ وَالنَّاسِ',
      translationEn:
          'Al-Ikhlas (112): Say, "He is Allah, who is One, Allah, the Eternal Refuge. He neither begets nor is born, nor is there to Him any equivalent."\n\n'
          'Al-Falaq (113): Say, "I seek refuge in the Lord of daybreak from the evil of that which He created, and from the evil of darkness when it settles, and from the evil of the blowers in knots, and from the evil of an envier when he envies."\n\n'
          'An-Nas (114): Say, "I seek refuge in the Lord of mankind, the Sovereign of mankind, the God of mankind, from the evil of the retreating whisperer who whispers into the breasts of mankind — from among the jinn and mankind."',
      translationMl:
          'അൽ-ഇഖ്‌ലാസ് (112): പറയുക: അവൻ അല്ലാഹു ഏകനാണ്. അല്ലാഹു ഏവർക്കും ആശ്രയമായുള്ളവനാണ്. അവൻ ജന്മം നൽകിയിട്ടില്ല; ജനിച്ചിട്ടുമില്ല. അവന് തുല്യനായി ആരുമില്ല.\n\n'
          'അൽ-ഫലഖ് (113): പറയുക: പുലരിയുടെ നാഥനോട് ഞാൻ അഭയം തേടുന്നു; അവൻ സൃഷ്ടിച്ചവയുടെ കെടുതിയിൽ നിന്നും, ഇരുട്ട് വ്യാപിക്കുമ്പോൾ രാത്രിയുടെ കെടുതിയിൽ നിന്നും, കെട്ടുകളിട്ട് ഊതുന്ന മന്ത്രവാദികളുടെ കെടുതിയിൽ നിന്നും, അസൂയാലു അസൂയപ്പെടുമ്പോഴുള്ള കെടുതിയിൽ നിന്നും.\n\n'
          'അൻ-നാസ് (114): പറയുക: മനുഷ്യരുടെ രക്ഷിതാവും രാജാവും ആരാധ്യനുമായവനോട് ഞാൻ അഭയം തേടുന്നു; മനുഷ്യരുടെ ഹൃദയങ്ങളിൽ ദുർബോധനം നടത്തുന്ന പിശാചിന്റെ ഉപദ്രവത്തിൽ നിന്നും — ജിന്നുകളിൽ നിന്നും മനുഷ്യരിൽ നിന്നുമുള്ള ദുഷ്ടന്മാരിൽ നിന്നും.',
      reference: 'Surahs 112, 113, 114 · Abu Dawud 5082',
      targetCount: 3,
    ),
    AdhkarEntry(
      id: 'dua_hasanah',
      source: 'quran',
      category: 'daily_duas',
      titleEn: 'Goodness in Both Worlds',
      titleMl: 'ഇഹത്തിലും പരത്തിലും നന്മയ്ക്കുള്ള പ്രാർത്ഥന',
      arabic:
          'رَبَّنَا آتِنَا فِي الدُّنْيَا حَسَنَةً وَفِي الْآخِرَةِ حَسَنَةً وَقِنَا عَذَابَ النَّارِ',
      translationEn:
          'Our Lord, grant us good in this world and good in the Hereafter, and protect us from the punishment of the Fire.',
      translationMl:
          'ഞങ്ങളുടെ രക്ഷിതാവേ, ഇഹലോകത്തും പരലോകത്തും ഞങ്ങൾക്ക് നീ നന്മ നൽകേണമേ; നരകശിക്ഷയിൽ നിന്ന് ഞങ്ങളെ കാക്കേണമേ.',
      reference: 'Al-Baqarah 2:201',
      targetCount: 1,
    ),
    AdhkarEntry(
      id: 'q_rabbana_la_tuzigh',
      source: 'quran',
      category: 'daily_duas',
      titleEn: 'Steadfastness on Guidance',
      titleMl: 'സന്മാർഗ്ഗത്തിൽ ഉറച്ചുനിൽക്കാൻ പ്രാർത്ഥന',
      arabic:
          'رَبَّنَا لَا تُزِغْ قُلُوبَنَا بَعْدَ إِذْ هَدَيْتَنَا وَهَبْ لَنَا مِن لَّدُنكَ رَحْمَةً ۚ إِنَّكَ أَنتَ الْوَهَّابُ',
      translationEn:
          'Our Lord, let not our hearts deviate after You have guided us, and grant us from Yourself mercy. Indeed, You are the Bestower.',
      translationMl:
          'ഞങ്ങളുടെ രക്ഷിതാവേ, ഞങ്ങളെ നീ നേർവഴിയിലാക്കിയതിന് ശേഷം ഞങ്ങളുടെ ഹൃദയങ്ങളെ തെറ്റിക്കരുതേ; നിന്റെ പക്കൽ നിന്ന് ഞങ്ങൾക്ക് നീ കാരുണ്യം നൽകേണമേ. തീർച്ചയായും നീ എല്ലാം ധാരാളമായി നൽകുന്നവനാണ്.',
      reference: 'Ali Imran 3:8',
      targetCount: 1,
    ),
    AdhkarEntry(
      id: 'q_hasbunallah',
      source: 'quran',
      category: 'daily_duas',
      titleEn: 'Allah Is Sufficient for Us',
      titleMl: 'ഞങ്ങൾക്ക് അല്ലാഹു മതി (ഹസ്ബുനല്ലാഹു വ നിഅ്മൽ വകീൽ)',
      arabic: 'حَسْبُنَا اللَّهُ وَنِعْمَ الْوَكِيلُ',
      translationEn:
          'Sufficient for us is Allah, and He is the best Disposer of affairs.',
      translationMl:
          'ഞങ്ങൾക്ക് അല്ലാഹു മതി; അവൻ എത്ര നല്ല ഭരമേൽപ്പിക്കപ്പെടുന്നവൻ!',
      reference: 'Ali Imran 3:173',
      targetCount: 1,
    ),
    AdhkarEntry(
      id: 'q_rabbana_faghfir',
      source: 'quran',
      category: 'daily_duas',
      titleEn: 'Forgiveness & Entry With the Righteous',
      titleMl: 'പാപമോചനത്തിനും സജ്ജനങ്ങൾക്കൊപ്പം മരിക്കാനും',
      arabic:
          'رَبَّنَا فَاغْفِرْ لَنَا ذُنُوبَنَا وَكَفِّرْ عَنَّا سَيِّئَاتِنَا وَتَوَفَّنَا مَعَ الْأَبْرَارِ',
      translationEn:
          'Our Lord, forgive us our sins, remove from us our misdeeds, and cause us to die among the righteous.',
      translationMl:
          'ഞങ്ങളുടെ രക്ഷിതാവേ, ഞങ്ങളുടെ പാപങ്ങൾ നീ പൊറുത്തുതരികയും ഞങ്ങളുടെ തിന്മകൾ മായ്ച്ചുകളയുകയും പുണ്യവാന്മാരോടൊപ്പം ഞങ്ങളെ മരിപ്പിക്കുകയും ചെയ്യേണമേ.',
      reference: 'Ali Imran 3:193',
      targetCount: 1,
    ),
    AdhkarEntry(
      id: 'q_rabbana_zalamna',
      source: 'quran',
      category: 'daily_duas',
      titleEn: 'Supplication of Prophet Adam (AS) for Repentance',
      titleMl: 'തൗബയും പാപമോചനവും തേടുന്ന പ്രാർത്ഥന',
      arabic:
          'رَبَّنَا ظَلَمْنَا أَنفُسَنَا وَإِن لَّمْ تَغْفِرْ لَنَا وَتَرْحَمْنَا لَنَكُونَنَّ مِنَ الْخَاسِرِينَ',
      translationEn:
          'Our Lord, we have wronged ourselves, and if You do not forgive us and have mercy upon us, we will surely be among the losers.',
      translationMl:
          'ഞങ്ങളുടെ രക്ഷിതാവേ, ഞങ്ങൾ ഞങ്ങളോട് തന്നെ അക്രമം ചെയ്തിരിക്കുന്നു. നീ ഞങ്ങൾക്ക് പൊറുത്തുതരികയും കരുണ ചെയ്യുകയും ചെയ്തില്ലെങ്കിൽ തീർച്ചയായും ഞങ്ങൾ നഷ്ടക്കാരിൽ പെട്ടുപോകും.',
      reference: 'Al-Araf 7:23',
      targetCount: 1,
    ),
    AdhkarEntry(
      id: 'am_hasbi_allah',
      source: 'quran',
      category: 'morning',
      titleEn: 'Sufficiency of Allah (Hasbi Allah)',
      titleMl: 'എനിക്ക് അല്ലാഹു മതി (ഹസ്ബിയല്ലാഹു...)',
      arabic:
          'حَسْبِيَ اللَّهُ لَا إِلَٰهَ إِلَّا هُوَ ۖ عَلَيْهِ تَوَكَّلْتُ ۖ وَهُوَ رَبُّ الْعَرْشِ الْعَظِيمِ',
      translationEn:
          'Sufficient for me is Allah; there is no deity except Him. On Him I have relied, and He is the Lord of the Great Throne.',
      translationMl:
          'എനിക്ക് അല്ലാഹു മതി; അവനല്ലാതെ മറ്റൊരു ആരാധ്യനില്ല. അവനിലാണ് ഞാൻ ഭരമേൽപ്പിച്ചിരിക്കുന്നത്. അവൻ മഹത്തായ അർശിന്റെ നാഥനാണ്.',
      reference: 'At-Tawbah 9:129',
      targetCount: 7,
    ),
    AdhkarEntry(
      id: 'dua_parents',
      source: 'quran',
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
      id: 'q_rabbi_zidni_ilma',
      source: 'quran',
      category: 'daily_duas',
      titleEn: 'Increase in Knowledge',
      titleMl: 'അറിവ് വർദ്ധിപ്പിക്കാനുള്ള പ്രാർത്ഥന',
      arabic: 'رَّبِّ زِدْنِي عِلْمًا',
      translationEn: 'My Lord, increase me in knowledge.',
      translationMl: 'എന്റെ രക്ഷിതാവേ, എനിക്ക് നീ അറിവ് വർദ്ധിപ്പിച്ചു തരേണമേ.',
      reference: 'Ta-Ha 20:114',
      targetCount: 1,
    ),
    AdhkarEntry(
      id: 'q_la_ilaha_illa_anta',
      source: 'quran',
      category: 'daily_duas',
      titleEn: 'Dua of Prophet Yunus (AS) in Distress',
      titleMl: 'വിഷമഘട്ടത്തിൽ യൂനുസ് നബി(അ)യുടെ പ്രാർത്ഥന',
      arabic:
          'لَّا إِلَٰهَ إِلَّا أَنتَ سُبْحَانَكَ إِنِّي كُنتُ مِنَ الظَّالِمِينَ',
      translationEn:
          'There is no deity except You; exalted are You. Indeed, I have been of the wrongdoers.',
      translationMl:
          'നീയല്ലാതെ ആരാധ്യനില്ല; നീ എത്രയോ പരിശുദ്ധൻ! തീർച്ചയായും ഞാൻ അക്രമികളിൽ പെട്ടുപോയിരിക്കുന്നു.',
      reference: 'Al-Anbiya 21:87',
      targetCount: 1,
    ),
    AdhkarEntry(
      id: 'q_rabbana_hab_lana',
      source: 'quran',
      category: 'daily_duas',
      titleEn: 'Comfort of Eyes in Family & Righteousness',
      titleMl: 'ഇണകളിലും സന്താനങ്ങളിലും കൺകുളിർമയ്ക്കുള്ള പ്രാർത്ഥന',
      arabic:
          'رَبَّنَا هَبْ لَنَا مِنْ أَزْوَاجِنَا وَذُرِّيَّاتِنَا قُرَّةَ أَعْيُنٍ وَاجْعَلْنَا لِلْمُتَّقِينَ إِمَامًا',
      translationEn:
          'Our Lord, grant us from among our spouses and offspring comfort to our eyes and make us an example for the righteous.',
      translationMl:
          'ഞങ്ങളുടെ രക്ഷിതാവേ, ഞങ്ങളുടെ ഇണകളിൽ നിന്നും സന്താനങ്ങളിൽ നിന്നും ഞങ്ങൾക്ക് കൺകുളിർമ നൽകുകയും ഭക്തന്മാർക്ക് ഞങ്ങളെ മാതൃകയാക്കുകയും ചെയ്യേണമേ.',
      reference: 'Al-Furqan 25:74',
      targetCount: 1,
    ),
    AdhkarEntry(
      id: 'dua_travel',
      source: 'quran',
      category: 'daily_duas',
      titleEn: 'When Beginning Travel',
      titleMl: 'യാത്ര പുറപ്പെടുമ്പോഴുള്ള പ്രാർത്ഥന',
      arabic:
          'سُبْحَانَ الَّذِي سَخَّرَ لَنَا هَٰذَا وَمَا كُنَّا لَهُ مُقْرِنِينَ ۝ وَإِنَّا إِلَىٰ رَبِّنَا لَمُنقَلِبُونَ',
      translationEn:
          'Glory be to Him who has subjected this to us, and we could never have it by our efforts; surely to our Lord we shall return.',
      translationMl:
          'ഇതിനെ ഞങ്ങൾക്ക് കീഴ്പ്പെടുത്തിത്തന്ന അല്ലാഹു എത്ര പരിശുദ്ധൻ! ഞങ്ങൾക്ക് സ്വന്തമായി ഇതിന് കഴിയുമായിരുന്നില്ല. തീർച്ചയായും ഞങ്ങളുടെ റബ്ബിലേക്ക് തന്നെ ഞങ്ങൾ മടങ്ങുന്നവരാണ്.',
      reference: 'Az-Zukhruf 43:13–14',
      targetCount: 1,
    ),

    // =========================================================================
    // 2. FROM THE HADITH (Curated Sunnah Adhkar — Zero Duplication)
    // =========================================================================
    // MORNING ADHKAR
    AdhkarEntry(
      id: 'am_asbahna',
      source: 'hadith',
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
      source: 'hadith',
      category: 'morning',
      titleEn: 'Sayyid al-Istighfar (Morning & Evening)',
      titleMl: 'സയ്യിദുൽ ഇസ്തിഗ്ഫാർ (രാവിലെയും വൈകുന്നേരവും)',
      arabic:
          'اللَّهُمَّ أَنْتَ رَبِّي لَا إِلَٰهَ إِلَّا أَنْتَ، خَلَقْتَنِي وَأَنَا عَبْدُكَ، وَأَنَا عَلَىٰ عَهْدِكَ وَوَعْدِكَ مَا اسْتَطَعْتُ، أَعُوذُ بِكَ مِنْ شَرِّ مَا صَنَعْتُ، أَبُوءُ لَكَ بِنِعْمَتِكَ عَلَيَّ، وَأَبُوءُ بِذَنْبِي فَاغْفِرْ لِي فَإِنَّهُ لَا يَغْفِرُ الذُّنُوبَ إِلَّا أَنْتَ',
      translationEn:
          'O Allah, You are my Lord, none has the right to be worshipped except You. You created me and I am Your servant. I acknowledge Your favor upon me and confess my sin, so forgive me, for none forgives sins except You. (Recite morning & evening.)',
      translationMl:
          'അല്ലാഹുവേ, നീ എന്റെ രക്ഷിതാവാണ്; നീയല്ലാതെ ആരാധ്യനില്ല. നീ എന്നെ സൃഷ്ടിച്ചു, ഞാൻ നിന്റെ അടിമയാണ്. നീ എനിക്ക് നൽകിയ അനുഗ്രഹങ്ങളും എന്റെ തെറ്റുകളും ഞാൻ ഏറ്റുപറയുന്നു. എനിക്ക് പൊറുത്തുതരേണമേ. (രാവിലെയും വൈകുന്നേരവും ഓതേണ്ടത്)',
      reference: 'Sahih al-Bukhari 6306',
      targetCount: 1,
    ),
    AdhkarEntry(
      id: 'am_bismillah_protect',
      source: 'hadith',
      category: 'morning',
      titleEn: 'Shield From All Harm (Morning & Evening)',
      titleMl: 'എല്ലാ ഉപദ്രവങ്ങളിൽ നിന്നും കാവൽ (രാവിലെയും വൈകിട്ടും)',
      arabic:
          'بِسْمِ اللَّهِ الَّذِي لَا يَضُرُّ مَعَ اسْمِهِ شَيْءٌ فِي الْأَرْضِ وَلَا فِي السَّمَاءِ وَهُوَ السَّمِيعُ الْعَلِيمُ',
      translationEn:
          'In the Name of Allah, with whose Name nothing on earth or in heaven can cause harm, and He is the All-Hearing, All-Knowing. (Recite 3 times morning & evening.)',
      translationMl:
          'ആകാശത്തോ ഭൂമിയിലോ ഉള്ള യാതൊന്നിനും തന്റെ നാമത്തോടൊപ്പം ഉപദ്രവം ചെയ്യാൻ കഴിയാത്ത അല്ലാഹുവിന്റെ നാമത്തിൽ. അവൻ എല്ലാം കേൾക്കുന്നവനും അറിയുന്നവനുമാണ്. (രാവിലെയും വൈകുന്നേരവും 3 തവണ)',
      reference: 'Abu Dawud 5088 · At-Tirmidhi 3388',
      targetCount: 3,
    ),
    AdhkarEntry(
      id: 'am_raditu',
      source: 'hadith',
      category: 'morning',
      titleEn: 'Contentment With Allah & Islam',
      titleMl: 'അല്ലാഹുവിനെയും ഇസ്‌ലാമിനെയും തൃപ്തിപ്പെടൽ',
      arabic:
          'رَضِيتُ بِاللَّهِ رَبًّا، وَبِالْإِسْلَامِ دِينًا، وَبِمُحَمَّدٍ صَلَّى اللَّهُ عَلَيْهِ وَسَلَّمَ نَبِيًّا',
      translationEn:
          'I am pleased with Allah as my Lord, with Islam as my religion, and with Muhammad (peace be upon him) as my Prophet.',
      translationMl:
          'അല്ലാഹുവിനെ രക്ഷിതാവായും ഇസ്‌ലാമിനെ മതമായും മുഹമ്മദ് നബി(സ)യെ പ്രവാചകനായും ഞാൻ തൃപ്തിപ്പെട്ടിരിക്കുന്നു.',
      reference: 'Ahmad · Abu Dawud 5072',
      targetCount: 3,
    ),
    AdhkarEntry(
      id: 'am_subhanallah_bihamdih',
      source: 'hadith',
      category: 'morning',
      titleEn: 'Tasbih & Praise',
      titleMl: 'തസ്ബീഹും സ്തുതിയും',
      arabic: 'سُبْحَانَ اللَّهِ وَبِحَمْدِهِ',
      translationEn: 'Glory be to Allah and praise be to Him.',
      translationMl: 'അല്ലാഹു എത്രയോ പരിശുദ്ധൻ! അവന് സർവ്വസ്തുതിയും.',
      reference: 'Sahih Muslim 2692',
      targetCount: 100,
    ),

    // EVENING ADHKAR
    AdhkarEntry(
      id: 'pm_amsayna',
      source: 'hadith',
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
      source: 'hadith',
      category: 'evening',
      titleEn: 'Protection From Evil Creation',
      titleMl: 'സൃഷ്ടികളുടെ ദോഷത്തിൽ നിന്നും അഭയം',
      arabic: 'أَعُوذُ بِكَلِمَاتِ اللَّهِ التَّامَّاتِ مِنْ شَرِّ مَا خَلَقَ',
      translationEn:
          'I seek refuge in the perfect words of Allah from the evil of what He has created.',
      translationMl:
          'അല്ലാഹു സൃഷ്ടിച്ചവയുടെ ഉപദ്രവങ്ങളിൽ നിന്നും അവന്റെ പരിപൂർണ്ണമായ വചനങ്ങൾ കൊണ്ട് ഞാൻ അഭയം തേടുന്നു.',
      reference: 'Sahih Muslim 2708',
      targetCount: 3,
    ),
    AdhkarEntry(
      id: 'pm_ya_hayyu',
      source: 'hadith',
      category: 'evening',
      titleEn: 'Seeking Rectification of Affairs',
      titleMl: 'കാര്യങ്ങളെല്ലാം നന്നാക്കിത്തരാൻ പ്രാർത്ഥന',
      arabic:
          'يَا حَيُّ يَا قَيُّومُ بِرَحْمَتِكَ أَسْتَغِيثُ أَصْلِحْ لِي شَأْنِي كُلَّهُ وَلَا تَكِلْنِي إِلَىٰ نَفْسِي طَرْفَةَ عَيْنٍ',
      translationEn:
          'O Ever-Living, O Sustainer, in Your mercy I seek relief; rectify all my affairs and do not leave me to myself even for the blink of an eye.',
      translationMl:
          'എന്നെന്നും ജീവിച്ചിരിക്കുന്നവനും സർവ്വനിയന്താവുമായ അല്ലാഹുവേ, നിന്റെ കാരുണ്യത്താൽ ഞാൻ സഹായം തേടുന്നു. എന്റെ എല്ലാ കാര്യങ്ങളും നന്നാക്കിത്തരേണമേ; കണ്ണിമവെട്ടുന്ന നേരം പോലും എന്നെ എന്റെ സ്വന്തം ഇഷ്ടത്തിന് വിട്ടേക്കരുതേ.',
      reference: "An-Nasa'i · Al-Hakim",
      targetCount: 1,
    ),

    // AFTER-SALAH ADHKAR
    AdhkarEntry(
      id: 'salah_istighfar',
      source: 'hadith',
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
      source: 'hadith',
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
      source: 'hadith',
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
      source: 'hadith',
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
      source: 'hadith',
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
      source: 'hadith',
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
      source: 'hadith',
      category: 'after_salah',
      titleEn: 'Dua for Gratitude & Excellence in Worship',
      titleMl: 'ദിക്റിലും ശുക്റിലും സഹായം തേടൽ',
      arabic: 'اللَّهُمَّ أَعِنِّي عَلَىٰ ذِكْرِكَ وَشُكْرِكَ وَحُسْنِ عِبَادَتِكَ',
      translationEn:
          'O Allah, help me to remember You, to give thanks to You, and to worship You in the best of manners.',
      translationMl:
          'അല്ലാഹുവേ, നിന്നെ സ്മരിക്കാനും നിനക്ക് നന്ദി കാണിക്കാനും നിന്നെ ഏറ്റവും നന്നായി ആരാധിക്കാനും എന്നെ സഹായിക്കേണമേ.',
      reference: 'Abu Dawud 1522',
      targetCount: 1,
    ),

    // DAILY DUAS
    AdhkarEntry(
      id: 'dua_sleep',
      source: 'hadith',
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
      source: 'hadith',
      category: 'daily_duas',
      titleEn: 'Upon Waking Up',
      titleMl: 'ഉറക്കത്തിൽ നിന്ന് ഉണരുമ്പോൾ',
      arabic: 'الْحَمْدُ لِلَّهِ الَّذِي أَحْيَانَا بَعْدَ مَا أَمَاتَنَا وَإِلَيْهِ النُّشُورُ',
      translationEn:
          'All praise is for Allah who gave us life after having taken it from us, and unto Him is the resurrection.',
      translationMl:
          'നമ്മെ മരിപ്പിച്ചതിനുശേഷം (ഉറക്കിയതിനുശേഷം) വീണ്ടും ജീവിപ്പിച്ച അല്ലാഹുവിനാണ് സർവ്വസ്തുതിയും. അവനിലേക്കാണ് പുനരുത്ഥാനം.',
      reference: 'Sahih al-Bukhari 6312',
      targetCount: 1,
    ),
    AdhkarEntry(
      id: 'dua_leave_home',
      source: 'hadith',
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
      source: 'hadith',
      category: 'daily_duas',
      titleEn: 'Entering the Mosque',
      titleMl: 'പള്ളിയിൽ പ്രവേശിക്കുമ്പോൾ',
      arabic: 'اللَّهُمَّ افْتَحْ لِي أَبْوَابَ رَحْمَتِكَ',
      translationEn: 'O Allah, open the gates of Your mercy for me.',
      translationMl:
          'അല്ലാഹുവേ, നിന്റെ കാരുണ്യത്തിന്റെ കവാടങ്ങൾ എനിക്കായി തുറന്നുതരേണമേ.',
      reference: 'Sahih Muslim 713',
      targetCount: 1,
    ),
    AdhkarEntry(
      id: 'dua_leave_mosque',
      source: 'hadith',
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
      source: 'hadith',
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
      id: 'dua_anxiety',
      source: 'hadith',
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
      id: 'dua_knowledge',
      source: 'hadith',
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
  ];
}
