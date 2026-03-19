import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/quran_provider.dart';
import '../models/surah.dart';
import '../../../l10n/app_localizations.dart';

class StorageManagerSheet extends StatelessWidget {
  const StorageManagerSheet({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final gold = theme.colorScheme.primary;
    final textMain = theme.colorScheme.onSurface;

    return Consumer<QuranProvider>(
      builder: (context, provider, child) {
        final downloadedSurahs = provider.allSurahs.where(
          (s) => provider.downloadStates[s.number] == DownloadState.downloaded).toList();
          
        return Container(
          decoration: BoxDecoration(
            color: theme.scaffoldBackgroundColor,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(32)),
            border: Border(top: BorderSide(color: gold.withValues(alpha: 0.2))),
          ),
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: gold.withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              const SizedBox(height: 24),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                       Text(
                        AppLocalizations.of(context).storage,
                        style: TextStyle(
                          color: gold,
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      FutureBuilder<double>(
                        future: provider.getTotalDownloadedSize(),
                        builder: (context, snapshot) {
                          return Text(
                            "${AppLocalizations.of(context).totalUsed}: ${snapshot.data?.toStringAsFixed(1) ?? '0'} MB",
                            style: TextStyle(color: textMain.withValues(alpha: 0.5), fontSize: 13),
                          );
                        },
                      ),
                    ],
                  ),
                  if (downloadedSurahs.isNotEmpty)
                    TextButton.icon(
                      icon: const Icon(Icons.delete_sweep_rounded, color: Colors.redAccent, size: 20),
                      label: Text(AppLocalizations.of(context).deleteAll, style: const TextStyle(color: Colors.redAccent, fontWeight: FontWeight.bold)),
                      onPressed: () => _confirmDeleteAll(context, provider),
                    ),
                ],
              ),
              const SizedBox(height: 24),
              _buildTextSyncSection(context, provider),
              const SizedBox(height: 20),
              Divider(color: gold.withValues(alpha: 0.1)),
              const SizedBox(height: 10),
              if (downloadedSurahs.isEmpty)
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 40),
                  child: Center(
                    child: Text(
                      AppLocalizations.of(context).noDownloaded,
                      style: TextStyle(color: textMain.withValues(alpha: 0.3)),
                    ),
                  ),
                )
              else
                Flexible(
                  child: ListView.separated(
                    shrinkWrap: true,
                    itemCount: downloadedSurahs.length,
                    separatorBuilder: (_, _) => Divider(color: gold.withValues(alpha: 0.1), height: 1),
                    itemBuilder: (context, index) {
                      final surah = downloadedSurahs[index];
                      return ListTile(
                        contentPadding: EdgeInsets.zero,
                        leading: CircleAvatar(
                          backgroundColor: gold.withValues(alpha: 0.1),
                          child: Text(
                            surah.number.toString(),
                            style: TextStyle(color: gold, fontSize: 12, fontWeight: FontWeight.bold),
                          ),
                        ),
                        title: Text(
                          surah.nameTransliteration,
                          style: TextStyle(color: textMain, fontSize: 15, fontWeight: FontWeight.w600),
                        ),
                        subtitle: Text(
                          surah.nameArabic,
                          style: TextStyle(color: textMain.withValues(alpha: 0.5), fontSize: 13, fontFamily: 'Traditional Arabic'),
                        ),
                        trailing: IconButton(
                          icon: const Icon(Icons.delete_outline_rounded, color: Colors.redAccent, size: 22),
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

  Widget _buildTextSyncSection(BuildContext context, QuranProvider provider) {
    final l10n = AppLocalizations.of(context);
    final theme = Theme.of(context);
    final gold = theme.colorScheme.primary;
    final surface = theme.colorScheme.surface;

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: surface,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: gold.withValues(alpha: 0.15)),
      ),
      child: Column(
        children: [
          Row(
            children: [
              Icon(Icons.description_outlined, color: gold, size: 22),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  l10n.downloadAllTexts,
                  style: TextStyle(color: theme.colorScheme.onSurface, fontSize: 14, fontWeight: FontWeight.bold),
                ),
              ),
              if (!provider.isDownloadingAllTexts)
                IconButton(
                  icon: Icon(Icons.sync_rounded, color: gold),
                  onPressed: () => provider.downloadAllTexts(),
                  tooltip: l10n.downloadAllTexts,
                )
              else
                SizedBox(
                  width: 20, height: 20,
                  child: CircularProgressIndicator(strokeWidth: 2, color: gold),
                ),
            ],
          ),
          if (provider.isDownloadingAllTexts) ...[
            const SizedBox(height: 16),
            ClipRRect(
              borderRadius: BorderRadius.circular(4),
              child: LinearProgressIndicator(
                value: provider.syncProgress,
                backgroundColor: gold.withValues(alpha: 0.1),
                color: gold,
                minHeight: 6,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              "${(provider.syncProgress * 100).toInt()}% - ${l10n.downloadingTexts}",
              style: TextStyle(color: theme.colorScheme.onSurface.withValues(alpha: 0.4), fontSize: 11),
            ),
          ] else if (provider.syncProgress == 1.0) ...[
            const SizedBox(height: 12),
            Row(
              children: [
                const Icon(Icons.check_circle_rounded, color: Colors.greenAccent, size: 16),
                const SizedBox(width: 8),
                Text(l10n.textsDownloaded, style: const TextStyle(color: Colors.greenAccent, fontSize: 12, fontWeight: FontWeight.w600)),
              ],
            ),
          ],
        ],
      ),
    );
  }

  void _confirmDeleteAll(BuildContext context, QuranProvider provider) {
    final theme = Theme.of(context);
    final gold = theme.colorScheme.primary;
    
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: theme.colorScheme.surface,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        title: Text("Delete All Downloads?", style: TextStyle(color: gold, fontWeight: FontWeight.bold)),
        content: Text("This will remove all offline surahs from your local storage.", style: TextStyle(color: theme.colorScheme.onSurface.withValues(alpha: 0.7))),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text("Cancel", style: TextStyle(color: theme.colorScheme.onSurface.withValues(alpha: 0.5))),
          ),
          TextButton(
            onPressed: () {
              provider.deleteAllDownloaded();
              Navigator.pop(context);
            },
            child: const Text("Delete All", style: TextStyle(color: Colors.redAccent, fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }
}
