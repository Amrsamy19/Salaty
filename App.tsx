// Salaty App Main Entry
// Version: 1.1.0 (Fixed Syntax and Robust Loading)
import React, { useEffect, useState, useCallback } from "react";
import {
  StyleSheet,
  Text,
  View,
  SafeAreaView,
  ScrollView,
  ActivityIndicator,
  TouchableOpacity,
  RefreshControl,
  Platform,
} from "react-native";
import { StatusBar } from "expo-status-bar";
import * as Location from "expo-location";
import { getPrayerTimes, formatTime } from "./src/utils/prayerTimes";
import {
  setupNotifications,
  schedulePrayerNotifications,
  startListeningForNotifications,
} from "./src/services/notifications";
import { audioService } from "./src/services/audio";
import { AzanModal } from "./src/components/AzanModal";
import {
  MapPin,
  Moon,
  Sun,
  Sunrise,
  Sunset,
  MoonStar,
  Settings as SettingsIcon,
  Calendar,
  Circle,
  CheckCircle,
  ClipboardList,
  Compass as CompassIcon,
} from "lucide-react-native";
import { SettingsModal } from "./src/components/SettingsModal";
import { TrackerModal } from "./src/components/TrackerModal";
import { QiblaModal } from "./src/components/QiblaModal";
import { AzkarModal } from "./src/components/AzkarModal";
import { settingsService } from "./src/services/settings";
import { trackerService } from "./src/services/tracker";
import { translations } from "./src/utils/translations";
import { getHijriDate, getFormattedGregorianDate } from "./src/utils/date";

