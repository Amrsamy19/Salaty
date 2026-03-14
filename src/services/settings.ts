import AsyncStorage from '@react-native-async-storage/async-storage';

export type Language = 'ar' | 'en';
export type AzanSound = 'abdelbaset' | 'egypt' | 'makah' | 'mohamedrefaat';

interface AppSettings {
  language: Language;
  fontSize: number;
  azanSound: AzanSound;
  enabledAzans: Record<string, boolean>;
}

const DEFAULT_SETTINGS: AppSettings = {
  language: 'ar',
  fontSize: 16,
  azanSound: 'egypt',
  enabledAzans: {
    fajr: true,
    dhuhr: true,
    asr: true,
    maghrib: true,
    isha: true,
  },
};

class SettingsService {
  private settings: AppSettings = DEFAULT_SETTINGS;
  private listeners: ((settings: AppSettings) => void)[] = [];

  constructor() {
    this.loadSettings();
  }

  private async loadSettings() {
    try {
      const stored = await AsyncStorage.getItem('app_settings');
      if (stored) {
        this.settings = { ...DEFAULT_SETTINGS, ...JSON.parse(stored) };
      }
      this.notifyListeners();
    } catch (e) {
      console.error('Failed to load settings', e);
    }
  }

  public async updateSettings(newSettings: Partial<AppSettings>) {
    this.settings = { ...this.settings, ...newSettings };
    this.notifyListeners();
    try {
      await AsyncStorage.setItem('app_settings', JSON.stringify(this.settings));
    } catch (e) {
      console.error('Failed to save settings', e);
    }
  }

  public getSettings() {
    return this.settings;
  }

  public subscribe(listener: (settings: AppSettings) => void) {
    this.listeners.push(listener);
    listener(this.settings);
    return () => {
      this.listeners = this.listeners.filter(l => l !== listener);
    };
  }

  private notifyListeners() {
    this.listeners.forEach(l => l(this.settings));
  }
}

export const settingsService = new SettingsService();
