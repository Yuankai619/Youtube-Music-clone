import 'dart:math';
import 'package:flutter/material.dart';
import 'package:just_audio/just_audio.dart';
import 'package:just_audio_background/just_audio_background.dart';
import 'package:youtube_explode_dart/youtube_explode_dart.dart';
import '../models/song_model.dart';
import '../data/youtube_service.dart';
import '../data/lyrics_service.dart';

enum RepeatMode { off, all, one }

enum LyricsState { hidden, fullscreen }

class PlayerViewModel extends ChangeNotifier {
  final YouTubeService _youtubeService = YouTubeService();
  final AudioPlayer _audioPlayer = AudioPlayer();
  final YoutubeExplode _yt = YoutubeExplode();
  final LyricsService _lyricsService = LyricsService();

  List<Song> _songs = [];
  List<Song> _searchResults = [];
  Song? _currentSong;
  bool _isPlaying = false;
  bool _isLoading = false;
  bool _isBuffering = false;
  RepeatMode _repeatMode = RepeatMode.off;
  bool _isShuffleEnabled = false;
  LyricsState _lyricsState = LyricsState.hidden;
  String _searchQuery = '';
  String _errorMessage = '';

  List<LyricLine> _lyrics = [];
  bool _isLoadingLyrics = false;
  bool _lyricsNotFound = false;
  int _currentLyricIndex = -1;

  // Getters
  List<Song> get songs => _songs;
  List<Song> get searchResults => _searchResults;
  Song? get currentSong => _currentSong;
  bool get isPlaying => _isPlaying;
  bool get isLoading => _isLoading;
  bool get isBuffering => _isBuffering;
  RepeatMode get repeatMode => _repeatMode;
  bool get isShuffleEnabled => _isShuffleEnabled;
  LyricsState get lyricsState => _lyricsState;
  AudioPlayer get audioPlayer => _audioPlayer;
  String get searchQuery => _searchQuery;
  String get errorMessage => _errorMessage;

  // Additional getters for lyrics
  List<LyricLine> get lyrics => _lyrics;
  bool get isLoadingLyrics => _isLoadingLyrics;
  bool get lyricsNotFound => _lyricsNotFound;
  int get currentLyricIndex => _currentLyricIndex;

  PlayerViewModel() {
    _initAudioPlayer();
  }

  void _initAudioPlayer() {
    _audioPlayer.playerStateStream.listen((playerState) {
      _isPlaying = playerState.playing;
      _isBuffering =
          playerState.processingState == ProcessingState.buffering ||
          playerState.processingState == ProcessingState.loading;

      if (playerState.processingState == ProcessingState.completed) {
        playNextSong();
      }

      notifyListeners();
    });

    _audioPlayer.positionStream.listen((position) {
      _updateCurrentLyricIndex(position);
      notifyListeners();
    });

    _audioPlayer.playbackEventStream.listen(
      (_) {},
      onError: (Object e, StackTrace st) {
        print('Audio player error: $e');
        _errorMessage = 'Playback error: ${e.toString()}';
        notifyListeners();
      },
    );
  }

  // Update the current lyric index based on playback position
  void _updateCurrentLyricIndex(Duration position) {
    if (_lyrics.isEmpty) return;

    for (int i = 0; i < _lyrics.length; i++) {
      final lyric = _lyrics[i];
      final nextLyricTimestamp =
          i < _lyrics.length - 1
              ? _lyrics[i + 1].timestamp
              : Duration(
                milliseconds: _audioPlayer.duration?.inMilliseconds ?? 0,
              );

      if (position >= lyric.timestamp && position < nextLyricTimestamp) {
        if (_currentLyricIndex != i) {
          _currentLyricIndex = i;
          notifyListeners();
        }
        return;
      }
    }

    // If we're before the first lyric
    if (position < _lyrics.first.timestamp && _currentLyricIndex != -1) {
      _currentLyricIndex = -1;
      notifyListeners();
    }
  }

