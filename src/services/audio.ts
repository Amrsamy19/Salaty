import { Audio } from 'expo-av';

class AudioService {
  private sound: Audio.Sound | null = null;
  private isPlaying: boolean = false;
  private listeners: ((isPlaying: boolean) => void)[] = [];

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

  public subscribe(listener: (isPlaying: boolean) => void) {
    this.listeners.push(listener);
    return () => {
      this.listeners = this.listeners.filter(l => l !== listener);
    };
  }

  private notifyListeners() {
    this.listeners.forEach(l => l(this.isPlaying));
  }

  public async playAzan() {
    try {
      if (this.sound) {
        await this.stopAzan();
      }

      console.log('Loading azan audio...');
      const azanFiles = [
        require('../../assets/azan/abdelbaset.mp3'),
        require('../../assets/azan/egypt.mp3'),
        require('../../assets/azan/makah.mp3'),
        require('../../assets/azan/mohamedrefaat.mp3'),
      ];
      const selectedAzan = azanFiles[Math.floor(Math.random() * azanFiles.length)];

      const { sound } = await Audio.Sound.createAsync(
        selectedAzan,
        { shouldPlay: true, isLooping: false }
      );
      
      this.sound = sound;
      this.isPlaying = true;
      this.notifyListeners();

      sound.setOnPlaybackStatusUpdate((status) => {
        if (status.isLoaded && status.didJustFinish) {
          this.isPlaying = false;
          this.notifyListeners();
          this.sound?.unloadAsync();
          this.sound = null;
        }
      });
    } catch (error) {
      console.error('Error playing azan:', error);
      this.isPlaying = false;
      this.notifyListeners();
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
      this.notifyListeners();
    }
  }
  
  public getIsPlaying() {
    return this.isPlaying;
  }
}

export const audioService = new AudioService();