export default function App() {
  const [loading, setLoading] = useState(true);
  const [errorMsg, setErrorMsg] = useState("");
  const [locationName, setLocationName] = useState("Salaty");
  const [prayers, setPrayers] = useState<any>(null);
  const [isAzanPlaying, setIsAzanPlaying] = useState(false);
  const [refreshing, setRefreshing] = useState(false);
  const [nextPrayer, setNextPrayer] = useState("");
  const [coords, setCoords] = useState<{ lat: number; lon: number } | null>(
    null,
  );
  const [settings, setSettings] = useState(settingsService.getSettings());
  const [activeTab, setActiveTab] = useState<"home" | "qibla" | "tracker" | "azkar" | "settings">("home");
  const [azkarType, setAzkarType] = useState<"morning" | "evening">("morning");
  const [prayerLogs, setPrayerLogs] = useState(trackerService.getLogs());

  // Safeguard translation selection
  const currentLang = settings?.language || "ar";
  const t = translations[currentLang] || translations.ar;

  const todayStr = new Date().toLocaleDateString("en-CA"); // YYYY-MM-DD in local time

  useEffect(() => {
    let isMounted = true;

    async function startup() {
      try {
        await setupNotifications();

        let { status } = await Location.requestForegroundPermissionsAsync();
        if (status !== "granted") {
          if (isMounted)
            setErrorMsg("Permission to access location was denied");
          setLoading(false);
          return;
        }

        let location = await Location.getCurrentPositionAsync({
          accuracy: Location.Accuracy.Low,
        });
        if (isMounted) {
          setCoords({
            lat: location.coords.latitude,
            lon: location.coords.longitude,
          });

          // Get location name
          try {
            const address = await Location.reverseGeocodeAsync({
              latitude: location.coords.latitude,
              longitude: location.coords.longitude,
            });
            if (address && address.length > 0) {
              const addr = address[0];
              const city =
                addr.city ||
                addr.subregion ||
                addr.district ||
                addr.region ||
                addr.name ||
                "";
              const country = addr.country || "";
              setLocationName(
                city && country
                  ? `${city}, ${country}`
                  : city || country || "Salaty",
              );
            }
          } catch (addrErr) {
            console.log("Address error", addrErr);
          }

          await schedulePrayerNotifications(
            location.coords.latitude,
            location.coords.longitude,
          );
        }
      } catch (e) {
        console.error("Startup error", e);
        if (isMounted)
          setErrorMsg("Failed to load data. Please check location settings.");
      } finally {
        if (isMounted) setLoading(false);
      }
    }

    startup();

    const unsubscribeAudio = audioService.subscribe((playing, isPreview) => {
      if (isMounted) setIsAzanPlaying(playing && !isPreview);
    });

    const unsubscribeSettings = settingsService.subscribe((newSettings) => {
      if (isMounted) setSettings(newSettings);
    });

    const unsubscribeNotifications = startListeningForNotifications((type) => {
      if (isMounted) {
        setAzkarType(type);
        setActiveTab("azkar");
      }
    });

    const unsubscribeTracker = trackerService.subscribe((newLogs) => {
      if (isMounted) setPrayerLogs(newLogs);
    });

    return () => {
      isMounted = false;
      unsubscribeAudio();
      unsubscribeSettings();
      unsubscribeNotifications();
      unsubscribeTracker();
    };
  }, []);

  useEffect(() => {
    if (coords) {
      updatePrayerTimes();
      const interval = setInterval(updatePrayerTimes, 60000);
      return () => clearInterval(interval);
    }
  }, [coords]);

  const updatePrayerTimes = () => {
    if (!coords) return;
    try {
      const times = getPrayerTimes(coords.lat, coords.lon);
      setPrayers(times);
      setNextPrayer(times.nextPrayer);
    } catch (e) {
      console.error("Error updating prayer times", e);
    }
  };

  const onRefresh = useCallback(async () => {
    setRefreshing(true);
    const { status } = await Location.requestForegroundPermissionsAsync();
    if (status === "granted") {
      const location = await Location.getCurrentPositionAsync({
        accuracy: Location.Accuracy.Low,
      });
      setCoords({
        lat: location.coords.latitude,
        lon: location.coords.longitude,
      });

      // Also update location name on refresh
      try {
        const address = await Location.reverseGeocodeAsync({
          latitude: location.coords.latitude,
          longitude: location.coords.longitude,
        });
        if (address && address.length > 0) {
          const addr = address[0];
          const city = addr.city || addr.subregion || addr.district || addr.region || addr.name || "";
          const country = addr.country || "";
          setLocationName(city && country ? `${city}, ${country}` : city || country || "Salaty");
        }
      } catch (e) {
        console.log("Refresh geocode error", e);
      }
    }
    setRefreshing(false);
  }, []);

  const handleStopAzan = () => {
    audioService.stopAzan();
  };

  const handleTogglePrayer = (prayerKey: string) => {
    if (prayerKey === "sunrise") return;
    trackerService.togglePrayer(todayStr, prayerKey);
  };

  const PRAYER_ICONS = {
    fajr: <Moon size={24} color="#e2d1a8" />,
    sunrise: <Sunrise size={24} color="#c5a35e" />,
    dhuhr: <Sun size={24} color="#c5a35e" />,
    asr: <Sun size={24} color="#c5a35e" />,
    maghrib: <Sunset size={24} color="#c5a35e" />,
    isha: <MoonStar size={24} color="#e2d1a8" />,
  };

  const renderPrayerCard = (label: string, key: string) => {
    if (!prayers || !prayers[key]) return null;

    const time = prayers[key];
    const isNext = nextPrayer === key;
    const isRTL = currentLang === "ar";
    const fontSize = settings.fontSize || 16;
    const isDone = prayerLogs[todayStr]?.[key] || false;
    const isTrackerEligible = key !== "sunrise";

    return (
      <View
        key={key}
        style={[
          styles.prayerCard,
          isNext && styles.prayerCardNext,
          isRTL && { flexDirection: "row-reverse" },
        ]}
      >
        <View
          style={[
            styles.prayerCardLeft,
            isRTL && { flexDirection: "row-reverse" },
          ]}
        >
          <View
            style={[styles.iconContainer, isNext && styles.iconContainerNext]}
          >
            {PRAYER_ICONS[key as keyof typeof PRAYER_ICONS] || (
              <Moon size={24} color="#e2d1a8" />
            )}
          </View>
          <Text
            style={[
              styles.prayerName,
              isNext && styles.textGold,
              { fontSize: fontSize + 2 },
              isRTL && { marginRight: 16 },
            ]}
          >
            {t[key as keyof typeof t] || label}
          </Text>
        </View>

        <View
          style={[
            styles.prayerCardRight,
            isRTL && { flexDirection: "row-reverse" },
          ]}
        >
          <Text
            style={[
              styles.prayerTime,
              isNext && styles.textGold,
              { fontSize: fontSize + 2 },
              !isRTL && { marginRight: 15 },
              isRTL && { marginLeft: 15 },
            ]}
          >
            {formatTime(time)}
          </Text>

          {isTrackerEligible && (
            <TouchableOpacity onPress={() => handleTogglePrayer(key)}>
              {isDone ? (
                <CheckCircle
                  size={22}
                  color="#c5a35e"
                  fill="rgba(197, 163, 94, 0.2)"
                />
              ) : (
                <Circle size={22} color="rgba(197, 163, 94, 0.3)" />
              )}
            </TouchableOpacity>
          )}
        </View>
      </View>
    );
  };

  if (loading) {
    return (
      <View style={styles.loadingContainer}>
        <ActivityIndicator size="large" color="#c5a35e" />
        <Text style={[styles.loadingText, { fontSize: settings.fontSize }]}>
          {t.locating || "Loading..."}
        </Text>
      </View>
    );
  }

  const isRTL = currentLang === "ar";
  const baseFontSize = settings.fontSize || 16;

  const renderHome = () => (
    <ScrollView
      contentContainerStyle={styles.scrollContent}
      refreshControl={
        <RefreshControl
          refreshing={refreshing}
          onRefresh={onRefresh}
          tintColor="#c5a35e"
        />
      }
    >
      <View style={styles.header}>
        {errorMsg ? (
          <Text style={styles.errorText}>{errorMsg}</Text>
        ) : (
          <>
            <View style={styles.dateContainer}>
              <Text style={[styles.dateText, { fontSize: baseFontSize - 2 }]}>
                {getFormattedGregorianDate(new Date(), currentLang)}
              </Text>
              <View
                style={[
                  styles.hijriBadge,
                  isRTL && { flexDirection: "row-reverse" },
                ]}
              >
                <Calendar size={14} color="#c5a35e" />
                <Text
                  style={[styles.hijriText, { fontSize: baseFontSize - 2 }]}
                >
                  {getHijriDate(new Date(), currentLang)}
                </Text>
              </View>
            </View>
          </>
        )}
      </View>

      <View style={styles.heroSection}>
        <MoonStar
          size={64}
          color="#c5a35e"
          style={{ marginBottom: 20, opacity: 0.8 }}
        />
        <Text
          style={[styles.nextPrayerLabel, { fontSize: baseFontSize - 2 }]}
        >
          {t.nextPrayer}
        </Text>
        <Text
          style={[styles.nextPrayerTitle, { fontSize: baseFontSize + 32 }]}
        >
          {nextPrayer && nextPrayer !== "none"
            ? t[nextPrayer as keyof typeof t] || nextPrayer
            : t.fajr || "Fajr"}
        </Text>
        <Text
          style={[styles.nextPrayerTime, { fontSize: baseFontSize + 16 }]}
        >
          {prayers && nextPrayer && nextPrayer !== "none"
            ? formatTime(prayers[nextPrayer])
            : prayers
              ? formatTime(prayers.fajr)
              : "--:--"}
        </Text>
      </View>

      <View style={[styles.listContainer, isRTL && { direction: "ltr" }]}>
        {renderPrayerCard("Fajr", "fajr")}
        {renderPrayerCard("Sunrise", "sunrise")}
        {renderPrayerCard("Dhuhr", "dhuhr")}
        {renderPrayerCard("Asr", "asr")}
        {renderPrayerCard("Maghrib", "maghrib")}
        {renderPrayerCard("Isha", "isha")}
      </View>

      {/* Padding for better scrolling */}
      <View style={{ height: 40 }} />
    </ScrollView>
  );

  return (
    <SafeAreaView
      style={[styles.container, { direction: isRTL ? "rtl" : "ltr" }]}
    >
      <StatusBar style="light" />

      {/* Header / Top Title */}
      <View style={styles.topNav}>
        <Text style={styles.appTitle}>{t.appName}</Text>
      </View>

      <View style={styles.mainContent}>
        {activeTab === "home" && renderHome()}
        
        {activeTab === "qibla" && coords && (
            <QiblaModal 
                visible={true} 
                onClose={() => setActiveTab("home")} 
                latitude={coords.lat} 
                longitude={coords.lon} 
                inline={true} 
            />
        )}

        {activeTab === "tracker" && (
            <TrackerModal 
                visible={true} 
                onClose={() => setActiveTab("home")} 
                inline={true} 
            />
        )}

        {activeTab === "azkar" && (
            <AzkarModal 
                visible={true} 
                onClose={() => setActiveTab("home")} 
                type={azkarType} 
                inline={true}
                onTypeChange={(type) => setAzkarType(type)}
            />
        )}

        {activeTab === "settings" && (
            <SettingsModal 
                visible={true} 
                onClose={() => setActiveTab("home")} 
                inline={true} 
            />
        )}
      </View>

      {/* Bottom Tab Bar */}
      <View style={[styles.tabBar, isRTL && { flexDirection: "row-reverse" }]}>
        <TouchableOpacity 
            style={styles.tabItem} 
            onPress={() => setActiveTab("home")}
        >
            <Calendar size={22} color={activeTab === "home" ? "#c5a35e" : "#64748b"} />
            <Text style={[styles.tabLabel, activeTab === "home" && styles.tabLabelActive]}>{t.prayers}</Text>
        </TouchableOpacity>

        <TouchableOpacity 
            style={styles.tabItem} 
            onPress={() => setActiveTab("qibla")}
        >
            <CompassIcon size={22} color={activeTab === "qibla" ? "#c5a35e" : "#64748b"} />
            <Text style={[styles.tabLabel, activeTab === "qibla" && styles.tabLabelActive]}>{t.qibla}</Text>
        </TouchableOpacity>

        <TouchableOpacity 
            style={styles.tabItem} 
            onPress={() => {
                const hour = new Date().getHours();
                setAzkarType(hour < 15 ? "morning" : "evening");
                setActiveTab("azkar");
            }}
        >
            {azkarType === "morning" ? 
                <Sun size={22} color={activeTab === "azkar" ? "#FBBF24" : "#64748b"} /> : 
                <Moon size={22} color={activeTab === "azkar" ? "#e2d1a8" : "#64748b"} />
            }
            <Text style={[styles.tabLabel, activeTab === "azkar" && styles.tabLabelActive]}>{t.morningAzkar.split(' ')[0]}</Text>
        </TouchableOpacity>

        <TouchableOpacity 
            style={styles.tabItem} 
            onPress={() => setActiveTab("tracker")}
        >
            <ClipboardList size={22} color={activeTab === "tracker" ? "#c5a35e" : "#64748b"} />
            <Text style={[styles.tabLabel, activeTab === "tracker" && styles.tabLabelActive]}>{t.trackerHistory.split(' ')[0]}</Text>
        </TouchableOpacity>

        <TouchableOpacity 
            style={styles.tabItem} 
            onPress={() => setActiveTab("settings")}
        >
            <SettingsIcon size={22} color={activeTab === "settings" ? "#c5a35e" : "#64748b"} />
            <Text style={[styles.tabLabel, activeTab === "settings" && styles.tabLabelActive]}>{t.settings}</Text>
        </TouchableOpacity>
      </View>

      <AzanModal visible={isAzanPlaying} onStop={handleStopAzan} />
    </SafeAreaView>
  );
}

