import 'package:flutter/material.dart';
import '../l10n/app_localizations.dart';

const _bg     = Color(0xFF061026);
const _bg2    = Color(0xFF0D1B3E);
const _gold   = Color(0xFFC5A35E);
const _cream  = Color(0xFFE2D1A8);
const _slate  = Color(0xFF64748B);

class AzkarScreen extends StatelessWidget {
  const AzkarScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);

    // Some common Azkar
    final morningAzkar = [
      "أَصْبَحْنَا وَأَصْبَحَ الْمُلْكُ لِلَّهِ، وَالْحَمْدُ لِلَّهِ، لَا إِلَهَ إِلَّا اللَّهُ وَحْدَهُ لَا شَرِيكَ لَهُ، لَهُ الْمُلْكُ وَلَهُ الْحَمْدُ وَهُوَ عَلَى كُلِّ شَيْءٍ قَدِيرٌ.",
      "اللَّهُمَّ إِنِّي أَسْأَلُكَ عِلْمًا نَافِعًا، وَرِزْقًا طَيِّبًا، وَعَمَلًا مُتَقَبَّلًا.",
      "سُبْحَانَ اللَّهِ وَبِحَمْدِهِ عَدَدَ خَلْقِهِ، وَرِضَا نَفْسِهِ، وَزِنَةَ عَرْشِهِ، وَمِدَادَ كَلِمَاتِهِ.",
      "بِسْمِ اللَّهِ الَّذِي لَا يَضُرُّ مَعَ اسْمِهِ شَيْءٌ فِي الْأَرْضِ وَلَا فِي السَّمَاءِ وَهُوَ السَّمِيعُ الْعَلِيمُ (ثلاث مرات).",
    ];

    final eveningAzkar = [
      "أَمْسَيْنَا وَأَمْسَى الْمُلْكُ لِلَّهِ، وَالْحَمْدُ لِلَّهِ، لَا إِلَهَ إِلَّا اللَّهُ وَحْدَهُ لَا شَرِيكَ لَهُ.",
      "اللَّهُمَّ بِكَ أَمْسَيْنَا، وَبِكَ أَصْبَحْنَا، وَبِكَ نَحْيَا، وَبِكَ نَمُوتُ وَإِلَيْكَ الْمَصِيرُ.",
      "أَمْسَيْنَا عَلَى فِطْرَةِ الْإِسْلَامِ، وَعَلَى كَلِمَةِ الْإِخْلَاصِ، وَعَلَى دِينِ نَبِيِّنَا مُحَمَّدٍ صَلَّى اللَّهُ عَلَيْهِ وَسَلَّمَ.",
      "بِسْمِ اللَّهِ الَّذِي لَا يَضُرُّ مَعَ اسْمِهِ شَيْءٌ فِي الْأَرْضِ وَلَا فِي السَّمَاءِ وَهُوَ السَّمِيعُ الْعَلِيمُ (ثلاث مرات).",
    ];

    return DefaultTabController(
      length: 2,
      child: Scaffold(
        backgroundColor: _bg,
        appBar: AppBar(
          title: Text(l.isAr ? 'الأذكار' : 'Azkar', style: const TextStyle(fontWeight: FontWeight.bold, color: _cream)),
          centerTitle: true,
          backgroundColor: _bg,
          elevation: 0,
          iconTheme: const IconThemeData(color: _gold),
          bottom: TabBar(
            indicatorColor: _gold,
            labelColor: _gold,
            unselectedLabelColor: _slate,
            tabs: [
              Tab(text: l.isAr ? 'أذكار الصباح' : 'Morning'),
              Tab(text: l.isAr ? 'أذكار المساء' : 'Evening'),
            ],
          ),
        ),
        body: Container(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [_bg, _bg2, _bg],
            ),
          ),
          child: TabBarView(
            children: [
              _buildAzkarList(morningAzkar),
              _buildAzkarList(eveningAzkar),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildAzkarList(List<String> azkar) {
    return ListView.builder(
      padding: const EdgeInsets.all(20),
      itemCount: azkar.length,
      itemBuilder: (context, index) {
        return Container(
          margin: const EdgeInsets.only(bottom: 16),
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: _bg2,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: _gold.withValues(alpha: 0.18)),
          ),
          child: Text(
            azkar[index],
            textAlign: TextAlign.justify,
            style: const TextStyle(
              color: _cream,
              fontSize: 18,
              height: 1.6,
            ),
          ),
        );
      },
    );
  }
}
