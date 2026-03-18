import 'package:flutter/material.dart';
import '../services/quote_service.dart';
import '../l10n/app_localizations.dart';

class QuoteWidget extends StatelessWidget {
  final double fs;
  const QuoteWidget({super.key, required this.fs});

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    final quote = QuoteService.getDailyQuote();
    final text = l.isAr ? quote.textAr : quote.textEn;
    final source = l.isAr ? quote.sourceAr : quote.sourceEn;

    return Container(
      width: double.infinity,
      margin: const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: const Color(0xFF0D1B3E),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: const Color(0xFFC5A35E).withValues(alpha: 0.15)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.2),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        children: [
          Icon(Icons.format_quote_rounded, color: const Color(0xFFC5A35E).withValues(alpha: 0.5), size: 30),
          const SizedBox(height: 8),
          Text(
            text,
            textAlign: TextAlign.center,
            style: TextStyle(
              color: const Color(0xFFE2D1A8),
              fontSize: 16 * fs,
              fontStyle: FontStyle.italic,
              height: 1.5,
            ),
          ),
          const SizedBox(height: 12),
          Text(
            source,
            textAlign: TextAlign.center,
            style: TextStyle(
              color: const Color(0xFFC5A35E),
              fontSize: 12 * fs,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }
}
