import * as Notifications from 'expo-notifications';
import { audioService } from './audio';
import { getPrayerTimes } from '../utils/prayerTimes';
import { Platform } from 'react-native';
import { subMinutes } from 'date-fns';

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
    { name: 'Fajr', time: today.fajr },
    { name: 'Dhuhr', time: today.dhuhr },
    { name: 'Asr', time: today.asr },
    { name: 'Maghrib', time: today.maghrib },
    { name: 'Isha', time: today.isha },
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
          title: `Time for ${prayer.name}`,
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
};

export const startListeningForNotifications = () => {
  const subscription = Notifications.addNotificationReceivedListener(notification => {
    // Check if it's a prayer notification
    const data = notification.request.content.data;
    if (data?.type === 'prayer') {
      audioService.playAzan();
    }
  });

  const responseSubscription = Notifications.addNotificationResponseReceivedListener(response => {
    const data = response.notification.request.content.data;
    if (data?.type === 'prayer') {
      audioService.playAzan();
    }
  });

  return () => {
    subscription.remove();
    responseSubscription.remove();
  };
};
