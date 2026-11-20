import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../core/l10n/app_strings.dart';
import '../models/surah_model.dart';
import '../services/quran_api_service.dart';
import '../services/storage_service.dart';

final apiServiceProvider = Provider<QuranApiService>((ref) => QuranApiService());
final storageServiceProvider =
    Provider<StorageService>((ref) => StorageService());

final surahListProvider = FutureProvider<List<SurahSummary>>((ref) async {
  return ref.read(apiServiceProvider).fetchSurahList();
});

class SettingsNotifier extends StateNotifier<AppSettings> {
  final StorageService _storage;

  SettingsNotifier(this._storage) : super(const AppSettings()) {
    _init();
  }

  Future<void> _init() async {
    state = await _storage.loadSettings();
  }

  Future<void> update(AppSettings next) async {
    state = next;
    await _storage.saveSettings(next);
  }

  Future<void> toggleTranslationLang(String code) async {
    final current = List<String>.from(state.selectedTranslations);
    if (current.contains(code)) {
      if (current.length > 1) {
        current.remove(code);
      }
    } else {
      current.add(code);
    }
    await update(state.copyWith(selectedTranslations: current));
  }
}

final settingsProvider =
    StateNotifierProvider<SettingsNotifier, AppSettings>((ref) {
  return SettingsNotifier(ref.read(storageServiceProvider));
});

final stringsProvider = Provider<AppStrings>((ref) {
  final lang = ref.watch(settingsProvider.select((s) => s.appLanguage));
  return AppStrings(lang);
});

class BookmarksNotifier extends StateNotifier<List<String>> {
  final StorageService _storage;

  BookmarksNotifier(this._storage) : super(const []) {
    _init();
  }

  Future<void> _init() async {
    state = await _storage.loadBookmarks();
  }

  Future<void> toggle(String ayahKey) async {
    final updated = List<String>.from(state);
    if (updated.contains(ayahKey)) {
      updated.remove(ayahKey);
    } else {
      updated.insert(0, ayahKey);
    }
    state = updated;
    await _storage.saveBookmarks(updated);
  }
}

final bookmarksProvider =
    StateNotifierProvider<BookmarksNotifier, List<String>>((ref) {
  return BookmarksNotifier(ref.read(storageServiceProvider));
});

class LastReadNotifier extends StateNotifier<LastReadPosition?> {
  final StorageService _storage;

  LastReadNotifier(this._storage) : super(null) {
    _init();
  }

  Future<void> _init() async {
    state = await _storage.loadLastRead();
  }

  Future<void> setPosition(LastReadPosition pos) async {
    state = pos;
    await _storage.saveLastRead(pos);
  }
}

final lastReadProvider =
    StateNotifierProvider<LastReadNotifier, LastReadPosition?>((ref) {
  return LastReadNotifier(ref.read(storageServiceProvider));
});
