import 'dart:async';
import 'package:audio_service/audio_service.dart';
import 'package:just_audio/just_audio.dart';

class MyAudioHandler extends BaseAudioHandler with QueueHandler, SeekHandler {
  final AudioPlayer _audioPlayer = AudioPlayer();

  // Add getters for compatibility with PlayerControls
  Duration? get duration => _audioPlayer.duration;
  Duration get position => _audioPlayer.position;
  double get volume => _audioPlayer.volume;

  // Add position stream
  Stream<Duration> get positionStream => _audioPlayer.positionStream;

  MyAudioHandler() {
    _init();
  }

  Future<void> _init() async {
    // Initialize with empty queue
    queue.add([]);

    // Listen to player events and broadcast state
    _audioPlayer.playbackEventStream.listen(_broadcastState);

    // Listen to sequence state changes
    _audioPlayer.sequenceStateStream.listen(_updateQueue);

    // Listen to current index changes
    _audioPlayer.currentIndexStream.listen(_updateMediaItem);

    // Listen to duration changes
    _audioPlayer.durationStream.listen(_updateDuration);

    // Initialize empty concatenating source
    await _audioPlayer.setAudioSource(ConcatenatingAudioSource(children: []));
  }

  void _broadcastState(PlaybackEvent event) {
    final playing = _audioPlayer.playing;
    final processingState = _audioPlayer.processingState;

    // Always broadcast state to ensure notification shows
    playbackState.add(
      PlaybackState(
        controls: [
          MediaControl.skipToPrevious,
          if (playing) MediaControl.pause else MediaControl.play,
          MediaControl.stop,
          MediaControl.skipToNext,
        ],
        systemActions: const {
          MediaAction.seek,
          MediaAction.seekForward,
          MediaAction.seekBackward,
        },
        androidCompactActionIndices: const [0, 1, 3],
        processingState: _mapProcessingState(processingState),
        playing: playing,
        updatePosition: _audioPlayer.position,
        bufferedPosition: _audioPlayer.bufferedPosition,
        speed: _audioPlayer.speed,
        queueIndex: event.currentIndex,
      ),
    );
  }

  AudioProcessingState _mapProcessingState(ProcessingState state) {
    switch (state) {
      case ProcessingState.idle:
        return AudioProcessingState.idle;
      case ProcessingState.loading:
        return AudioProcessingState.loading;
      case ProcessingState.buffering:
        return AudioProcessingState.buffering;
      case ProcessingState.ready:
        return AudioProcessingState.ready;
      case ProcessingState.completed:
        return AudioProcessingState.completed;
    }
  }

  void _updateQueue(SequenceState? sequenceState) {
    final sequence = sequenceState?.effectiveSequence;
    if (sequence == null || sequence.isEmpty) {
      queue.add([]);
      return;
    }

    final items = sequence.map((source) => source.tag as MediaItem).toList();
    queue.add(items);
  }

  void _updateMediaItem(int? index) {
    final currentQueue = queue.value;
    if (index == null || currentQueue.isEmpty || index >= currentQueue.length) {
      return;
    }

    mediaItem.add(currentQueue[index]);
  }

  void _updateDuration(Duration? duration) {
    final currentQueue = queue.value;
    final index = _audioPlayer.currentIndex;

    if (duration == null ||
        index == null ||
        currentQueue.isEmpty ||
        index >= currentQueue.length) {
      return;
    }

    final oldMediaItem = currentQueue[index];
    final newMediaItem = oldMediaItem.copyWith(duration: duration);
    final newQueue = List<MediaItem>.from(currentQueue);
    newQueue[index] = newMediaItem;
    queue.add(newQueue);
    mediaItem.add(newMediaItem);
  }

  @override
  Future<void> addQueueItem(MediaItem mediaItem) async {
    try {
      print('Adding queue item: ${mediaItem.title}');

      // Create single audio source
      final audioSource = _createAudioSource(mediaItem);

      // Set as single item source
      await _audioPlayer.setAudioSource(audioSource);

      // Update queue manually
      queue.add([mediaItem]);
      this.mediaItem.add(mediaItem);

      // Force broadcast state to show notification
      _broadcastState(PlaybackEvent());

      print('Queue item added successfully');
    } catch (e) {
      print('Error adding queue item: $e');
      rethrow;
    }
  }

