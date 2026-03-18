import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:scrollable_positioned_list/scrollable_positioned_list.dart';
import '../providers/quran_provider.dart';
import '../models/surah.dart';
import '../widgets/mini_player.dart';
import '../../../l10n/app_localizations.dart';

class SurahReadingScreen extends StatefulWidget {
  final int surahNumber;
  const SurahReadingScreen({super.key, required this.surahNumber});

  @override
  State<SurahReadingScreen> createState() => _SurahReadingScreenState();
}

class _SurahReadingScreenState extends State<SurahReadingScreen> {
  final ItemScrollController _itemScrollController = ItemScrollController();
  final ItemPositionsListener _itemPositionsListener = ItemPositionsListener.create();
  int _lastActiveIndex = -1;

  @override
  void initState() {
    super.initState();
    Future.microtask(() => 
      Provider.of<QuranProvider>(context, listen: false).fetchAyahs(widget.surahNumber)
    );
  }

  void _scrollToActiveAyah(int index) {
    if (index != -1 && index != _lastActiveIndex) {
      _lastActiveIndex = index;
      if (_itemScrollController.isAttached) {
        _itemScrollController.scrollTo(
          index: index,
          duration: const Duration(milliseconds: 500),
          curve: Curves.easeInOutCubic,
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<QuranProvider>(
      builder: (context, provider, child) {
        final surah = provider.allSurahs.firstWhere((s) => s.number == widget.surahNumber);
        final ayahs = provider.surahAyahs[widget.surahNumber];
        final isLoading = provider.isFetching(widget.surahNumber);
        final activeIndex = provider.activeAyahIndex;
        final isPlayingCurrent = provider.currentSurahNumber == widget.surahNumber && provider.isPlaying;

        if (isPlayingCurrent) {
          WidgetsBinding.instance.addPostFrameCallback((_) => _scrollToActiveAyah(activeIndex));
        }

        return Scaffold(
          backgroundColor: const Color(0xFF0A0A0F),
          appBar: AppBar(
            backgroundColor: const Color(0xFF0A0A0F),
            elevation: 0,
            title: Text(
              surah.nameArabic,
              style: const TextStyle(
                color: Color(0xFFFFD700),
                fontSize: 24,
                fontWeight: FontWeight.bold,
                fontFamily: 'Traditional Arabic',
              ),
            ),
            centerTitle: true,
          ),
          body: Column(
            children: [
              _buildReadingHeader(surah),
              Expanded(
                child: isLoading
                    ? const Center(child: CircularProgressIndicator(color: Color(0xFF6C63FF)))
                    : ayahs == null || ayahs.isEmpty
                        ? Center(child: Text(AppLocalizations.of(context).errorLoading, style: const TextStyle(color: Colors.white70)))
                        : ScrollablePositionedList.separated(
                            itemScrollController: _itemScrollController,
                            itemPositionsListener: _itemPositionsListener,
                            padding: const EdgeInsets.fromLTRB(20, 0, 20, 100),
                            itemCount: ayahs.length,
                            separatorBuilder: (_, __) => const SizedBox(height: 16),
                            itemBuilder: (context, index) {
                              final ayah = ayahs[index];
                              final isActive = provider.currentSurahNumber == widget.surahNumber && activeIndex == index;
                              return _buildAyahTile(ayah, isActive, index == 0 && widget.surahNumber != 1 && widget.surahNumber != 9);
                            },
                          ),
              ),
            ],
          ),
          bottomSheet: const MiniPlayer(),
        );
      },
    );
  }

  Widget _buildReadingHeader(Surah surah) {
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.all(16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFF1A1A2E),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFFFD700).withValues(alpha: 0.1)),
      ),
      child: Column(
        children: [
          Text(surah.nameEnglish, style: const TextStyle(color: Colors.white70, fontSize: 14)),
          const SizedBox(height: 4),
          Text(
            "${surah.versesCount} ${AppLocalizations.of(context).ayahs} • ${surah.revelationType == 'Meccan' ? AppLocalizations.of(context).meccan : AppLocalizations.of(context).medinan}",
            style: const TextStyle(color: Colors.white38, fontSize: 12),
          ),
        ],
      ),
    );
  }

  Widget _buildAyahTile(Ayah ayah, bool isActive, bool showBismillah) {
    return Column(
      children: [
        if (showBismillah)
          const Padding(
            padding: EdgeInsets.symmetric(vertical: 20),
            child: Text(
              "بِسْمِ اللَّهِ الرَّحْمَٰنِ الرَّحِيمِ",
              textAlign: TextAlign.center,
              style: TextStyle(
                color: Color(0xFFFFD700),
                fontSize: 26,
                fontFamily: 'Traditional Arabic',
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        AnimatedContainer(
          duration: const Duration(milliseconds: 300),
          width: double.infinity,
          decoration: BoxDecoration(
            color: isActive ? const Color(0xFF6C63FF).withValues(alpha: 0.15) : const Color(0xFF1A1A2E).withValues(alpha: 0.5),
            borderRadius: BorderRadius.circular(16),
            border: isActive ? Border.all(color: const Color(0xFF6C63FF).withValues(alpha: 0.3)) : null,
          ),
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.end,
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
              CircleAvatar(
                radius: 14,
                backgroundColor: isActive ? const Color(0xFF6C63FF) : const Color(0xFF6C63FF).withValues(alpha: 0.2),
                child: Text(
                  ayah.numberInSurah.toString(),
                  style: TextStyle(color: isActive ? Colors.white : const Color(0xFFFFD700), fontSize: 10, fontWeight: FontWeight.bold),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