  Future<void> searchSongs(String query) async {
    if (query.isEmpty) return;

    _searchQuery = query;
    _isLoading = true;
    _searchResults = [];
    notifyListeners();

    try {
      final results = await _youtubeService.searchSongs(query);
      _searchResults = results;
      _isLoading = false;
      notifyListeners();
    } catch (e) {
      print('Search error: $e');
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> fetchLyrics() async {
    if (_currentSong == null) return;

    _isLoadingLyrics = true;
    _lyricsNotFound = false;
    _lyrics = [];
    _currentLyricIndex = -1;
    notifyListeners();

    try {
      final fetchedLyrics = await _lyricsService.fetchLyrics(_currentSong!);
      _lyrics = fetchedLyrics;
      _lyricsNotFound = fetchedLyrics.isEmpty;

      // Update the current lyric index based on current position
      _updateCurrentLyricIndex(_audioPlayer.position);
    } catch (e) {
      print('Error fetching lyrics: $e');
      _lyricsNotFound = true;
    } finally {
      _isLoadingLyrics = false;
      notifyListeners();
    }
  }

  Future<void> playSong(Song song) async {
    _isLoading = true;
    _errorMessage = '';
    _currentSong = song;

    // Clear search results when playing a song
    _clearSearchResults();

    notifyListeners();

    try {
      // For YouTube videos
      if (song.videoId.isNotEmpty) {
        print("Playing YouTube video ID: ${song.videoId}");

        try {
          // Get the video manifest
          final manifest = await _yt.videos.streamsClient.getManifest(
            song.videoId,
          );

          // Try to get audio-only streams
          final audioOnlyStreams = manifest.audioOnly;

          if (audioOnlyStreams.isNotEmpty) {
            // Sort by bitrate and filter for more compatible formats (mp4a)
            final compatibleStreams =
                audioOnlyStreams
                    .where((stream) => stream.codec.toString().contains('mp4a'))
                    .toList();

            final audioStream =
                compatibleStreams.isNotEmpty
                    ? compatibleStreams
                        .first // Use mp4a if available
                    : audioOnlyStreams
                        .withHighestBitrate(); // Fallback to highest bitrate

            print(
              "Selected audio format: ${audioStream.codec}, bitrate: ${audioStream.bitrate}, container: ${audioStream.container}",
            );

            final audioUrl = audioStream.url.toString();

            // Create appropriate MediaItem for the background audio service
            final mediaItem = MediaItem(
              id: song.id,
              title: song.title,
              artist: song.artist,
              album: song.album,
              artUri: Uri.parse(song.albumArt),
              duration: song.duration,
              displayTitle: song.title,
              displaySubtitle: song.artist,
              displayDescription: song.album,
            );

            // Try to load and play the audio
            await _audioPlayer.stop(); // Stop any current playback

            print("Setting audio source URL: $audioUrl");
            await _audioPlayer.setAudioSource(
              AudioSource.uri(Uri.parse(audioUrl), tag: mediaItem),
              preload: true,
            );

            print("Playing audio");
            await _audioPlayer.play();
            _isPlaying = true;

            // After successfully setting up playback, fetch lyrics
            fetchLyrics();
          } else {
            throw Exception("No audio stream available for this video");
          }
        } catch (e) {
          print('Error playing YouTube video: $e');
          _errorMessage = 'Failed to play video: ${e.toString()}';
          _isPlaying = false;
        }
      }
      // For direct audio URLs (if any)
      else if (song.previewUrl.isNotEmpty) {
        await _audioPlayer.setAudioSource(
          AudioSource.uri(
            Uri.parse(song.previewUrl),
            tag: MediaItem(
              id: song.id,
              title: song.title,
              artist: song.artist,
              album: song.album,
              artUri: Uri.parse(song.albumArt),
            ),
          ),
        );

        _audioPlayer.play();
        _isPlaying = true;
      }
    } catch (e) {
      print("Error playing song: $e");
      _errorMessage = 'Playback error: ${e.toString()}';
      _isPlaying = false;
    } finally {
      _isLoading = false; // Ensure loading state is reset
      _isBuffering = false; // Reset buffering state as well
      notifyListeners();
    }
  }

  void _clearSearchResults() {
    _searchResults = [];
  }

  Future<void> addToPlaylist(Song song) async {
    if (!_songs.any((s) => s.id == song.id)) {
      _songs.add(song);
      notifyListeners();
    }

    if (_songs.length == 1 && _currentSong == null) {
      await playSong(song);
    }
  }

  void removeFromPlaylist(Song song) {
    _songs.removeWhere((s) => s.id == song.id);

    // If we removed the currently playing song, play the next one if available
    if (_currentSong != null && _currentSong!.id == song.id) {
      if (_songs.isNotEmpty) {
        playNextSong();
      } else {
        _currentSong = null;
        _audioPlayer.stop();
        _isPlaying = false;
      }
    }

    notifyListeners();
  }

  void clearPlaylist() {
    _songs = [];
    _currentSong = null;
    _audioPlayer.stop();
    _isPlaying = false;
    notifyListeners();
  }

  // Improved next song logic
  Future<void> playNextSong() async {
    if (_songs.isEmpty || _currentSong == null) return;

    int currentIndex = _songs.indexWhere((song) => song.id == _currentSong!.id);

    if (currentIndex == -1) return;

    int nextIndex;

    // Handle repeat modes properly
    if (_repeatMode == RepeatMode.one) {
      // For repeat one, restart the current song
      nextIndex = currentIndex;
      await _audioPlayer.seek(Duration.zero);
      await _audioPlayer.play();
      return;
    } else if (_isShuffleEnabled) {
      // For shuffle mode, pick a random song that's not the current one
      if (_songs.length > 1) {
        int randomIndex;
        do {
          randomIndex = Random().nextInt(_songs.length);
        } while (randomIndex == currentIndex);
        nextIndex = randomIndex;
      } else {
        nextIndex = 0;
      }
    } else {
      // Normal next song logic
      nextIndex = (currentIndex + 1) % _songs.length;

      // If repeat is off and we're at the end, stop
      if (nextIndex == 0 &&
          _repeatMode == RepeatMode.off &&
          currentIndex == _songs.length - 1) {
        _audioPlayer.stop();
        _isPlaying = false;
        notifyListeners();
        return;
      }
    }

    await playSong(_songs[nextIndex]);
  }

  // Improved play random song logic
  void playRandomSong() {
    if (_songs.isEmpty) return;

    final randomIndex = Random().nextInt(_songs.length);
    playSong(_songs[randomIndex]);
  }

  // Improve the togglePlayPause method to handle loading state
  void togglePlayPause() {
    if (_currentSong == null) return;

    // Don't allow toggle if still loading
    if (_isLoading || _isBuffering) return;

    if (_isPlaying) {
      _audioPlayer.pause();
    } else {
      _audioPlayer.play();
    }

    _isPlaying = !_isPlaying;
    notifyListeners();
  }

  void setVolume(double volume) {
    _audioPlayer.setVolume(volume);
    notifyListeners();
  }

  void seekTo(Duration position) {
    _audioPlayer.seek(position);
    notifyListeners();
  }

  void toggleShuffleMode() {
    _isShuffleEnabled = !_isShuffleEnabled;
    notifyListeners();
  }

  void cycleRepeatMode() {
    switch (_repeatMode) {
      case RepeatMode.off:
        _repeatMode = RepeatMode.all;
        break;
      case RepeatMode.all:
        _repeatMode = RepeatMode.one;
        break;
      case RepeatMode.one:
        _repeatMode = RepeatMode.off;
        break;
    }
    notifyListeners();
  }

  void toggleLyricsState() {
    if (_lyricsState == LyricsState.hidden) {
      _lyricsState = LyricsState.fullscreen;
      // Fetch lyrics if not already loaded
      if (_lyrics.isEmpty && !_isLoadingLyrics && !_lyricsNotFound) {
        fetchLyrics();
      }
    } else {
      _lyricsState = LyricsState.hidden;
    }
    notifyListeners();
  }

  // Public method to clear search results
  void clearSearchResults() {
    _searchResults = [];
    notifyListeners();
  }

  // Add this missing method for previous song functionality
  Future<void> playPreviousSong() async {
    if (_songs.isEmpty || _currentSong == null) return;

    int currentIndex = _songs.indexWhere((song) => song.id == _currentSong!.id);

    if (currentIndex == -1) return;

    // If current position is more than 3 seconds, restart current song
    if (_audioPlayer.position.inSeconds > 3) {
      await _audioPlayer.seek(Duration.zero);
      return;
    }

    int prevIndex;

    if (_repeatMode == RepeatMode.one) {
      prevIndex = currentIndex;
    } else if (_isShuffleEnabled) {
      // In shuffle mode, pick a random song
      if (_songs.length > 1) {
        int randomIndex;
        do {
          randomIndex = Random().nextInt(_songs.length);
        } while (randomIndex == currentIndex);
        prevIndex = randomIndex;
      } else {
        prevIndex = 0;
      }
    } else {
      // Normal previous logic
      prevIndex =
          (currentIndex - 1) < 0 ? _songs.length - 1 : (currentIndex - 1);
    }

    await playSong(_songs[prevIndex]);
  }

  // Add this missing method for adding all songs to playlist
  void addAllToPlaylist(List<Song> newSongs) {
    for (var song in newSongs) {
      if (!_songs.any((s) => s.id == song.id)) {
        _songs.add(song);
      }
    }

    if (_songs.isNotEmpty && _currentSong == null) {
      playSong(_songs.first);
    }

    notifyListeners();
  }

  @override
  void dispose() {
    _audioPlayer.dispose();
    _yt.close();
    super.dispose();
  }
}
