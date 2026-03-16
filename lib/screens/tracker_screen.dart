import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../providers/prayer_provider.dart';
import '../models/tracker_model.dart';
import '../l10n/app_localizations.dart';

// Brand palette
const _bg     = Color(0xFF061026);
const _bg2    = Color(0xFF0D1B3E);
const _gold   = Color(0xFFC5A35E);
const _faint  = Color(0x33C5A35E);
const _cream  = Color(0xFFE2D1A8);
const _slate  = Color(0xFF64748B);

class TrackerScreen extends StatelessWidget {
  const TrackerScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final provider = Provider.of<PrayerProvider>(context);
    final history = provider.history;
    final l = AppLocalizations.of(context);

    // Summary stats
    final totalDays = history.length;
    int perfectDays = 0;
    int totalDone = 0;
    int totalPossible = 0;
    for (final day in history) {
      final prayers = day.prayerStatus.values;
      totalDone += prayers.where((v) => v).length;
      totalPossible += prayers.length;
      if (prayers.every((v) => v)) perfectDays++;
    }
    final pct = totalPossible > 0 ? (totalDone / totalPossible * 100).toInt() : 0;

    return Scaffold(
      backgroundColor: _bg,
      appBar: AppBar(
        title: Text(l.commitHistory,
            style: const TextStyle(fontWeight: FontWeight.bold, color: _cream)),
        centerTitle: true,
        backgroundColor: _bg,
        elevation: 0,
        iconTheme: const IconThemeData(color: _gold),
      ),
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [_bg, _bg2, _bg],
          ),
        ),
        child: history.isEmpty
            ? Center(
                child: Text(l.noHistory, style: const TextStyle(color: _slate, fontSize: 18)),
              )
            : ListView(
                padding: const EdgeInsets.all(20),
                children: [
                  // Stats header card
                  _buildStatsCard(totalDays, totalDone, totalPossible, pct, perfectDays, l),
                  const SizedBox(height: 20),
                  ...history.map((day) => _buildDayCard(context, day, l)).toList(),
                ],
              ),
      ),
    );
  }

  Widget _buildStatsCard(int totalDays, int totalDone, int totalPossible, int pct, int perfectDays, AppLocalizations l) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: _faint,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: _gold.withValues(alpha: 0.35), width: 1.2),
      ),
      child: Column(
        children: [
          Text(
            l.commitStats,
            style: const TextStyle(color: _gold, fontSize: 18, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 16),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _statItem('$pct%', l.commitRate),
              _statDivider(),
              _statItem('$totalDone/$totalPossible', l.prayersDone),
              _statDivider(),
              _statItem('$perfectDays', l.perfectDays),
            ],
          ),
          const SizedBox(height: 16),
          // Progress bar
          ClipRRect(
            borderRadius: BorderRadius.circular(10),
            child: LinearProgressIndicator(
              value: totalPossible > 0 ? totalDone / totalPossible : 0,
              backgroundColor: _slate.withValues(alpha: 0.2),
              valueColor: const AlwaysStoppedAnimation<Color>(_gold),
              minHeight: 8,
            ),
          ),
        ],
      ),
    );
  }

  Widget _statItem(String value, String label) {
    return Column(
      children: [
        Text(value, style: const TextStyle(color: _cream, fontSize: 18, fontWeight: FontWeight.bold)),
        const SizedBox(height: 4),
        Text(label, style: const TextStyle(color: _slate, fontSize: 11)),
      ],
    );
  }

  Widget _statDivider() {
    return Container(width: 1, height: 36, color: _gold.withValues(alpha: 0.2));
  }

  Widget _buildDayCard(BuildContext context, TrackerModel day, AppLocalizations l) {
    final prayers = day.prayerStatus;
    final total = prayers.length;
    final completed = prayers.values.where((v) => v).length;
    final isPerfect = completed == total;
    final isToday = day.date == DateTime.now().toIso8601String().substring(0, 10);

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: _bg2,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isToday ? _gold.withValues(alpha: 0.5) : _gold.withValues(alpha: 0.12),
          width: isToday ? 1.5 : 1,
        ),
      ),
      child: ExpansionTile(
        tilePadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
        childrenPadding: EdgeInsets.zero,
        iconColor: _gold,
        collapsedIconColor: _slate,
        title: Row(
          children: [
            if (isToday)
              Container(
                margin: const EdgeInsets.only(left: 8),
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                decoration: BoxDecoration(
                  color: _faint,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Text(l.today, style: const TextStyle(color: _gold, fontSize: 11)),
              ),
            Expanded(
              child: Text(
                DateFormat('EEEE، d MMMM', l.isAr ? 'ar' : 'en').format(DateTime.parse(day.date)),
                style: const TextStyle(color: _cream, fontSize: 15, fontWeight: FontWeight.bold),
              ),
            ),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              decoration: BoxDecoration(
                color: isPerfect ? Colors.green.withValues(alpha: 0.2) : _faint,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: isPerfect ? Colors.green.withValues(alpha: 0.4) : _gold.withValues(alpha: 0.3)),
              ),
              child: Text(
                '$completed / $total',
                style: TextStyle(
                  color: isPerfect ? Colors.green : _gold,
                  fontWeight: FontWeight.bold,
                  fontSize: 13,
                ),
              ),
            ),
          ],
        ),
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
            child: Column(
              children: [
                const Divider(color: Color(0x33C5A35E), height: 1),
                const SizedBox(height: 12),
                // Mini progress bar per day
                Row(
                  children: List.generate(total, (i) {
                    final prayerName = prayers.keys.elementAt(i);
                    final isDone = prayers[prayerName] ?? false;
                    return Expanded(
                      child: Padding(
                        padding: EdgeInsets.only(left: i < total - 1 ? 4 : 0),
                        child: Column(
                          children: [
                            Icon(
                              isDone ? Icons.check_circle_rounded : Icons.circle_outlined,
                              color: isDone ? Colors.green : _slate,
                              size: 22,
                            ),
                            const SizedBox(height: 4),
                            Text(
                              l.prayerName(prayerName),
                              textAlign: TextAlign.center,
                              style: TextStyle(
                                color: isDone ? Colors.green : _slate,
                                fontSize: 11,
                              ),
                            ),
                          ],
                        ),
                      ),
                    );
                  }),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
