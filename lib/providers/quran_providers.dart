import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../core/l10n/app_strings.dart';
import '../models/recent_activity_model.dart';
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
  Future<void>? _initFutureBacking;
  Future<void> get _initFuture => _initFutureBacking ??= _init();
  Future<void>? _writeChainBacking;
  Future<void> get _writeChain => _writeChainBacking ??= Future<void>.value();
  set _writeChain(Future<void> v) => _writeChainBacking = v;
  bool? _hasExplicitWriteBacking;
  bool get _hasExplicitWrite => _hasExplicitWriteBacking ?? false;
  set _hasExplicitWrite(bool v) => _hasExplicitWriteBacking = v;

  SettingsNotifier(this._storage) : super(const AppSettings()) {
    _initFuture;
  }

  Future<void> _init() async {
    final loaded = await _storage.loadSettings();
    if (!_hasExplicitWrite) {
      state = loaded;
    }
  }

  Future<AppSettings> ensureLoaded() async {
    await _initFuture;
    return state;
  }

  Future<void> updateWith(AppSettings Function(AppSettings current) updater) {
    final op = _writeChain.then((_) async {
      await _initFuture;
      _hasExplicitWrite = true;
      final next = updater(state);
      state = next;
      await _storage.saveSettings(next);
    });
    _writeChain = op.catchError((_) {});
    return op;
  }

  Future<void> update(AppSettings next) => updateWith((_) => next);

  Future<void> toggleTranslationLang(String code) {
    return updateWith((currentState) {
      final current = List<String>.from(currentState.selectedTranslations);
      if (current.contains(code)) {
        if (current.length > 1) {
          current.remove(code);
        }
      } else {
        current.add(code);
      }
      return currentState.copyWith(selectedTranslations: current);
    });
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
  Future<void>? _initFutureBacking;
  Future<void> get _initFuture => _initFutureBacking ??= _init();
  Future<void>? _writeChainBacking;
  Future<void> get _writeChain => _writeChainBacking ??= Future<void>.value();
  set _writeChain(Future<void> v) => _writeChainBacking = v;

  BookmarksNotifier(this._storage) : super(const []) {
    _initFuture;
  }

  Future<void> _init() async {
    state = await _storage.loadBookmarks();
  }

  Future<void> toggle(String ayahKey) {
    final op = _writeChain.then((_) async {
      await _initFuture;
      final updated = List<String>.from(state);
      if (updated.contains(ayahKey)) {
        updated.remove(ayahKey);
      } else {
        updated.insert(0, ayahKey);
      }
      state = updated;
      await _storage.saveBookmarks(updated);
    });
    _writeChain = op.catchError((_) {});
    return op;
  }
}

final bookmarksProvider =
    StateNotifierProvider<BookmarksNotifier, List<String>>((ref) {
  return BookmarksNotifier(ref.read(storageServiceProvider));
});

class LastReadNotifier extends StateNotifier<LastReadPosition?> {
  final StorageService _storage;
  Future<void>? _initFutureBacking;
  Future<void> get _initFuture => _initFutureBacking ??= _init();
  Future<void>? _writeChainBacking;
  Future<void> get _writeChain => _writeChainBacking ??= Future<void>.value();
  set _writeChain(Future<void> v) => _writeChainBacking = v;
  bool? _hasExplicitWriteBacking;
  bool get _hasExplicitWrite => _hasExplicitWriteBacking ?? false;
  set _hasExplicitWrite(bool v) => _hasExplicitWriteBacking = v;

  LastReadNotifier(this._storage) : super(null) {
    _initFuture;
  }

  Future<void> _init() async {
    final loaded = await _storage.loadLastRead();
    if (!_hasExplicitWrite) {
      state = loaded;
    }
  }

  Future<LastReadPosition?> ensureLoaded() async {
    await _initFuture;
    return state;
  }

  Future<void> setPosition(LastReadPosition pos) {
    final op = _writeChain.then((_) async {
      await _initFuture;
      _hasExplicitWrite = true;
      state = pos;
      await _storage.saveLastRead(pos);
    });
    _writeChain = op.catchError((_) {});
    return op;
  }
}

final lastReadProvider =
    StateNotifierProvider<LastReadNotifier, LastReadPosition?>((ref) {
  return LastReadNotifier(ref.read(storageServiceProvider));
});

