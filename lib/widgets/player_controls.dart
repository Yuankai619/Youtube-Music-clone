import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../viewmodels/player_viewmodel.dart';

class PlayerControls extends StatelessWidget {
  const PlayerControls({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer<PlayerViewModel>(
      builder: (context, viewModel, _) {
        final duration = viewModel.audioPlayer.duration ?? Duration.zero;
        final position = viewModel.audioPlayer.position;

        final bool hasSongs = viewModel.songs.isNotEmpty;
        final bool isProcessing = viewModel.isLoading || viewModel.isBuffering;

        return Column(
          children: [
            // Error message
            if (viewModel.errorMessage.isNotEmpty)
              Padding(
                padding: const EdgeInsets.all(8.0),
                child: Text(
                  viewModel.errorMessage,
                  style: TextStyle(color: Colors.red[400], fontSize: 12),
                  textAlign: TextAlign.center,
                ),
              ),

            // Progress slider
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16.0),
              child: Row(
                children: [
                  Text(
                    _formatDuration(position),
                    style: TextStyle(fontSize: 12, color: Colors.grey[400]),
                  ),
                  Expanded(
                    child: Slider(
                      value: position.inMilliseconds.toDouble().clamp(
                        0,
                        duration.inMilliseconds.toDouble() == 0
                            ? 1
                            : duration.inMilliseconds.toDouble(),
                      ),
                      max:
                          duration.inMilliseconds.toDouble() == 0
                              ? 1
                              : duration.inMilliseconds.toDouble(),
                      onChanged: (value) {
                        viewModel.seekTo(Duration(milliseconds: value.toInt()));
                      },
                      activeColor: Theme.of(context).colorScheme.secondary,
                    ),
                  ),
                  Text(
                    _formatDuration(duration),
                    style: TextStyle(fontSize: 12, color: Colors.grey[400]),
                  ),
                ],
              ),
            ),

            // Main controls
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                // Shuffle button
                IconButton(
                  icon: Icon(
                    Icons.shuffle,
                    color:
                        viewModel.isShuffleEnabled
                            ? Theme.of(context).colorScheme.secondary
                            : Colors.white,
                  ),
                  onPressed: hasSongs ? viewModel.toggleShuffleMode : null,
                ).opacity(hasSongs ? 1.0 : 0.5),

                // Previous button
                IconButton(
                  iconSize: 32,
                  icon: const Icon(Icons.skip_previous),
                  onPressed: hasSongs ? viewModel.playPreviousSong : null,
                ).opacity(hasSongs ? 1.0 : 0.5),

                // Play/Pause/Loading button
                Container(
                  width: 64,
                  height: 64,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color:
                        isProcessing || !hasSongs
                            ? Theme.of(
                              context,
                            ).colorScheme.secondary.withValues(alpha: 0.5)
                            : Theme.of(context).colorScheme.secondary,
                  ),
                  child:
                      isProcessing
                          ? const Center(
                            child: SizedBox(
                              width: 32,
                              height: 32,
                              child: CircularProgressIndicator(
                                valueColor: AlwaysStoppedAnimation<Color>(
                                  Colors.white,
                                ),
                                strokeWidth: 3,
                              ),
                            ),
                          )
                          : IconButton(
                            iconSize: 32,
                            icon: Icon(
                              viewModel.isPlaying
                                  ? Icons.pause
                                  : Icons.play_arrow,
                              color: Colors.white,
                            ),
                            onPressed:
                                hasSongs ? viewModel.togglePlayPause : null,
                          ),
                ),

                // Next button
                IconButton(
                  iconSize: 32,
                  icon: const Icon(Icons.skip_next),
                  onPressed: hasSongs ? viewModel.playNextSong : null,
                ).opacity(hasSongs ? 1.0 : 0.5),

                // Repeat button
                IconButton(
                  icon: Icon(
                    viewModel.repeatMode == RepeatMode.one
                        ? Icons.repeat_one
                        : Icons.repeat,
                    color:
                        viewModel.repeatMode != RepeatMode.off
                            ? Theme.of(context).colorScheme.secondary
                            : Colors.white,
                  ),
                  onPressed: hasSongs ? viewModel.cycleRepeatMode : null,
                ).opacity(hasSongs ? 1.0 : 0.5),
              ],
            ),

            // Volume and lyrics controls
            Padding(
              padding: const EdgeInsets.symmetric(
                horizontal: 16.0,
                vertical: 8.0,
              ),
              child: Row(
                children: [
                  // Random song button
                  // IconButton(
                  //   icon: const Icon(Icons.shuffle_on, size: 24),
                  //   onPressed: viewModel.playRandomSong,
                  //   tooltip: 'Play random song',
                  // ),

                  // Volume control
                  const Icon(Icons.volume_down, size: 20),
                  Expanded(
                    child: Slider(
                      value: viewModel.audioPlayer.volume,
                      min: 0.0,
                      max: 1.0,
                      onChanged: viewModel.setVolume,
                    ),
                  ),
                  const Icon(Icons.volume_up, size: 20),

                  // Lyrics button
                  // IconButton(
                  //   icon: const Icon(Icons.lyrics, size: 24),
                  //   onPressed: viewModel.toggleLyricsState,
                  //   tooltip: 'Show lyrics',
                  //   color:
                  //       viewModel.lyricsState == LyricsState.fullscreen
                  //           ? Theme.of(context).colorScheme.secondary
                  //           : Colors.white,
                  // ),
                ],
              ),
            ),
          ],
        );
      },
    );
  }

  String _formatDuration(Duration duration) {
    final minutes = duration.inMinutes.remainder(60).toString().padLeft(2, '0');
    final seconds = duration.inSeconds.remainder(60).toString().padLeft(2, '0');
    return '$minutes:$seconds';
  }
}

extension IconButtonX on IconButton {
  IconButton opacity(double opacity) {
    if (opacity == 1.0) return this;

    return IconButton(
      icon: Opacity(opacity: opacity, child: icon),
      onPressed: onPressed,
      tooltip: tooltip,
      iconSize: iconSize,
      color: color,
      padding: padding,
      alignment: alignment,
      splashRadius: splashRadius,
      focusColor: focusColor,
      hoverColor: hoverColor,
      highlightColor: highlightColor,
      splashColor: splashColor,
      disabledColor: disabledColor,
    );
  }
}
