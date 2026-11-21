# അൽ-ഖുർആൻ (Al-Quran) — ആപ്പ് ബ്രാൻഡിംഗ് & കസ്റ്റമൈസേഷൻ ഗൈഡ്

ഈ ആപ്പിന്റെ **പേര്, ലോഗോ, ഫോൺ ഐക്കൺ, നിറങ്ങൾ, APK ഫയൽ പേര്, പാക്കേജ് ഐഡി** എന്നിവ ഭാവിയിൽ നിങ്ങൾക്ക് സ്വയം എളുപ്പത്തിൽ മാറ്റുന്നതിനുള്ള സമ്പൂർണ്ണ മാർഗ്ഗനിർദ്ദേശമാണിത്.

---

## 1. പ്രധാന ഫയലുകളുടെ സംഗ്രഹം (ദ്രുത സൂചിക)

| എന്താണ് മാറ്റേണ്ടത്? | എഡിറ്റ് ചെയ്യേണ്ട ഫയൽ / ഫോൾഡർ | പ്രധാന ഭാഗം |
| :--- | :--- | :--- |
| ആപ്പിന്റെ പ്രധാന പേര് (UI) | `lib/core/config/app_branding.dart` | `appName`, `appTagline`, `appVersion` |
| ഭാഷാടിസ്ഥാനത്തിലുള്ള പേര് (EN / ML / AR) | `lib/core/l10n/app_strings.dart` | `appTitle` |
| മാസ്റ്റർ ലോഗോ & അഡാപ്റ്റീവ് ഐക്കൺ | `assets/branding/app_logo.png` | `1024 × 1024 px` PNG |
| ഫോൺ ഹോം സ്ക്രീൻ ലോഗോ പശ്ചാത്തലം | `pubspec.yaml` | `flutter_launcher_icons` |
| ആൻഡ്രോയിഡ് ആപ്പ് പേര് (ഫോണിൽ കാണുന്നത്) | `android_config/AndroidManifest.xml` | `android:label="Al-Quran"` |
| വെബ് / PWA പേരും നിറവും | `web/manifest.json`, `web/index.html` | `name`, `short_name`, `theme_color`, `<title>` |
| APK ഫയൽ പേരും പാക്കേജ് ഐഡിയും | `.github/workflows/android-build.yml` | `--org`, `Al-Quran.apk` |

---

## 2. ആപ്പിന്റെ പേര് മാറ്റുന്ന വിധം

ആപ്പിന്റെ ഡിഫോൾട്ട് പേര് ഇപ്പോൾ **`Al-Quran`** എന്നാണ് സെറ്റ് ചെയ്തിരിക്കുന്നത്. ഇത് മറ്റൊരു പേരിലേക്ക് മാറ്റാൻ താഴെ പറയുന്ന സ്ഥലങ്ങളിൽ മാറ്റം വരുത്തുക:

### A. ആപ്പിനുള്ളിലെ പേരും ടാഗ്‌ലൈനും (In-App UI)
1. `lib/core/config/app_branding.dart` തുറക്കുക:
   ```dart
   static const String appName = 'Al-Quran';
   static const String appTagline = 'Read, Listen & Export';
   static const String appVersion = '4.0.0';
   ```
   ഇവിടെ `'Al-Quran'` എന്നതിന് പകരം നിങ്ങൾക്ക് ഇഷ്ടമുള്ള പേര് നൽകുക.
2. മലയാളം, ഇംഗ്ലീഷ്, അറബിക് ഭാഷകളിലെ ഹെഡർ പേര് മാറ്റാൻ `lib/core/l10n/app_strings.dart` തുറന്ന് 12-ാമത്തെ വരി തിരുത്തുക:
   ```dart
   String get appTitle => _pick('Al-Quran', 'അൽ-ഖുർആൻ', 'القرآن الكريم');
   ```

