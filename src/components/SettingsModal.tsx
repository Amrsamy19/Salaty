import React, { useState, useEffect } from "react";
import {
  View,
  Text,
  StyleSheet,
  Modal,
  TouchableOpacity,
  Dimensions,
  ScrollView,
  Switch,
} from "react-native";
import { X, Globe, Type, Music, Bell, Play, Square } from "lucide-react-native";
import { settingsService, Language, AzanSound } from "../services/settings";
import { translations } from "../utils/translations";
import { audioService } from "../services/audio";

interface SettingsModalProps {
  visible: boolean;
  onClose: () => void;
  inline?: boolean;
}

const { width, height } = Dimensions.get("window");

export const SettingsModal: React.FC<SettingsModalProps> = ({
  visible,
  onClose,
  inline,
}) => {
  const [settings, setSettings] = useState(settingsService.getSettings());
  const [playingPreview, setPlayingPreview] = useState<string | null>(null);
  const t = translations[settings.language];

  useEffect(() => {
    const unsubscribeSettings = settingsService.subscribe(setSettings);
    const unsubscribeAudio = audioService.subscribe((playing, isPreview) => {
      if (!playing) setPlayingPreview(null);
    });
    return () => {
      unsubscribeSettings();
      unsubscribeAudio();
    };
  }, []);

  const handleLanguageChange = (lang: Language) => {
    settingsService.updateSettings({ language: lang });
  };

  const handleFontSizeChange = (direction: "up" | "down") => {
    const newSize =
      direction === "up" ? settings.fontSize + 1 : settings.fontSize - 1;
    if (newSize >= 12 && newSize <= 24) {
      settingsService.updateSettings({ fontSize: newSize });
    }
  };

  const handleSoundChange = (sound: AzanSound) => {
    settingsService.updateSettings({ azanSound: sound });
  };

  const toggleAzan = (prayer: string) => {
    const newEnabled = { ...settings.enabledAzans };
    newEnabled[prayer] = !newEnabled[prayer];
    settingsService.updateSettings({ enabledAzans: newEnabled });
  };

  const sounds: AzanSound[] = ["abdelbaset", "egypt", "makah", "mohamedrefaat"];
  const prayers = ["fajr", "dhuhr", "asr", "maghrib", "isha"];

  const content = (
    <View style={[styles.container, inline && styles.inlineContainer]}>
      <View style={styles.header}>
        <Text style={styles.title}>{t.settings}</Text>
        {!inline && (
          <TouchableOpacity onPress={onClose} style={styles.closeButton}>
            <X size={24} color="#c5a35e" />
          </TouchableOpacity>
        )}
      </View>

      <ScrollView showsVerticalScrollIndicator={false}>
        {/* Language Selection */}
        <View style={styles.section}>
          <View style={styles.sectionHeader}>
            <Globe size={20} color="#c5a35e" />
            <Text style={styles.sectionTitle}>{t.language}</Text>
          </View>
          <View style={styles.optionRow}>
            <TouchableOpacity
              style={[
                styles.segment,
                settings.language === "ar" && styles.segmentActive,
              ]}
              onPress={() => handleLanguageChange("ar")}
            >
              <Text
                style={[
                  styles.segmentText,
                  settings.language === "ar" && styles.segmentTextActive,
                ]}
              >
                العربية
              </Text>
            </TouchableOpacity>
            <TouchableOpacity
              style={[
                styles.segment,
                settings.language === "en" && styles.segmentActive,
              ]}
              onPress={() => handleLanguageChange("en")}
            >
              <Text
                style={[
                  styles.segmentText,
                  settings.language === "en" && styles.segmentTextActive,
                ]}
              >
                English
              </Text>
            </TouchableOpacity>
          </View>
        </View>

        {/* Font Size Selection */}
        <View style={styles.section}>
          <View style={styles.sectionHeader}>
            <Type size={20} color="#c5a35e" />
            <Text style={styles.sectionTitle}>{t.fontSize}</Text>
          </View>
          <View style={styles.fontControls}>
            <TouchableOpacity
              onPress={() => handleFontSizeChange("down")}
              style={styles.fontBtn}
            >
              <Text style={styles.fontBtnText}>-</Text>
            </TouchableOpacity>
            <Text style={styles.fontSizeValue}>{settings.fontSize}</Text>
            <TouchableOpacity
              onPress={() => handleFontSizeChange("up")}
              style={styles.fontBtn}
            >
              <Text style={styles.fontBtnText}>+</Text>
            </TouchableOpacity>
          </View>
        </View>

        {/* Azan Sound Selection */}
        <View style={styles.section}>
          <View style={styles.sectionHeader}>
            <Music size={20} color="#c5a35e" />
            <Text style={styles.sectionTitle}>{t.azanSound}</Text>
          </View>
          {sounds.map((sound) => (
            <View
              key={sound}
              style={[
                styles.soundOption,
                settings.azanSound === sound && styles.soundOptionActive,
              ]}
            >
              <TouchableOpacity
                style={styles.soundInfo}
                onPress={() => handleSoundChange(sound)}
              >
                <Text
                  style={[
                    styles.soundText,
                    settings.azanSound === sound && styles.soundTextActive,
                  ]}
                >
                  {t[sound as keyof typeof t]}
                </Text>
                {settings.azanSound === sound && (
                  <View style={styles.activeDot} />
                )}
              </TouchableOpacity>

              <TouchableOpacity
                style={styles.previewBtn}
                onPress={() => {
                  if (playingPreview === sound) {
                    audioService.stopAzan();
                    setPlayingPreview(null);
                  } else {
                    audioService.playPreview(sound);
                    setPlayingPreview(sound);
                  }
                }}
              >
                {playingPreview === sound ? (
                  <Square size={18} color="#c5a35e" fill="#c5a35e" />
                ) : (
                  <Play
                    size={18}
                    color="#c5a35e"
                    fill="rgba(197, 163, 94, 0.2)"
                  />
                )}
              </TouchableOpacity>
            </View>
          ))}
        </View>

        {/* Prayer-specific Notifications */}
        <View style={styles.section}>
          <View style={styles.sectionHeader}>
            <Bell size={20} color="#c5a35e" />
            <Text style={styles.sectionTitle}>
              {t.notificationSettings}
            </Text>
          </View>
          <View style={styles.prayerList}>
            {prayers.map((prayer) => (
              <View key={prayer} style={styles.prayerRow}>
                <Text style={styles.prayerToggleLabel}>
                  {t[prayer as keyof typeof t]}
                </Text>
                <Switch
                  value={settings.enabledAzans[prayer]}
                  onValueChange={() => toggleAzan(prayer)}
                  trackColor={{
                    false: "#1e293b",
                    true: "rgba(197, 163, 94, 0.5)",
                  }}
                  thumbColor={
                    settings.enabledAzans[prayer] ? "#c5a35e" : "#64748b"
                  }
                />
              </View>
            ))}
          </View>
        </View>
      </ScrollView>
    </View>
  );

  if (inline) {
    return (
      <View style={[styles.viewWrapper, { direction: settings.language === "ar" ? "rtl" : "ltr" }]}>
        {content}
      </View>
    );
  }

  return (
    <Modal visible={visible} animationType="slide" transparent={true}>
      <View
        style={[
          styles.overlay,
          { direction: settings.language === "ar" ? "rtl" : "ltr" },
        ]}
      >
        {content}
      </View>
    </Modal>
  );
};

