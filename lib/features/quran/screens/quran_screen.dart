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
    return Scaffold(
      backgroundColor: const Color(0xFF0A0A0F),
      appBar: AppBar(
        backgroundColor: const Color(0xFF0A0A0F),
        elevation: 0,
        title: Text(
          AppLocalizations.of(context).quranTitle,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 24,
            fontWeight: FontWeight.bold,
            fontFamily: 'Traditional Arabic',
          ),
        ),
        centerTitle: true,
        actions: [
          IconButton(
            icon: const Icon(Icons.storage_rounded, color: Color(0xFFFFD700)),
            onPressed: () => _showStorageSheet(context),
            tooltip: "Storage Management",
          ),
        ],
      ),
      body: Column(
        children: [
          // Search Bar
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: TextField(
              controller: _searchController,
              onChanged: (v) => setState(() => _searchQuery = v.toLowerCase()),
              style: const TextStyle(color: Colors.white),
              decoration: InputDecoration(
                filled: true,
                fillColor: const Color(0xFF1A1A2E),
                hintText: AppLocalizations.of(context).searchSurah,
                hintStyle: TextStyle(color: Colors.white.withValues(alpha: 0.3)),
                prefixIcon: const Icon(Icons.search_rounded, color: Colors.white30),
                suffixIcon: _searchQuery.isNotEmpty 
                  ? IconButton(
                    icon: const Icon(Icons.close, color: Colors.white30),
                    onPressed: () {
                      _searchController.clear();
                      setState(() => _searchQuery = "");
                    },
                  ) : null,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(16),
                  borderSide: BorderSide.none,
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
