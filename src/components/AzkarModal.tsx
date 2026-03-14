import React, { useState, useEffect } from 'react';
import {
  View,
  Text,
  StyleSheet,
  Modal,
  TouchableOpacity,
  Dimensions,
  ScrollView,
  Share,
} from 'react-native';
import { X, Check, RotateCcw, Share2, Sun, Moon } from 'lucide-react-native';
import { morningAzkar, eveningAzkar, AzkarItem } from '../utils/azkar';
import { translations } from '../utils/translations';
import { settingsService } from '../services/settings';

interface AzkarModalProps {
  visible: boolean;
  onClose: () => void;
  type: 'morning' | 'evening';
  inline?: boolean;
  onTypeChange?: (type: 'morning' | 'evening') => void;
}

const { width, height } = Dimensions.get('window');

export const AzkarModal: React.FC<AzkarModalProps> = ({ visible, onClose, type, inline, onTypeChange }) => {
  const currentSettings = settingsService.getSettings();
  const t = translations[currentSettings.language];
  const isRTL = currentSettings.language === 'ar';
  
  const initialData = type === 'morning' ? morningAzkar : eveningAzkar;
  const [items, setItems] = useState<AzkarItem[]>([]);

  useEffect(() => {
    if (visible || inline) {
      setItems(initialData.map(item => ({ ...item })));
    }
  }, [visible, inline, type]);

  const handlePress = (id: number) => {
    setItems(prev => prev.map(item => {
      if (item.id === id && item.count > 0) {
        return { ...item, count: item.count - 1 };
      }
      return item;
    }));
  };

  const handleReset = () => {
    setItems(initialData.map(item => ({ ...item })));
  };

  const handleShare = async (text: string) => {
    try {
      await Share.share({ message: text });
    } catch (e) {
      console.error(e);
    }
  };

  const content = (
    <View style={[styles.container, inline && styles.inlineContainer]}>
      <View style={styles.header}>
        <View style={[styles.titleGroup, isRTL && { flexDirection: 'row-reverse' }]}>
            {type === 'morning' ? <Sun size={24} color="#FBBF24" /> : <Moon size={24} color="#e2d1a8" />}
            <Text style={[styles.title, isRTL ? { marginRight: 10 } : { marginLeft: 10 }]}>
                {type === 'morning' ? t.morningAzkar : t.eveningAzkar}
            </Text>
        </View>
        <View style={{ flexDirection: 'row', alignItems: 'center' }}>
            {inline && (
              <TouchableOpacity 
                onPress={() => onTypeChange?.(type === 'morning' ? 'evening' : 'morning')} 
                style={[styles.headerBtn, { marginRight: 15 }]}
              >
                {type === 'morning' ? <Moon size={20} color="#e2d1a8" /> : <Sun size={20} color="#FBBF24" />}
              </TouchableOpacity>
            )}
            <TouchableOpacity onPress={handleReset} style={styles.headerBtn}>
                <RotateCcw size={20} color="#c5a35e" />
            </TouchableOpacity>
            {!inline && (
              <TouchableOpacity onPress={onClose} style={[styles.headerBtn, { marginLeft: 15 }]}>
                  <X size={24} color="#c5a35e" />
              </TouchableOpacity>
            )}
        </View>
      </View>

      <ScrollView showsVerticalScrollIndicator={false} contentContainerStyle={styles.scrollContent}>
        {items.map((item) => {
          const isFinished = item.count === 0;
          return (
            <TouchableOpacity 
              key={item.id} 
              style={[styles.azkarCard, isFinished && styles.azkarCardFinished]}
              onPress={() => handlePress(item.id)}
              activeOpacity={0.7}
            >
              <Text style={[styles.azkarText, { fontSize: currentSettings.fontSize + 2 }, isFinished && styles.azkarTextFinished]}>
                {item.text}
              </Text>
              <View style={[styles.cardFooter, isRTL && { flexDirection: 'row-reverse' }]}>
                <View style={styles.countBadge}>
                  {isFinished ? (
                    <Check size={16} color="#061026" />
                  ) : (
                    <Text style={styles.countValue}>{item.count}</Text>
                  )}
                </View>
                <TouchableOpacity onPress={() => handleShare(item.text)} style={styles.shareBtn}>
                    <Share2 size={16} color="#c5a35e" />
                </TouchableOpacity>
              </View>
            </TouchableOpacity>
          );
        })}
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
    height: '100%',
    backgroundColor: 'transparent',
    borderWidth: 0,
    borderTopLeftRadius: 0,
    borderTopRightRadius: 0,
  },
  overlay: {
    flex: 1,
    backgroundColor: 'rgba(6, 16, 38, 0.9)',
    justifyContent: 'flex-end',
  },
  container: {
    height: height * 0.85,
    backgroundColor: '#0a1a3a',
    borderTopLeftRadius: 32,
    borderTopRightRadius: 32,
    padding: 20,
    borderWidth: 1,
    borderColor: 'rgba(197, 163, 94, 0.3)',
  },
  header: {
    flexDirection: 'row',
    justifyContent: 'space-between',
    alignItems: 'center',
    marginBottom: 20,
    paddingHorizontal: 5,
  },
  titleGroup: {
    flexDirection: 'row',
    alignItems: 'center',
  },
  title: {
    fontSize: 22,
    fontWeight: 'bold',
    color: '#c5a35e',
  },
  headerBtn: {
    padding: 5,
  },
  scrollContent: {
    paddingBottom: 20,
  },
  azkarCard: {
    backgroundColor: 'rgba(30, 41, 59, 0.4)',
    borderRadius: 20,
    padding: 20,
    marginBottom: 16,
    borderWidth: 1,
    borderColor: 'rgba(197, 163, 94, 0.15)',
  },
  azkarCardFinished: {
    opacity: 0.5,
    borderColor: 'rgba(197, 163, 94, 0.05)',
  },
  azkarText: {
    color: '#e2d1a8',
    lineHeight: 32,
    textAlign: 'center',
    marginBottom: 15,
  },
  azkarTextFinished: {
    textDecorationLine: 'none',
  },
  cardFooter: {
    flexDirection: 'row',
    justifyContent: 'center',
    alignItems: 'center',
  },
  countBadge: {
    width: 44,
    height: 44,
    borderRadius: 22,
    backgroundColor: '#c5a35e',
    justifyContent: 'center',
    alignItems: 'center',
    marginHorizontal: 20,
    elevation: 4,
    shadowColor: '#000',
    shadowOffset: { width: 0, height: 2 },
    shadowOpacity: 0.25,
    shadowRadius: 3.84,
  },
  countValue: {
    color: '#061026',
    fontSize: 20,
    fontWeight: 'bold',
  },
  shareBtn: {
    position: 'absolute',
    right: 0,
    padding: 10,
  },
});
