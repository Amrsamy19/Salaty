import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'providers/prayer_provider.dart';
import 'screens/home_screen.dart';
import 'l10n/app_localizations.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await initializeDateFormatting('ar', null);
  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => PrayerProvider()..init()),
      ],
      child: const MyApp(),
    ),
  );
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  // Expose as constants so widgets can reference them
  static const Color bg        = Color(0xFF061026);
  static const Color gold      = Color(0xFFC5A35E);
  static const Color goldFaint = Color(0x33C5A35E);
  static const Color textColor = Color(0xFFE2D1A8);
  static const Color slate     = Color(0xFF64748B);

  @override
  Widget build(BuildContext context) {
    return Consumer<PrayerProvider>(
      builder: (context, provider, _) {
        return MaterialApp(
          title: 'صلاتي',
          debugShowCheckedModeBanner: false,
          locale: provider.locale,
          supportedLocales: const [Locale('ar'), Locale('en')],
          localizationsDelegates: const [
            AppLocalizations.delegate,
            GlobalMaterialLocalizations.delegate,
            GlobalWidgetsLocalizations.delegate,
            GlobalCupertinoLocalizations.delegate,
          ],
          theme: ThemeData(
            useMaterial3: true,
            scaffoldBackgroundColor: bg,
            colorScheme: ColorScheme.fromSeed(
              seedColor: gold,
              brightness: Brightness.dark,
              background: bg,
              surface: const Color(0xFF0D1B3E),
              primary: gold,
              secondary: gold,
              onPrimary: bg,
              onBackground: textColor,
              onSurface: textColor,
            ),
            appBarTheme: const AppBarTheme(
              backgroundColor: bg,
              foregroundColor: textColor,
              elevation: 0,
            ),
            textTheme: GoogleFonts.amiriTextTheme(ThemeData.dark().textTheme).apply(
              bodyColor: textColor,
              displayColor: textColor,
            ),
          ),
          builder: (context, child) {
            return MediaQuery(
              data: MediaQuery.of(context).copyWith(
                textScaler: TextScaler.linear(provider.fontSizeMultiplier),
              ),
              child: child!,
            );
          },
          home: const HomeScreen(),
        );
      },
    );
  }
}


