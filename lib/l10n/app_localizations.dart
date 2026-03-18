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
  String get azkar           => isAr ? 'الأذكار'                  : 'Azkar';
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
  String get morningAzkar    => isAr ? 'أذكار الصباح'             : 'Morning Azkar';
  String get eveningAzkar    => isAr ? 'أذكار المساء'             : 'Evening Azkar';
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
      'أذكار الصباح': 'Morning Azkar', 'أذكار المساء': 'Evening Azkar',
    };
    return map[arName] ?? arName;
  }

  String hijriMonthName(int month) {
    final ar = ['محرم', 'صفر', 'ربيع الأول', 'ربيع الآخر', 'جمادى الأولى', 'جمادى الآخرة', 'رجب', 'شعبان', 'رمضان', 'شوال', 'ذو القعدة', 'ذو الحجة'];
    final en = ['Muharram', 'Safar', "Rabi' al-Awwal", "Rabi' al-Thani", 'Jumada al-Ula', 'Jumada al-Akhira', 'Rajab', "Sha'ban", 'Ramadan', 'Shawwal', "Dhu al-Qi'dah", 'Dhu al-Hijjah'];
    return isAr ? ar[month - 1] : en[month - 1];
  }

  String get hijriSuffix => isAr ? ' هـ' : ' AH';

  // Quran Feature
  String get quranTitle      => isAr ? 'القرآن الكريم'            : 'Holy Quran';
  String get searchSurah     => isAr ? 'ابحث عن سورة...'          : 'Search Surah...';
  String get ayahs           => isAr ? 'آية'                      : 'Ayahs';
  String get meccan          => isAr ? 'مكية'                     : 'Meccan';
  String get medinan         => isAr ? 'مدنية'                    : 'Medinan';
  String get storage         => isAr ? 'إدارة التخزين'           : 'Storage Management';
  String get totalUsed       => isAr ? 'إجمالي المساحة المستخدمة' : 'Total Space Used';
  String get delete          => isAr ? 'حذف'                      : 'Delete';
  String get deleteAll       => isAr ? 'حذف الكل'                 : 'Delete All';
  String get noDownloaded    => isAr ? 'لا توجد سور محملة'        : 'No downloaded surahs';
  String get nowPlaying      => isAr ? 'يتلو الآن'               : 'Now Playing';
  String get swipeUpToRead   => isAr ? 'اسحب للأعلى للقراءة'     : 'Swipe up to read';
  String get swipeUpForAyahs => isAr ? 'اسحب للأعلى للآيات'      : 'Swipe up for Ayahs';
  String get mushafView      => isAr ? 'عرض المصحف'              : 'Mushaf View';
  String get noInternet      => isAr ? 'يجب توفر إنترنت لبدء التحميل' : 'There has to be internet to start the download';
  String get noStream        => isAr ? 'لا يوجد إنترنت لتشغيل السورة' : 'No internet to stream this surah';
  String get loading         => isAr ? 'جاري التحميل...'          : 'Loading...';
  String get errorLoading    => isAr ? 'خطأ في تحميل الآيات'      : 'Error loading ayahs';
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