class AppResumeNotifier extends StateNotifier<AppResumeState> {
  final StorageService _storage;
  Future<void>? _initFutureBacking;
  Future<void> get _initFuture => _initFutureBacking ??= _init();
  bool? _hasExplicitWriteBacking;
  bool get _hasExplicitWrite => _hasExplicitWriteBacking ?? false;
  set _hasExplicitWrite(bool v) => _hasExplicitWriteBacking = v;

  AppResumeNotifier(this._storage) : super(const AppResumeState()) {
    _initFuture;
  }

  Future<void> _init() async {
    final loaded = await _storage.loadResumeState();
    if (!_hasExplicitWrite) {
      state = loaded;
    }
  }

  Future<AppResumeState> ensureLoaded() async {
    await _initFuture;
    return state;
  }

  Future<void> updateState(AppResumeState Function(AppResumeState) updater) async {
    await _initFuture;
    _hasExplicitWrite = true;
    final next = updater(state);
    state = next;
    await _storage.saveResumeState(next);
  }

  Future<void> updateHomeTabsAndScroll({
    int? homeTabIndex,
    int? quranSubTabIndex,
    int? featuresSubTabIndex,
    double? surahListScrollOffset,
    double? juzListScrollOffset,
    double? bookmarksScrollOffset,
    String? lastScreen,
  }) {
    return updateState(
      (s) => s.copyWith(
        lastScreen: lastScreen ?? s.lastScreen,
        homeTabIndex: homeTabIndex ?? s.homeTabIndex,
        quranSubTabIndex: quranSubTabIndex ?? s.quranSubTabIndex,
        featuresSubTabIndex: featuresSubTabIndex ?? s.featuresSubTabIndex,
        surahListScrollOffset:
            surahListScrollOffset ?? s.surahListScrollOffset,
        juzListScrollOffset: juzListScrollOffset ?? s.juzListScrollOffset,
        bookmarksScrollOffset:
            bookmarksScrollOffset ?? s.bookmarksScrollOffset,
      ),
    );
  }

  Future<void> setReaderActive({
    required int surahNumber,
    required int ayahNumber,
    int? pageNumber,
    required double anchorOffsetPx,
    required String readingMode,
  }) {
    return updateState(
      (s) => s.copyWith(
        lastScreen: 'reader',
        activeSurahNumber: surahNumber,
        activeAyahNumber: ayahNumber,
        activePageNumber: pageNumber,
        activeAnchorOffsetPx: anchorOffsetPx,
        activeReadingMode: readingMode,
      ),
    );
  }

  Future<void> markReturnedHome() {
    return updateState(
      (s) => s.copyWith(lastScreen: 'home'),
    );
  }
}

final appResumeProvider =
    StateNotifierProvider<AppResumeNotifier, AppResumeState>((ref) {
  return AppResumeNotifier(ref.read(storageServiceProvider));
});

class RecentActivityNotifier extends StateNotifier<List<RecentActivityEntry>> {
  final StorageService _storage;
  Future<void>? _initFutureBacking;
  Future<void> get _initFuture => _initFutureBacking ??= _init();
  bool? _hasExplicitWriteBacking;
  bool get _hasExplicitWrite => _hasExplicitWriteBacking ?? false;
  set _hasExplicitWrite(bool v) => _hasExplicitWriteBacking = v;

  RecentActivityNotifier(this._storage) : super(const []) {
    _initFuture;
  }

  Future<void> _init() async {
    final raw = await _storage.loadRecentActivitiesRaw();
    if (!_hasExplicitWrite) {
      state = raw
          .map(RecentActivityEntry.fromJson)
          .take(RecentActivityEntry.maxHistoryCount)
          .toList();
    }
  }

  Future<void> record(RecentActivityEntry entry) async {
    await _initFuture;
    _hasExplicitWrite = true;
    final updated = [
      entry,
      ...state.where((e) => e.id != entry.id),
    ].take(RecentActivityEntry.maxHistoryCount).toList();
    state = updated;
    await _storage.saveRecentActivitiesRaw(
      updated.map((e) => e.toJson()).toList(),
    );
  }

  Future<void> clearAll() async {
    _hasExplicitWrite = true;
    state = const [];
    await _storage.saveRecentActivitiesRaw(const []);
  }
}

final recentActivityProvider =
    StateNotifierProvider<RecentActivityNotifier, List<RecentActivityEntry>>(
        (ref) {
  return RecentActivityNotifier(ref.read(storageServiceProvider));
});