### B. ആൻഡ്രോയിഡ് ഫോണിൽ ഇൻസ്റ്റാൾ ചെയ്യുമ്പോൾ കാണുന്ന പേര്
1. `android_config/AndroidManifest.xml` തുറക്കുക.
2. `<application ...>` ഭാഗത്ത് `android:label` മാറ്റുക:
   ```xml
   android:label="നിങ്ങളുടെ പുതിയ പേര്"
   ```

### C. വെബ് ബ്രൗസറിലും PWA-യിലും കാണുന്ന പേര്
1. `web/index.html` തുറന്ന് താഴെ കാണുന്ന 3 വരികൾ മാറ്റുക:
   - `<title>Al-Quran</title>`
   - `<meta name="apple-mobile-web-app-title" content="Al-Quran">`
   - `<meta property="og:title" content="Al-Quran">`
2. `web/manifest.json` തുറന്ന് `name`, `short_name` എന്നിവ മാറ്റുക:
   ```json
   "name": "Al-Quran",
   "short_name": "Al-Quran",
   ```

---

## 3. ആപ്പ് ലോഗോയും ഫോൺ ഐക്കണും മാറ്റുന്ന വിധം

എല്ലാ സ്ഥലങ്ങളിലേക്കും (ആപ്പിന്റെ മുകൾഭാഗം, സെറ്റിംഗ്സ് ഡ്രോയർ, ആൻഡ്രോയിഡ് ലോഞ്ചർ ഐക്കൺ, വെബ് ഐക്കണുകൾ) ഒരൊറ്റ മാസ്റ്റർ ലോഗോയിൽ നിന്നാണ് ചിത്രം എടുക്കുന്നത്.

### ഘട്ടം 1: പുതിയ ലോഗോ തയ്യാറാക്കുക
- **മാസ്റ്റർ ലോഗോ (`assets/branding/app_logo.png`)**:
  - വലിപ്പം: **`1024 × 1024` പിക്സൽ (1:1 സ്ക്വയർ)**
  - ഫോർമാറ്റ്: **`PNG`**
  - ശ്രദ്ധിക്കേണ്ട കാര്യം: നാലു മൂലകളിലും വെള്ള നിറം (White Corners) ഒഴിവാക്കി മുഴുവനായും (Full-bleed) പശ്ചാത്തല നിറം നൽകുക.
- **അഡാപ്റ്റീവ് ഫോർഗ്രൗണ്ട് ലോഗോ (`assets/branding/app_logo_foreground.png`)**:
  - ആൻഡ്രോയിഡ് ഫോണുകളിൽ വൃത്താകൃതിയിലോ (Circle) സ്ക്വയർ ആകൃതിയിലോ ഐക്കൺ മുറിയാതിരിക്കാൻ, പ്രധാന ചിഹ്നം മധ്യത്തിലെ **65%–70% ഭാഗത്ത്** മാത്രം വരുന്ന രീതിയിൽ സുതാര്യമായ (Transparent) പശ്ചാത്തലത്തോടെ `1024 × 1024 PNG` ആയി സേവ് ചെയ്യുക.

### ഘട്ടം 2: ലോഗോ ഫയലുകൾ റീപ്ലേസ് ചെയ്യുക
1. നിങ്ങളുടെ പുതിയ ലോഗോ ഫയലുകൾ പഴയവയ്ക്ക് പകരമായി `assets/branding/` ഫോൾഡറിൽ അതേ പേരിൽ സേവ് ചെയ്യുക:
   - `assets/branding/app_logo.png`
   - `assets/branding/app_logo_foreground.png`

### ഘട്ടം 3: എല്ലാ ഫോൺ/വെബ് ഐക്കണുകളും ഓട്ടോമാറ്റിക്കായി അപ്ഡേറ്റ് ചെയ്യുക
ടെർമിനലിൽ താഴെ പറയുന്ന കമാൻഡുകൾ റൺ ചെയ്യുക:
```bash
flutter pub get
dart run flutter_launcher_icons
```
ഇത് പ്രവർത്തിക്കുമ്പോൾ:
- `assets/branding/app_logo.png` ഉപയോഗിച്ച് വെബിലെ എല്ലാ ഐക്കണുകളും (`web/favicon.png`, `web/icons/Icon-192.png`, `Icon-512.png`, `Icon-maskable-*.png`) പുതുക്കും.
- GitHub Actions വഴി APK ബിൽഡ് ചെയ്യുമ്പോഴും ഈ കമാൻഡ് ഓട്ടോമാറ്റിക്കായി റൺ ചെയ്ത് ആൻഡ്രോയിഡ് ലോഞ്ചർ ഐക്കണുകൾ (`mipmap-*`) APK-യിൽ ഉൾപ്പെടുത്തും.

