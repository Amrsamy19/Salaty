import React, { useEffect, useState } from 'react';
import { StyleSheet, Text, View, SafeAreaView, ScrollView, ActivityIndicator, TouchableOpacity, RefreshControl } from 'react-native';
import { StatusBar } from 'expo-status-bar';
import * as Location from 'expo-location';
import { getPrayerTimes, formatTime } from './src/utils/prayerTimes';
import { setupNotifications, schedulePrayerNotifications, startListeningForNotifications } from './src/services/notifications';
import { audioService } from './src/services/audio';
import { AzanModal } from './src/components/AzanModal';
import { MapPin, Moon, Sun, Sunrise, Sunset, MoonStar } from 'lucide-react-native';

export default function App() {
  const [loading, setLoading] = useState(true);
  const [errorMsg, setErrorMsg] = useState('');
  const [locationName, setLocationName] = useState('Locating...');
  const [prayers, setPrayers] = useState<any>(null);
  const [isAzanPlaying, setIsAzanPlaying] = useState(false);
  const [refreshing, setRefreshing] = useState(false);
  const [nextPrayer, setNextPrayer] = useState('');
  const [coords, setCoords] = useState<{lat: number, lon: number} | null>(null);

  useEffect(() => {
    init();

    const unsubscribeAudio = audioService.subscribe((playing) => {
      setIsAzanPlaying(playing);
    });

    const unsubscribeNotifications = startListeningForNotifications();

    return () => {
      unsubscribeAudio();
      unsubscribeNotifications();
    };
  }, []);

  useEffect(() => {
    if (coords) updatePrayerTimes();
    
    // Check prayer times every minute to update the next prayer countdown
    const interval = setInterval(() => {
      if (coords) updatePrayerTimes();
    }, 60000);
    return () => clearInterval(interval);
  }, [coords]);

  const init = async () => {
    setLoading(true);
    try {
      // Setup notifications first
      await setupNotifications();
      
      let { status } = await Location.requestForegroundPermissionsAsync();
      if (status !== 'granted') {
        setErrorMsg('Permission to access location was denied');
        return;
      }

      let location = await Location.getCurrentPositionAsync({});
      setCoords({ lat: location.coords.latitude, lon: location.coords.longitude });
      
      // Get readable address
      let address = await Location.reverseGeocodeAsync({
        latitude: location.coords.latitude,
        longitude: location.coords.longitude
      });
      
      if (address && address.length > 0) {
        setLocationName(`${address[0].city || address[0].subregion}, ${address[0].country}`);
      }
      
      // Schedule background notifications
      await schedulePrayerNotifications(location.coords.latitude, location.coords.longitude);
      
    } catch (e) {
      setErrorMsg('Failed to initialize. Checking location permissions.');
      console.error(e);
    } finally {
      setLoading(false);
    }
  };

  const updatePrayerTimes = () => {
    if (!coords) return;
    const times = getPrayerTimes(coords.lat, coords.lon);
    setPrayers(times);
    setNextPrayer(times.nextPrayer);
  };

  const onRefresh = React.useCallback(async () => {
    setRefreshing(true);
    await init();
    setRefreshing(false);
  }, []);

  const handleStopAzan = () => {
    audioService.stopAzan();
  };

  // Icons for list
  const PRAYER_ICONS = {
    fajr: <Moon size={24} color="#e2d1a8" />,
    sunrise: <Sunrise size={24} color="#c5a35e" />,
    dhuhr: <Sun size={24} color="#c5a35e" />,
    asr: <Sun size={24} color="#c5a35e" />,
    maghrib: <Sunset size={24} color="#c5a35e" />,
    isha: <MoonStar size={24} color="#e2d1a8" />
  };

  const renderPrayerCard = (name: string, key: string) => {
    if (!prayers) return null;
    
    const time = prayers[key];
    const isNext = nextPrayer === key;

    return (
      <View style={[styles.prayerCard, isNext && styles.prayerCardNext]}>
        <View style={styles.prayerCardLeft}>
          <View style={[styles.iconContainer, isNext && styles.iconContainerNext]}>
            {PRAYER_ICONS[key as keyof typeof PRAYER_ICONS] || <Moon size={24} color="#A7F3D0" />}
          </View>
          <Text style={[styles.prayerName, isNext && styles.textGold]}>{name}</Text>
        </View>
        <Text style={[styles.prayerTime, isNext && styles.textGold]}>{formatTime(time)}</Text>
      </View>
    );
  };

  const testAzanPlayback = () => {
    // For manual testing
    audioService.playAzan();
  };

  if (loading) {
    return (
      <View style={styles.loadingContainer}>
        <ActivityIndicator size="large" color="#c5a35e" />
        <Text style={styles.loadingText}>Locating your direction...</Text>
      </View>
    );
  }

  return (
    <SafeAreaView style={styles.container}>
      <StatusBar style="light" />
      
      <ScrollView 
        contentContainerStyle={styles.scrollContent}
        refreshControl={
          <RefreshControl refreshing={refreshing} onRefresh={onRefresh} tintColor="#c5a35e" />
        }
      >
        <View style={styles.header}>
          {errorMsg ? (
            <Text style={styles.errorText}>{errorMsg}</Text>
          ) : (
            <>
              <View style={styles.locationContainer}>
                <MapPin size={20} color="#c5a35e" />
                <Text style={styles.locationText}>{locationName}</Text>
              </View>
              <Text style={styles.dateText}>{new Date().toLocaleDateString(undefined, { weekday: 'long', year: 'numeric', month: 'long', day: 'numeric' })}</Text>
            </>
          )}
        </View>

        <View style={styles.heroSection}>
          <MoonStar size={64} color="#c5a35e" style={{ marginBottom: 20, opacity: 0.8 }} />
          <Text style={styles.nextPrayerLabel}>Next Prayer</Text>
          <Text style={styles.nextPrayerTitle}>
            {nextPrayer && nextPrayer !== 'none' ? nextPrayer.charAt(0).toUpperCase() + nextPrayer.slice(1) : 'Fajr'}
          </Text>
          <Text style={styles.nextPrayerTime}>
            {prayers && nextPrayer && nextPrayer !== 'none' ? formatTime(prayers[nextPrayer]) : formatTime(prayers?.fajr)}
          </Text>
          
          {/* Debug Button */}
          {__DEV__ && (
            <TouchableOpacity onPress={testAzanPlayback} style={styles.debugBtn}>
              <Text style={styles.debugBtnText}>[Test Azan Modal]</Text>
            </TouchableOpacity>
          )}
        </View>

        <View style={styles.listContainer}>
          {renderPrayerCard('Fajr', 'fajr')}
          {renderPrayerCard('Sunrise', 'sunrise')}
          {renderPrayerCard('Dhuhr', 'dhuhr')}
          {renderPrayerCard('Asr', 'asr')}
          {renderPrayerCard('Maghrib', 'maghrib')}
          {renderPrayerCard('Isha', 'isha')}
        </View>
      </ScrollView>

      <AzanModal 
        visible={isAzanPlaying} 
        onStop={handleStopAzan} 
      />
    </SafeAreaView>
  );
}

