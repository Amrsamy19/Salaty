import moment from 'moment-hijri';

const HIJRI_MONTHS = {
  ar: [
    'محرم', 'صفر', 'ربيع الأول', 'ربيع الآخر', 'جمادى الأولى', 'جمادى الآخرة',
    'رجب', 'شعبان', 'رمضان', 'شوال', 'ذو القعدة', 'ذو الحجة'
  ],
  en: [
    'Muharram', 'Safar', 'Rabi\' al-Awwal', 'Rabi\' al-Thani', 'Jumada al-Ula', 'Jumada al-Akhira',
    'Rajab', 'Sha\'ban', 'Ramadan', 'Shawwal', 'Dhu al-Qi\'dah', 'Dhu al-Hijjah'
  ]
};

export const getHijriDate = (date: Date = new Date(), locale: string = 'ar') => {
  try {
    const m = moment(date);
    const iDay = m.iDate();
    const iMonthIndex = m.iMonth(); // 0-indexed
    const iYear = m.iYear();
    
    const lang = locale === 'ar' ? 'ar' : 'en';
    const monthName = HIJRI_MONTHS[lang][iMonthIndex];
    
    if (locale === 'ar') {
      // Basic Arabic number conversion if needed, or keep as is if context/font handles it
      // Using standard numbers for now as it's cleaner in UI
      return `${iDay} ${monthName} ${iYear}`;
    }
    return `${iDay} ${monthName} ${iYear}`;
  } catch (e) {
    console.error('Hijri date error:', e);
    return '';
  }
};

export const getFormattedGregorianDate = (date: Date = new Date(), locale: string = 'ar-EG') => {
  return date.toLocaleDateString(locale === 'ar' ? 'ar-EG' : 'en-US', {
    weekday: 'long',
    year: 'numeric',
    month: 'long',
    day: 'numeric',
  });
};
