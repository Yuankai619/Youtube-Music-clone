import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/song_model.dart';
import '../viewmodels/player_viewmodel.dart';
import 'dynamic_lyrics_view.dart';

class LyricsView extends StatelessWidget {
  final Song song;
  final bool fullscreen;

  const LyricsView({super.key, required this.song, required this.fullscreen});

  @override
  Widget build(BuildContext context) {
    if (!fullscreen)
      return const SizedBox.shrink(); // No mini view, just ignore it

    return Consumer<PlayerViewModel>(
      builder: (context, viewModel, _) {
        return DynamicLyricsView(
          lyrics: viewModel.lyrics,
          currentIndex: viewModel.currentLyricIndex,
          currentPosition: viewModel.audioPlayer.position,
          isLoading: viewModel.isLoadingLyrics,
          notFound: viewModel.lyricsNotFound,
          onRefresh: viewModel.fetchLyrics,
          onClose: viewModel.toggleLyricsState,
        );
      },
    );
  }
}
