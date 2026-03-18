import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../models/tracker_model.dart';

class HeatmapWidget extends StatelessWidget {
  final List<TrackerModel> history;
  final Color activeColor;
  final Color inactiveColor;

  const HeatmapWidget({
    super.key,
    required this.history,
    this.activeColor = const Color(0xFFC5A35E),
    this.inactiveColor = const Color(0x1AC5A35E),
  });

  @override
  Widget build(BuildContext context) {
    // We want to show the last 7 weeks (approx 50 days)
    final now = DateTime.now();
    final startDate = now.subtract(const Duration(days: 48)); // 7 weeks * 7 = 49
    
    // Adjust start date to be the Sunday of that week for a clean grid
    final adjustedStart = startDate.subtract(Duration(days: startDate.weekday % 7));
    
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text(
              'نشاط الصلوات (آخر 7 أسابيع)',
              style: TextStyle(color: Colors.white70, fontSize: 13, fontWeight: FontWeight.bold),
            ),
            Text(
              '${history.where((h) => h.prayerStatus.values.every((v) => v)).length} أيام مكتملة',
              style: TextStyle(color: activeColor, fontSize: 11),
            ),
          ],
        ),
        const SizedBox(height: 12),
        LayoutBuilder(
          builder: (context, constraints) {
            final cellSize = (constraints.maxWidth - (6 * 4)) / 7;
            
            return Column(
              children: List.generate(7, (weekIndex) {
                return Padding(
                  padding: const EdgeInsets.only(bottom: 4),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: List.generate(7, (dayIndex) {
                      final date = adjustedStart.add(Duration(days: weekIndex * 7 + dayIndex));
                      final dateStr = DateFormat('yyyy-MM-dd').format(date);
                      
                      final historyEntry = history.firstWhere(
                        (h) => h.date == dateStr,
                        orElse: () => TrackerModel(date: dateStr, prayerStatus: {}),
                      );
                      
                      final completedCount = historyEntry.prayerStatus.values.where((v) => v).length;
                      final totalCount = 5; // Assuming 5 prayers
                      
                      double opacity = 0.0;
                      if (completedCount > 0) {
                        opacity = (completedCount / totalCount).clamp(0.2, 1.0);
                      }
                      
                      final isFuture = date.isAfter(now);

                      return Tooltip(
                        message: '${DateFormat('yMMMd').format(date)}: $completedCount/$totalCount',
                        child: Container(
                          width: cellSize,
                          height: cellSize,
                          decoration: BoxDecoration(
                            color: isFuture 
                                ? Colors.transparent 
                                : (completedCount > 0 ? activeColor.withValues(alpha: opacity) : inactiveColor),
                            borderRadius: BorderRadius.circular(4),
                            border: isFuture ? Border.all(color: inactiveColor.withValues(alpha: 0.1), width: 0.5) : null,
                          ),
                        ),
                      );
                    }),
                  ),
                );
              }),
            );
          },
        ),
      ],
    );
  }
}
