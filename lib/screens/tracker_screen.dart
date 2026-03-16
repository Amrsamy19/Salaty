import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../providers/prayer_provider.dart';
import '../models/tracker_model.dart';

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
        title: const Text('سجل الصلوات',
            style: TextStyle(fontWeight: FontWeight.bold, color: _cream)),
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
            ? const Center(
                child: Text('لا يوجد سجل بعد', style: TextStyle(color: _slate, fontSize: 18)),
              )
            : ListView(
                padding: const EdgeInsets.all(20),
                children: [
                  // Stats header card
                  _buildStatsCard(totalDays, totalDone, totalPossible, pct, perfectDays),
                  const SizedBox(height: 20),
                  ...history.map((day) => _buildDayCard(context, day)).toList(),
                ],
              ),
      ),
    );
  }

  Widget _buildStatsCard(int totalDays, int totalDone, int totalPossible, int pct, int perfectDays) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: _faint,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: _gold.withOpacity(0.35), width: 1.2),
      ),
      child: Column(
        children: [
          const Text(
            'إحصائيات الالتزام',
            style: TextStyle(color: _gold, fontSize: 18, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 16),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _statItem('$pct%', 'نسبة الال