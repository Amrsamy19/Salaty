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
      final provider = Provider.of<QuranProvider>(context, listen: false);
      provider.fetchAyahs(provider.currentSurahNumber ?? widget.surahNumber);
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
          backgroundColor: const Color(0xFF0A0A0F),
          appBar: AppBar(
            backgroundColor: const Color(0xFF0A0A0F),
            elevation: 0,
            leading: IconButton(
              icon: const Icon(Icons.arrow_back_ios_new_rounded, color: Colors.white, size: 20),
              onPressed: () => Navigator.pop(context),
            ),
            title: Column(
              children: [
                Text(
                  l10n.isAr ? surah.nameArabic : surah.nameTransliteration,
                  style: const TextStyle(
                    color: Color(0xFFFFD700),
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    fontFamily: 'Traditional Arabic',
                  ),
                ),
                Text(
                  l10n.isAr ? surah.nameTransliteration : surah.nameArabic,
                  style: const TextStyle(color: Colors.white60, fontSize: 12),
                ),
              ],
            ),
            centerTitle: true,
            actions: [
              if (state != DownloadState.downloaded)
                IconButton(
                  icon: const Icon(Icons.download_rounded, color: Color(0xFF6C63FF)),
                  onPressed: () => provider.downloadSurah(surah.number),
                )
              else
                IconButton(
                  icon: const Icon(Icons.delete_outline_rounded, color: Colors.redAccent),
                  onPressed: () => provider.deleteSurah(surah.number).then((_) => Navigator.pop(context)),
                ),
            ],
          ),
          body: Column(
            children: [
              // 1. Ayahs List (Now at the top as main content)
              Expanded(
                child: isFetching
                    ? const Center(child: CircularProgressIndicator(color: Color(0xFF6C63FF)))
                    : ayahs == null
                        ? Center(child: Text(l10n.loading, style: const TextStyle(color: Colors.white38)))
                        : ScrollablePositionedList.separated(
                            itemScrollController: _itemScrollController,
                            itemPositionsListener: _itemPositionsListener,
                            padding: const EdgeInsets.fromLTRB(20, 20, 20, 40),
                            itemCount: ayahs.length,
                            separatorBuilder: (_, __) => const SizedBox(height: 16),
                            itemBuilder: (context, index) {
                              final ayah = ayahs[index];
                              final isActive = activeIndex == index;
                              return AnimatedContainer(
                                duration: const Duration(milliseconds: 300),
                                padding: const EdgeInsets.all(20),
                                decoration: BoxDecoration(
                                  color: isActive ? const Color(0xFF6C63FF).withValues(alpha: 0.15) : const Color(0xFF1A1A2E).withValues(alpha: 0.4),
                                  borderRadius: BorderRadius.circular(16),
                                  border: isActive ? Border.all(color: const Color(0xFF6C63FF).withValues(alpha: 0.4)) : null,
                                ),
                                child: Column(
                                  children: [
                                    Text(
                                      ayah.text,
                                      textAlign: TextAlign.right,
                                      textDirection: TextDirection.rtl,
                                      style: TextStyle(
                                        color: isActive ? const Color(0xFFFFD700) : Colors.white,
                                        fontSize: 24,
                                        fontFamily: 'Traditional Arabic',
                                        height: 1.8,
                                        fontWeight: isActive ? FontWeight.bold : FontWeight.normal,
                                      ),
                                    ),
                                    const SizedBox(height: 12),
                                    Align(
                                      alignment: Alignment.centerLeft,
                                      child: CircleAvatar(
                                        radius: 14,
                                        backgroundColor: isActive ? const Color(0xFF6C63FF) : const Color(0xFF6C63FF).withValues(alpha: 0.2),
                                        child: Text(
                                          ayah.numberInSurah.toString(),
                                          style: TextStyle(color: isActive ? Colors.white : const Color(0xFFFFD700), fontSize: 10, fontWeight: FontWeight.bold),
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              );
                            },
                          ),
              ),

              // 2. Player Controls (Sleek Bottom Panel)
              Container(
                padding: const EdgeInsets.fromLTRB(24, 0, 24, 40),
                decoration: BoxDecoration(
                  color: const Color(0xFF1A1A2E),
                  borderRadius: const BorderRadius.vertical(top: Radius.circular(32)),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.4),
                      blurRadius: 20,
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
                      decoration: BoxDecoration(color: Colors.white12, borderRadius: BorderRadius.circular(2)),
                    ),
                    const SizedBox(height: 16),
                    SliderTheme(
                      data: SliderTheme.of(context).copyWith(
                        trackHeight: 3,
                        thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 6),
                        activeTrackColor: const Color(0xFF6C63FF),
                        inactiveTrackColor: Colors.white10,
                        thumbColor: const Color(0xFFFFD700),
                        overlayColor: const Color(0xFF6C63FF).withValues(alpha: 0.2),
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
                          Text(_formatDuration(provider.position), style: const TextStyle(color: Colors.white38, fontSize: 10)),
                          Text(_formatDuration(provider.duration), style: const TextStyle(color: Colors.white38, fontSize: 10)),
                        ],
                      ),
                    ),
                    const SizedBox(height: 12),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                      children: [
                        IconButton(
                          icon: const Icon(Icons.shuffle_rounded, color: Colors.white24, size: 20),
                          onPressed: () {},
                        ),
                        IconButton(
                          icon: const Icon(Icons.skip_previous_rounded, color: Colors.white, size: 40),
                          onPressed: () => provider.playSurah(surah.number > 1 ? surah.number - 1 : 114),
                        ),
                        GestureDetector(
                          onTap: () => provider.playSurah(surah.number),
                          child: Container(
                            width: 64,
                            height: 64,
                            decoration: const BoxDecoration(
                              color: Color(0xFF6C63FF),
                              shape: BoxShape.circle,
                              boxShadow: [
                                BoxShadow(color: Color(0xFF6C63FF), blurRadius: 15, spreadRadius: -2)
                              ],
                            ),
                            child: Icon(isPlaying ? Icons.pause_rounded : Icons.play_arrow_rounded, color: Colors.white, size: 36),
                          ),
                        ),
                        IconButton(
                          icon: const Icon(Icons.skip_next_rounded, color: Colors.white, size: 40),
                          onPressed: () => provider.playSurah(surah.number < 114 ? surah.number + 1 : 1),
                        ),
                        IconButton(
                          icon: const Icon(Icons.repeat_rounded, color: Colors.white24, size: 20),
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
