# Al-Quran Malayalam — Flutter Android & Web App

ഇത് **Flutter + Riverpod + Offline Cache** ഉപയോഗിച്ച് നിർമ്മിച്ച സമ്പൂർണ്ണ ഖുർആൻ ആപ്പ് പ്രോജക്റ്റ് ആണ് (Android APK + Web Preview).

## 1. API Key എങ്ങനെ പ്രവർത്തിക്കുന്നു?
- **ഉടൻ പ്രവർത്തിക്കാൻ (Zero API Key):** ബൈ ഡിഫോൾട്ട് ഈ ആപ്പ് സൗജന്യ [Al Quran Cloud API](https://alquran.cloud/api) (`https://api.alquran.cloud/v1`) ഉപയോഗിക്കുന്നു — അറബിക് (`quran-uthmani`), മലയാളം (`ml.abdulhameed`), ഇംഗ്ലീഷ് (`en.sahih`), തഫ്സീർ (`ar.muyassar`) എന്നിവയ്ക്ക് API Key ആവശ്യമില്ല.
- **സ്വന്തം API Key നൽകാൻ:** ഭാവിയിൽ നിങ്ങൾക്ക് ഒരു API Key നൽകണമെങ്കിൽ GitHub Repository-ൽ `Settings -> Secrets and variables -> Actions -> New repository secret` എന്നിവിടെ `QURAN_API_KEY` എന്ന പേരിൽ സേവ് ചെയ്താൽ മതി.

## 2. GitHub വഴി ഓട്ടോമാറ്റിക് Android APK ബിൽഡ് ചെയ്യുന്ന വിധം

```bash
# 1. Git തുടങ്ങുക & നിങ്ങളുടെ GitHub Repo-യിലേക്ക് പുഷ് ചെയ്യുക
git init
git add .
git commit -m "Al-Quran Flutter app with Android APK workflow"
git branch -M main
git remote add origin https://github.com/YOUR_USERNAME/quran-malayalam-app.git
git push -u origin main
```

3. GitHub-ൽ നിങ്ങളുടെ റിപ്പോസിറ്ററി തുറന്ന് **Actions** ടാബിൽ ക്ലിക്ക് ചെയ്യുക.
4. `Build Quran Android APK` വർക്ക്‌ഫ്ലോ പൂർത്തിയാകുമ്പോൾ, താഴെ കാണുന്ന **Al-Quran-APK** എന്ന ആർട്ടിഫാക്റ്റ് ഡൗൺലോഡ് ചെയ്ത് അകത്തുള്ള **`Al-Quran.apk`** ഫോണിൽ ഇൻസ്റ്റാൾ ചെയ്യുക!
