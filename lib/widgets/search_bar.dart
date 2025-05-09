import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../viewmodels/player_viewmodel.dart';
import '../views/playlist_view.dart';

class MusicSearchBar extends StatefulWidget {
  const MusicSearchBar({super.key});

  @override
  State<MusicSearchBar> createState() => _MusicSearchBarState();
}

class _MusicSearchBarState extends State<MusicSearchBar> {
  final TextEditingController _searchController = TextEditingController();
  bool _isSearchMode = false;

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final viewModel = Provider.of<PlayerViewModel>(context);
    final bool isPlayerActive = viewModel.currentSong != null;
    final bool hasSearchResults = viewModel.searchResults.isNotEmpty;

    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Row(
        children: [
          // Show back button if player is active
          if (isPlayerActive && !_isSearchMode)
            IconButton(
              icon: const Icon(Icons.arrow_back),
              onPressed: () {
                // This button now opens search mode
                setState(() {
                  _isSearchMode = true;
                });
              },
              tooltip: 'Search music',
            ),

          // Show search icon if in player mode
          if (!_isSearchMode && !hasSearchResults)
            IconButton(
              icon: const Icon(Icons.search),
              onPressed: () {
                // Enter search mode
                setState(() {
                  _isSearchMode = true;
                });
              },
              tooltip: 'Search music',
            ),

          // Search field appears when in search mode or showing search results
          if (_isSearchMode || hasSearchResults)
            Expanded(
              child: TextField(
                controller: _searchController,
                style: const TextStyle(color: Colors.white),
                autofocus: _isSearchMode,
                decoration: InputDecoration(
                  hintText: 'Search songs, artists...',
                  hintStyle: TextStyle(color: Colors.grey[400]),
                  prefixIcon:
                      hasSearchResults
                          ? IconButton(
                            icon: const Icon(
                              Icons.arrow_back,
                              color: Colors.white70,
                            ),
                            onPressed: () {
                              // Clear search and go back to player
                              _searchController.clear();
                              viewModel.clearSearchResults();
                              setState(() {
                                _isSearchMode = false;
                              });
                            },
                          )
                          : const Icon(Icons.search, color: Colors.white70),
                  suffixIcon: IconButton(
                    icon: const Icon(Icons.clear, color: Colors.white70),
                    onPressed: () {
                      _searchController.clear();
                      if (hasSearchResults) {
                        viewModel.clearSearchResults();
                        setState(() {
                          _isSearchMode = false;
                        });
                      }
                    },
                  ),
                  filled: true,
                  fillColor: Colors.grey[900],
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(32),
                    borderSide: BorderSide.none,
                  ),
                  contentPadding: const EdgeInsets.symmetric(vertical: 15),
                ),
                onSubmitted: (value) {
                  if (value.trim().isNotEmpty) {
                    viewModel.searchSongs(value);
                  }
                },
              ),
            ),

          // If not in search mode, show playlist icon
          if (!_isSearchMode && !hasSearchResults && viewModel.songs.isNotEmpty)
            IconButton(
              icon: const Icon(Icons.playlist_play),
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => const PlaylistView()),
                );
              },
              tooltip: 'View Playlist',
            ),
        ],
      ),
    );
  }
}
