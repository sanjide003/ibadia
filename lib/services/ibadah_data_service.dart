import 'dart:convert';

import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models/ibadah_models.dart';

class IbadahDataService {
  static final IbadahDataService instance = IbadahDataService._internal();
  IbadahDataService._internal();

  Future<NiyyahBundle>? _niyyahFuture;
  Future<SalahGuideBundle>? _salahFuture;
  Future<SunnahAndSurahsBundle>? _sunnahFuture;
  Future<MayyithGuideBundle>? _mayyithFuture;

  Future<NiyyahBundle> loadNiyyah() {
    return _niyyahFuture ??= _readJson('assets/data/ibadah/niyyah.json')
        .then(NiyyahBundle.fromJson);
  }

  Future<SalahGuideBundle> loadSalahGuide() {
    return _salahFuture ??= _readJson('assets/data/ibadah/salah_guide.json')
        .then(SalahGuideBundle.fromJson);
  }

  Future<SunnahAndSurahsBundle> loadSunnahAndSurahs() {
    return _sunnahFuture ??=
        _readJson('assets/data/ibadah/sunnah_and_surahs.json')
            .then(SunnahAndSurahsBundle.fromJson);
  }

  Future<MayyithGuideBundle> loadMayyithGuide() {
    return _mayyithFuture ??= _readJson('assets/data/ibadah/mayyith_guide.json')
        .then(MayyithGuideBundle.fromJson);
  }

  Future<Map<String, dynamic>> _readJson(String assetPath) async {
    final raw = await rootBundle.loadString(assetPath);
    return jsonDecode(raw) as Map<String, dynamic>;
  }
}

final ibadahNiyyahProvider = FutureProvider<NiyyahBundle>((ref) {
  return IbadahDataService.instance.loadNiyyah();
});

final ibadahSalahGuideProvider = FutureProvider<SalahGuideBundle>((ref) {
  return IbadahDataService.instance.loadSalahGuide();
});

final ibadahSunnahSurahsProvider =
    FutureProvider<SunnahAndSurahsBundle>((ref) {
  return IbadahDataService.instance.loadSunnahAndSurahs();
});

final ibadahMayyithProvider = FutureProvider<MayyithGuideBundle>((ref) {
  return IbadahDataService.instance.loadMayyithGuide();
});
