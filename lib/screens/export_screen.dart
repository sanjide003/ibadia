import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';

import '../core/l10n/app_strings.dart';
import '../models/recent_activity_model.dart';
import '../models/surah_model.dart';
import '../providers/quran_providers.dart';
import '../services/export_service.dart';
import '../services/storage_service.dart';

class ExportScreen extends ConsumerStatefulWidget {
  final bool showHeader;
  const ExportScreen({super.key, this.showHeader = true});

  @override
  ConsumerState<ExportScreen> createState() => _ExportScreenState();
}

class _ExportScreenState extends ConsumerState<ExportScreen> {
  ExportScope _scope = ExportScope.range;
  int _selectedSurah = 1;
  int _selectedJuz = 1;
  final TextEditingController _fromController = TextEditingController(text: '1');
  final TextEditingController _toController = TextEditingController(text: '7');

  bool _includeTranslation = true;
  List<String> _selectedTranslations = ['ml'];
  bool _syncedSettingsOnce = false;

  ExportFormat _format = ExportFormat.pdf;

  bool _isGenerating = false;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      final loaded = await ref.read(settingsProvider.notifier).ensureLoaded();
      if (!mounted) return;
      setState(() {
        _syncedSettingsOnce = false;
        _syncDefaultsFromSettings(loaded);
      });
    });
  }

  @override
  void dispose() {
    _fromController.dispose();
    _toController.dispose();
    super.dispose();
  }

  ExportScope _parseScope(String raw) {
    switch (raw) {
      case 'surah':
        return ExportScope.surah;
      case 'juz':
        return ExportScope.juz;
      default:
        return ExportScope.range;
    }
  }

  String _scopeKey(ExportScope scope) {
    switch (scope) {
      case ExportScope.surah:
        return 'surah';
      case ExportScope.juz:
        return 'juz';
      case ExportScope.range:
        return 'range';
    }
  }

  void _persistExportSettings() {
    final fromVal = int.tryParse(_fromController.text.trim());
    final toVal = int.tryParse(_toController.text.trim());
    ref.read(settingsProvider.notifier).updateWith(
          (s) => s.copyWith(
            exportScope: _scopeKey(_scope),
            exportSurahNo: _selectedSurah,
            exportJuzNo: _selectedJuz,
            exportFromAyah: fromVal != null && fromVal > 0 ? fromVal : null,
            exportToAyah: toVal != null && toVal > 0 ? toVal : null,
            exportFormat: _format == ExportFormat.image ? 'image' : 'pdf',
            exportIncludeTranslation: _includeTranslation,
            exportTranslationCodes: List<String>.from(_selectedTranslations),
          ),
        );
  }

  void _syncDefaultsFromSettings(AppSettings settings) {
    if (_syncedSettingsOnce) return;
    _syncedSettingsOnce = true;
    _scope = _parseScope(settings.exportScope);
    _selectedSurah = settings.exportSurahNo;
    _selectedJuz = settings.exportJuzNo;
    _fromController.text = '${settings.exportFromAyah}';
    _toController.text = '${settings.exportToAyah}';
    _format = settings.exportFormat == 'image'
        ? ExportFormat.image
        : ExportFormat.pdf;
    _includeTranslation =
        settings.exportIncludeTranslation ?? settings.showTranslation;
    final savedCodes = settings.exportTranslationCodes;
    if (savedCodes != null && savedCodes.isNotEmpty) {
      _selectedTranslations = List<String>.from(savedCodes);
    } else if (settings.selectedTranslations.isNotEmpty) {
      _selectedTranslations = List<String>.from(settings.selectedTranslations);
    }
  }

  void _toggleTranslationCode(String code) {
    setState(() {
      if (_selectedTranslations.contains(code)) {
        if (_selectedTranslations.length > 1) {
          _selectedTranslations.remove(code);
        }
      } else {
        _selectedTranslations.add(code);
      }
    });
    _persistExportSettings();
  }

  void _onSurahChanged(int? surahNo, List<SurahSummary> surahs) {
    if (surahNo == null) return;
    final match = surahs.firstWhere(
      (s) => s.number == surahNo,
      orElse: () => surahs.first,
    );
    setState(() {
      _selectedSurah = surahNo;
      _fromController.text = '1';
      _toController.text = '${match.numberOfAyahs}';
      _errorMessage = null;
    });
    _persistExportSettings();
  }

  Future<void> _openSurahSearchSheet(
    List<SurahSummary> surahs,
    AppStrings t,
  ) async {
    final picked = await showModalBottomSheet<int>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      backgroundColor: Colors.transparent,
      builder: (_) => _SurahSearchBottomSheet(
        surahs: surahs,
        selectedSurah: _selectedSurah,
        strings: t,
      ),
    );
    if (picked != null && mounted) {
      _onSurahChanged(picked, surahs);
    }
  }

  Future<void> _generateAndOpenPreview(
    List<SurahSummary> surahs,
    AppStrings t,
  ) async {
    setState(() => _errorMessage = null);

    final activeTranslations =
        _includeTranslation ? _selectedTranslations : const <String>[];

    if (_scope == ExportScope.range) {
      final surah = surahs.firstWhere(
        (s) => s.number == _selectedSurah,
        orElse: () => surahs.first,
      );
      final fromAyah = int.tryParse(_fromController.text.trim());
      final toAyah = int.tryParse(_toController.text.trim());

      if (fromAyah == null ||
          toAyah == null ||
          fromAyah < 1 ||
          toAyah > surah.numberOfAyahs ||
          fromAyah > toAyah) {
        setState(() {
          _errorMessage =
              '${t.invalidAyahRange} (1 – ${surah.numberOfAyahs})';
        });
        return;
      }
    }

    setState(() => _isGenerating = true);
    try {
      final api = ref.read(apiServiceProvider);
      late final List<ExportPageData> pages;
      late final String baseFileName;
      late final String docTitle;

      if (_scope == ExportScope.juz) {
        final juzDetail = await api.fetchJuzDetail(
          juzNumber: _selectedJuz,
          requiredTranslations: activeTranslations,
        );
        docTitle = '${t.juzLabel} $_selectedJuz';
        baseFileName = 'quran_juz_$_selectedJuz';
        pages = await ExportService.paginateJuz(
          detail: juzDetail,
          includeTranslation: _includeTranslation,
          translationCodes: activeTranslations,
          headerTitle: docTitle,
          headerSubtitle: '${juzDetail.entries.length} ${t.ayahsLabel}',
        );
      } else {
        final surahSummary = surahs.firstWhere(
          (s) => s.number == _selectedSurah,
          orElse: () => surahs.first,
        );
        final fromAyah = _scope == ExportScope.surah
            ? 1
            : int.parse(_fromController.text.trim());
        final toAyah = _scope == ExportScope.surah
            ? surahSummary.numberOfAyahs
            : int.parse(_toController.text.trim());

        final detail = await api.fetchSurahDetail(
          surahNumber: _selectedSurah,
          requiredTranslations: activeTranslations,
        );

        final surahName =
            t.lang == 'ar' ? detail.summary.nameArabic : detail.summary.englishName;
        docTitle = _scope == ExportScope.surah
            ? '${detail.summary.number}. $surahName'
            : '${detail.summary.number}. $surahName ($fromAyah–$toAyah)';
        baseFileName = _scope == ExportScope.surah
            ? 'surah_${detail.summary.number}_${detail.summary.englishName}'
            : 'surah_${detail.summary.number}_${detail.summary.englishName}_${fromAyah}_$toAyah';

        pages = await ExportService.paginateSurah(
          detail: detail,
          fromAyah: fromAyah,
          toAyah: toAyah,
          includeTranslation: _includeTranslation,
          translationCodes: activeTranslations,
          headerTitle: docTitle,
          headerSubtitle:
              '${t.ayahLabel} $fromAyah – $toAyah (${toAyah - fromAyah + 1} ${t.ayahsLabel})',
        );
      }

      if (!mounted) return;
      if (pages.isEmpty) {
        setState(() => _errorMessage = t.invalidAyahRange);
        return;
      }

      ref.read(recentActivityProvider.notifier).record(
            RecentActivityEntry(
              id: 'tool:export',
              type: RecentActivityType.exportPdf,
              titleEn: docTitle,
              titleMl: docTitle,
              titleAr: docTitle,
              subtitleEn: 'Export (${_format.name.toUpperCase()})',
              subtitleMl: 'എക്സ്പോർട്ട് (${_format.name.toUpperCase()})',
              subtitleAr: 'تصدير (${_format.name.toUpperCase()})',
              timestampMs: DateTime.now().millisecondsSinceEpoch,
              quranSubTab: 3,
            ),
          );

      await Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => ExportPreviewScreen(
            pages: pages,
            format: _format,
            includeTranslation: _includeTranslation,
            translationCodes: activeTranslations,
            baseFileName: baseFileName,
            documentTitle: docTitle,
            strings: t,
          ),
        ),
      );
    } catch (_) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(t.loadError)),
      );
    } finally {
      if (mounted) {
        setState(() => _isGenerating = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final surahsAsync = ref.watch(surahListProvider);
    final settings = ref.watch(settingsProvider);
    final t = ref.watch(stringsProvider);
    final cs = Theme.of(context).colorScheme;

    _syncDefaultsFromSettings(settings);

    return surahsAsync.when(
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (_, __) => Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.wifi_off_rounded, size: 42),
              const SizedBox(height: 12),
              Text(t.loadError, textAlign: TextAlign.center),
              const SizedBox(height: 12),
              FilledButton(
                onPressed: () => ref.invalidate(surahListProvider),
                child: Text(t.retry),
              ),
            ],
          ),
        ),
      ),
      data: (surahs) {
        final currentSurah = surahs.firstWhere(
          (s) => s.number == _selectedSurah,
          orElse: () => surahs.first,
        );

        final hPad =
            math.max(16.0, (MediaQuery.sizeOf(context).width - 860) / 2);

        return ListView(
          padding: EdgeInsets.fromLTRB(hPad, 12, hPad, 28),
          children: [
            if (widget.showHeader) ...[
              // Title header
              Row(
                children: [
                  Icon(Icons.picture_as_pdf_rounded, color: cs.primary),
                  const SizedBox(width: 10),
                  Text(
                    t.exportTitle,
                    style: Theme.of(context)
                        .textTheme
                        .titleLarge
                        ?.copyWith(fontWeight: FontWeight.w700),
                  ),
                ],
              ),
              const SizedBox(height: 14),
            ],

            // 1. Scope selector card
            Card(
              elevation: 0,
              color: cs.surfaceContainerLow,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(14),
                side: BorderSide(color: cs.outlineVariant),
              ),
              child: Padding(
                padding: const EdgeInsets.all(14),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      t.exportScope,
                      style: const TextStyle(
                        fontWeight: FontWeight.w700,
                        fontSize: 14,
                      ),
                    ),
                    const SizedBox(height: 10),
                    SizedBox(
                      width: double.infinity,
                      child: SegmentedButton<ExportScope>(
                        segments: [
                          ButtonSegment(
                            value: ExportScope.range,
                            label: Text(
                              t.scopeRange,
                              overflow: TextOverflow.ellipsis,
                            ),
                            icon: const Icon(Icons.format_list_numbered_rounded,
                                size: 18),
                          ),
                          ButtonSegment(
                            value: ExportScope.surah,
                            label: Text(
                              t.scopeSurah,
                              overflow: TextOverflow.ellipsis,
                            ),
                            icon: const Icon(Icons.menu_book_rounded, size: 18),
                          ),
                          ButtonSegment(
                            value: ExportScope.juz,
                            label: Text(
                              t.scopeJuz,
                              overflow: TextOverflow.ellipsis,
                            ),
                            icon: const Icon(Icons.layers_rounded, size: 18),
                          ),
                        ],
                        selected: {_scope},
                        onSelectionChanged: (sel) {
                          setState(() {
                            _scope = sel.first;
                            _errorMessage = null;
                          });
                          _persistExportSettings();
                        },
                      ),
                    ),
                    const SizedBox(height: 14),

                    if (_scope == ExportScope.juz) ...[
                      InputDecorator(
                        decoration: InputDecoration(
                          labelText: t.selectJuz,
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          contentPadding: const EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 4,
                          ),
                        ),
                        child: DropdownButtonHideUnderline(
                          child: DropdownButton<int>(
                            value: _selectedJuz,
                            isExpanded: true,
                            items: List<DropdownMenuItem<int>>.generate(
                              30,
                              (i) {
                                final juz = i + 1;
                                return DropdownMenuItem<int>(
                                  value: juz,
                                  child: Text('${t.juzLabel} $juz'),
                                );
                              },
                            ),
                            onChanged: (val) {
                              if (val != null) {
                                setState(() {
                                  _selectedJuz = val;
                                  _errorMessage = null;
                                });
                                _persistExportSettings();
                              }
                            },
                          ),
                        ),
                      ),
                    ] else ...[
                      InkWell(
                        borderRadius: BorderRadius.circular(12),
                        onTap: () => _openSurahSearchSheet(surahs, t),
                        child: InputDecorator(
                          decoration: InputDecoration(
                            labelText: t.selectSurah,
                            prefixIcon: const Icon(Icons.search_rounded, size: 20),
                            suffixIcon: const Icon(Icons.arrow_drop_down_rounded),
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                            contentPadding: const EdgeInsets.symmetric(
                              horizontal: 12,
                              vertical: 12,
                            ),
                          ),
                          child: Text(
                            t.lang == 'ar'
                                ? '${currentSurah.number}. ${currentSurah.nameArabic} (${currentSurah.numberOfAyahs})'
                                : '${currentSurah.number}. ${currentSurah.englishName} — ${currentSurah.nameArabic} (${currentSurah.numberOfAyahs})',
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                              fontSize: 15,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ),
                      ),
                      if (_scope == ExportScope.range) ...[
                        const SizedBox(height: 12),
                        Row(
                          children: [
                            Expanded(
                              child: TextField(
                                controller: _fromController,
                                keyboardType: TextInputType.number,
                                inputFormatters: [
                                  FilteringTextInputFormatter.digitsOnly,
                                ],
                                decoration: InputDecoration(
                                  labelText: t.fromAyah,
                                  hintText: '1',
                                  border: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  isDense: true,
                                ),
                                onChanged: (_) {
                                  if (_errorMessage != null) {
                                    setState(() => _errorMessage = null);
                                  }
                                  _persistExportSettings();
                                },
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: TextField(
                                controller: _toController,
                                keyboardType: TextInputType.number,
                                inputFormatters: [
                                  FilteringTextInputFormatter.digitsOnly,
                                ],
                                decoration: InputDecoration(
                                  labelText: t.toAyah,
                                  hintText: '${currentSurah.numberOfAyahs}',
                                  border: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  isDense: true,
                                ),
                                onChanged: (_) {
                                  if (_errorMessage != null) {
                                    setState(() => _errorMessage = null);
                                  }
                                  _persistExportSettings();
                                },
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 6),
                        Text(
                          '${t.ayahLabel}: 1 – ${currentSurah.numberOfAyahs}',
                          style: TextStyle(
                            fontSize: 12,
                            color: cs.onSurfaceVariant,
                          ),
                        ),
                      ],
                    ],

                    if (_errorMessage != null) ...[
                      const SizedBox(height: 8),
                      Text(
                        _errorMessage!,
                        style: TextStyle(
                          color: cs.error,
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ),

            const SizedBox(height: 12),

            // 2. Translations Card
            Card(
              elevation: 0,
              color: cs.surfaceContainerLow,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(14),
                side: BorderSide(color: cs.outlineVariant),
              ),
              child: Column(
                children: [
                  SwitchListTile(
                    title: Text(
                      t.includeTranslation,
                      style: const TextStyle(fontWeight: FontWeight.w600),
                    ),
                    value: _includeTranslation,
                    onChanged: (v) {
                      setState(() => _includeTranslation = v);
                      _persistExportSettings();
                    },
                  ),
                  if (_includeTranslation) ...[
                    const Divider(height: 1),
                    Padding(
                      padding: const EdgeInsets.fromLTRB(14, 10, 14, 12),
                      child: Align(
                        alignment: AlignmentDirectional.centerStart,
                        child: Wrap(
                          spacing: 8,
                          runSpacing: 6,
                          children: [
                            FilterChip(
                              label: Text(t.langMalayalam),
                              selected: _selectedTranslations.contains('ml'),
                              onSelected: (_) => _toggleTranslationCode('ml'),
                            ),
                            FilterChip(
                              label: Text(t.langEnglish),
                              selected: _selectedTranslations.contains('en'),
                              onSelected: (_) => _toggleTranslationCode('en'),
                            ),
                            FilterChip(
                              label: Text(t.langArabicTafsir),
                              selected: _selectedTranslations.contains('ar'),
                              onSelected: (_) => _toggleTranslationCode('ar'),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ],
              ),
            ),

            const SizedBox(height: 12),

            // 3. Export Format Card (Mobile-optimized clean layout by default)
            Card(
              elevation: 0,
              color: cs.surfaceContainerLow,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(14),
                side: BorderSide(color: cs.outlineVariant),
              ),
              child: Padding(
                padding: const EdgeInsets.all(14),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      t.exportFormat,
                      style: const TextStyle(
                        fontWeight: FontWeight.w700,
                        fontSize: 14,
                      ),
                    ),
                    const SizedBox(height: 10),
                    SizedBox(
                      width: double.infinity,
                      child: SegmentedButton<ExportFormat>(
                        segments: [
                          ButtonSegment(
                            value: ExportFormat.pdf,
                            label: Text(t.formatPdf),
                            icon:
                                const Icon(Icons.picture_as_pdf_rounded, size: 18),
                          ),
                          ButtonSegment(
                            value: ExportFormat.image,
                            label: Text(t.formatImage),
                            icon: const Icon(Icons.image_outlined, size: 18),
                          ),
                        ],
                        selected: {_format},
                        onSelectionChanged: (sel) {
                          setState(() => _format = sel.first);
                          _persistExportSettings();
                        },
                      ),
                    ),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 20),

            // 4. Generate Preview CTA
            SizedBox(
              height: 52,
              child: FilledButton.icon(
                onPressed: _isGenerating
                    ? null
                    : () => _generateAndOpenPreview(surahs, t),
                icon: _isGenerating
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(
                          strokeWidth: 2.2,
                          color: Colors.white,
                        ),
                      )
                    : const Icon(Icons.visibility_rounded),
                label: Text(
                  t.generatePreview,
                  style: const TextStyle(
                    fontSize: 15.5,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ),
          ],
        );
      },
    );
  }
}

class ExportPreviewScreen extends StatefulWidget {
  final List<ExportPageData> pages;
  final ExportFormat format;
  final bool includeTranslation;
  final List<String> translationCodes;
  final String baseFileName;
  final String documentTitle;
  final AppStrings strings;

  const ExportPreviewScreen({
    super.key,
    required this.pages,
    required this.format,
    required this.includeTranslation,
    required this.translationCodes,
    required this.baseFileName,
    required this.documentTitle,
    required this.strings,
  });

  @override
  State<ExportPreviewScreen> createState() => _ExportPreviewScreenState();
}

class _ExportPreviewScreenState extends State<ExportPreviewScreen> {
  ExportPageData? _renderingPage;
  bool _isExporting = false;
  double _progress = 0.0;
  String _progressLabel = '';

  Future<void> _runExport({required bool share}) async {
    if (_isExporting) return;
    final t = widget.strings;
    setState(() {
      _isExporting = true;
      _progress = 0.0;
      _progressLabel = '${t.preparingPages} 0/${widget.pages.length}';
    });

    final List<Uint8List> capturedPngs = [];
    final List<Size> logicalSizes = [];

    try {
      await GoogleFonts.pendingFonts();

      for (int i = 0; i < widget.pages.length; i++) {
        if (!mounted) return;
        final page = widget.pages[i];
        setState(() {
          _renderingPage = page;
          _progress = (i + 0.5) / widget.pages.length;
          _progressLabel = '${t.preparingPages} ${i + 1}/${widget.pages.length}';
        });

        // Allow UI progress indicator to paint cleanly, then render offscreen on isolated Canvas
        await Future<void>.delayed(const Duration(milliseconds: 18));
        final rendered = await ExportService.renderPagePng(
          page: page,
          includeTranslation: widget.includeTranslation,
          translationCodes: widget.translationCodes,
        );
        capturedPngs.add(rendered.bytes);
        logicalSizes.add(rendered.logicalSize);
      }

      if (!mounted) return;
      setState(() {
        _renderingPage = null;
        _progress = 1.0;
      });

      bool saved = false;
      bool savedToGallery = false;

      if (widget.format == ExportFormat.pdf) {
        final pdfBytes = await ExportService.buildPdfBytes(
          pagePngs: capturedPngs,
          pageLogicalSizes: logicalSizes,
        );
        if (share) {
          await ExportService.sharePdfBytes(
            bytes: pdfBytes,
            baseName: widget.baseFileName,
            title: widget.documentTitle,
          );
        } else {
          saved = await ExportService.savePdfBytes(
            bytes: pdfBytes,
            baseName: widget.baseFileName,
          );
        }
      } else {
        if (share) {
          await ExportService.sharePngPages(
            pages: capturedPngs,
            baseName: widget.baseFileName,
            title: widget.documentTitle,
          );
        } else {
          savedToGallery = await ExportService.savePngPages(
            pages: capturedPngs,
            baseName: widget.baseFileName,
          );
          saved = true;
        }
      }

      if (!mounted) return;
      if (!share && saved) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              savedToGallery
                  ? t.savedToGallery(capturedPngs.length)
                  : t.exportSuccess,
            ),
          ),
        );
      }
    } catch (_) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(t.exportError)),
      );
    } finally {
      if (mounted) {
        setState(() {
          _renderingPage = null;
          _isExporting = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final t = widget.strings;
    final cs = Theme.of(context).colorScheme;
    final formatLabel =
        widget.format == ExportFormat.pdf ? t.formatPdf : t.formatImage;

    return Directionality(
      textDirection: t.textDirection,
      child: Stack(
        children: [
          Scaffold(
            backgroundColor: const Color(0xFFE7ECEF),
            appBar: AppBar(
              title: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    t.exportPreview,
                    style: const TextStyle(
                      fontSize: 17,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  Text(
                    '${widget.pages.length} ${t.pagesLabel} • $formatLabel',
                    style: TextStyle(
                      fontSize: 12,
                      color: cs.onSurfaceVariant,
                    ),
                  ),
                ],
              ),
            ),
            body: ListView.separated(
              padding: const EdgeInsets.symmetric(
                horizontal: 14,
                vertical: 16,
              ),
              itemCount: widget.pages.length,
              separatorBuilder: (_, __) => const SizedBox(height: 16),
              itemBuilder: (context, index) {
                final page = widget.pages[index];
                return Center(
                  child: Container(
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(6),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.12),
                          blurRadius: 12,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    clipBehavior: Clip.antiAlias,
                    child: FittedBox(
                      fit: BoxFit.scaleDown,
                      alignment: Alignment.topCenter,
                      child: _ExportPageCard(
                        page: page,
                        includeTranslation: widget.includeTranslation,
                        translationCodes: widget.translationCodes,
                      ),
                    ),
                  ),
                );
              },
            ),
            bottomNavigationBar: Material(
              elevation: 8,
              color: cs.surface,
              child: SafeArea(
                top: false,
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(16, 10, 16, 12),
                  child: Row(
                    children: [
                      Expanded(
                        child: SizedBox(
                          height: 48,
                          child: FilledButton.icon(
                            onPressed:
                                _isExporting ? null : () => _runExport(share: false),
                            icon: const Icon(Icons.download_rounded),
                            label: Text(
                              t.download,
                              style: const TextStyle(
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: SizedBox(
                          height: 48,
                          child: FilledButton.tonalIcon(
                            onPressed:
                                _isExporting ? null : () => _runExport(share: true),
                            icon: const Icon(Icons.share_rounded),
                            label: Text(
                              t.share,
                              style: const TextStyle(
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),

          if (_isExporting)
            Positioned.fill(
              child: ColoredBox(
                color: Colors.black.withValues(alpha: 0.62),
                child: SafeArea(
                  child: Center(
                    child: ConstrainedBox(
                      constraints: BoxConstraints(
                        maxWidth: 400,
                        maxHeight: MediaQuery.sizeOf(context).height * 0.80,
                      ),
                      child: Padding(
                        padding: const EdgeInsets.all(20),
                        child: Material(
                          color: cs.surface,
                          elevation: 14,
                          borderRadius: BorderRadius.circular(18),
                          clipBehavior: Clip.antiAlias,
                          child: Padding(
                            padding: const EdgeInsets.all(16),
                            child: Column(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Row(
                                  children: [
                                    SizedBox(
                                      width: 18,
                                      height: 18,
                                      child: CircularProgressIndicator(
                                        strokeWidth: 2.2,
                                        color: cs.primary,
                                      ),
                                    ),
                                    const SizedBox(width: 10),
                                    Expanded(
                                      child: Text(
                                        _progressLabel,
                                        style: const TextStyle(
                                          fontSize: 14,
                                          fontWeight: FontWeight.w700,
                                          decoration: TextDecoration.none,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 10),
                                ClipRRect(
                                  borderRadius: BorderRadius.circular(4),
                                  child: LinearProgressIndicator(value: _progress),
                                ),
                                if (_renderingPage != null) ...[
                                  const SizedBox(height: 14),
                                  Flexible(
                                    child: Center(
                                      child: Container(
                                        decoration: BoxDecoration(
                                          color: Colors.white,
                                          borderRadius: BorderRadius.circular(8),
                                          border: Border.all(
                                            color: Colors.black.withValues(alpha: 0.08),
                                          ),
                                          boxShadow: [
                                            BoxShadow(
                                              color: Colors.black.withValues(alpha: 0.12),
                                              blurRadius: 12,
                                              offset: const Offset(0, 4),
                                            ),
                                          ],
                                        ),
                                        clipBehavior: Clip.antiAlias,
                                        child: FittedBox(
                                          fit: BoxFit.contain,
                                          alignment: Alignment.center,
                                          child: _ExportPageCard(
                                            page: _renderingPage!,
                                            includeTranslation:
                                                widget.includeTranslation,
                                            translationCodes: widget.translationCodes,
                                          ),
                                        ),
                                      ),
                                    ),
                                  ),
                                ],
                              ],
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}

class _ExportPageCard extends StatelessWidget {
  final ExportPageData page;
  final bool includeTranslation;
  final List<String> translationCodes;

  const _ExportPageCard({
    required this.page,
    required this.includeTranslation,
    required this.translationCodes,
  });

  @override
  Widget build(BuildContext context) {
    final spec = ExportLayoutSpec.mobile();

    final bodyContent = Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        for (int sIdx = 0; sIdx < page.sections.length; sIdx++) ...[
          if (sIdx > 0) SizedBox(height: spec.sectionGap),
          _buildSection(
            section: page.sections[sIdx],
            spec: spec,
          ),
        ],
      ],
    );

    return MediaQuery(
      data: MediaQuery.of(context).copyWith(textScaler: TextScaler.noScaling),
      child: Material(
        color: ExportLayoutSpec.paperBg,
        textStyle: const TextStyle(
          color: ExportLayoutSpec.inkPrimary,
          decoration: TextDecoration.none,
        ),
        child: DefaultTextStyle(
          style: const TextStyle(
            color: ExportLayoutSpec.inkPrimary,
            decoration: TextDecoration.none,
          ),
          child: Container(
            width: spec.cardWidth,
            color: ExportLayoutSpec.paperBg,
            padding: EdgeInsets.symmetric(
              horizontal: spec.hPad,
              vertical: spec.vPad,
            ),
            child: bodyContent,
          ),
        ),
      ),
    );
  }

  Widget _buildSection({
    required ExportSurahSection section,
    required ExportLayoutSpec spec,
  }) {
    final surah = section.summary;

    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // Clean Surah Banner shown only on the opening slice of each Surah
        if (section.showBanner)
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
            decoration: BoxDecoration(
              color: ExportLayoutSpec.emeraldTint,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(
                color: ExportLayoutSpec.emeraldBorder,
                width: 1,
              ),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Text(
                    '${surah.number}. ${surah.englishName}',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: spec.bannerEnStyle,
                  ),
                ),
                const SizedBox(width: 8),
                Text(
                  surah.nameArabic,
                  textDirection: TextDirection.rtl,
                  style: spec.bannerArStyle,
                ),
              ],
            ),
          ),

        if (section.showBismillah) ...[
          const SizedBox(height: 8),
          Center(
            child: Text(
              'بِسْمِ ٱللَّهِ ٱلرَّحْمَٰنِ ٱلرَّحِيمِ',
              textDirection: TextDirection.rtl,
              style: spec.bismillahStyle,
            ),
          ),
        ],

        if (section.showBanner || section.showBismillah)
          const SizedBox(height: 8),

        // Continuous RTL Mushaf Arabic block with padding so diacritics never clip
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
          child: Directionality(
            textDirection: TextDirection.rtl,
            child: Text.rich(
              TextSpan(
                style: spec.arabicStyle,
                children: spec.buildArabicSpans(section.ayahs),
              ),
              textDirection: TextDirection.rtl,
              textAlign: TextAlign.right,
            ),
          ),
        ),

        if (includeTranslation &&
            section.ayahs.any((a) => a.translations.isNotEmpty)) ...[
          const SizedBox(height: 8),
          Container(
            padding: const EdgeInsets.only(top: 7),
            decoration: const BoxDecoration(
              border: Border(
                top: BorderSide(
                  color: ExportLayoutSpec.divider,
                  width: 0.8,
                ),
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                for (final ayah in section.ayahs)
                  if (ayah.translations.isNotEmpty)
                    Padding(
                      padding: const EdgeInsets.only(bottom: 4),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          for (final code in translationCodes)
                            if ((ayah.translations[code] ?? '').isNotEmpty)
                              _buildTranslationLine(
                                ayahNumber: ayah.numberInSurah,
                                code: code,
                                text: ayah.translations[code]!,
                                spec: spec,
                              ),
                        ],
                      ),
                    ),
              ],
            ),
          ),
        ],
      ],
    );
  }

  Widget _buildTranslationLine({
    required int ayahNumber,
    required String code,
    required String text,
    required ExportLayoutSpec spec,
  }) {
    final bool isAr = code == 'ar';
    final style = spec.translationStyle(code);

    return Padding(
      padding: const EdgeInsets.only(bottom: 2),
      child: Text.rich(
        TextSpan(
          style: style,
          children: [
            TextSpan(
              text: '$ayahNumber. ',
              style: style.copyWith(
                fontWeight: FontWeight.w700,
                color: ExportLayoutSpec.emerald,
              ),
            ),
            TextSpan(text: text, style: style),
          ],
        ),
        textDirection: isAr ? TextDirection.rtl : TextDirection.ltr,
      ),
    );
  }
}

class _SurahSearchBottomSheet extends StatefulWidget {
  final List<SurahSummary> surahs;
  final int selectedSurah;
  final AppStrings strings;

  const _SurahSearchBottomSheet({
    required this.surahs,
    required this.selectedSurah,
    required this.strings,
  });

  @override
  State<_SurahSearchBottomSheet> createState() =>
      _SurahSearchBottomSheetState();
}

class _SurahSearchBottomSheetState extends State<_SurahSearchBottomSheet> {
  final TextEditingController _searchController = TextEditingController();
  String _query = '';

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final t = widget.strings;
    final cs = Theme.of(context).colorScheme;
    final q = _query.trim().toLowerCase();

    final filtered = q.isEmpty
        ? widget.surahs
        : widget.surahs.where((s) {
            return '${s.number}' == q ||
                '${s.number}'.contains(q) ||
                s.englishName.toLowerCase().contains(q) ||
                s.englishNameTranslation.toLowerCase().contains(q) ||
                s.nameArabic.contains(_query.trim());
          }).toList();

    return FractionallySizedBox(
      heightFactor: 0.85,
      child: Material(
        color: cs.surface,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(22)),
        clipBehavior: Clip.antiAlias,
        child: Directionality(
          textDirection: t.textDirection,
          child: Column(
            children: [
              const SizedBox(height: 10),
              Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: cs.outlineVariant,
                  borderRadius: BorderRadius.circular(99),
                ),
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 12, 16, 10),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      t.selectSurah,
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.w700,
                          ),
                    ),
                    const SizedBox(height: 10),
                    TextField(
                      controller: _searchController,
                      autofocus: true,
                      onChanged: (val) => setState(() => _query = val),
                      decoration: InputDecoration(
                        hintText: t.searchSurah,
                        prefixIcon: const Icon(Icons.search_rounded),
                        suffixIcon: _query.isNotEmpty
                            ? IconButton(
                                icon: const Icon(Icons.clear_rounded),
                                onPressed: () {
                                  _searchController.clear();
                                  setState(() => _query = '');
                                },
                              )
                            : null,
                        filled: true,
                        fillColor: cs.surfaceContainerHighest
                            .withValues(alpha: 0.45),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(14),
                          borderSide: BorderSide.none,
                        ),
                        contentPadding: const EdgeInsets.symmetric(
                          horizontal: 14,
                          vertical: 12,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const Divider(height: 1),
              Expanded(
                child: ListView.separated(
                  itemCount: filtered.length,
                  separatorBuilder: (_, __) =>
                      Divider(height: 1, color: cs.outlineVariant.withValues(alpha: 0.4)),
                  itemBuilder: (context, index) {
                    final s = filtered[index];
                    final isSelected = s.number == widget.selectedSurah;
                    return ListTile(
                      selected: isSelected,
                      selectedTileColor:
                          cs.primaryContainer.withValues(alpha: 0.35),
                      onTap: () => Navigator.pop(context, s.number),
                      leading: Container(
                        width: 36,
                        height: 36,
                        alignment: Alignment.center,
                        decoration: BoxDecoration(
                          color: isSelected
                              ? cs.primary
                              : cs.primaryContainer.withValues(alpha: 0.5),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Text(
                          '${s.number}',
                          style: TextStyle(
                            color: isSelected ? cs.onPrimary : cs.primary,
                            fontWeight: FontWeight.w700,
                            fontSize: 13,
                          ),
                        ),
                      ),
                      title: Text(
                        s.englishName,
                        style: const TextStyle(fontWeight: FontWeight.w700),
                      ),
                      subtitle: Text(
                        '${s.numberOfAyahs} ${t.ayahsLabel} • ${t.revelationLabel(s.revelationType)}',
                        style: TextStyle(
                          fontSize: 12,
                          color: cs.onSurfaceVariant,
                        ),
                      ),
                      trailing: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            s.nameArabic,
                            textDirection: TextDirection.rtl,
                            style: GoogleFonts.amiri(
                              fontSize: 19,
                              fontWeight: FontWeight.w700,
                              color: cs.primary,
                            ),
                          ),
                          if (isSelected) ...[
                            const SizedBox(width: 8),
                            Icon(
                              Icons.check_circle_rounded,
                              color: cs.primary,
                              size: 20,
                            ),
                          ],
                        ],
                      ),
                    );
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
