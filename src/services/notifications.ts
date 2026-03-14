import * as Notifications from 'expo-notifications';
import { audioService } from './audio';
import { getPrayerTimes } from '../utils/prayerTimes';
import { Platform } from 'react-native';
import { subMinutes } from 'date-fns';
import { settingsService } from './settings';

Notifications.setNotificationHandler({
  handleNotification: async () => ({
    shouldShowAlert: true,
    shouldPlaySound: true,
    shouldSetBadge: false,
    shouldShowBanner: true,
    shouldShowList: true,
  }),
});

export const setupNotifications = async () => {
  const { status: existingStatus } = await Notifications.getPermissionsAsync();
  let finalStatus = existingStatus;
  
  if (existingStatus !== 'granted') {
    const { status } = await Notifications.requestPermissionsAsync();
    finalStatus = status;
  }
  
  if (finalStatus !== 'granted') {
    return false;
  }

  if (Platform.OS === 'android') {
    Notifications.setNotificationChannelAsync('prayer_times', {
      name: 'Prayer Times Notifications',
      importance: Notifications.AndroidImportance.MAX,
      vibrationPattern: [0, 250, 250, 250],
      lightColor: '#FF231F7C',
    });
  }
  
  // Clean up any existing notifications on startup
  await Notifications.cancelAllScheduledNotificationsAsync();
  return true;
};

export const schedulePrayerNotifications = async (latitude: number, longitude: number) => {
  // Try to cancel all before scheduling again to avoid duplicate notifications
  await Notifications.cancelAllScheduledNotificationsAsync();
  
  // Calculate today's prayer times
  const today = getPrayerTimes(latitude, longitude, new Date());
  
  // Schedule a notification for each prayer
  const prayers = [
    { name: 'fajr', time: today.fajr },
    { name: 'dhuhr', time: today.dhuhr },
    { name: 'asr', time: today.asr },
    { name: 'maghrib', time: today.maghrib },
    { name: 'isha', time: today.isha },
  ];
  
  const now = new Date().getTime();
  
  for (const prayer of prayers) {
    if (!prayer.time) continue;
    
    // Test: you can uncomment below to test by scheduling close to current time
    // if (prayer.name === 'Isha') prayer.time = new Date(Date.now() + 10000); 

    const prayerTimeMs = prayer.time.getTime();
    if (prayerTimeMs > now) {
      await Notifications.scheduleNotificationAsync({
        content: {
          title: `Time for ${prayer.name.charAt(0).toUpperCase() + prayer.name.slice(1)}`,
          body: `It is time for ${prayer.name} prayer.`,
          data: { type: 'prayer', prayerName: prayer.name },
        },
        trigger: {
          type: Notifications.SchedulableTriggerInputTypes.DATE,
          date: new Date(prayerTimeMs),
        },
      });
    }
  }

  // Schedule Azkar
  const azkar = [
    { type: 'morning', time: today.fajr ? new Date(today.fajr.getTime() + 20 * 60000) : null, title: 'Morning Azkar', body: 'It is time for Morning Azkar' },
    { type: 'evening', time: today.asr ? new Date(today.asr.getTime() + 20 * 60000) : null, title: 'Evening Azkar', body: 'It is time for Evening Azkar' },
  ];

  for (const zkr of azkar) {
    if (!zkr.time) continue;
    if (zkr.time.getTime() > now) {
      await Notifications.scheduleNotificationAsync({
        content: {
          title: zkr.title,
          body: zkr.body,
          data: { type: 'azkar', azkarType: zkr.type },
          android: {
            channelId: 'prayer_times',
          },
        },
        trigger: {
          type: Notifications.SchedulableTriggerInputTypes.DATE,
          date: zkr.time,
        },
      });
    }
  }
};

export const startListeningForNotifications = (onAzkar: (type: 'morning' | 'evening') => void) => {
  const subscription = Notifications.addNotificationReceivedListener(notification => {
    const data = notification.request.content.data;
    if (data?.type === 'prayer') {
      const settings = settingsService.getSettings();
      const prayerName = (data.prayerName as string)?.toLowerCase();
      if (prayerName && settings.enabledAzans[prayerName]) {
        audioService.playAzan();
      }
    } else if (data?.type === 'azkar') {
      onAzkar(data.azkarType as 'morning' | 'evening');
    }
  });

  const responseSubscription = Notifications.addNotificationResponseReceivedListener(response => {
    const data = response.notification.request.content.data;
    if (data?.type === 'prayer') {
      const settings = settingsService.getSettings();
      const prayerName = (data.prayerName as string)?.toLowerCase();
      if (prayerName && settings.enabledAzans[prayerName]) {
        audioService.playAzan();
      }
    } else if (data?.type === 'azkar') {
      onAzkar(data.azkarType as 'morning' | 'evening');
    }
  });

  return () => {
    subscription.remove();
    responseSubscription.remove();
  };
};
