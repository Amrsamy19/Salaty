import { Coordinates, CalculationMethod, PrayerTimes } from 'adhan';

export const getPrayerTimes = (latitude: number, longitude: number, date: Date = new Date()) => {
  const coordinates = new Coordinates(latitude, longitude);
  // Using Mecca calculation method as a common default, but this can be changed
  const params = CalculationMethod.Egyptian();
  
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

export const calculateQibla = (latitude: number, longitude: number) => {
  const PI = Math.PI;
  const lat1 = latitude * PI / 180;
  const lon1 = longitude * PI / 180;
  const lat2 = 21.4225 * PI / 180; // Kaaba latitude
  const lon2 = 39.8262 * PI / 180; // Kaaba longitude

  const dLon = lon2 - lon1;

  const y = Math.sin(dLon);
  const x = Math.cos(lat1) * Math.tan(lat2) - Math.sin(lat1) * Math.cos(dLon);

  let qibla = Math.atan2(y, x) * 180 / PI;
  return (qibla + 360) % 360;
};
