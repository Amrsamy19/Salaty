import 'dart:async';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import 'package:adhan/adhan.dart';
import 'package:hijri/hijri_calendar.dart';
import '../providers/prayer_provider.dart';
import '../l10n/app_localizations.dart';
import 'qibla_screen.dart';
import 'settings_screen.dart';
import 'tracker_screen.dart';
import 'azkar_screen.dart';
import '../widgets/quote_widget.dart';

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
    final l = AppLocalizations.of(context);

    const bg = Color(0xFF061026);
    const gold = Color(0xFFC5A35E);
    const txt = Color(0xFFE2D1A8);

    return Scaffold(
      backgroundColor: bg,
      appBar: AppBar(
        title: Text(
          l.appTitle,
          style: const TextStyle(fontWeight: FontWeight.bold, color: txt),
        ),
        centerTitle: true,
        backgroundColor: bg,
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.book, color: gold),
            tooltip: l.azkar,
            onPressed: () => Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const AzkarScreen()),
            ),
          ),
          IconButton(
            icon: const Icon(Icons.explore, color: gold),
            tooltip: l.qibla,
            onPressed: () => Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const QiblaScreen()),
            ),
          ),
          IconButton(
            icon: const Icon(Icons.history, color: gold),
            tooltip: l.history,
            onPressed: () => Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const TrackerScreen()),
            ),
          ),
          IconButton(
            icon: const Icon(Icons.settings, color: gold),
            tooltip: l.settings,
            onPressed: () => Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const SettingsScreen()),
            ),
          ),
        ],
      ),
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              prayerProvider.themeBackground[0],
              prayerProvider.themeBackground[1],
              prayerProvider.themeBackground[0],
            ],
          ),
        ),
        child: SafeArea(
          child: prayerProvider.isLoading
              ? const Center(
                  child: CircularProgressIndicator(color: Color(0xFFC5A35E)),
                )
              : prayerProvider.errorMessage != null
              ? Center(
                  child: Padding(
                    padding: const EdgeInsets.all(24.0),
                    child: SingleChildScrollView(
                      child: Text(
                        "Error:\n${prayerProvider.errorMessage}",
                        style: const TextStyle(color: Colors.red, fontSize: 16),
                      ),
                    ),
                  ),
                )
              : CustomScrollView(
                  slivers: [
                    _buildHeader(context, prayerProvider, fs),
                    SliverToBoxAdapter(child: QuoteWidget(fs: fs)),
                    _buildPrayerTimesList(prayerProvider, fs),
                    _buildTrackerSection(prayerProvider, fs),
                    const SliverToBoxAdapter(child: SizedBox(height: 30)),
                  ],
                ),
        ),
      ),
    );
  }

  Widget _buildHeader(
    BuildContext context,
    PrayerProvider provider,
    double fs,
  ) {
    final nextPrayer = provider.nextPrayer;
    final l = AppLocalizations.of(context);
    final nextPrayerName = provider.prayerTimes != null
        ? l.prayerName(_getPrayerName(nextPrayer))
        : '...';

    // Countdown logic
    String countdownStr = "--:--:--";
    if (provider.prayerTimes != null) {
      DateTime? nextTime;
      if (nextPrayer != Prayer.none) {
        nextTime = provider.prayerTimes!.timeForPrayer(nextPrayer);
      } else if (provider.currentPosition != null) {
        final tomorrow = DateTime.now().add(const Duration(days: 1));
        final tomorrowPT = PrayerTimes(
          Coordinates(
            provider.currentPosition!.latitude,
            provider.currentPosition!.longitude,
          ),
          DateComponents.from(tomorrow),
          CalculationMethod.muslim_world_league.getParameters(),
        );
        nextTime = tomorrowPT.fajr;
      }
      if (nextTime != null) {
        final diff = nextTime.difference(DateTime.now());
        String twoDigits(int n) => n.abs().toString().padLeft(2, '0');
        countdownStr =
            '${twoDigits(diff.inHours)}:${twoDigits(diff.inMinutes.remainder(60))}:${twoDigits(diff.inSeconds.remainder(60))}';
      }
    }

    final hijri = HijriCalendar.now();
    final hijriStr =
        '${hijri.hDay} ${l.hijriMonthName(hijri.hMonth)} ${hijri.hYear}${l.hijriSuffix}';
    final locale = l.isAr ? 'ar' : 'en';
    final gregorianStr = DateFormat(
      'EEEE، d MMMM y',
      locale,
    ).format(DateTime.now());

    final gold = Theme.of(context).colorScheme.primary;
    final textMain =
        Theme.of(context).textTheme.bodyLarge?.color ?? Colors.white;

    return SliverToBoxAdapter(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
        child: Column(
          children: [
            // Islamic Arch Date Card
            Stack(
              clipBehavior: Clip.none,
              alignment: Alignment.center,
              children: [
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.fromLTRB(20, 32, 20, 20),
                  decoration: BoxDecoration(
                    color: provider.themeBackground[1].withValues(alpha: 0.9),
                    borderRadius: const BorderRadius.only(
                      topLeft: Radius.circular(50),
                      topRight: Radius.circular(50),
                      bottomLeft: Radius.circular(20),
                      bottomRight: Radius.circular(20),
                    ),
                    border: Border.all(
                      color: gold.withValues(alpha: 0.2),
                      width: 1.5,
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: gold.withValues(alpha: 0.05),
                        blurRadius: 20,
                        spreadRadius: 2,
                      ),
                    ],
                  ),
                  child: Column(
                    children: [
                      Text(
                        hijriStr,
                        style: TextStyle(
                          color: gold,
                          fontSize: 22 * fs,
                          fontWeight: FontWeight.bold,
                          letterSpacing: 0.5,
                        ),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        gregorianStr,
                        style: TextStyle(
                          color: textMain.withValues(alpha: 0.6),
                          fontSize: 14 * fs,
                        ),
                      ),
                    ],
                  ),
                ),
                Positioned(
                  top: -12,
                  child: Container(
                    margin: const EdgeInsets.only(top: 20),
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: gold,
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Icon(
                      provider.seasonIcon,
                      color: Colors.black,
                      size: 20,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            // Countdown Section (Premium Glassmorphism Style)
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [
                    gold.withValues(alpha: 0.15),
                    Colors.black.withValues(alpha: 0.2),
                  ],
                ),
                borderRadius: BorderRadius.circular(30),
                border: Border.all(
                  color: gold.withValues(alpha: 0.3),
                  width: 1,
                ),
              ),
              child: Column(
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Container(
                        width: 40,
                        height: 1,
                        color: gold.withValues(alpha: 0.3),
                      ),
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 12),
                        child: Text(
                          l.nextPrayer.toUpperCase(),
                          style: TextStyle(
                            color: gold.withValues(alpha: 0.8),
                            fontSize: 12 * fs,
                            fontWeight: FontWeight.w900,
                            letterSpacing: 3,
                          ),
                        ),
                      ),
                      Container(
                        width: 40,
                        height: 1,
                        color: gold.withValues(alpha: 0.3),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Text(
                    nextPrayerName,
                    style: TextStyle(
                      color: textMain,
                      fontSize: 34 * fs,
                      fontWeight: FontWeight.w800,
                      shadows: [
                        Shadow(
                          color: gold.withValues(alpha: 0.3),
                          blurRadius: 10,
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 12),
                  // Digital Countdown with monospaced font
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 20,
                      vertical: 8,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.black.withValues(alpha: 0.3),
                      borderRadius: BorderRadius.circular(15),
                      border: Border.all(color: gold.withValues(alpha: 0.1)),
                    ),
                    child: Text(
                      countdownStr,
                      style: TextStyle(
                        color: gold,
                        fontSize: 48 * fs,
                        fontWeight: FontWeight.w300,
                        fontFeatures: const [FontFeature.tabularFigures()],
                        letterSpacing: 4,
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.access_time_filled_rounded,
                        color: gold.withValues(alpha: 0.6),
                        size: 14,
                      ),
                      const SizedBox(width: 8),
                      Text(
                        l.timeRemaining,
                        style: TextStyle(
                          color: textMain.withValues(alpha: 0.5),
                          fontSize: 13 * fs,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
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
    if (provider.prayerTimes == null) {
      return const SliverToBoxAdapter(child: SizedBox());
    }

    final l = AppLocalizations.of(context);
    final gold = Theme.of(context).colorScheme.primary;
    final surface = Theme.of(context).colorScheme.surface;
    final textMain =
        Theme.of(context).textTheme.bodyLarge?.color ?? Colors.white;

    final times = [
      {
        'name': 'الفجر',
        'time': provider.prayerTimes!.fajr,
        'icon': Icons.nights_stay_rounded,
      },
      {
        'name': 'الشروق',
        'time': provider.prayerTimes!.sunrise,
        'icon': Icons.wb_twilight_rounded,
      },
      {
        'name': 'الظهر',
        'time': provider.prayerTimes!.dhuhr,
        'icon': Icons.wb_sunny_rounded,
      },
      {
        'name': 'العصر',
        'time': provider.prayerTimes!.asr,
        'icon': Icons.wb_cloudy_rounded,
      },
      {
        'name': 'المغرب',
        'time': provider.prayerTimes!.maghrib,
        'icon': Icons.wb_twilight_rounded,
      }, // reused twilight
      {
        'name': 'العشاء',
        'time': provider.prayerTimes!.isha,
        'icon': Icons.bedtime_rounded,
      },
    ];

    return SliverPadding(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
      sliver: SliverList(
        delegate: SliverChildBuilderDelegate((context, index) {
          final item = times[index];
          final prayerEnum = _getPrayerEnum(item['name'] as String);
          final isNext = provider.nextPrayer == prayerEnum;

          return AnimatedContainer(
            duration: const Duration(milliseconds: 400),
            margin: const EdgeInsets.only(bottom: 12),
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: isNext ? gold.withValues(alpha: 0.15) : surface,
              borderRadius: BorderRadius.circular(20),
              border: Border.all(
                color: isNext ? gold : gold.withValues(alpha: 0.1),
                width: isNext ? 1.5 : 1,
              ),
              boxShadow: isNext
                  ? [
                      BoxShadow(
                        color: gold.withValues(alpha: 0.1),
                        blurRadius: 10,
                        offset: const Offset(0, 4),
                      ),
                    ]
                  : [],
            ),
            child: Row(
              children: [
                // Icon with background
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: isNext ? gold : Colors.white.withValues(alpha: 0.05),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    item['icon'] as IconData,
                    color: isNext ? Colors.black : gold,
                    size: 20 * fs,
                  ),
                ),
                const SizedBox(width: 16),
                // Prayer Name
                Expanded(
                  child: Text(
                    l.prayerName(item['name'] as String),
                    style: TextStyle(
                      color: isNext ? gold : textMain,
                      fontSize: 18 * fs,
                      fontWeight: isNext ? FontWeight.bold : FontWeight.w500,
                    ),
                  ),
                ),
                // Time
                Text(
                  DateFormat.jm(
                    l.isAr ? 'ar' : 'en',
                  ).format(item['time'] as DateTime),
                  style: TextStyle(
                    color: isNext ? gold : textMain.withValues(alpha: 0.7),
                    fontSize: 18 * fs,
                    fontWeight: isNext ? FontWeight.bold : FontWeight.w300,
                    letterSpacing: 0.5,
                  ),
                ),
              ],
            ),
          );
        }, childCount: times.length),
      ),
    );
  }

  Widget _buildTrackerSection(PrayerProvider provider, double fs) {
    if (provider.tracker == null) {
      return const SliverToBoxAdapter(child: SizedBox());
    }

    final l = AppLocalizations.of(context);
    final gold = Theme.of(context).colorScheme.primary;
    final surface = Theme.of(context).colorScheme.surface;

    final prayers = provider.tracker!.prayerStatus.keys.toList();
    final doneCount = prayers
        .where((p) => provider.tracker!.prayerStatus[p] == true)
        .length;

    return SliverToBoxAdapter(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.only(left: 8, bottom: 12),
              child: Row(
                children: [
                  Container(
                    width: 4,
                    height: 18,
                    decoration: BoxDecoration(
                      color: gold,
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Text(
                    l.prayerTracker,
                    style: TextStyle(
                      color: gold,
                      fontSize: 18 * fs,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const Spacer(),
                  Text(
                    '$doneCount/${prayers.length}',
                    style: TextStyle(
                      color: gold.withValues(alpha: 0.6),
                      fontSize: 14 * fs,
                    ),
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
                    duration: const Duration(milliseconds: 300),
                    curve: Curves.easeOutCubic,
                    decoration: BoxDecoration(
                      color: isDone
                          ? Colors.green.withValues(alpha: 0.15)
                          : surface,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(
                        color: isDone
                            ? Colors.green
                            : gold.withValues(alpha: 0.1),
                        width: isDone ? 1.5 : 1,
                      ),
                    ),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          isDone
                              ? Icons.check_circle_rounded
                              : Icons.radio_button_unchecked_rounded,
                          color: isDone
                              ? Colors.green
                              : gold.withValues(alpha: 0.4),
                          size: 24,
                        ),
                        const SizedBox(height: 6),
                        Text(
                          l.prayerName(prayer),
                          style: TextStyle(
                            color: isDone
                                ? Colors.green
                                : gold.withValues(alpha: 0.7),
                            fontSize: 10 * fs,
                            fontWeight: isDone
                                ? FontWeight.bold
                                : FontWeight.normal,
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
      case Prayer.fajr:
        return 'الفجر';
      case Prayer.sunrise:
        return 'الشروق';
      case Prayer.dhuhr:
        return 'الظهر';
      case Prayer.asr:
        return 'العصر';
      case Prayer.maghrib:
        return 'المغرب';
      case Prayer.isha:
        return 'العشاء';
      case Prayer.none:
        return '...';
    }
  }

  Prayer _getPrayerEnum(String name) {
    switch (name) {
      case 'الفجر':
        return Prayer.fajr;
      case 'الشروق':
        return Prayer.sunrise;
      case 'الظهر':
        return Prayer.dhuhr;
      case 'العصر':
        return Prayer.asr;
      case 'المغرب':
        return Prayer.maghrib;
      case 'العشاء':
        return Prayer.isha;
      default:
        return Prayer.none;
    }
  }
}
