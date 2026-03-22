import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:volume_controller/volume_controller.dart';
import 'providers/prayer_provider.dart';
import 'features/quran/providers/quran_provider.dart';
import 'screens/main_navigation.dart';
import 'l10n/app_localizations.dart';

import 'package:android_alarm_manager_plus/android_alarm_manager_plus.dart';
import 'services/azan_foreground_service.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  // Initialize Background Services
  await AndroidAlarmManager.initialize();
  AzanForegroundService.init();
  
  await initializeDateFormatting('ar', null);

  // Check if launched by full-screen intent/notification
  final FlutterLocalNotificationsPlugin plugin = FlutterLocalNotificationsPlugin();
  final details = await plugin.getNotificationAppLaunchDetails();
  if (details?.didNotificationLaunchApp ?? false) {
    try {
      VolumeController.instance.showSystemUI = false;
      await VolumeController.instance.setVolume(0.5);
    } catch (_) {} // volume controller might throw if unsupported
  }

  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => PrayerProvider()..init()),
        ChangeNotifierProvider(create: (_) => QuranProvider()),
      ],
      child: const MyApp(),
    ),
  );
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  // Sophisticated Islamic Brand Palette
  static const Color bg            = Color(0xFF040B1A); // Deeper navy
  static const Color surface       = Color(0xFF0A162B); // Slightly lighter navy for cards
  static const Color gold          = Color(0xFFD4AF37); // Traditional gold
  static const Color goldAccent    = Color(0xFFE5C167); // Brighter gold for highlights
  static const Color goldFaint     = Color(0x1AD4AF37); // Faint gold for overlays
  static const Color emerald       = Color(0xFF0A4D3C); // Deep Islamic emerald
  static const Color textMain      = Color(0xFFF1E6D0); // Soft cream for primary text
  static const Color textSecondary = Color(0xFFA6ADBB); // Muted slate for secondary text

  @override
  Widget build(BuildContext context) {
    return Consumer<PrayerProvider>(
      builder: (context, provider, _) {
        final isAr = provider.locale.languageCode == 'ar';
        
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
            brightness: Brightness.dark,
            scaffoldBackgroundColor: bg,
            colorScheme: ColorScheme.fromSeed(
              seedColor: gold,
              brightness: Brightness.dark,
              primary: gold,
              onPrimary: bg,
              secondary: emerald,
              onSecondary: Colors.white,
              surface: surface,
              onSurface: textMain,
            ),
            appBarTheme: AppBarTheme(
              backgroundColor: Colors.transparent,
              foregroundColor: gold,
              elevation: 0,
              centerTitle: true,
              titleTextStyle: (isAr ? GoogleFonts.cairo() : GoogleFonts.outfit()).copyWith(
                fontSize: 22,
                fontWeight: FontWeight.bold,
                color: gold,
                letterSpacing: 1.2,
              ),
            ),
            cardTheme: CardThemeData(
              color: surface,
              elevation: 4,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(24),
                side: BorderSide(color: gold.withValues(alpha: 0.1), width: 1),
              ),
              shadowColor: Colors.black.withValues(alpha: 0.5),
            ),
            textTheme: (isAr
                    ? GoogleFonts.cairoTextTheme(ThemeData.dark().textTheme)
                    : GoogleFonts.outfitTextTheme(ThemeData.dark().textTheme))
                .apply(
              bodyColor: textMain,
              displayColor: gold,
            ).copyWith(
              headlineMedium: TextStyle(fontWeight: FontWeight.bold, color: gold),
              titleLarge: TextStyle(fontWeight: FontWeight.bold, color: textMain),
            ),
            navigationBarTheme: NavigationBarThemeData(
              backgroundColor: bg,
              indicatorColor: gold.withValues(alpha: 0.2),
              labelTextStyle: WidgetStateProperty.all(
                TextStyle(fontSize: 12, fontWeight: FontWeight.w500, color: textSecondary),
              ),
              iconTheme: WidgetStateProperty.all(
                const IconThemeData(size: 24),
              ),
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
          home: const MainNavigation(),
        );
      },
    );
  }
}