  @override
  Future<void> addQueueItems(List<MediaItem> mediaItems) async {
    try {
      final audioSources = mediaItems.map(_createAudioSource).toList();
      final concatenatingSource = ConcatenatingAudioSource(
        children: audioSources,
      );

      await _audioPlayer.setAudioSource(concatenatingSource);

      queue.add(mediaItems);
      if (mediaItems.isNotEmpty) {
        mediaItem.add(mediaItems.first);
      }
    } catch (e) {
      print('Error adding queue items: $e');
      rethrow;
    }
  }

  AudioSource _createAudioSource(MediaItem mediaItem) {
    final url = mediaItem.extras?['url'] as String?;
    if (url == null || url.isEmpty) {
      throw Exception(
        'No URL found in media item extras for ${mediaItem.title}',
      );
    }

    print('Creating audio source for URL: $url');
    return AudioSource.uri(Uri.parse(url), tag: mediaItem);
  }

  @override
  Future<void> play() async {
    try {
      print('AudioHandler: Starting playback');
      await _audioPlayer.play();
    } catch (e) {
      print('Error playing: $e');
      rethrow;
    }
  }

  @override
  Future<void> pause() async {
    try {
      print('AudioHandler: Pausing playback');
      await _audioPlayer.pause();
    } catch (e) {
      print('Error pausing: $e');
      rethrow;
    }
  }

  @override
  Future<void> seek(Duration position) async {
    try {
      await _audioPlayer.seek(position);
    } catch (e) {
      print('Error seeking: $e');
    }
  }

  @override
  Future<void> skipToNext() async {
    try {
      await _audioPlayer.seekToNext();
    } catch (e) {
      print('Error skipping to next: $e');
    }
  }

  @override
  Future<void> skipToPrevious() async {
    try {
      await _audioPlayer.seekToPrevious();
    } catch (e) {
      print('Error skipping to previous: $e');
    }
  }

  Future<void> setVolume(double volume) async {
    try {
      await _audioPlayer.setVolume(volume);
    } catch (e) {
      print('Error setting volume: $e');
    }
  }

  @override
  Future<void> setRepeatMode(AudioServiceRepeatMode repeatMode) async {
    try {
      switch (repeatMode) {
        case AudioServiceRepeatMode.none:
          await _audioPlayer.setLoopMode(LoopMode.off);
          break;
        case AudioServiceRepeatMode.one:
          await _audioPlayer.setLoopMode(LoopMode.one);
          break;
        case AudioServiceRepeatMode.group:
        case AudioServiceRepeatMode.all:
          await _audioPlayer.setLoopMode(LoopMode.all);
          break;
      }
    } catch (e) {
      print('Error setting repeat mode: $e');
    }
  }

  @override
  Future<void> setShuffleMode(AudioServiceShuffleMode shuffleMode) async {
    try {
      if (shuffleMode == AudioServiceShuffleMode.none) {
        await _audioPlayer.setShuffleModeEnabled(false);
      } else {
        await _audioPlayer.shuffle();
        await _audioPlayer.setShuffleModeEnabled(true);
      }
    } catch (e) {
      print('Error setting shuffle mode: $e');
    }
  }

  @override
  Future<void> stop() async {
    try {
      await _audioPlayer.stop();
      // Clear the queue and media item
      queue.add([]);
      mediaItem.add(null);

      // Broadcast stopped state
      playbackState.add(
        PlaybackState(
          processingState: AudioProcessingState.idle,
          playing: false,
        ),
      );

      await super.stop();
    } catch (e) {
      print('Error stopping: $e');
    }
  }

  @override
  Future<void> customAction(String name, [Map<String, dynamic>? extras]) async {
    try {
      if (name == 'dispose') {
        await _audioPlayer.dispose();
        super.stop();
      }
    } catch (e) {
      print('Error in custom action: $e');
    }
  }
}
