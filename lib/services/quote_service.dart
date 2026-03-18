class Quote {
  final String textAr;
  final String textEn;
  final String sourceAr;
  final String sourceEn;

  Quote({
    required this.textAr,
    required this.textEn,
    required this.sourceAr,
    required this.sourceEn,
  });
}

class QuoteService {
  static final List<Quote> quotes = [
    Quote(
      textAr: "إِنَّ مَعَ الْعُسْرِ يُسْرًا",
      textEn: "Indeed, with hardship comes ease.",
      sourceAr: "سورة الشرح - الآية 6",
      sourceEn: "Surah Ash-Sharh - Verse 6",
    ),
    Quote(
      textAr: "الَّذِينَ آمَنُوا وَتَطْمَئِنُّ قُلُوبُهُم بِذِكْرِ اللَّهِ ۗ أَلَا بِذِكْرِ اللَّهِ تَطْمَئِنُّ الْقُلُوبُ",
      textEn: "Those who believe and whose hearts find rest in the remembrance of Allah. Unquestionably, by the remembrance of Allah do hearts find rest.",
      sourceAr: "سورة الرعد - الآية 28",
      sourceEn: "Surah Ar-Ra'd - Verse 28",
    ),
    Quote(
      textAr: "يَا أَيُّهَا الَّذِينَ آمَنُوا اسْتَعِينُوا بِالصَّبْرِ وَالصَّلَاةِ ۚ إِنَّ اللَّهَ مَعَ الصَّابِرِينَ",
      textEn: "O you who have believed, seek help through patience and prayer. Indeed, Allah is with the patient.",
      sourceAr: "سورة البقرة - الآية 153",
      sourceEn: "Surah Al-Baqarah - Verse 153",
    ),
    Quote(
      textAr: "إِنَّ اللَّهَ وَمَلَائِكَتَهُ يُصَلُّونَ عَلَى النَّبِيِّ ۚ يَا أَيُّهَا الَّذِينَ آمَنُوا صَلُّوا عَلَيْهِ وَسَلِّمُوا تَسْلِيمًا",
      textEn: "Indeed, Allah and His angels bless the Prophet. O you who have believed, ask [Allah to bless] him and send him greetings of peace.",
      sourceAr: "سورة الأحزاب - الآية 56",
      sourceEn: "Surah Al-Ahzab - Verse 56",
    ),
    Quote(
      textAr: "وَمَن يَتَّقِ اللَّهَ يَجْعَل لَّهُ مَخْرَجًا * وَيَرْزُقْهُ مِنْ حَيْثُ لَا يَحْتَسِبُ",
      textEn: "And whoever fears Allah - He will make for him a way out and will provide for him from where he does not expect.",
      sourceAr: "سورة الطلاق - الآيات 2-3",
      sourceEn: "Surah At-Talaq - Verses 2-3",
    ),
    Quote(
      textAr: "فَاذْكُرُونِي أَذْكُرْكُمْ وَاشْكُرُوا لِي وَلَا تَكْفُرُونِ",
      textEn: "So remember Me; I will remember you. And be grateful to Me and do not deny Me.",
      sourceAr: "سورة البقرة - الآية 152",
      sourceEn: "Surah Al-Baqarah - Verse 152",
    ),
    Quote(
      textAr: "رَبَّنَا لَا تُزِغْ قُلُوبَنَا بَعْدَ إِذْ هَدَيْتَنَا وَهَبْ لَنَا مِن لَّدُنكَ رَحْمَةً ۚ إِنَّكَ أَنتَ الْوَهَّابُ",
      textEn: "Our Lord, let not our hearts deviate after You have guided us and grant us from Yourself mercy. Indeed, You are the Bestower.",
      sourceAr: "سورة آل عمران - الآية 8",
      sourceEn: "Surah Ali 'Imran - Verse 8",
    ),
  ];

  static Quote getDailyQuote() {
    final now = DateTime.now();
    final index = (now.year * 365 + now.month * 31 + now.day) % quotes.length;
    return quotes[index];
  }
}
