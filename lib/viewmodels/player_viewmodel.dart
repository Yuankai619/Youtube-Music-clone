import 'dart:async';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:audio_service/audio_service.dart';
import 'package:youtube_explode_dart/youtube_explode_dart.dart';
import '../models/song_model.dart';
import '../data/youtube_service.dart';
import '../main.dart';
import '../services/audio_handler.dart';

enum RepeatMode { off, all, one }

enum LyricsState { hidden, fullscreen }

class PlayerViewModel extends ChangeNotifier {
  final YouTubeService _youtubeService = YouTubeService();
  final YoutubeExplode _yt = YoutubeExplode();

  List<Song> _songs = [];
  List<Song> _searchResults = [];
  Song? _currentSong;
  bool _isPlaying = false;
  bool _isLoading = false;
  bool _isBuffering = false;
  RepeatMode _repeatMode = RepeatMode.off;
  bool _isShuffleEnabled = false;
  String _searchQuery = '';
  String _errorMessage = '';

  // Stream subscriptions
  late StreamSubscription _playbackStateSubscription;
  late StreamSubscription _mediaItemSubscription;
  late StreamSubscription _positionSubscription;

  // Getters
  List<Song> get songs => _songs;
  List<Song> get searchResults => _searchResults;
  Song? get currentSong => _currentSong;
  bool get isPlaying => _isPlaying;
  bool get isLoading => _isLoading;
  bool get isBuffering => _isBuffering;
  RepeatMode get repeatMode => _repeatMode;
  bool get isShuffleEnabled => _isShuffleEnabled;
  // For compatibility with existing code - return the audio handler
  MyAudioHandler get audioPlayer => audioHandler as MyAudioHandler;
  String get searchQuery => _searchQuery;
  String get errorMessage => _errorMessage;

  PlayerViewModel() {
    _initAudioHandler();
  }

