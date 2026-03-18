enum DownloadState { notDownloaded, downloading, downloaded, error }

class Surah {
  final int number;
  final String nameArabic;
  final String nameTransliteration;
  final String nameEnglish;
  final int versesCount;
  final String revelationType;

  const Surah({
    required this.number,
    required this.nameArabic,
    required this.nameTransliteration,
    required this.nameEnglish,
    required this.versesCount,
    required this.revelationType,
  });
}

class Ayah {
  final int number;
  final int numberInSurah;
  final String text;
  final int timestampFrom; // milliseconds
  final int timestampTo;   // milliseconds

  const Ayah({
    required this.number,
    required this.numberInSurah,
    required this.text,
    this.timestampFrom = 0,
    this.timestampTo = 0,
  });

  factory Ayah.fromJson(Map<String, dynamic> json) {
    return Ayah(
      number: json['number'],
      numberInSurah: json['numberInSurah'],
      text: json['text'],
    );
  }

  Ayah copyWith({int? timestampFrom, int? timestampTo, String? text}) {
    return Ayah(
      number: number,
      numberInSurah: numberInSurah,
      text: text ?? this.text,
      timestampFrom: timestampFrom ?? this.timestampFrom,
      timestampTo: timestampTo ?? this.timestampTo,
    );
  }
}
