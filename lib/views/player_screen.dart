import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../viewmodels/player_viewmodel.dart';
import '../widgets/album_art.dart';
import '../widgets/player_controls.dart';
import '../widgets/search_bar.dart';
import 'playlist_view.dart';

class PlayerScreen extends StatefulWidget {
  const PlayerScreen({super.key});

  @override
  State<PlayerScreen> createState() => _PlayerScreenState();
}

class _PlayerScreenState extends State<PlayerScreen> {
  @override
  Widget build(BuildContext context) {
    return Consumer<PlayerViewModel>(
      builder: (context, viewModel, _) {
        final bool showSearchResults = viewModel.searchResults.isNotEmpty;

        return Scaffold(
          body: SafeArea(
            child: Column(
              children: [
                // Search bar at the top
                MusicSearchBar(),

                // Main content area
                Expanded(
                  child:
                      viewModel.isLoading &&
                              viewModel.searchResults.isEmpty &&
                              viewModel.currentSong == null
                          ? const Center(child: CircularProgressIndicator())
                          : showSearchResults
                          ? _buildSearchResults(viewModel)
                          : _buildPlayerView(viewModel),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildSearchResults(PlayerViewModel viewModel) {
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.all(16.0),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Text(
                  'Search Results for "${viewModel.searchQuery}"',
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              TextButton(
                onPressed: () {
                  viewModel.addAllToPlaylist(viewModel.searchResults);
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('All songs added to playlist'),
                    ),
                  );
                  // Clear search results to show the player
                  viewModel.clearSearchResults();
                },
                child: const Text('Add All'),
              ),
            ],
          ),
        ),
        Expanded(
          child: ListView.builder(
            itemCount: viewModel.searchResults.length,
            itemBuilder: (context, index) {
              final song = viewModel.searchResults[index];
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
                ),
                subtitle: Text(
                  '${song.artist} • ${song.album}',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                trailing: IconButton(
                  icon: const Icon(Icons.add),
                  onPressed: () {
                    viewModel.addToPlaylist(song);
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text('${song.title} added to playlist'),
                      ),
                    );
                  },
                ),
                onTap: () => viewModel.playSong(song),
              );
            },
          ),
        ),
      ],
    );
  }

  Widget _buildPlayerView(PlayerViewModel viewModel) {
    final currentSong = viewModel.currentSong;

    if (currentSong == null) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Text(
              'Search and add songs to start playing',
              style: TextStyle(fontSize: 16),
            ),
            const SizedBox(height: 20),
            if (viewModel.songs.isNotEmpty)
              ElevatedButton.icon(
                icon: const Icon(Icons.playlist_play),
                label: const Text('View Playlist'),
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => const PlaylistView(),
                    ),
                  );
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: Theme.of(context).colorScheme.secondary,
                ),
              ),
          ],
        ),
      );
    }

    return Column(
      children: [
        // App bar with playlist button
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              IconButton(
                icon: const Icon(Icons.keyboard_arrow_down),
                onPressed: () {
                  // Mini-player mode (future enhancement)
                },
              ),
              Text(
                'NOW PLAYING',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                  color: Colors.grey[400],
                ),
              ),
              IconButton(
                icon: const Icon(Icons.playlist_play),
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => const PlaylistView(),
                    ),
                  );
                },
                tooltip: 'View Playlist',
              ),
            ],
          ),
        ),

        // Album art and song info
        Expanded(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Spacer(),
              Stack(
                alignment: Alignment.center,
                children: [
                  AlbumArt(imageUrl: currentSong.albumArt),

                  // Show loading indicator over album art if buffering
                  if (viewModel.isBuffering)
                    Container(
                      width: MediaQuery.of(context).size.width * 0.7,
                      height: MediaQuery.of(context).size.width * 0.7,
                      decoration: BoxDecoration(
                        color: Colors.black.withValues(alpha: 0.5),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: const Center(child: CircularProgressIndicator()),
                    ),
                ],
              ),
              const SizedBox(height: 24),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 24.0),
                child: Column(
                  children: [
                    Text(
                      currentSong.title,
                      style: const TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                      ),
                      textAlign: TextAlign.center,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 8),
                    Text(
                      '${currentSong.artist} • ${currentSong.album}',
                      style: TextStyle(fontSize: 16, color: Colors.grey[400]),
                      textAlign: TextAlign.center,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
              const Spacer(),
            ],
          ),
        ),

        // Player controls
        const PlayerControls(),

        // Mini playlist preview
        if (viewModel.songs.isNotEmpty)
          GestureDetector(
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => const PlaylistView()),
              );
            },
            child: Container(
              height: 70,
              decoration: BoxDecoration(
                color: Colors.grey[900],
                border: Border(
                  top: BorderSide(color: Colors.grey[800]!, width: 0.5),
                ),
              ),
              child: Row(
                children: [
                  // Playlist info
                  Expanded(
                    flex: 2,
                    child: Padding(
                      padding: const EdgeInsets.only(left: 16.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text(
                            'Your Playlist',
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              color: Colors.grey[300],
                            ),
                          ),
                          Text(
                            '${viewModel.songs.length} songs',
                            style: TextStyle(
                              fontSize: 12,
                              color: Colors.grey[500],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),

                  // Playlist preview
                  Expanded(
                    flex: 3,
                    child: ListView.builder(
                      scrollDirection: Axis.horizontal,
                      itemCount: viewModel.songs.length,
                      itemBuilder: (context, index) {
                        final song = viewModel.songs[index];
                        final isCurrentSong = currentSong.id == song.id;

                        return Container(
                          width: 60,
                          margin: const EdgeInsets.symmetric(
                            horizontal: 4,
                            vertical: 8,
                          ),
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(4),
                            border:
                                isCurrentSong
                                    ? Border.all(
                                      color:
                                          Theme.of(context).colorScheme.primary,
                                      width: 2,
                                    )
                                    : null,
                          ),
                          child: Stack(
                            fit: StackFit.expand,
                            children: [
                              ClipRRect(
                                borderRadius: BorderRadius.circular(3),
                                child: Image.network(
                                  song.albumArt,
                                  fit: BoxFit.cover,
                                  errorBuilder: (context, error, stackTrace) {
                                    return Container(
                                      color: Colors.grey[800],
                                      child: const Icon(Icons.music_note),
                                    );
                                  },
                                ),
                              ),

                              if (isCurrentSong && viewModel.isBuffering)
                                Container(
                                  decoration: BoxDecoration(
                                    borderRadius: BorderRadius.circular(3),
                                    color: Colors.black.withValues(alpha: 0.5),
                                  ),
                                  child: const Center(
                                    child: SizedBox(
                                      width: 20,
                                      height: 20,
                                      child: CircularProgressIndicator(
                                        strokeWidth: 2,
                                      ),
                                    ),
                                  ),
                                ),
                            ],
                          ),
                        );
                      },
                    ),
                  ),
                ],
              ),
            ),
          ),
      ],
    );
  }
}