  void _initAudioHandler() {
    _playbackStateSubscription = audioHandler.playbackState.listen((
      playbackState,
    ) {
      final wasPlaying = _isPlaying;
      final wasBuffering = _isBuffering;
      final wasLoading = _isLoading;

      _isPlaying = playbackState.playing;
      _isBuffering =
          playbackState.processingState == AudioProcessingState.buffering;
      _isLoading =
          playbackState.processingState == AudioProcessingState.loading;

      if (playbackState.processingState == AudioProcessingState.completed) {
        playNextSong();
      }

      // Notify if any state changed
      if (wasPlaying != _isPlaying ||
          wasBuffering != _isBuffering ||
          wasLoading != _isLoading) {
        notifyListeners();
      }
    });

    _mediaItemSubscription = audioHandler.mediaItem.listen((mediaItem) {
      if (mediaItem != null) {
        // Find the corresponding song in our playlist
        final song = _songs.firstWhere(
          (s) => s.id == mediaItem.id,
          orElse:
              () => Song(
                id: mediaItem.id,
                title: mediaItem.title,
                artist: mediaItem.artist ?? 'Unknown Artist',
                album: mediaItem.album ?? 'Unknown Album',
                albumArt: mediaItem.artUri?.toString() ?? '',
                previewUrl: '',
                videoId: mediaItem.extras?['videoId'] ?? '',
                duration: mediaItem.duration ?? Duration.zero,
              ),
        );

        if (_currentSong?.id != song.id) {
          _currentSong = song;
          notifyListeners();
        }
      }
    });

    // Listen to position changes from AudioHandler
    final handler = audioHandler as MyAudioHandler;
    _positionSubscription = handler.positionStream.listen((position) {
      // Only notify listeners to update the UI with new position
      notifyListeners();
    });
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

  Future<void> playSong(Song song) async {
    _isLoading = true;
    _errorMessage = '';
    _currentSong = song;

    // Add song to playlist if it's not already there
    if (!_songs.any((s) => s.id == song.id)) {
      _songs.add(song);
    }

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
                    ? compatibleStreams.first
                    : audioOnlyStreams.withHighestBitrate();

            print(
              "Selected audio format: ${audioStream.codec}, bitrate: ${audioStream.bitrate}, container: ${audioStream.container}",
            );

            final audioUrl = audioStream.url.toString();
            print("Audio URL: $audioUrl");

            // Create MediaItem for AudioService
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
              extras: {
                'url': audioUrl,
                'videoId': song.videoId,
                'source': 'youtube',
              },
            );

            print(
              "Created MediaItem: ${mediaItem.title} by ${mediaItem.artist}",
            );

            // Stop current playback and add new song
            await audioHandler.stop();

            // Add the new song to queue
            await audioHandler.addQueueItem(mediaItem);

            // Start playback
            await audioHandler.play();

            print("Successfully started playback for: ${song.title}");
          } else {
            throw Exception("No audio stream available for this video");
          }
        } catch (e) {
          print('Error playing YouTube video: $e');
          _errorMessage = 'Failed to play video: ${e.toString()}';
          _isPlaying = false;
          _isLoading = false;
          _isBuffering = false;
          notifyListeners();
        }
      }
      // For direct audio URLs (if any)
      else if (song.previewUrl.isNotEmpty) {
        final mediaItem = MediaItem(
          id: song.id,
          title: song.title,
          artist: song.artist,
          album: song.album,
          artUri: Uri.parse(song.albumArt),
          duration: song.duration,
          extras: {'url': song.previewUrl},
        );

        await audioHandler.stop();
        await audioHandler.addQueueItem(mediaItem);
        await audioHandler.play();
      }
    } catch (e) {
      print("Error playing song: $e");
      _errorMessage = 'Playback error: ${e.toString()}';
      _isPlaying = false;
      _isLoading = false;
      _isBuffering = false;
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
        audioHandler.stop();
        _isPlaying = false;
      }
    }

    notifyListeners();
  }

  void clearPlaylist() {
    _songs = [];
    _currentSong = null;
    audioHandler.stop();
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
      await audioHandler.seek(Duration.zero);
      await audioHandler.play();
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
        audioHandler.stop();
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
  Future<void> togglePlayPause() async {
    if (_currentSong == null) return;

    if (_isLoading) {
      print('Cannot toggle play/pause while loading');
      return;
    }

    try {
      if (_isPlaying) {
        print('Pausing audio');
        await audioHandler.pause();
      } else {
        print('Resuming audio');
        await audioHandler.play();
      }
    } catch (e) {
      print('Error toggling play/pause: $e');
      _errorMessage = 'Playbook control error: ${e.toString()}';
      notifyListeners();
    }
  }

  void setVolume(double volume) {
    final handler = audioHandler as MyAudioHandler;
    handler.setVolume(volume);
    notifyListeners();
  }

  void seekTo(Duration position) {
    audioHandler.seek(position);
    notifyListeners();
  }

  void toggleShuffleMode() {
    _isShuffleEnabled = !_isShuffleEnabled;
    audioHandler.setShuffleMode(
      _isShuffleEnabled
          ? AudioServiceShuffleMode.all
          : AudioServiceShuffleMode.none,
    );
    notifyListeners();
  }

  void cycleRepeatMode() {
    switch (_repeatMode) {
      case RepeatMode.off:
        _repeatMode = RepeatMode.all;
        audioHandler.setRepeatMode(AudioServiceRepeatMode.all);
        break;
      case RepeatMode.all:
        _repeatMode = RepeatMode.one;
        audioHandler.setRepeatMode(AudioServiceRepeatMode.one);
        break;
      case RepeatMode.one:
        _repeatMode = RepeatMode.off;
        audioHandler.setRepeatMode(AudioServiceRepeatMode.none);
        break;
    }
    notifyListeners();
  }

  Future<void> playPreviousSong() async {
    await audioHandler.skipToPrevious();
  }

  // Public method to clear search results
  void clearSearchResults() {
    _searchResults = [];
    notifyListeners();
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
    _playbackStateSubscription.cancel();
    _mediaItemSubscription.cancel();
    _positionSubscription.cancel();
    audioHandler.customAction('dispose');
    _yt.close();
    super.dispose();
  }
}
