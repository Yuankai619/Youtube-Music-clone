import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../viewmodels/player_viewmodel.dart';

class PlaylistView extends StatelessWidget {
  const PlaylistView({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Consumer<PlayerViewModel>(
      builder: (context, viewModel, _) {
        final currentSong = viewModel.currentSong;
        final songs = viewModel.songs;

        return Scaffold(
          appBar: AppBar(
            title: const Text('Your Playlist'),
            actions: [
              if (songs.isNotEmpty)
                IconButton(
                  icon: const Icon(Icons.shuffle),
                  onPressed: viewModel.playRandomSong,
                  tooltip: 'Shuffle Play',
                ),
              if (songs.isNotEmpty)
                IconButton(
                  icon: const Icon(Icons.delete),
                  onPressed: () {
                    showDialog(
                      context: context,
                      builder:
                          (context) => AlertDialog(
                            title: const Text('Clear Playlist'),
                            content: const Text(
                              'Are you sure you want to clear your playlist?',
                            ),
                            actions: [
                              TextButton(
                                child: const Text('Cancel'),
                                onPressed: () => Navigator.pop(context),
                              ),
                              TextButton(
                                child: const Text('Clear'),
                                onPressed: () {
                                  viewModel.clearPlaylist();
                                  Navigator.pop(context);
                                  Navigator.pop(context);
                                },
                              ),
                            ],
                          ),
                    );
                  },
                  tooltip: 'Clear Playlist',
                ),
            ],
          ),
          body:
              songs.isEmpty
                  ? const Center(
                    child: Text(
                      'Your playlist is empty.\nAdd songs to get started!',
                    ),
                  )
                  : ListView.builder(
                    itemCount: songs.length,
                    itemBuilder: (context, index) {
                      final song = songs[index];
                      final isPlaying = currentSong?.id == song.id;

                      return ListTile(
                        leading: ClipRRect(
                          borderRadius: BorderRadius.circular(4),
                          child: Image.network(
                            song.albumArt,
                            width: 50,
                            height: 50,
                            fit: BoxFit.cover,
                            errorBuilder: (context, error, stackTrace) {
                              return Container(
                                width: 50,
                                height: 50,
                                color: Colors.grey[800],
                                child: const Icon(Icons.music_note),
                              );
                            },
                          ),
                        ),
                        title: Text(
                          song.title,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            fontWeight:
                                isPlaying ? FontWeight.bold : FontWeight.normal,
                            color:
                                isPlaying
                                    ? Theme.of(context).colorScheme.secondary
                                    : null,
                          ),
                        ),
                        subtitle: Text(
                          '${song.artist} • ${song.album}',
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        trailing: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            if (isPlaying)
                              Icon(
                                Icons.volume_up,
                                color: Theme.of(context).colorScheme.secondary,
                                size: 20,
                              ),
                            IconButton(
                              icon: const Icon(Icons.remove_circle_outline),
                              onPressed:
                                  () => viewModel.removeFromPlaylist(song),
                              tooltip: 'Remove from playlist',
                            ),
                          ],
                        ),
                        onTap: () {
                          viewModel.playSong(song);
                          Navigator.pop(
                            context,
                          ); // Go back to player after selecting
                        },
                      );
                    },
                  ),
          bottomNavigationBar:
              songs.isNotEmpty
                  ? BottomAppBar(
                    child: Padding(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 8,
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            '${songs.length} song${songs.length == 1 ? '' : 's'}',
                          ),
                          ElevatedButton.icon(
                            icon: const Icon(Icons.play_arrow),
                            label: const Text('Play All'),
                            onPressed: () {
                              if (songs.isNotEmpty) {
                                viewModel.playSong(songs.first);
                                Navigator.pop(context);
                              }
                            },
                            style: ElevatedButton.styleFrom(
                              backgroundColor:
                                  Theme.of(context).colorScheme.secondary,
                              foregroundColor: Colors.white,
                            ),
                          ),
                        ],
                      ),
                    ),
                  )
                  : null,
        );
      },
    );
  }
}
