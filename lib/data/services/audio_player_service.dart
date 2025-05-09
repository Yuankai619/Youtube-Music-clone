import 'package:just_audio/just_audio.dart';
import 'package:flutter/foundation.dart';

class AudioPlayerService {
  final AudioPlayer _audioPlayer = AudioPlayer();

  Stream<bool> get playingStateStream => _audioPlayer.playingStream;
  Stream<Duration> get positionStream => _audioPlayer.positionStream;
  Stream<Duration?> get durationStream => _audioPlayer.durationStream;
  Stream<PlayerState> get playerStateStream => _audioPlayer.playerStateStream;

  Future<void> playUrl(String url) async {
    try {
      await _audioPlayer.setUrl(url);
      _audioPlayer.play();
    } catch (e) {
      debugPrint("Error loading audio source: $e");
      // Handle error (e.g., show a message to the user)
    }
  }

  Future<void> play() async {
    await _audioPlayer.play();
  }

  Future<void> pause() async {
    await _audioPlayer.pause();
  }

  Future<void> seek(Duration position) async {
    await _audioPlayer.seek(position);
  }

  Future<void> setVolume(double volume) async {
    await _audioPlayer.setVolume(volume.clamp(0.0, 1.0));
  }

  Future<void> setLoopMode(LoopMode mode) async {
    await _audioPlayer.setLoopMode(
      mode,
    ); // LoopMode.off, LoopMode.one, LoopMode.all
  }

  Future<void> setShuffleModeEnabled(bool enabled) async {
    await _audioPlayer.setShuffleModeEnabled(enabled);
  }

  void dispose() {
    _audioPlayer.dispose();
  }
}