const styles = StyleSheet.create({
  container: {
    flex: 1,
    backgroundColor: "#061026",
    paddingTop: Platform.OS === 'ios' ? 0 : 60,
  },
  mainContent: {
    flex: 1,
  },
  topNav: {
    flexDirection: "row",
    justifyContent: "center",
    alignItems: "center",
    paddingHorizontal: 20,
    paddingTop: 10,
    paddingBottom: 15,
  },
  appTitle: {
    color: "#c5a35e",
    fontSize: 22,
    fontWeight: "bold",
    letterSpacing: 2,
    textTransform: 'uppercase',
  },
  tabBar: {
    flexDirection: "row",
    backgroundColor: "#0a1a3a",
    paddingBottom: Platform.OS === "ios" ? 30 : 12,
    paddingTop: 12,
    borderTopWidth: 1,
    borderTopColor: "rgba(197, 163, 94, 0.2)",
    justifyContent: "space-around",
    alignItems: "center",
  },
  tabItem: {
    alignItems: "center",
    justifyContent: "center",
    flex: 1,
  },
  tabLabel: {
    color: "#64748b",
    fontSize: 10,
    marginTop: 4,
    fontWeight: "500",
  },
  tabLabelActive: {
    color: "#c5a35e",
    fontWeight: "bold",
  },
  loadingContainer: {
    flex: 1,
    backgroundColor: "#061026",
    justifyContent: "center",
    alignItems: "center",
  },
  loadingText: {
    color: "#e2d1a8",
    marginTop: 16,
    textAlign: "center",
  },
  scrollContent: {
    flexGrow: 1,
    paddingHorizontal: 20,
    paddingTop: 10,
  },
  header: {
    alignItems: "center",
    marginBottom: 30,
  },
  locationContainer: {
    flexDirection: "row",
    alignItems: "center",
    marginBottom: 12,
    backgroundColor: "rgba(197, 163, 94, 0.1)",
    paddingHorizontal: 16,
    paddingVertical: 8,
    borderRadius: 20,
  },
  locationText: {
    color: "#c5a35e",
    fontWeight: "600",
    marginLeft: 8,
  },
  dateContainer: {
    alignItems: "center",
  },
  dateText: {
    color: "#e2d1a8",
    marginBottom: 6,
  },
  hijriBadge: {
    flexDirection: "row",
    alignItems: "center",
    justifyContent: "center",
    backgroundColor: "rgba(197, 163, 94, 0.15)",
    paddingHorizontal: 12,
    paddingVertical: 4,
    borderRadius: 12,
    borderWidth: 1,
    borderColor: "rgba(197, 163, 94, 0.2)",
  },
  hijriText: {
    color: "#c5a35e",
    fontWeight: "600",
    marginLeft: 8,
  },
  errorText: {
    color: "#EF4444",
    textAlign: "center",
    padding: 20,
  },
  heroSection: {
    alignItems: "center",
    marginBottom: 40,
  },
  nextPrayerLabel: {
    color: "#e2d1a8",
    fontWeight: "600",
    textTransform: "uppercase",
    letterSpacing: 2,
    marginBottom: 8,
  },
  nextPrayerTitle: {
    color: "#c5a35e",
    fontWeight: "bold",
    marginBottom: 4,
  },
  nextPrayerTime: {
    color: "#e2d1a8",
    fontWeight: "300",
  },
  listContainer: {
    backgroundColor: "rgba(10, 26, 58, 0.3)",
    borderRadius: 24,
    padding: 10,
    borderWidth: 1,
    borderColor: "rgba(197, 163, 94, 0.15)",
  },
  prayerCard: {
    flexDirection: "row",
    alignItems: "center",
    justifyContent: "space-between",
    paddingVertical: 14,
    paddingHorizontal: 16,
    borderBottomWidth: 1,
    borderBottomColor: "rgba(197, 163, 94, 0.1)",
  },
  prayerCardNext: {
    backgroundColor: "rgba(197, 163, 94, 0.12)",
    borderRadius: 16,
    borderBottomWidth: 0,
    marginVertical: 4,
  },
  prayerCardLeft: {
    flexDirection: "row",
    alignItems: "center",
  },
  prayerCardRight: {
    flexDirection: "row",
    alignItems: "center",
  },
  iconContainer: {
    width: 38,
    height: 38,
    borderRadius: 19,
    backgroundColor: "rgba(197, 163, 94, 0.05)",
    justifyContent: "center",
    alignItems: "center",
    marginRight: 14,
  },
  iconContainerNext: {
    backgroundColor: "rgba(197, 163, 94, 0.2)",
  },
  prayerName: {
    color: "#e2d1a8",
    fontWeight: "500",
  },
  prayerTime: {
    color: "#e2d1a8",
    fontWeight: "500",
  },
  textGold: {
    color: "#c5a35e",
    fontWeight: "bold",
  },
});
