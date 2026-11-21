# Al-Quran Malayalam — Flutter Android APK & Website (Vercel + PWA)

ഇത് **Flutter + Riverpod + Offline Cache** ഉപയോഗിച്ച് നിർമ്മിച്ച സമ്പൂർണ്ണ ഖുർആൻ ആപ്പ് പ്രോജക്റ്റ് ആണ്. ഒരേ കോഡിൽ നിന്ന് നിങ്ങൾക്ക് **Android APK (`Al-Quran.apk`)** ആയും, **Vercel-ൽ ലൈവ് വെബ്സൈറ്റ് (PWA)** ആയും ഇത് ഉപയോഗിക്കാം.

---

## 1. API Key എങ്ങനെ പ്രവർത്തിക്കുന്നു?
- **ഉടൻ പ്രവർത്തിക്കാൻ (Zero API Key):** ബൈ ഡിഫോൾട്ട് ഈ ആപ്പ് സൗജന്യ [Al Quran Cloud API](https://alquran.cloud/api) (`https://api.alquran.cloud/v1`) ഉപയോഗിക്കുന്നു — അറബിക് (`quran-uthmani`), മലയാളം (`ml.abdulhameed`), ഇംഗ്ലീഷ് (`en.sahih`), തഫ്സീർ (`ar.muyassar`) എന്നിവയ്ക്ക് API Key ആവശ്യമില്ല.
- **സ്വന്തം API Key നൽകാൻ:** ഭാവിയിൽ നിങ്ങൾക്ക് ഒരു API Key നൽകണമെങ്കിൽ:
  - GitHub APK ബിൽഡിനായി: `Settings -> Secrets and variables -> Actions -> New repository secret` എന്നിവിടെ `QURAN_API_KEY` സേവ് ചെയ്യുക.
  - Vercel വെബ്സൈറ്റിനായി: Vercel Project `Settings -> Environment Variables`-ൽ `QURAN_API_KEY` നൽകുക.

---

## 2. Vercel വഴി വെബ്സൈറ്റും PWA-യും പബ്ലിഷ് ചെയ്യുന്ന വിധം

ഈ പ്രോജക്റ്റിൽ `vercel.json`-ഉം ഓട്ടോമാറ്റിക് ബിൽഡ് സ്ക്രിപ്റ്റും (`scripts/vercel_build.sh`) ഇതിനകം സെറ്റ് ചെയ്തിട്ടുണ്ട്. അതിനാൽ നിങ്ങൾ GitHub-ലേക്ക് കോഡ് Push ചെയ്താൽ മതി — Vercel സ്വയം Flutter Web ബിൽഡ് ചെയ്ത് വെബ്സൈറ്റ് ലൈവ് ആക്കും!

### ഘട്ടം 1: കോഡ് GitHub-ലേക്ക് Push ചെയ്യുക
```bash
git init
git add .
git commit -m "Al-Quran Android APK + Vercel Website & PWA"
git branch -M main
git remote add origin https://github.com/YOUR_USERNAME/quran-malayalam-app.git
git push -u origin main
```

### ഘട്ടം 2: Vercel-ൽ പ്രോജക്റ്റ് Connect & Deploy ചെയ്യുക
1. [vercel.com](https://vercel.com)-ൽ GitHub അക്കൗണ്ട് ഉപയോഗിച്ച് ലോഗിൻ ചെയ്യുക.
2. **Add New → Project** ക്ലിക്ക് ചെയ്യുക.
3. നിങ്ങളുടെ GitHub Repository (`quran-malayalam-app`) തിരഞ്ഞെടുത്ത് **Import** ക്ലിക്ക് ചെയ്യുക.
4. `vercel.json` സ്വയമേവ റീഡ് ചെയ്യുന്നതിനാൽ **Build Command** (`bash scripts/vercel_build.sh`), **Output Directory** (`build/web`) എന്നിവ തനിയെ സെറ്റ് ആകും. *(മാറ്റം വരുത്തേണ്ടതില്ല!)*
5. *(ഓപ്ഷണൽ)* **Environment Variables** ഭാഗത്ത് താഴെ പറയുന്നവ നൽകാം:
   - `ANDROID_APK_URL`: വെബ്സൈറ്റിലെ **"Download Android APK"** ബട്ടൺ ക്ലിക്ക് ചെയ്യുമ്പോൾ നേരിട്ട് APK ഡൗൺലോഡ് ആകാൻ നിങ്ങളുടെ GitHub Release APK ലിങ്ക് നൽകുക (ഉദാ: `https://github.com/YOUR_USERNAME/quran-malayalam-app/releases/latest/download/Al-Quran.apk`).
   - `QURAN_API_KEY`: ആവശ്യമുണ്ടെങ്കിൽ മാത്രം.
6. **Deploy** ബട്ടൺ ക്ലിക്ക് ചെയ്യുക. ഏകദേശം 1–2 മിനിറ്റിനുള്ളിൽ നിങ്ങളുടെ വെബ്സൈറ്റ് (`https://your-project.vercel.app`) ലൈവ് ആകും!

### ഘട്ടം 3: വെബ്സൈറ്റ് ഫോണിൽ ആപ്പ് പോലെ ഇൻസ്റ്റാൾ ചെയ്യാൻ (PWA)
- **Android Chrome / Desktop Edge / Chrome:** വെബ്സൈറ്റ് തുറക്കുമ്പോൾ ഹെഡറിലോ വലതുവശത്തെ സെറ്റിംഗ്സ് ഡ്രോയറിലോ കാണുന്ന **Install App** ബട്ടൺ ക്ലിക്ക് ചെയ്താൽ ബ്രൗസർ ബാറില്ലാതെ സ്വന്തം ആപ്പ് പോലെ ഫോൺ ഹോം സ്ക്രീനിൽ ഇൻസ്റ്റാൾ ആകും.
- **iPhone / iPad (Safari):** സെറ്റിംഗ്സ് ഡ്രോയറിലെ **Install App** ക്ലിക്ക് ചെയ്യുകയോ Safari-യിലെ **Share → Add to Home Screen** ഉപയോഗിക്കുകയോ ചെയ്യുക.
- **Offline Reading:** ഒരിക്കൽ തുറന്ന സൂറത്തുകളും പരിഭാഷകളും ബ്രൗസറിൽ സേവ് ആകുന്നതിനാൽ ഇന്റർനെറ്റ് ഇല്ലാതെയും വായിക്കാം.

### ഘട്ടം 4: സ്വന്തം Domain കണക്ട് ചെയ്യാൻ (ഓപ്ഷണൽ)
Vercel Dashboard → നിങ്ങളുടെ പ്രോജക്റ്റ് → **Settings → Domains** വഴി നിങ്ങളുടെ കസ്റ്റം ഡൊമെയ്ൻ (ഉദാ: `alquran.yourdomain.com`) സൗജന്യ SSL സഹിതം ചേർക്കാം.

---

## 3. GitHub വഴി ഓട്ടോമാറ്റിക് Android APK ബിൽഡ് ചെയ്യുന്ന വിധം

വെബ്സൈറ്റ് Vercel-ൽ അപ്ഡേറ്റ് ആകുന്നതോടൊപ്പം തന്നെ, GitHub-ൽ പുഷ് ചെയ്യുമ്പോഴെല്ലാം Android APK ഫയലും ഓട്ടോമാറ്റിക്കായി ബിൽഡ് ആകും:

1. GitHub-ൽ നിങ്ങളുടെ റിപ്പോസിറ്ററി തുറന്ന് **Actions** ടാബിൽ ക്ലിക്ക് ചെയ്യുക.
2. `Build Quran Android APK` വർക്ക്‌ഫ്ലോ പൂർത്തിയാകുമ്പോൾ, താഴെ കാണുന്ന **Al-Quran-APK** എന്ന ആർട്ടിഫാക്റ്റ് ഡൗൺലോഡ് ചെയ്ത് അകത്തുള്ള **`Al-Quran.apk`** ഫോണിൽ ഇൻസ്റ്റാൾ ചെയ്യുക!
3. *(ടിപ്പ്: നിങ്ങൾ GitHub-ൽ ഒരു Release സൃഷ്ടിച്ച് `Al-Quran.apk` അപ്‌ലോഡ് ചെയ്ത ശേഷം ആ ലിങ്ക് Vercel-ലെ `ANDROID_APK_URL`-ൽ നൽകിയാൽ, വെബ്സൈറ്റിൽ നിന്ന് തന്നെ ആർക്കും APK ഡൗൺലോഡ് ചെയ്യാനാകും.)*

---

## 4. ലോഗോയും പേരും സ്വയം മാറ്റാൻ
ആപ്പിന്റെ ലോഗോ, പേര്, നിറങ്ങൾ എന്നിവ പിന്നീട് സ്വയം എഡിറ്റ് ചെയ്യുന്നതിനുള്ള വിശദമായ മലയാളം ഗൈഡിനായി **`BRANDING_GUIDE.md`** കാണുക.
