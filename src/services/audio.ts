import { Audio } from 'expo-av';

class AudioService {
  private sound: Audio.Sound | null = null;
  private isPlaying: boolean = false;
  private isPreview: boolean = false;
  private listeners: ((isPlaying: boolean, isPreview: boolean) => void)[] = [];

  constructor() {
    this.configureAudio();
  }

  private async configureAudio() {
    await Audio.setAudioModeAsync({
      playsInSilentModeIOS: true,
      staysActiveInBackground: true,
      shouldDuckAndroid: true,
      playThroughEarpieceAndroid: false,
    });
  }

  public subscribe(listener: (isPlaying: boolean, isPreview: boolean) => void) {
    this.listeners.push(listener);
    return () => {
      this.listeners = this.listeners.filter(l => l !== listener);
    };
  }

  private notifyListeners() {
    this.listeners.forEach(l => l(this.isPlaying, this.isPreview));
  }

  private getAzanFile(azanSound: string) {
    const azanFiles: Record<string, any> = {
      abdelbaset: require('../../assets/azan/abdelbaset.mp3'),
      egypt: require('../../assets/azan/egypt.mp3'),
      makah: require('../../assets/azan/makah.mp3'),
      mohamedrefaat: require('../../assets/azan/mohamedrefaat.mp3'),
    };
    return azanFiles[azanSound] || azanFiles.egypt;
  }

  public async playAzan() {
    try {
      if (this.sound) {
        await this.stopAzan();
      }

      const { settingsService } = require('./settings');
      const settings = settingsService.getSettings();
      const selectedAzan = this.getAzanFile(settings.azanSound);

      const { sound } = await Audio.Sound.createAsync(
        selectedAzan,
        { shouldPlay: true, isLooping: false }
      );
      
      this.sound = sound;
      this.isPlaying = true;
      this.isPreview = false;
      this.notifyListeners();

      sound.setOnPlaybackStatusUpdate((status) => {
        if (status.isLoaded && status.didJustFinish) {
          this.cleanup();
        }
      });
    } catch (error) {
      console.error('Error playing azan:', error);
      this.isPlaying = false;
      this.isPreview = false;
      this.notifyListeners();
    }
  }

  public async playPreview(soundName: string) {
    try {
      if (this.sound) {
        await this.stopAzan();
      }

      const selectedAzan = this.getAzanFile(soundName);
      const { sound } = await Audio.Sound.createAsync(
        selectedAzan,
        { shouldPlay: true, isLooping: false }
      );

      this.sound = sound;
      this.isPlaying = true;
      this.isPreview = true;
      this.notifyListeners();

      sound.setOnPlaybackStatusUpdate((status) => {
        if (status.isLoaded && status.didJustFinish) {
          this.cleanup();
        }
      });
    } catch (error) {
      console.error('Error playing preview:', error);
      this.isPlaying = false;
      this.isPreview = false;
      this.notifyListeners();
    }
  }

  private async cleanup() {
    this.isPlaying = false;
    this.isPreview = false;
    this.notifyListeners();
    if (this.sound) {
      try {
        await this.sound.unloadAsync();
      } catch (e) {}
      this.sound = null;
    }
  }

  public async stopAzan() {
    try {
      if (this.sound) {
        await this.sound.stopAsync();
        await this.sound.unloadAsync();
        this.sound = null;
      }
    } catch (error) {
      console.error('Error stopping azan:', error);
    } finally {
      this.isPlaying = false;
      this.isPreview = false;
      this.notifyListeners();
    }
  }
  
  public getIsPlaying() {
    return this.isPlaying;
  }

  public getIsPreview() {
    return this.isPreview;
  }
}

export const audioService = new AudioService();
