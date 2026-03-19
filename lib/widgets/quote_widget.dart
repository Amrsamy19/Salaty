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

    final gold = Theme.of(context).colorScheme.primary;
    final surface = Theme.of(context).colorScheme.surface;
    final textMain = Theme.of(context).textTheme.bodyLarge?.color ?? Colors.white;

    return Container(
      width: double.infinity,
      margin: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: surface,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: gold.withValues(alpha: 0.15)),
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            surface,
            gold.withValues(alpha: 0.05),
          ],
        ),
      ),
      child: Stack(
        children: [
          Positioned(
            top: -10,
            left: l.isAr ? null : -5,
            right: l.isAr ? -5 : null,
            child: Icon(
              Icons.format_quote_rounded,
              color: gold.withValues(alpha: 0.1),
              size: 60,
            ),
          ),
          Column(
            children: [
              const SizedBox(height: 10),
              Text(
                text,
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: textMain.withValues(alpha: 0.9),
                  fontSize: 16 * fs,
                  fontStyle: FontStyle.italic,
                  height: 1.6,
                  letterSpacing: 0.3,
                ),
              ),
              const SizedBox(height: 16),
              Container(
                height: 1,
                width: 40,
                color: gold.withValues(alpha: 0.3),
              ),
              const SizedBox(height: 12),
              Text(
                source,
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: gold,
                  fontSize: 12 * fs,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 1.2,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