const styles = StyleSheet.create({
  container: {
    flex: 1,
    backgroundColor: '#061026', // Deep Blue
  },
  loadingContainer: {
    flex: 1,
    backgroundColor: '#061026',
    justifyContent: 'center',
    alignItems: 'center',
  },
  loadingText: {
    color: '#e2d1a8', // Light Gold
    marginTop: 16,
    fontSize: 16,
  },
  scrollContent: {
    flexGrow: 1,
    padding: 24,
    paddingTop: 48,
  },
  header: {
    alignItems: 'center',
    marginBottom: 40,
  },
  locationContainer: {
    flexDirection: 'row',
    alignItems: 'center',
    marginBottom: 8,
    backgroundColor: 'rgba(197, 163, 94, 0.1)',
    paddingHorizontal: 16,
    paddingVertical: 8,
    borderRadius: 20,
  },
  locationText: {
    color: '#c5a35e', // Gold
    fontSize: 16,
    fontWeight: '600',
    marginLeft: 8,
  },
  dateText: {
    color: '#e2d1a8', // Light Gold
    fontSize: 14,
  },
  errorText: {
    color: '#EF4444', // Red 500
    textAlign: 'center',
  },
  heroSection: {
    alignItems: 'center',
    marginBottom: 48,
  },
  nextPrayerLabel: {
    color: '#e2d1a8', // Light Gold
    fontSize: 14,
    fontWeight: '600',
    textTransform: 'uppercase',
    letterSpacing: 2,
    marginBottom: 8,
  },
  nextPrayerTitle: {
    color: '#c5a35e', // Gold
    fontSize: 48,
    fontWeight: 'bold',
    marginBottom: 8,
  },
  nextPrayerTime: {
    color: '#e2d1a8', // Light Gold
    fontSize: 32,
    fontWeight: '300',
  },
  listContainer: {
    backgroundColor: 'rgba(10, 26, 58, 0.5)', // Medium Blue with opacity
    borderRadius: 24,
    padding: 16,
    borderWidth: 1,
    borderColor: '#1e293b', // Subtle border
  },
  prayerCard: {
    flexDirection: 'row',
    alignItems: 'center',
    justifyContent: 'space-between',
    paddingVertical: 16,
    paddingHorizontal: 16,
    borderBottomWidth: 1,
    borderBottomColor: 'rgba(30, 41, 59, 0.5)',
  },
  prayerCardNext: {
    backgroundColor: '#0a1a3a', // Darker Blue
    borderRadius: 16,
    borderBottomWidth: 0,
    marginTop: 8,
    marginBottom: 8,
    shadowColor: '#c5a35e',
    shadowOffset: { width: 0, height: 4 },
    shadowOpacity: 0.1,
    shadowRadius: 10,
    elevation: 5,
  },
  prayerCardLeft: {
    flexDirection: 'row',
    alignItems: 'center',
  },
  iconContainer: {
    width: 40,
    height: 40,
    borderRadius: 20,
    backgroundColor: 'rgba(197, 163, 94, 0.1)',
    justifyContent: 'center',
    alignItems: 'center',
    marginRight: 16,
  },
  iconContainerNext: {
    backgroundColor: 'rgba(197, 163, 94, 0.2)', // More gold with opacity
  },
  prayerName: {
    color: '#e2d1a8', // Light Gold
    fontSize: 18,
    fontWeight: '500',
  },
  prayerTime: {
    color: '#e2d1a8', // Light Gold
    fontSize: 18,
    fontWeight: '500',
  },
  textGold: {
    color: '#c5a35e',
    fontWeight: 'bold',
  },
  debugBtn: {
    marginTop: 20,
    padding: 10,
    backgroundColor: '#1e293b',
    borderRadius: 10,
  },
  debugBtnText: {
    color: '#e2d1a8',
    fontSize: 12,
  }
});
