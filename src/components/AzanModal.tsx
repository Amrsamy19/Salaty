import React from 'react';
import { View, Text, StyleSheet, Modal, TouchableOpacity, Dimensions } from 'react-native';
import { Volume2, VolumeX } from 'lucide-react-native';

interface AzanModalProps {
  visible: boolean;
  onStop: () => void;
}

const { width, height } = Dimensions.get('window');

export const AzanModal: React.FC<AzanModalProps> = ({ visible, onStop }) => {
  return (
    <Modal visible={visible} animationType="slide" transparent={true}>
      <View style={styles.overlay}>
        <View style={styles.container}>
          <Volume2 size={64} color="#FBBF24" style={styles.icon} />
          
          <Text style={styles.title}>Time for Prayer</Text>
          <Text style={styles.subtitle}>The Azan is currently playing</Text>
          
          <TouchableOpacity style={styles.stopButton} onPress={onStop}>
            <VolumeX size={24} color="#064E3B" style={styles.buttonIcon} />
            <Text style={styles.buttonText}>Stop Notification</Text>
          </TouchableOpacity>
        </View>
      </View>
    </Modal>
  );
};

const styles = StyleSheet.create({
  overlay: {
    flex: 1,
    backgroundColor: 'rgba(6, 16, 38, 0.85)', // Deep blue with opacity
    justifyContent: 'center',
    alignItems: 'center',
  },
  container: {
    width: width * 0.85,
    backgroundColor: '#0a1a3a', // Dark blue
    borderRadius: 24,
    padding: 32,
    alignItems: 'center',
    borderWidth: 1,
    borderColor: '#c5a35e', // Gold border
    shadowColor: '#000',
    shadowOffset: { width: 0, height: 10 },
    shadowOpacity: 0.3,
    shadowRadius: 20,
    elevation: 10,
  },
  icon: {
    marginBottom: 24,
  },
  title: {
    fontSize: 28,
    fontWeight: '700',
    color: '#c5a35e', // Gold
    marginBottom: 8,
    textAlign: 'center',
  },
  subtitle: {
    fontSize: 16,
    color: '#e2d1a8', // Light gold
    marginBottom: 40,
    textAlign: 'center',
  },
  stopButton: {
    flexDirection: 'row',
    alignItems: 'center',
    backgroundColor: '#c5a35e', // Gold button
    paddingVertical: 16,
    paddingHorizontal: 24,
    borderRadius: 16,
    width: '100%',
    justifyContent: 'center',
  },
  buttonIcon: {
    marginRight: 12,
  },
  buttonText: {
    color: '#061026', // Deep blue text on gold button
    fontSize: 18,
    fontWeight: 'bold',
  },
});
