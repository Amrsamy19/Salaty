import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:google_fonts/google_fonts.dart';
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
          duration: const Duration(milliseconds: 500),
          curve: Curves.easeInOutCubic,
          alignment: 0.1,
        );
      }
    }
  }

  String _toArabicDigits(int n) {
    const arabicDigits = ['٠', '١', '٢', '٣', '٤', '٥', '٦', '٧', '٨', '٩'];
    return n.toString().split('').map((d) => int.tryParse(d) != null ? arabicDigits[int.parse(d)] : d).join();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final gold = theme.colorScheme.primary;
    final surface = theme.colorScheme.surface;
    final textMain = theme.colorScheme.onSurface;

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
          backgroundColor: theme.scaffoldBackgroundColor,
          appBar: AppBar(
            backgroundColor: Colors.transparent,
            elevation: 0,
            leading: IconButton(
              icon: Icon(Icons.arrow_back_ios_new_rounded, color: gold, size: 20),
              onPressed: () => Navigator.pop(context),
            ),
            title: Text(
              AppLocalizations.of(context).isAr ? surah.nameArabic : surah.nameTransliteration,
              style: theme.appBarTheme.titleTextStyle,
            ),
            centerTitle: true,
          ),
          body: Column(
            children: [
              _buildReadingHeader(surah, gold, textMain),
              Expanded(
                child: isLoading
                    ? Center(child: CircularProgressIndicator(color: gold))
                    : ayahs == null || ayahs.isEmpty
                        ? Center(child: Text(AppLocalizations.of(context).errorLoading))
                        : ScrollablePositionedList.separated(
                            itemScrollController: _itemScrollController,
                            itemPositionsListener: _itemPositionsListener,
                            padding: const EdgeInsets.fromLTRB(20, 0, 20, 100),
                            itemCount: ayahs.length,
                            separatorBuilder: (_, _) => const SizedBox(height: 16),
                            itemBuilder: (context, index) {
                              final ayah = ayahs[index];
                              String displayAyahText = ayah.text.trim();

                              if (index == 0) {
                                final bismillahRegex = RegExp(r'^بِسْمِ ?\S* اللَّهِ ?\S* الرَّحْمَٰنِ ?\S* الرَّحِيمِ ?\S*');
                                if (displayAyahText.startsWith('بِسْمِ')) {
                                  displayAyahText = displayAyahText.replaceFirst(bismillahRegex, "").trim();
                                }
                              }

                              if (displayAyahText.isEmpty && index == 0) {
                                return const SizedBox.shrink();
                              }

                              final isActive = provider.currentSurahNumber == widget.surahNumber && activeIndex == index;
                              return _buildAyahTile(ayah, displayAyahText, isActive, gold, surface, textMain);
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

  Widget _buildReadingHeader(Surah surah, Color gold, Color textMain) {
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.all(20),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: gold.withValues(alpha: 0.1)),
      ),
      child: Column(
        children: [
          Text(
            AppLocalizations.of(context).isAr ? surah.nameTransliteration : surah.nameEnglish,
            style: TextStyle(color: gold, fontSize: 16, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 8),
          Text(
            "${surah.versesCount} ${AppLocalizations.of(context).ayahs} • ${surah.revelationType == 'Meccan' ? AppLocalizations.of(context).meccan : AppLocalizations.of(context).medinan}",
            style: TextStyle(color: textMain.withValues(alpha: 0.5), fontSize: 13),
          ),
        ],
      ),
    );
  }

  Widget _buildAyahTile(Ayah ayah, String displayAyahText, bool isActive, Color gold, Color surface, Color textMain) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 400),
      width: double.infinity,
      decoration: BoxDecoration(
        color: isActive ? gold.withValues(alpha: 0.1) : surface,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: isActive ? gold : gold.withValues(alpha: 0.1),
          width: isActive ? 1.5 : 1,
        ),
      ),
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          SizedBox(
            width: double.infinity,
            child: Text(
              displayAyahText,
              textAlign: TextAlign.right,
              textDirection: TextDirection.rtl,
              style: GoogleFonts.amiri(
                color: isActive ? gold : textMain,
                fontSize: 28,
                height: 1.6,
                fontWeight: isActive ? FontWeight.bold : FontWeight.normal,
              ),
            ),
          ),
          const SizedBox(height: 16),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
            decoration: BoxDecoration(
              color: gold.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: gold.withAlpha(50)),
            ),
            child: Text(
              _toArabicDigits(ayah.numberInSurah),
              style: GoogleFonts.amiri(
                color: gold, 
                fontSize: 16, 
                fontWeight: FontWeight.bold
              ),
            ),
          ),
        ],
      ),
    );
  }
}
