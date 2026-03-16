import 'package:flutter/material.dart';

class AppLocalizations {
  final Locale locale;
  AppLocalizations(this.locale);

  static AppLocalizations of(BuildContext context) {
    return Localizations.of<AppLocalizations>(context, AppLocalizations)!;
  }

  static const delegate = _AppLocalizationsDelegate();

  bool get isAr => locale.languageCode == 'ar';

  String get appTitle        => isAr ? 'صلاتي'                   : 'Salaty';
  String get nextPrayer      => isAr ? 'الصلاة القادمة'           : 'Next Prayer';
  String get timeRemaining   => isAr ? 'متبقي على الموعد'         : 'Time Remaining';
  String get prayerTracker   => isAr ? 'متتبع الصلوات'            : 'Prayer Tracker';
  String get qibla           => isAr ? 'القبلة'                   : 'Qibla';
  String get history         => isAr ? 'السجل'                    : 'History';
  String get settings        => isAr ? 'الإعدادات'                : 'Settings';
  String get fajr            => isAr ? 'الفجر'                    : 'Fajr';
  String get sunrise         => isAr ? 'الشروق'                   : 'Sunrise';
  String get dhuhr           => isAr ? 'الظهر'                    : 'Dhuhr';
  String get asr             => isAr ? 'العصر'                    : 'Asr';
  String get maghrib         => isAr ? 'المغرب'                   : 'Maghrib';
  String get isha            => isAr ? 'العشاء'                   : 'Isha';
  String get qiblaDirection  => isAr ? 'اتجاه القبلة'             : 'Qibla Direction';
  String get fromNorth       => isAr ? 'من الشمال'                : 'from North';
  String get rotatePhone     => isAr ? 'أدر الهاتف حتى تتجه الإبرة الذهبية نحو القبلة' : 'Rotate your phone until the golden needle points to Qibla';
  String get commitHistory   => isAr ? 'سجل الصلوات'              : 'Prayer Log';
  String get commitStats     => isAr ? 'إحصائيات الالتزام'        : 'Commitment Stats';
  String get commitRate      => isAr ? 'نسبة الالتزام'            : 'Commitment Rate';
  String get prayersDone     => isAr ? 'الصلوات المؤداة'          : 'Prayers Done';
  String get perfectDays     => isAr ? 'أيام مكتملة'              : 'Perfect Days';
  String get today           => isAr ? 'اليوم'                    : 'Today';
  String get noHistory       => isAr ? 'لا يوجد سجل بعد'          : 'No history yet';
  String get displaySettings => isAr ? 'تخصيص العرض'              : 'Display';
  String get fontSize        => isAr ? 'حجم الخط'                 : 'Font Size';
  String get small           => isAr ? 'صغير'                     : 'Small';
  String get large           => isAr ? 'كبير'                     : 'Large';
  String get azanSound       => isAr ? 'صوت الأذان'               : 'Azan Sound';
  String get notifications   => isAr ? 'تنبيهات الصلوات'          : 'Prayer Notifications';
  String get language        => isAr ? 'اللغة'                    : 'Language';
  String get arabic          => isAr ? 'العربية'                  : 'Arabic';
  String get english         => isAr ? 'الإنجليزية'               : 'English';

  String get makahAzan     => isAr ? 'أذان مكة'      : 'Makkah Azan';
  String get egyptAzan     => isAr ? 'أذان مصري'     : 'Egyptian Azan';
  String get abdelbaset    => isAr ? 'عبد الباسط'    : 'Abdelbaset';
  String get mohamedrefaat => isAr ? 'محمد رفعت'     : 'Mohamed Refaat';

  List<String> get prayerNames => [fajr, dhuhr, asr, maghrib, isha];
  List<String> get prayerNamesAr => ['الفجر', 'الظهر', 'العصر', 'المغرب', 'العشاء'];

  String prayerName(String arName) {
    if (isAr) return arName;
    final map = {
      'الفجر': 'Fajr', 'الشروق': 'Sunrise', 'الظهر': 'Dhuhr',
      'العصر': 'Asr', 'المغرب': 'Maghrib', 'العشاء': 'Isha',
    };
    return map[arName] ?? arName;
  }

  String hijriMonthName(int month) {
    final ar = ['محرم', 'صفر', 'ربيع الأول', 'ربيع الآخر', 'جمادى الأولى', 'جمادى الآخرة', 'رجب', 'شعبان', 'رمضان', 'شوال', 'ذو القعدة', 'ذو الحجة'];
    final en = ['Muharram', 'Safar', "Rabi' al-Awwal", "Rabi' al-Thani", 'Jumada al-Ula', 'Jumada al-Akhira', 'Rajab', "Sha'ban", 'Ramadan', 'Shawwal', "Dhu al-Qi'dah", 'Dhu al-Hijjah'];
    return isAr ? ar[month - 1] : en[month - 1];
  }

  String get hijriSuffix => isAr ? ' هـ' : ' AH';
}

class _AppLocalizationsDelegate extends LocalizationsDelegate<AppLocalizations> {
  const _AppLocalizationsDelegate();

  @override
  bool isSupported(Locale locale) => ['ar', 'en'].contains(locale.languageCode);

  @override
  Future<AppLocalizations> load(Locale locale) async => AppLocalizations(locale);

  @override
  bool shouldReload(_) => false;
}
