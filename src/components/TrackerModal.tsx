import React from 'react';
import {
  View,
  Text,
  StyleSheet,
  Modal,
  TouchableOpacity,
  Dimensions,
  ScrollView,
} from 'react-native';
import { X, CheckCircle, Circle, Trophy } from 'lucide-react-native';
import { trackerService, PrayerLogs } from '../services/tracker';
import { translations } from '../utils/translations';
import { settingsService } from '../services/settings';

interface TrackerModalProps {
  visible: boolean;
  onClose: () => void;
  inline?: boolean;
}

const { width, height } = Dimensions.get('window');

export const TrackerModal: React.FC<TrackerModalProps> = ({ visible, onClose, inline }) => {
  const currentSettings = settingsService.getSettings();
  const t = translations[currentSettings.language];
  const isRTL = currentSettings.language === 'ar';
  const logs = trackerService.getLogs();

  // Sort dates descending
  const sortedDates = Object.keys(logs).sort((a, b) => b.localeCompare(a));
  const prayers = ['fajr', 'dhuhr', 'asr', 'maghrib', 'isha'];

  const calculateDailyTotal = (dateStr: string) => {
    let count = 0;
    prayers.forEach(p => {
      if (logs[dateStr]?.[p]) count++;
    });
    return count;
  };

  const content = (
    <View style={[styles.container, inline && styles.inlineContainer]}>
      <View style={styles.header}>
        <View style={[styles.titleGroup, isRTL && { flexDirection: 'row-reverse' }]}>
            <Trophy size={24} color="#c5a35e" />
            <Text style={[styles.title, isRTL ? { marginRight: 10 } : { marginLeft: 10 }]}>{t.trackerHistory}</Text>
        </View>
        {!inline && (
          <TouchableOpacity onPress={onClose} style={styles.closeButton}>
            <X size={24} color="#c5a35e" />
          </TouchableOpacity>
        )}
      </View>

      <ScrollView showsVerticalScrollIndicator={false}>
        {sortedDates.length === 0 ? (
            <View style={styles.emptyContainer}>
                <Text style={styles.emptyText}>{t.noLogsYet}</Text>
            </View>
        ) : (
            sortedDates.map((dateStr) => {
                const total = calculateDailyTotal(dateStr);
                return (
                    <View key={dateStr} style={styles.dayCard}>
                        <View style={[styles.dayHeader, isRTL && { flexDirection: 'row-reverse' }]}>
                            <Text style={styles.dayDate}>{dateStr}</Text>
                            <View style={styles.scoreBadge}>
                                <Text style={styles.scoreText}>{total}/5</Text>
                            </View>
                        </View>
                        
                        <View style={[styles.statusRow, isRTL && { flexDirection: 'row-reverse' }]}>
                            {prayers.map((p) => (
                                <View key={p} style={styles.statusItem}>
                                    <Text style={styles.prayerLabel}>{t[p as keyof typeof t].charAt(0)}</Text>
                                    {logs[dateStr]?.[p] ? (
                                        <CheckCircle size={16} color="#c5a35e" fill="rgba(197, 163, 94, 0.2)" />
                                    ) : (
                                        <Circle size={16} color="rgba(197, 163, 94, 0.2)" />
                                    )}
                                </View>
                            ))}
                        </View>
                    </View>
                );
            })
        )}
        <View style={{ height: 40 }} />
      </ScrollView>
    </View>
  );

  if (inline) {
    return (
      <View style={[styles.viewWrapper, { direction: isRTL ? 'rtl' : 'ltr' }]}>
        {content}
      </View>
    );
  }

  return (
    <Modal visible={visible} animationType="slide" transparent={true}>
      <View style={[styles.overlay, { direction: isRTL ? 'rtl' : 'ltr' }]}>
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
    paddingTop: 10,
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
  titleGroup: {
    flexDirection: "row",
    alignItems: "center",
    justifyContent: "center",
    gap: 10,
  },
  title: {
    fontSize: 22,
    fontWeight: "bold",
    color: "#c5a35e",
  },
  closeButton: {
    padding: 4,
  },
  emptyContainer: {
    alignItems: "center",
    justifyContent: "center",
    padding: 40,
  },
  emptyText: {
    color: "#e2d1a8",
    opacity: 0.6,
    fontSize: 16,
  },
  dayCard: {
    backgroundColor: "rgba(30, 41, 59, 0.3)",
    borderRadius: 16,
    padding: 16,
    marginBottom: 12,
    borderWidth: 1,
    borderColor: "rgba(197, 163, 94, 0.1)",
  },
  dayHeader: {
    flexDirection: "row",
    justifyContent: "space-between",
    alignItems: "center",
    marginBottom: 12,
  },
  dayDate: {
    color: "#e2d1a8",
    fontWeight: "bold",
    fontSize: 16,
  },
  scoreBadge: {
    backgroundColor: "rgba(197, 163, 94, 0.15)",
    paddingHorizontal: 10,
    paddingVertical: 4,
    borderRadius: 10,
  },
  scoreText: {
    color: "#c5a35e",
    fontWeight: "bold",
    fontSize: 14,
  },
  statusRow: {
    flexDirection: "row",
    justifyContent: "space-between",
    paddingHorizontal: 10,
  },
  statusItem: {
    alignItems: "center",
  },
  prayerLabel: {
    color: "#e2d1a8",
    fontSize: 12,
    marginBottom: 4,
    opacity: 0.8,
  },
});