const styles = StyleSheet.create({
  viewWrapper: {
    flex: 1,
  },
  inlineContainer: {
    height: "100%",
    backgroundColor: "transparent",
    borderWidth: 0,
    borderTopLeftRadius: 0,
    borderTopRightRadius: 0,
  },
  overlay: {
    flex: 1,
    backgroundColor: "rgba(6, 16, 38, 0.85)",
    justifyContent: "flex-end",
  },
  container: {
    height: height * 0.7,
    backgroundColor: "#0a1a3a",
    borderTopLeftRadius: 32,
    borderTopRightRadius: 32,
    padding: 24,
    borderWidth: 1,
    borderColor: "rgba(197, 163, 94, 0.3)",
  },
  header: {
    flexDirection: "row",
    justifyContent: "space-between",
    alignItems: "center",
    marginBottom: 24,
  },
  title: {
    fontSize: 24,
    fontWeight: "bold",
    color: "#c5a35e",
  },
  closeButton: {
    padding: 4,
  },
  section: {
    marginBottom: 24,
  },
  sectionHeader: {
    flexDirection: "row",
    alignItems: "center",
    marginBottom: 16,
  },
  sectionTitle: {
    color: "#e2d1a8",
    fontSize: 18,
    fontWeight: "600",
    marginLeft: 8,
    marginRight: 8,
  },
  optionRow: {
    flexDirection: "row",
    backgroundColor: "rgba(30, 41, 59, 0.5)",
    borderRadius: 12,
    padding: 4,
  },
  segment: {
    flex: 1,
    paddingVertical: 10,
    alignItems: "center",
    borderRadius: 8,
  },
  segmentActive: {
    backgroundColor: "#c5a35e",
  },
  segmentText: {
    color: "#e2d1a8",
    fontWeight: "500",
  },
  segmentTextActive: {
    color: "#061026",
    fontWeight: "bold",
  },
  fontControls: {
    flexDirection: "row",
    alignItems: "center",
    justifyContent: "center",
    backgroundColor: "rgba(30, 41, 41, 0.3)",
    borderRadius: 12,
    padding: 8,
  },
  fontBtn: {
    width: 40,
    height: 40,
    borderRadius: 20,
    backgroundColor: "rgba(197, 163, 94, 0.2)",
    justifyContent: "center",
    alignItems: "center",
  },
  fontBtnText: {
    color: "#c5a35e",
    fontSize: 24,
    fontWeight: "bold",
  },
  fontSizeValue: {
    color: "#e2d1a8",
    fontSize: 20,
    fontWeight: "bold",
    marginHorizontal: 32,
  },
  soundOption: {
    flexDirection: "row",
    alignItems: "center",
    justifyContent: "space-between",
    paddingVertical: 12,
    paddingHorizontal: 16,
    backgroundColor: "rgba(30, 41, 59, 0.3)",
    borderRadius: 12,
    marginBottom: 8,
    borderWidth: 1,
    borderColor: "transparent",
  },
  soundInfo: {
    flex: 1,
    flexDirection: "row",
    alignItems: "center",
    justifyContent: "space-between",
    paddingRight: 12,
  },
  previewBtn: {
    padding: 8,
    backgroundColor: "rgba(197, 163, 94, 0.1)",
    borderRadius: 8,
  },
  soundOptionActive: {
    borderColor: "rgba(197, 163, 94, 0.5)",
    backgroundColor: "rgba(197, 163, 94, 0.1)",
  },
  soundText: {
    color: "#e2d1a8",
    fontSize: 16,
  },
  soundTextActive: {
    color: "#c5a35e",
    fontWeight: "bold",
  },
  activeDot: {
    width: 8,
    height: 8,
    borderRadius: 4,
    marginHorizontal: 12,
    backgroundColor: "#c5a35e",
  },
  prayerList: {
    backgroundColor: "rgba(30, 41, 59, 0.3)",
    borderRadius: 12,
    padding: 8,
  },
  prayerRow: {
    flexDirection: "row",
    alignItems: "center",
    justifyContent: "space-between",
    paddingVertical: 12,
    paddingHorizontal: 12,
    borderBottomWidth: 1,
    borderBottomColor: "rgba(197, 163, 94, 0.05)",
  },
  prayerToggleLabel: {
    color: "#e2d1a8",
    fontSize: 16,
  },
});
