import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:scrollable_positioned_list/scrollable_positioned_list.dart';
import '../providers/quran_provider.dart';
import '../models/surah.dart';
import '../../../l10n/app_localizations.dart';

class SurahPlayerScreen extends StatefulWidget {
  final int surahNumber;
  const SurahPlayerScreen({super.key, required this.surahNumber});

  @override
  State<SurahPlayerScreen> createState() => _SurahPlayerScreenState();
}

class _SurahPlayerScreenState extends State<SurahPlayerScreen> {
  final ItemScrollController _itemScrollController = ItemScrollController();
  final ItemPositionsListener _itemPositionsListener = ItemPositionsListener.create();
  int _lastActiveIndex = -1;

  @override
  void initState() {
    super.initState();
    Future.microtask(() {
      if (mounted) {
        final provider = context.read<QuranProvider>();
        provider.fetchAyahs(provider.currentSurahNumber ?? widget.surahNumber);
      }
    });
  }

  void _scrollToActiveAyah(int index) {
    if (index != -1 && index != _lastActiveIndex) {
      _lastActiveIndex = index;
      if (_itemScrollController.isAttached) {
        _itemScrollController.scrollTo(
          index: index,
          duration: const Duration(milliseconds: 600),
          curve: Curves.easeInOutCubic,
          alignment: 0.3, // Scroll so the active ayah is near the top but with some margin
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final gold = theme.colorScheme.primary;
    final surface = theme.colorScheme.surface;
    final textMain = theme.colorScheme.onSurface;

    return Consumer<QuranProvider>(
      builder: (context, provider, child) {
        final currentSurahNum = provider.currentSurahNumber ?? widget.surahNumber;
        final surah = provider.allSurahs.firstWhere((s) => s.number == currentSurahNum);
        final state = provider.downloadStates[surah.number] ?? DownloadState.notDownloaded;
        final isPlaying = provider.currentSurahNumber == surah.number && provider.isPlaying;
        final ayahs = provider.surahAyahs[surah.number];
        final isFetching = provider.isFetching(surah.number);
        final activeIndex = provider.activeAyahIndex;
        final l10n = AppLocalizations.of(context);

        if (isPlaying) {
          WidgetsBinding.instance.addPostFrameCallback((_) => _scrollToActiveAyah(activeIndex));
        }

        return Scaffold(
          backgroundColor: theme.scaffoldBackgroundColor,
          appBar: AppBar(
            backgroundColor: Colors.transparent,
            elevation: 0,
            leading: IconButton(
              icon: Icon(Icons.arrow_back_ios_new_rounded, color: gold, size: 20),
              onPressed: () => Navigator.pop(context),
            ),
            title: Column(
              children: [
                Text(
                  l10n.isAr ? surah.nameArabic : surah.nameTransliteration,
                  style: theme.appBarTheme.titleTextStyle,
                ),
                Text(
                  l10n.isAr ? surah.nameTransliteration : surah.nameArabic,
                  style: TextStyle(color: textMain.withValues(alpha: 0.6), fontSize: 12),
                ),
              ],
            ),
            centerTitle: true,
            actions: [
              if (state != DownloadState.downloaded)
                IconButton(
                  icon: Icon(Icons.download_rounded, color: theme.colorScheme.secondary),
                  onPressed: () => provider.downloadSurah(surah.number),
                )
              else
                IconButton(
                  icon: const Icon(Icons.delete_outline_rounded, color: Colors.redAccent),
                  onPressed: () async {
                    await provider.deleteSurah(surah.number);
                    if (context.mounted) Navigator.pop(context);
                  },
                ),
            ],
          ),
          body: Column(
            children: [
              Expanded(
                child: isFetching
                    ? Center(child: CircularProgressIndicator(color: gold))
                    : ayahs == null
                        ? Center(child: Text(l10n.loading, style: TextStyle(color: textMain.withValues(alpha: 0.38))))
                        : ScrollablePositionedList.separated(
                            itemScrollController: _itemScrollController,
                            itemPositionsListener: _itemPositionsListener,
                            padding: const EdgeInsets.fromLTRB(20, 20, 20, 40),
                            itemCount: ayahs.length,
                            separatorBuilder: (_, _) => const SizedBox(height: 16),
                            itemBuilder: (context, index) {
                              final ayah = ayahs[index];
                              final isActive = activeIndex == index;
                              return AnimatedContainer(
                                duration: const Duration(milliseconds: 400),
                                padding: const EdgeInsets.all(24),
                                decoration: BoxDecoration(
                                  color: isActive ? gold.withValues(alpha: 0.1) : surface,
                                  borderRadius: BorderRadius.circular(24),
                                  border: Border.all(
                                    color: isActive ? gold : gold.withValues(alpha: 0.1),
                                    width: isActive ? 1.5 : 1,
                                  ),
                                  boxShadow: isActive 
                                      ? [BoxShadow(color: gold.withValues(alpha: 0.1), blurRadius: 10)]
                                      : [],
                                ),
                                child: Column(
                                  children: [
                                    Text(
                                      ayah.text,
                                      textAlign: TextAlign.right,
                                      textDirection: TextDirection.rtl,
                                      style: TextStyle(
                                        color: isActive ? gold : textMain,
                                        fontSize: 26,
                                        fontFamily: 'Traditional Arabic',
                                        height: 1.8,
                                        fontWeight: isActive ? FontWeight.bold : FontWeight.normal,
                                      ),
                                    ),
                                    const SizedBox(height: 16),
                                    Row(
                                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                      children: [
                                        Container(
                                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                                          decoration: BoxDecoration(
                                            color: gold.withValues(alpha: 0.1),
                                            borderRadius: BorderRadius.circular(10),
                                          ),
                                          child: Text(
                                            '${surah.number}:${ayah.numberInSurah}',
                                            style: TextStyle(color: gold, fontSize: 10, fontWeight: FontWeight.bold),
                                          ),
                                        ),
                                        const Spacer(),
                                      ],
                                    ),
                                  ],
                                ),
                              );
                            },
                          ),
              ),

              // Player Controls
              Container(
                padding: const EdgeInsets.fromLTRB(24, 0, 24, 40),
                decoration: BoxDecoration(
                  color: surface,
                  borderRadius: const BorderRadius.vertical(top: Radius.circular(40)),
                  border: Border(top: BorderSide(color: gold.withValues(alpha: 0.2))),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.5),
                      blurRadius: 30,
                      spreadRadius: 5,
                    )
                  ],
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const SizedBox(height: 12),
                    Container(
                      width: 40, height: 4,
                      decoration: BoxDecoration(color: gold.withValues(alpha: 0.2), borderRadius: BorderRadius.circular(2)),
                    ),
                    const SizedBox(height: 16),
                    SliderTheme(
                      data: SliderTheme.of(context).copyWith(
                        trackHeight: 4,
                        thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 8),
                        activeTrackColor: gold,
                        inactiveTrackColor: gold.withValues(alpha: 0.1),
                        thumbColor: gold,
                        overlayColor: gold.withValues(alpha: 0.2),
                      ),
                      child: Slider(
                        value: provider.position.inMilliseconds.toDouble().clamp(0, provider.duration.inMilliseconds.toDouble()),
                        max: provider.duration.inMilliseconds.toDouble(),
                        onChanged: (v) => provider.seekTo(Duration(milliseconds: v.toInt())),
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(_formatDuration(provider.position), style: TextStyle(color: textMain.withValues(alpha: 0.4), fontSize: 11)),
                          Text(_formatDuration(provider.duration), style: TextStyle(color: textMain.withValues(alpha: 0.4), fontSize: 11)),
                        ],
                      ),
                    ),
                    const SizedBox(height: 12),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                      children: [
                        IconButton(
                          icon: Icon(Icons.shuffle_rounded, color: textMain.withValues(alpha: 0.3), size: 20),
                          onPressed: () {},
                        ),
                        IconButton(
                          icon: Icon(Icons.skip_previous_rounded, color: textMain, size: 40),
                          onPressed: () => provider.playSurah(surah.number > 1 ? surah.number - 1 : 114),
                        ),
                        GestureDetector(
                          onTap: () => provider.playSurah(surah.number),
                          child: Container(
                            width: 72,
                            height: 72,
                            decoration: BoxDecoration(
                              color: gold,
                              shape: BoxShape.circle,
                              boxShadow: [
                                BoxShadow(color: gold.withValues(alpha: 0.3), blurRadius: 20, spreadRadius: 2)
                              ],
                            ),
                            child: Icon(isPlaying ? Icons.pause_rounded : Icons.play_arrow_rounded, color: Colors.black, size: 40),
                          ),
                        ),
                        IconButton(
                          icon: Icon(Icons.skip_next_rounded, color: textMain, size: 40),
                          onPressed: () => provider.playSurah(surah.number < 114 ? surah.number + 1 : 1),
                        ),
                        IconButton(
                          icon: Icon(Icons.repeat_rounded, color: textMain.withValues(alpha: 0.3), size: 20),
                          onPressed: () {},
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  String _formatDuration(Duration d) {
    final minutes = d.inMinutes.remainder(60).toString().padLeft(2, '0');
    final seconds = d.inSeconds.remainder(60).toString().padLeft(2, '0');
    return "$minutes:$seconds";
  }
}
