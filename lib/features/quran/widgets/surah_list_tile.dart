import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/surah.dart';
import '../providers/quran_provider.dart';
import '../screens/surah_player_screen.dart';
import '../screens/surah_reading_screen.dart';
import '../../../l10n/app_localizations.dart';

class SurahListTile extends StatelessWidget {
  final Surah surah;
  const SurahListTile({super.key, required this.surah});

  @override
  Widget build(BuildContext context) {
    return Consumer<QuranProvider>(
      builder: (context, provider, child) {
        final state = provider.downloadStates[surah.number] ?? DownloadState.notDownloaded;
        final isPlaying = provider.currentSurahNumber == surah.number;
        final progress = provider.downloadProgress[surah.number] ?? 0.0;
        
        return Container(
          margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          decoration: BoxDecoration(
            color: const Color(0xFF1A1A2E),
            borderRadius: BorderRadius.circular(16),
            border: isPlaying ? Border.all(color: const Color(0xFF6C63FF), width: 1) : null,
            boxShadow: isPlaying ? [
              BoxShadow(
                color: const Color(0xFF6C63FF).withValues(alpha: 0.2),
                blurRadius: 10,
                spreadRadius: 1,
              )
            ] : [],
          ),
          child: ListTile(
            contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            onTap: () {
              if (state == DownloadState.downloaded) {
                 Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => SurahPlayerScreen(surahNumber: surah.number)),
                );
              } else {
                 provider.playSurah(surah.number);
              }
            },
            leading: _buildLeading(surah),
            title: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      AppLocalizations.of(context).isAr ? surah.nameArabic : surah.nameTransliteration,
                      style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                        fontSize: 18,
                      ),
                    ),
                    Row(
                      children: [
                        Text(
                          "${surah.versesCount} ${AppLocalizations.of(context).ayahs}",
                          style: const TextStyle(color: Colors.white60, fontSize: 12),
                        ),
                        const SizedBox(width: 8),
                        _buildTypeChip(context, surah),
                      ],
                    ),
                  ],
                ),
                Text(
                  AppLocalizations.of(context).isAr ? surah.nameTransliteration : surah.nameArabic,
                  style: TextStyle(
                    color: AppLocalizations.of(context).isAr ? Colors.white38 : const Color(0xFFFFD700),
                    fontSize: AppLocalizations.of(context).isAr ? 14 : 22,
                    fontFamily: 'Traditional Arabic',
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            trailing: _buildTrailing(context, provider, state, progress),
          ),
        );
      },
    );
  }

  Widget _buildLeading(Surah surah) {
    return Container(
      width: 45,
      height: 45,
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF6C63FF), Color(0xFFFFD700)],
        ),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Center(
        child: Text(
          surah.number.toString(),
          style: const TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.bold,
            fontSize: 14,
          ),
        ),
      ),
    );
  }

  Widget _buildTypeChip(BuildContext context, Surah surah) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: surah.revelationType == "Meccan" ? Colors.green.withValues(alpha: 0.2) : Colors.blue.withValues(alpha: 0.2),
        borderRadius: BorderRadius.circular(6),
        border: Border.all(
          color: surah.revelationType == "Meccan" ? Colors.green.withValues(alpha: 0.5) : Colors.blue.withValues(alpha: 0.5),
          width: 0.5,
        ),
      ),
      child: Text(
        surah.revelationType == "Meccan" 
            ? AppLocalizations.of(context).meccan 
            : AppLocalizations.of(context).medinan,
        style: TextStyle(
          color: surah.revelationType == "Meccan" ? Colors.greenAccent : Colors.lightBlueAccent,
          fontSize: 10,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }

  Widget _buildTrailing(BuildContext context, QuranProvider provider, DownloadState state, double progress) {
    final readButton = IconButton(
      icon: const Icon(Icons.menu_book_rounded, color: Colors.white38),
      onPressed: () {
        Navigator.push(
          context,
          MaterialPageRoute(builder: (context) => SurahReadingScreen(surahNumber: surah.number)),
        );
      },
    );

    switch (state) {
      case DownloadState.notDownloaded:
        return Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            readButton,
            IconButton(
              icon: const Icon(Icons.download_rounded, color: Colors.white60),
              onPressed: () => provider.downloadSurah(surah.number),
            ),
          ],
        );
      case DownloadState.downloading:
        return SizedBox(
          width: 40,
          height: 40,
          child: Stack(
            alignment: Alignment.center,
            children: [
              CircularProgressIndicator(
                value: progress,
                strokeWidth: 3,
                valueColor: const AlwaysStoppedAnimation<Color>(Color(0xFF6C63FF)),
              ),
              Text(
                "${(progress * 100).toInt()}%",
                style: const TextStyle(fontSize: 10, color: Colors.white),
              ),
            ],
          ),
        );
      case DownloadState.downloaded:
        return Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            readButton,
            IconButton(
              icon: Icon(
                provider.currentSurahNumber == surah.number && provider.isPlaying 
                  ? Icons.pause_rounded 
                  : Icons.play_arrow_rounded,
                color: const Color(0xFF6C63FF),
              ),
              onPressed: () => provider.playSurah(surah.number),
            ),
            IconButton(
              icon: const Icon(Icons.delete_rounded, color: Colors.redAccent),
              onPressed: () => provider.deleteSurah(surah.number),
            ),
          ],
        );
      case DownloadState.error:
        return Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            readButton,
            IconButton(
              icon: const Icon(Icons.error_outline_rounded, color: Colors.redAccent),
              onPressed: () => provider.downloadSurah(surah.number),
            ),
          ],
        );
    }
  }
}