*(ഓപ്ഷണൽ: വെബ് ഫാവിക്കോണുകൾ വേഗത്തിൽ സ്വയം മാറ്റാൻ `web/favicon.png`, `web/icons/` എന്നിവയിലുള്ള PNG ഫയലുകളും നേരിട്ട് മാറ്റി നൽകാവുന്നതാണ്.)*

---

## 4. ബ്രാൻഡ് നിറങ്ങളും (Brand Colors) ഐക്കൺ പശ്ചാത്തലവും മാറ്റുന്ന വിധം

### A. ആപ്പിന്റെ തീം നിറങ്ങൾ (UI Colors)
`lib/core/config/app_branding.dart` എന്ന ഫയലിൽ ഹെക്സ് കോഡുകൾ (Hex Colors) മാറ്റുക (ഉദാഹരണത്തിന് `0xFF` എന്നതിന് ശേഷം 6 അക്ക കളർ കോഡ് നൽകുക):
```dart
static const Color primaryEmerald = Color(0xFF047857);
static const Color darkEmerald = Color(0xFF064E3B);
static const Color headerEmerald = Color(0xFF065F46);
static const Color accentGold = Color(0xFFD97706);
```

### B. ആൻഡ്രോയിഡ് Adaptive Icon പശ്ചാത്തല നിറം
`pubspec.yaml` ഫയലിൽ `flutter_launcher_icons:` എന്ന ഭാഗത്ത് മാറ്റം വരുത്തുക:
```yaml
flutter_launcher_icons:
  android: true
  ios: false
  image_path: "assets/branding/app_logo.png"
  adaptive_icon_background: "#045A3D"
  adaptive_icon_foreground: "assets/branding/app_logo_foreground.png"
  min_sdk_android: 21
  web:
    generate: true
    image_path: "assets/branding/app_logo.png"
    background_color: "#047857"
    theme_color: "#047857"
```

### C. വെബ് ബ്രൗസർ & PWA തീം നിറം
1. `web/manifest.json` ഫയലിൽ `"background_color"`, `"theme_color"` എന്നിവ മാറ്റുക.
2. `web/index.html` ഫയലിൽ `<meta name="theme-color" content="#047857">` എന്നത് പുതിയ നിറത്തിലേക്ക് മാറ്റുക.

---

## 5. Package ID, Version & APK ഫയലിന്റെ പേര് മാറ്റുന്ന വിധം

ആൻഡ്രോയിഡ് ഫോണിൽ ഒരു പുതിയ സ്വതന്ത്ര ആപ്പ് പോലെ ഇൻസ്റ്റാൾ ചെയ്യാനോ, ഡൗൺലോഡ് ചെയ്യുന്ന `.apk` ഫയലിന്റെ പേര് മാറ്റാനോ താഴെ പറയുന്നവ ശ്രദ്ധിക്കുക:

1. **പാക്കേജ് ഐഡി (Package / Organization ID)**:
   `.github/workflows/android-build.yml` തുറന്ന് `--org` ഭാഗം മാറ്റുക:
   ```yaml
   run: flutter create . --platforms=android --org com.quranapp.malayalam && rm -f test/widget_test.dart
   ```
   *(ശ്രദ്ധിക്കുക: `com.yourcompany` നൽകിയാൽ Flutter സ്വയം `com.yourcompany.quran_malayalam_app` എന്ന പാക്കേജ് ഐഡി നിർമ്മിക്കും. ഒരിക്കൽ Play Store-ൽ ഇട്ടതിന് ശേഷം പാക്കേജ് ഐഡി മാറ്റരുത്.)*

