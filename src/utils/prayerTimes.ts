import { Coordinates, CalculationMethod, PrayerTimes } from 'adhan';

export const getPrayerTimes = (latitude: number, longitude: number, date: Date = new Date()) => {
  const coordinates = new Coordinates(latitude, longitude);
  // Using Mecca calculation method as a common default, but this can be changed
  const params = CalculationMethod.MuslimWorldLeague();
  
  const prayerTimes = new PrayerTimes(coordinates, date, params);
  
  return {
    fajr: prayerTimes.fajr,
    sunrise: prayerTimes.sunrise,
    dhuhr: prayerTimes.dhuhr,
    asr: prayerTimes.asr,
    maghrib: prayerTimes.maghrib,
    isha: prayerTimes.isha,
    nextPrayer: prayerTimes.nextPrayer(),
    timeForPrayer: (prayer: string) => prayerTimes.timeForPrayer(prayer as any)
  };
};

export const formatTime = (date: Date | null) => {
  if (!date) return '--:--';
  return date.toLocaleTimeString([], { hour: '2-digit', minute: '2-digit' });
};
