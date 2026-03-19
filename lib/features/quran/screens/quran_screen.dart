import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/quran_provider.dart';
import '../widgets/surah_list_tile.dart';
import '../widgets/mini_player.dart';
import '../widgets/storage_manager_sheet.dart';
import '../../../l10n/app_localizations.dart';

class QuranScreen extends StatefulWidget {
  const QuranScreen({super.key});

  @override
  State<QuranScreen> createState() => _QuranScreenState();
}

class _QuranScreenState extends State<QuranScreen> {
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = "";

  @override
  void initState() {
    super.initState();
    _setupErrorListener();
  }

  void _setupErrorListener() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final provider = Provider.of<QuranProvider>(context, listen: false);
      provider.addListener(() {
        if (provider.errorMessage != null) {
          final l10n = AppLocalizations.of(context);
          String message = provider.errorMessage!;
          
          // Map hardcoded English messages to localized ones
          if (message == "There has to be internet to start the download") {
            message = l10n.noInternet;
          } else if (message == "No internet to stream this surah") {
            message = l10n.noStream;
          }

          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(message),
              backgroundColor: Colors.redAccent,
              behavior: SnackBarBehavior.floating,
              duration: const Duration(seconds: 3),
            ),
          );
          provider.clearError();
        }
      });
    });
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final gold = theme.colorScheme.primary;

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: Text(
          AppLocalizations.of(context).quranTitle,
          style: theme.appBarTheme.titleTextStyle,
        ),
        centerTitle: true,
        actions: [
          IconButton(
            icon: Icon(Icons.storage_rounded, color: gold),
            onPressed: () => _showStorageSheet(context),
            tooltip: "Storage Management",
          ),
        ],
      ),
      body: Column(
        children: [
          // Premium Search Bar
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
            child: TextField(
              controller: _searchController,
              onChanged: (v) => setState(() => _searchQuery = v.toLowerCase()),
              style: TextStyle(color: theme.colorScheme.onSurface),
              decoration: InputDecoration(
                filled: true,
                fillColor: theme.colorScheme.surface,
                hintText: AppLocalizations.of(context).searchSurah,
                hintStyle: TextStyle(color: theme.colorScheme.onSurface.withValues(alpha: 0.3)),
                prefixIcon: Icon(Icons.search_rounded, color: gold.withValues(alpha: 0.5)),
                suffixIcon: _searchQuery.isNotEmpty 
                  ? IconButton(
                    icon: Icon(Icons.close, color: gold.withValues(alpha: 0.5)),
                    onPressed: () {
                      _searchController.clear();
                      setState(() => _searchQuery = "");
                    },
                  ) : null,
                contentPadding: const EdgeInsets.symmetric(vertical: 20),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(24),
                  borderSide: BorderSide(color: gold.withValues(alpha: 0.1), width: 1),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(24),
                  borderSide: BorderSide(color: gold, width: 1.5),
                ),
              ),
            ),
          ),
          
          // Surah List
          Expanded(
            child: Consumer<QuranProvider>(
              builder: (context, provider, child) {
                final filteredSurahs = provider.allSurahs.where((s) {
                  return s.nameArabic.toLowerCase().contains(_searchQuery) ||
                         s.nameEnglish.toLowerCase().contains(_searchQuery) ||
                         s.nameTransliteration.toLowerCase().contains(_searchQuery);
                }).toList();

                return ListView.builder(
                  padding: const EdgeInsets.only(bottom: 90),
                  itemCount: filteredSurahs.length,
                  itemBuilder: (context, index) {
                    return SurahListTile(surah: filteredSurahs[index]);
                  },
                );
              },
            ),
          ),
        ],
      ),
      bottomNavigationBar: const MiniPlayer(),
    );
  }

  void _showStorageSheet(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => const StorageManagerSheet(),
    );
  }
}
