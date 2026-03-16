import 'dart:async';
import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import 'package:adhan/adhan.dart';
import 'package:hijri/hijri_calendar.dart';
import '../providers/prayer_provider.dart';
import 'qibla_screen.dart';
import 'settings_screen.dart';
import 'tracker_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (mounted) setState(() {});
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final prayerProvider = Provider.of<PrayerProvider>(context);
    final fs = prayerProvider.fontSizeMultiplier;

    const bg    = Color(0xFF061026);
    const gold  = Color(0xFFC5A35E);
    const txt   = Color(0xFFE2D1A8);

    return Scaffold(
      backgroundColor: bg,
      appBar: AppBar(
        title: const Text('صلاتي', style: TextStyle(fontWeight: FontWeight.bold, color: txt)),
        centerTitle: true,
        backgroundColor: bg,
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.explore, color: gold),
            tooltip: 'القبلة',
            onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const QiblaScreen())),
          ),
          IconButton(
            icon: const Icon(Icons.history, color: gold),
            tooltip: 'السجل',
            onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const TrackerScreen())),
          ),
          IconButton(
            icon: const Icon(Icons.settings, color: gold),
            tooltip: 'الإعدادات',
            onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const SettingsScreen())),
          ),
        ],
      ),
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              Color(0xFF061026),
              Color(0xFF0D1B3E),
              Color(0xFF061026),
            ],
          ),
        ),
        child: SafeArea(
          child: prayerProvider.isLoading
              ? const Center(child: CircularProgressIndicator(color: Color(0xFFC5A35E)))
              : CustomScrollView(
                  slivers: [
                    _buildHeader(context, prayerProvider, fs),
                    _buildPrayerTimesList(prayerProvider, fs),
                    _buildTrackerSection(prayerProvider, fs),
                    const SliverToBoxAdapter(child: SizedBox(height: 30)),
                  ],
                ),
        ),
      ),
    );
  }

  Widget _buildHeader(BuildContext context, PrayerProvider provider, double fs) {
    final nextPrayer = provider.nextPrayer;
    final nextPrayerName = provider.prayerTimes != null 
        ? _getPrayerName(nextPrayer) 
        : '...';
    
    // Compute countdown locally so it refreshes every second via the Timer
    String countdownStr = "--:--:--";
    if (provider.prayerTimes != null) {
      DateTime? nextTime;
      if (nextPrayer != Prayer.none) {
        nextTime = provider.prayerTimes!.timeForPrayer(nextPrayer);
      } else if (provider.currentPosition != null) {
        // Past Isha — show time to tomorrow's Fajr
        final tomorrow = DateTime.now().add(const Duration(days: 1));
        final tomorrowPT = PrayerTimes(
          Coordinates(provider.currentPosition!.latitude, provider.currentPosition!.longitude),
          DateComponents.from(tomorrow),
          CalculationMethod.muslim_world_league.getParameters(),
        );
        nextTime = tomorrowPT.fajr;
      }
      if (nextTime != null) {
        final diff = nextTime.difference(DateTime.now());
        String twoDigits(int n) => n.abs().toString().padLeft(2, '0');
        countdownStr = '${twoDigits(diff.inHours)}:${twoDigits(diff.inMinutes.remainder(60))}:${twoDigits(diff.inSeconds.remainder(60))}';
      }
    }

    // Build Hijri date string
    final hijri = HijriCalendar.now();
    final hijriMonths = [
      'محرم', 'صفر', 'ربيع الأول', 'ربيع الآخر',
      'جمادى الأولى', 'جمادى الآخرة', 'رجب', 'شعبان',
      'رمضان', 'شوال', 'ذو القعدة', 'ذو الحجة',
    ];
    final hijriStr = '${hijri.hDay} ${hijriMonths[hijri.hMonth - 1]} ${hijri.hYear} هـ';
    final gregorianStr = DateFormat('EEEE، d MMMM y', 'ar').format(DateTime.now());

    return SliverToBoxAdapter(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(24, 16, 24, 24),
        child: Column(
          children: [
            // Date card
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 20),
              decoration: BoxDecoration(
                color: const Color(0xFF0D1B3E),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: const Color(0xFFC5A35E).withOpacity(0.18)),
              ),
              child: Column(
                children: [
                  Text(
                    hijriStr,
                    style: TextStyle(
                      color: const Color(0xFFC5A35E),
                      fontSize: 20 * fs,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    gregorianStr,
                    style: TextStyle(
                      color: const Color(0xFFE2D1A8).withOpacity(0.5),
                      fontSize: 13 * fs,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 14),
            // Countdown card
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: const Color(0x33C5A35E),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: const Color(0xFFC5A35E).withOpacity(0.35), width: 1.2),
              ),
              child: Column(
                children: [
                  Text(
                    'الصلاة القادمة',
                    style: TextStyle(color: const Color(0xFFE2D1A8).withOpacity(0.55), fontSize: 14 * fs),
                  ),
                  Text(
                    nextPrayerName,
                    style: TextStyle(color: const Color(0xFFC5A35E), fontSize: 30 * fs, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 10),
                  Text(
                    countdownStr,
                    style: TextStyle(
                      color: const Color(0xFFE2D1A8),
                      fontSize: 42 * fs,
                      fontWeight: FontWeight.bold,
                      fontFeatures: const [FontFeature.tabularFigures()],
                      letterSpacing: 3,
                      fontFamily: 'monospace',
                    ),
                  ),
                  Text(
                    'متبقي على الموعد',
                    style: TextStyle(color: const Color(0xFF64748B), fontSize: 13 * fs),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPrayerTimesList(PrayerProvider provider, double fs) {
    if (provider.prayerTimes == null) return const SliverToBoxAdapter(child: SizedBox());

    final times = [
      {'name': 'الفجر', 'time': provider.prayerTimes!.fajr},
      {'name': 'الشروق', 'time': provider.prayerTimes!.sunrise},
      {'name': 'الظهر', 'time': provider.prayerTimes!.dhuhr},
      {'name': 'العصر', 'time': provider.prayerTimes!.asr},
      {'name': 'المغرب', 'time': provider.prayerTimes!.maghrib},
      {'name': 'العشاء', 'time': provider.prayerTimes!.isha},
    ];

    return SliverList(
      delegate: SliverChildBuilderDelegate(
        (context, index) {
          final item = times[index];
          final isNext = _isNextPrayer(provider, _getPrayerEnum(item['name'] as String));
          
          const gold   = Color(0xFFC5A35E);
          const cream  = Color(0xFFE2D1A8);
          const slate  = Color(0xFF64748B);
          return Container(
            margin: const EdgeInsets.symmetric(horizontal: 20, vertical: 6),
            padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
            decoration: BoxDecoration(
              color: isNext ? const Color(0x33C5A35E) : const Color(0xFF0D1B3E),
              borderRadius: BorderRadius.circular(14),
              border: Border.all(
                color: isNext ? gold : const Color(0xFFC5A35E).withOpacity(0.18),
                width: isNext ? 1.5 : 1,
              ),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  item['name'] as String,
                  style: TextStyle(
                    color: isNext ? gold : cream,
                    fontSize: 20 * fs,
                    fontWeight: isNext ? FontWeight.bold : FontWeight.normal,
                  ),
                ),
                Text(
                  DateFormat.jm('ar').format(item['time'] as DateTime),
                  style: TextStyle(
                    color: isNext ? gold : slate,
                    fontSize: 18 * fs,
                  ),
                ),
              ],
            ),
          );
        },
        childCount: times.length,
      ),
    );
  }

  Widget _buildTrackerSection(PrayerProvider provider, double fs) {
    if (provider.tracker == null) return const SliverToBoxAdapter(child: SizedBox());

    final prayers = provider.tracker!.prayerStatus.keys.toList();

    return SliverToBoxAdapter(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(20, 0, 20, 24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.only(bottom: 14),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'متتبع الصلوات',
                    style: TextStyle(color: Colors.amber, fontSize: 22 * fs, fontWeight: FontWeight.bold),
                  ),
                  Text(
                    '${prayers.where((p) => provider.tracker!.prayerStatus[p] == true).length}/${prayers.length}',
                    style: TextStyle(color: Colors.white54, fontSize: 14 * fs),
                  ),
                ],
              ),
            ),
            GridView.count(
              crossAxisCount: 5,
              crossAxisSpacing: 10,
              mainAxisSpacing: 10,
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              children: prayers.map((prayer) {
                final isDone = provider.tracker!.prayerStatus[prayer] ?? false;
                return GestureDetector(
                  onTap: () => provider.togglePrayer(prayer),
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 250),
                    curve: Curves.easeInOut,
                    decoration: BoxDecoration(
                      color: isDone
                          ? Colors.green.withOpacity(0.25)
                          : Colors.white.withOpacity(0.05),
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(
                        color: isDone ? Colors.green : Colors.white24,
                        width: 1.5,
                      ),
                    ),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        AnimatedSwitcher(
                          duration: const Duration(milliseconds: 200),
                          child: Icon(
                            isDone ? Icons.check_circle_rounded : Icons.circle_outlined,
                            key: ValueKey(isDone),
                            color: isDone ? Colors.green : Colors.white38,
                            size: 26,
                          ),
                        ),
                        const SizedBox(height: 6),
                        Text(
                          prayer,
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            color: isDone ? Colors.green : Colors.white70,
                            fontSize: 11 * fs,
                            fontWeight: isDone ? FontWeight.bold : FontWeight.normal,
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              }).toList(),
            ),
          ],
        ),
      ),
    );
  }



  String _getPrayerName(Prayer prayer) {
    switch (prayer) {
      case Prayer.fajr: return 'الفجر';
      case Prayer.sunrise: return 'الشروق';
      case Prayer.dhuhr: return 'الظهر';
      case Prayer.asr: return 'العصر';
      case Prayer.maghrib: return 'المغرب';
      case Prayer.isha: return 'العشاء';
      case Prayer.none: return '...';
    }
  }

  Prayer _getPrayerEnum(String name) {
    switch (name) {
      case 'الفجر': return Prayer.fajr;
      case 'الشروق': return Prayer.sunrise;
      case 'الظهر': return Prayer.dhuhr;
      case 'العصر': return Prayer.asr;
      case 'المغرب': return Prayer.maghrib;
      case 'العشاء': return Prayer.isha;
      default: return Prayer.none;
    }
  }

  bool _isNextPrayer(PrayerProvider provider, Prayer current) {
    if (provider.prayerTimes == null) return false;
    return provider.nextPrayer == current;
  }
}