2. **APK ഫയലിന്റെ പേര്**:
   `.github/workflows/android-build.yml` ഫയലിൽ അവസാന ഭാഗത്ത്:
   ```yaml
   cp build/app/outputs/flutter-apk/app-release.apk build/app/outputs/flutter-apk/Al-Quran.apk
   ```
   എന്നതിലെ `Al-Quran.apk` എന്നതും `name: Al-Quran-APK` എന്നതും നിങ്ങൾക്ക് ഇഷ്ടമുള്ള പേരാക്കി മാറ്റാം.

3. **ആപ്പ് വേർഷൻ നമ്പർ (Version Update)**:
   - `pubspec.yaml`: `version: 4.0.0+4` (ഉദാഹരണത്തിന് അടുത്ത അപ്ഡേറ്റിന് `4.1.0+5`)
   - `lib/core/config/app_branding.dart`: `static const String appVersion = '4.0.0';`

---

## 6. മാറ്റങ്ങൾക്ക് ശേഷം പുതുതായി ബിൽഡ് ചെയ്യുന്ന വിധം

എഡിറ്റിംഗ് പൂർത്തിയായാൽ പുതിയ ആപ്പ് നിർമ്മിക്കാൻ:

### 1. GitHub Actions വഴി Android APK ഉണ്ടാക്കാൻ:
മാറ്റങ്ങൾ `main` ബ്രാഞ്ചിലേക്ക് Push ചെയ്യുക (അല്ലെങ്കിൽ GitHub Actions-ൽ **Build Quran Android APK → Run workflow** ക്ലിക്ക് ചെയ്യുക). ബിൽഡ് പൂർത്തിയാകുമ്പോൾ പുതിയ ലോഗോയും പേരുമുള്ള **`Al-Quran.apk`** ഡൗൺലോഡ് ചെയ്യാൻ ലഭിക്കും.

### 2. കമ്പ്യൂട്ടറിൽ ലോക്കലായി ബിൽഡ് ചെയ്യാൻ:
```bash
# ഡിപെൻഡൻസികളും ഐക്കണുകളും അപ്ഡേറ്റ് ചെയ്യുക
flutter pub get
dart run flutter_launcher_icons

# കോഡ് ചെക്ക് ചെയ്യുക
flutter analyze

# Android APK നിർമ്മിക്കുക
flutter build apk --release

# Web ആപ്പ് നിർമ്മിക്കുക
flutter build web --release
```

---

## 7. ശ്രദ്ധിക്കേണ്ട ചെറിയ കാര്യങ്ങൾ (Tips)

- ലോഗോ ഫയലുകൾ മാറ്റിയ ശേഷം ബ്രൗസറിൽ പഴയ ഐക്കൺ കാണുന്നുവെങ്കിൽ ബ്രൗസർ ക്യാഷ് ക്ലിയർ ചെയ്യുക (`Ctrl + Shift + R`).
- ആൻഡ്രോയിഡ് ഫോണിൽ പഴയ ആപ്പിന് മുകളിൽ ഇൻസ്റ്റാൾ ചെയ്യുമ്പോൾ പഴയ ഐക്കൺ തന്നെ കാണുന്നുവെങ്കിൽ ഫോൺ റീസ്റ്റാർട്ട് ചെയ്യുകയോ ആപ്പ് അൺഇൻസ്റ്റാൾ ചെയ്ത് പുതിയ APK ഇൻസ്റ്റാൾ ചെയ്യുകയോ ചെയ്യുക.
- അഡാപ്റ്റീവ് ഐക്കണിന്റെ വൃത്തത്തിനുള്ളിൽ ലോഗോ മുറിഞ്ഞുപോകാതിരിക്കാൻ പ്രധാന ചിഹ്നം എല്ലായ്പ്പോഴും നടുക്കുള്ള **66% സുരക്ഷിത മേഖലയിൽ** തന്നെ ക്രമീകരിക്കുക.
