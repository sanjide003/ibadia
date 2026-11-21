import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';

import '../core/l10n/app_strings.dart';
import '../models/surah_model.dart';
import '../providers/quran_providers.dart';
import '../services/export_service.dart';
import '../services/storage_service.dart';

class ExportScreen extends ConsumerStatefulWidget {
  const ExportScreen({super.key});

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

  ExportPageSize _pageSize = ExportPageSize.automatic;
  ExportFormat _format = ExportFormat.pdf;

  bool _isGenerating = false;
  String? _errorMessage;

  @override
  void dispose() {
    _fromController.dispose();
    _toController.dispose();
    super.dispose();
  }

  void _syncDefaultsFromSettings(AppSettings settings) {
    if (_syncedSettingsOnce) return;
    _syncedSettingsOnce = true;
    _includeTranslation = settings.showTranslation;
    if (settings.selectedTranslations.isNotEmpty) {
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
          pageSize: _pageSize,
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
          pageSize: _pageSize,
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

      await Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => ExportPreviewScreen(
            pages: pages,
            pageSize: _pageSize,
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

        return ListView(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 28),
          children: [
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
                              }
                            },
                          ),
                        ),
                      ),
                    ] else ...[
                      InputDecorator(
                        decoration: InputDecoration(
                          labelText: t.selectSurah,
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
                            value: _selectedSurah,
                            isExpanded: true,
                            items: surahs.map((s) {
                              final title = t.lang == 'ar'
                                  ? '${s.number}. ${s.nameArabic}'
                                  : '${s.number}. ${s.englishName} — ${s.nameArabic}';
                              return DropdownMenuItem<int>(
                                value: s.number,
                                child: Text(
                                  '$title (${s.numberOfAyahs})',
                                  overflow: TextOverflow.ellipsis,
                                ),
                              );
                            }).toList(),
                            onChanged: (val) => _onSurahChanged(val, surahs),
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
                    onChanged: (v) => setState(() => _includeTranslation = v),
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

            // 3. Page Size & Format Card
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
                      t.pageSize,
                      style: const TextStyle(
                        fontWeight: FontWeight.w700,
                        fontSize: 14,
                      ),
                    ),
                    const SizedBox(height: 10),
                    SizedBox(
                      width: double.infinity,
                      child: SegmentedButton<ExportPageSize>(
                        segments: [
                          ButtonSegment(
                            value: ExportPageSize.automatic,
                            label: Text(t.sizeAutomatic),
                            icon: const Icon(Icons.smartphone_rounded, size: 18),
                          ),
                          ButtonSegment(
                            value: ExportPageSize.a4,
                            label: Text(t.sizeA4),
                            icon: const Icon(Icons.description_outlined,
                                size: 18),
                          ),
                        ],
                        selected: {_pageSize},
                        onSelectionChanged: (sel) =>
                            setState(() => _pageSize = sel.first),
                      ),
                    ),
                    if (_pageSize == ExportPageSize.automatic) ...[
                      const SizedBox(height: 8),
                      Text(
                        t.sizeAutomaticDesc,
                        style: TextStyle(
                          fontSize: 12,
                          color: cs.onSurfaceVariant,
                        ),
                      ),
                    ],
                    const SizedBox(height: 16),
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
                        onSelectionChanged: (sel) =>
                            setState(() => _format = sel.first),
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
  final ExportPageSize pageSize;
  final ExportFormat format;
  final bool includeTranslation;
  final List<String> translationCodes;
  final String baseFileName;
  final String documentTitle;
  final AppStrings strings;

  const ExportPreviewScreen({
    super.key,
    required this.pages,
    required this.pageSize,
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
  final GlobalKey _captureKey = GlobalKey();
  ExportPageData? _capturingPage;
  int _capturingIndex = -1;
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
      // Pre-warm fonts before mounting page 1 into the visible capture modal.
      ExportLayoutSpec.forPageSize(widget.pageSize);
      await GoogleFonts.pendingFonts();

      for (int i = 0; i < widget.pages.length; i++) {
        if (!mounted) return;
        setState(() {
          _capturingIndex = i;
          _capturingPage = widget.pages[i];
          _progress = (i + 0.5) / widget.pages.length;
          _progressLabel = '${t.preparingPages} ${i + 1}/${widget.pages.length}';
        });

        await WidgetsBinding.instance.endOfFrame;
        await GoogleFonts.pendingFonts();
        await WidgetsBinding.instance.endOfFrame;
        await Future<void>.delayed(Duration(milliseconds: i == 0 ? 120 : 50));
        await WidgetsBinding.instance.endOfFrame;

        final renderObject = _captureKey.currentContext?.findRenderObject();
        if (renderObject is! RenderRepaintBoundary || !renderObject.hasSize) {
          throw Exception('Capture boundary unavailable');
        }

        final pageSize = renderObject.size;
        logicalSizes.add(pageSize);

        double pixelRatio =
            widget.pageSize == ExportPageSize.a4 ? 2.4 : 2.6;
        if (pageSize.height * pixelRatio > 3800.0 && pageSize.height > 0) {
          pixelRatio = (3800.0 / pageSize.height).clamp(1.2, 2.6);
        }

        final image = await renderObject.toImage(pixelRatio: pixelRatio);
        try {
          final byteData =
              await image.toByteData(format: ui.ImageByteFormat.png);
          if (byteData == null) {
            throw Exception('Failed to encode PNG bytes');
          }
          capturedPngs.add(byteData.buffer.asUint8List());
        } finally {
          image.dispose();
        }
      }

      if (!mounted) return;
      setState(() {
        _capturingPage = null;
        _capturingIndex = -1;
      });

      bool saved = false;
      bool savedToGallery = false;

      if (widget.format == ExportFormat.pdf) {
        final pdfBytes = await ExportService.buildPdfBytes(
          pagePngs: capturedPngs,
          pageSize: widget.pageSize,
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
          _capturingPage = null;
          _capturingIndex = -1;
          _isExporting = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final t = widget.strings;
    final cs = Theme.of(context).colorScheme;
    final sizeLabel = widget.pageSize == ExportPageSize.a4
        ? t.sizeA4
        : t.sizeAutomatic;
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
                    '${widget.pages.length} ${t.pagesLabel} • $formatLabel • $sizeLabel',
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
                        pageSize: widget.pageSize,
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

          // Visible centered modal preview stage so RepaintBoundary paints cleanly with zero GPU occlusion/corruption
          if (_isExporting)
            Positioned.fill(
              child: ColoredBox(
                color: Colors.black.withValues(alpha: 0.62),
                child: SafeArea(
                  child: Center(
                    child: ConstrainedBox(
                      constraints: BoxConstraints(
                        maxWidth: 420,
                        maxHeight: MediaQuery.sizeOf(context).height * 0.82,
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
                                if (_capturingPage != null) ...[
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
                                          child: RepaintBoundary(
                                            key: _captureKey,
                                            child: _ExportPageCard(
                                              key: ValueKey('cap_card_$_capturingIndex'),
                                              page: _capturingPage!,
                                              pageSize: widget.pageSize,
                                              includeTranslation:
                                                  widget.includeTranslation,
                                              translationCodes: widget.translationCodes,
                                            ),
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
  final ExportPageSize pageSize;
  final bool includeTranslation;
  final List<String> translationCodes;

  const _ExportPageCard({
    super.key,
    required this.page,
    required this.pageSize,
    required this.includeTranslation,
    required this.translationCodes,
  });

  @override
  Widget build(BuildContext context) {
    final spec = ExportLayoutSpec.forPageSize(pageSize);

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

    // Material + explicit TextDecoration.none eliminates debug yellow underlines in all render contexts.
    return Material(
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
          height: spec.cardHeight,
          color: ExportLayoutSpec.paperBg,
          padding: EdgeInsets.symmetric(
            horizontal: spec.hPad,
            vertical: spec.vPad,
          ),
          child: spec.isA4
              ? Align(
                  alignment: Alignment.topCenter,
                  child: FittedBox(
                    fit: BoxFit.scaleDown,
                    alignment: Alignment.topCenter,
                    child: SizedBox(
                      width: spec.innerWidth,
                      child: bodyContent,
                    ),
                  ),
                )
              : bodyContent,
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
              TextSpan(children: spec.buildArabicSpans(section.ayahs)),
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
