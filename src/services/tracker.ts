import AsyncStorage from '@react-native-async-storage/async-storage';

export interface PrayerLogs {
  [date: string]: {
    [prayer: string]: boolean;
  };
}

class TrackerService {
  private logs: PrayerLogs = {};
  private listeners: ((logs: PrayerLogs) => void)[] = [];

  constructor() {
    this.loadLogs();
  }

  private async loadLogs() {
    try {
      const stored = await AsyncStorage.getItem('prayer_tracker_logs');
      if (stored) {
        this.logs = JSON.parse(stored);
      }
      this.notifyListeners();
    } catch (e) {
      console.error('Failed to load prayer logs', e);
    }
  }

  public async togglePrayer(dateStr: string, prayer: string) {
    if (!this.logs[dateStr]) {
      this.logs[dateStr] = {};
    }
    this.logs[dateStr][prayer] = !this.logs[dateStr][prayer];
    
    this.notifyListeners();
    try {
      await AsyncStorage.setItem('prayer_tracker_logs', JSON.stringify(this.logs));
    } catch (e) {
      console.error('Failed to save prayer logs', e);
    }
  }

  public getLogs() {
    return this.logs;
  }

  public getPrayerStatus(dateStr: string, prayer: string): boolean {
    return this.logs[dateStr]?.[prayer] || false;
  }

  public subscribe(listener: (logs: PrayerLogs) => void) {
    this.listeners.push(listener);
    listener(this.logs);
    return () => {
      this.listeners = this.listeners.filter(l => l !== listener);
    };
  }

  private notifyListeners() {
    this.listeners.forEach(l => l({ ...this.logs }));
  }
}

export const trackerService = new TrackerService();
