import React, { useState, useEffect } from "react";
import {
  View,
  Text,
  StyleSheet,
  Modal,
  TouchableOpacity,
  Dimensions,
  Image,
} from "react-native";
import { Magnetometer } from "expo-sensors";
import Svg, { Path, Circle, G, Text as SvgText, Line } from "react-native-svg";
import { X, Compass as CompassIcon, LocateFixed } from "lucide-react-native";
import { translations } from "../utils/translations";
import { settingsService } from "../services/settings";
import { calculateQibla } from "../utils/prayerTimes";

interface QiblaModalProps {
  visible: boolean;
  onClose: () => void;
  latitude: number;
  longitude: number;
  inline?: boolean;
}

const { width, height } = Dimensions.get("window");

export const QiblaModal: React.FC<QiblaModalProps> = ({
  visible,
  onClose,
  latitude,
  longitude,
  inline,
}) => {
  const currentSettings = settingsService.getSettings();
  const t = translations[currentSettings.language];
  const isRTL = currentSettings.language === "ar";

  const [magnetometer, setMagnetometer] = useState(0);
  const qiblaDirection = calculateQibla(latitude, longitude);

  useEffect(() => {
    let subscription: any;
    if (visible || inline) {
      Magnetometer.setUpdateInterval(100);
      subscription = Magnetometer.addListener((data) => {
        let angle = Math.atan2(data.y, data.x) * (180 / Math.PI);
        angle = (angle + 360) % 360;
        setMagnetometer(angle);
      });
    }
    return () => {
      if (subscription) subscription.remove();
    };
  }, [visible, inline]);

  // The rotation for the compass dial
  const compassRotation = 360 - magnetometer;
  // The rotation for the Qibla needle relative to the North
  const qiblaRelativeRotation = qiblaDirection - magnetometer;

  const content = (
    <View style={[styles.container, inline && styles.inlineContainer]}>
      <View style={styles.header}>
        <View
          style={[styles.titleGroup, isRTL && { flexDirection: "row-reverse" }]}
        >
          <CompassIcon size={24} color="#c5a35e" />
          <Text
            style={[
              styles.title,
              isRTL ? { marginRight: 10 } : { marginLeft: 10 },
            ]}
          >
            {t.qibla}
          </Text>
        </View>
        {!inline && (
          <TouchableOpacity onPress={onClose} style={styles.closeButton}>
            <X size={24} color="#c5a35e" />
          </TouchableOpacity>
        )}
      </View>

      <View style={styles.compassContainer}>
        <View style={styles.compassWrap}>
          {/* Compass Background / Outer Ring */}
          <Svg height="300" width="300" viewBox="0 0 100 100">
            <G rotation={compassRotation} origin="50, 50">
              <Circle
                cx="50"
                cy="50"
                r="48"
                stroke="#c5a35e"
                strokeWidth="1"
                fill="rgba(197, 163, 94, 0.05)"
              />

              {/* Degree Markers */}
              {[0, 30, 60, 90, 120, 150, 180, 210, 240, 270, 300, 330].map(
                (degree) => (
                  <G key={degree} rotation={degree} origin="50, 50">
                    <Line
                      x1="50"
                      y1="2"
                      x2="50"
                      y2="8"
                      stroke="#c5a35e"
                      strokeWidth="0.5"
                    />
                    <SvgText
                      x="50"
                      y="15"
                      fontSize="6"
                      fill="#c5a35e"
                      textAnchor="middle"
                      fontWeight="bold"
                      transform={`rotate(${-degree}, 50, 15)`}
                    >
                      {degree === 0
                        ? "N"
                        : degree === 90
                          ? "E"
                          : degree === 180
                            ? "S"
                            : degree === 270
                              ? "W"
                              : ""}
                    </SvgText>
                  </G>
                ),
              )}
            </G>

            {/* Static Center Point */}
            <Circle cx="50" cy="50" r="2" fill="#c5a35e" />

            {/* Qibla Indicator Needle */}
            <G rotation={qiblaRelativeRotation} origin="50, 50">
              {/* The Arrow */}
              <Path
                d="M50 10 L45 30 L50 25 L55 30 Z"
                fill="#c5a35e"
                stroke="#c5a35e"
                strokeWidth="1"
              />
              <Line
                x1="50"
                y1="30"
                x2="50"
                y2="50"
                stroke="#c5a35e"
                strokeWidth="1.5"
              />

              {/* Mosque Icon (Simple Path) */}
              <G transform="translate(42, 5) scale(0.15)">
                <Path d="M25 0 L50 20 L50 50 L0 50 L0 20 Z" fill="#c5a35e" />
              </G>
            </G>
          </Svg>
        </View>

        <View style={styles.infoBox}>
          <Text style={styles.directionValue}>
            {Math.round(qiblaDirection)}°
          </Text>
          <Text style={styles.directionLabel}>{t.qibla}</Text>
        </View>
      </View>

      <View style={styles.footer}>
        <LocateFixed size={20} color="#e2d1a8" style={{ opacity: 0.6 }} />
        <Text style={styles.coordsText}>
          {latitude.toFixed(4)}, {longitude.toFixed(4)}
        </Text>
      </View>
    </View>
  );

  if (inline) {
    return (
      <View style={[styles.viewWrapper, { direction: isRTL ? "rtl" : "ltr" }]}>
        {content}
      </View>
    );
  }

  return (
    <Modal visible={visible} animationType="slide" transparent={true}>
      <View style={[styles.overlay, { direction: isRTL ? "rtl" : "ltr" }]}>
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
    height: height * 0.75,
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
    marginBottom: 40,
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
  compassContainer: {
    flex: 1,
    alignItems: "center",
    justifyContent: "center",
  },
  compassWrap: {
    width: 300,
    height: 300,
    alignItems: "center",
    justifyContent: "center",
  },
  infoBox: {
    marginTop: 40,
    alignItems: "center",
  },
  directionValue: {
    fontSize: 48,
    fontWeight: "bold",
    color: "#c5a35e",
  },
  directionLabel: {
    fontSize: 18,
    color: "#e2d1a8",
    opacity: 0.8,
    textTransform: "uppercase",
    letterSpacing: 2,
  },
  footer: {
    flexDirection: "row",
    alignItems: "center",
    justifyContent: "center",
    marginTop: "auto",
    paddingVertical: 20,
    borderTopWidth: 1,
    borderTopColor: "rgba(197, 163, 94, 0.1)",
  },
  coordsText: {
    color: "#e2d1a8",
    fontSize: 14,
    marginLeft: 8,
    opacity: 0.6,
  },
});
