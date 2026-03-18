import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/quran_provider.dart';
import '../models/surah.dart';
import '../../../l10n/app_localizations.dart';

class StorageManagerSheet extends StatelessWidget {
  const StorageManagerSheet({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer<QuranProvider>(
      builder: (context, provider, child) {
        final downloadedSurahs = provider.allSurahs.where(
          (s) => provider.downloadStates[s.number] == DownloadState.downloaded).toList();
          
        return Container(
          decoration: const BoxDecoration(
            color: Color(0xFF0A0A0F),
            borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
          ),
          padding: const EdgeInsets.all(20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 40,
                height: 5,
                decoration: BoxDecoration(
                  color: Colors.white24,
                  borderRadius: BorderRadius.circular(5),
                ),
              ),
              const SizedBox(height: 16),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                       Text(
                        AppLocalizations.of(context).storage,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      FutureBuilder<double>(
                        future: provider.getTotalDownloadedSize(),
                        builder: (context, snapshot) {
                          return Text(
                            "${AppLocalizations.of(context).totalUsed}: ${snapshot.data?.toStringAsFixed(1) ?? '0'} MB",
                            style: const TextStyle(color: Colors.white60, fontSize: 13),
                          );
                        },
                      ),
                    ],
                  ),
                  if (downloadedSurahs.isNotEmpty)
                    TextButton.icon(
                      icon: const Icon(Icons.delete_sweep_rounded, color: Colors.redAccent),
                      label: Text(AppLocalizations.of(context).deleteAll, style: const TextStyle(color: Colors.redAccent)),
                      onPressed: () => _confirmDeleteAll(context, provider),
                    ),
                ],
              ),
              const SizedBox(height: 20),
              if (downloadedSurahs.isEmpty)
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 40),
                  child: Center(
                    child: Text(
                      AppLocalizations.of(context).noDownloaded,
                      style: const TextStyle(color: Colors.white24),
                    ),
                  ),
                )
              else
                Flexible(
                  child: ListView.separated(
                    shrinkWrap: true,
                    itemCount: downloadedSurahs.length,
                    separatorBuilder: (_, __) => const Divider(color: Colors.white10),
                    itemBuilder: (context, index) {
                      final surah = downloadedSurahs[index];
                      return ListTile(
                        leading: CircleAvatar(
                          backgroundColor: Colors.white12,
                          child: Text(
                            surah.number.toString(),
                            style: const TextStyle(color: Colors.white70, fontSize: 12),
                          ),
                        ),
                        title: Text(
                          surah.nameTransliteration,
                          style: const TextStyle(color: Colors.white, fontSize: 14),
                        ),
                        subtitle: Text(
                          surah.nameArabic,
                          style: const TextStyle(color: Colors.white60, fontSize: 12, fontFamily: 'Traditional Arabic'),
                        ),
                        trailing: IconButton(
                          icon: const Icon(Icons.delete_outline_rounded, color: Colors.redAccent, size: 20),
                          onPressed: () => provider.deleteSurah(surah.number),
                        ),
                      );
                    },
                  ),
                ),
            ],
          ),
        );
      },
    );
  }

  void _confirmDeleteAll(BuildContext context, QuranProvider provider) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFF1A1A2E),
        title: const Text("Delete All Downloads?", style: TextStyle(color: Colors.white)),
        content: const Text("This will remove all offline surahs from your local storage.", style: TextStyle(color: Colors.white70)),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text("Cancel"),
          ),
          TextButton(
            onPressed: () {
              provider.deleteAllDownloaded();
              Navigator.pop(context);
            },
            child: const Text("Delete All", style: TextStyle(color: Colors.redAccent)),
          ),
        ],
      ),
    );
  }
}
