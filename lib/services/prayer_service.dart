import 'package:adhan/adhan.dart';
import 'package:intl/intl.dart';

class PrayerService {
  PrayerTimes getPrayerTimes(double latitude, double longitude) {
    final coordinates = Coordinates(latitude, longitude);
    final params = CalculationMethod.egyptian.getParameters();
    params.madhab = Madhab.shafi;
    
    return PrayerTimes.today(coordinates, params);
  }

  String getPrayerNameArabic(Prayer prayer) {
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
        return 'غير معروف';
    }
  }

  String formatTime(DateTime time) {
    return DateFormat.jm('ar').format(time);
  }
}
