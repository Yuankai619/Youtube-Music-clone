import 'package:flutter/material.dart';
import '../data/lyrics_service.dart';

class DynamicLyricsView extends StatefulWidget {
  final List<LyricLine> lyrics;
  final int currentIndex;
  final Duration currentPosition;
  final bool isLoading;
  final bool notFound;
  final Function() onRefresh;
  final Function() onClose;

  const DynamicLyricsView({
    Key? key,
    required this.lyrics,
    required this.currentIndex,
    required this.currentPosition,
    required this.isLoading,
    required this.notFound,
    required this.onRefresh,
    required this.onClose,
  }) : super(key: key);

  @override
  State<DynamicLyricsView> createState() => _DynamicLyricsViewState();
}

class _DynamicLyricsViewState extends State<DynamicLyricsView> {
  final ScrollController _scrollController = ScrollController();

  @override
  void didUpdateWidget(DynamicLyricsView oldWidget) {
    super.didUpdateWidget(oldWidget);

    // Scroll to the current lyric when it changes
    if (widget.currentIndex != oldWidget.currentIndex &&
        widget.currentIndex >= 0) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _scrollToCurrentLyric();
      });
    }
  }

  void _scrollToCurrentLyric() {
    if (widget.currentIndex < 0 || widget.lyrics.isEmpty) return;

    final itemHeight = 60.0; // Estimated height of each lyric line
    final screenHeight = MediaQuery.of(context).size.height;
    final targetOffset =
        (widget.currentIndex * itemHeight) - (screenHeight / 3);

    _scrollController.animateTo(
      targetOffset.clamp(0, _scrollController.position.maxScrollExtent),
      duration: const Duration(milliseconds: 300),
      curve: Curves.easeInOut,
    );
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (widget.isLoading) {
      return const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            CircularProgressIndicator(),
            SizedBox(height: 16),
            Text('Loading lyrics...'),
          ],
        ),
      );
    }

    if (widget.notFound) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.lyrics_outlined, size: 64, color: Colors.grey),
            const SizedBox(height: 16),
            const Text(
              'No lyrics found',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            const Text(
              'We couldn\'t find lyrics for this song',
              style: TextStyle(color: Colors.grey),
            ),
            const SizedBox(height: 24),
            ElevatedButton(
              onPressed: widget.onRefresh,
              child: const Text('Try Again'),
            ),
          ],
        ),
      );
    }

    if (widget.lyrics.isEmpty) {
      return const Center(child: Text('No lyrics available for this song'));
    }

    return Stack(
      children: [
        // Lyrics list
        ListView.builder(
          controller: _scrollController,
          padding: const EdgeInsets.only(top: 80, bottom: 80),
          itemCount: widget.lyrics.length,
          itemBuilder: (context, index) {
            final lyric = widget.lyrics[index];
            final isCurrentLine = index == widget.currentIndex;

            return Container(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
              margin: const EdgeInsets.symmetric(vertical: 4),
              child: AnimatedDefaultTextStyle(
                duration: const Duration(milliseconds: 300),
                style: TextStyle(
                  fontSize: isCurrentLine ? 22 : 18,
                  fontWeight:
                      isCurrentLine ? FontWeight.bold : FontWeight.normal,
                  color: isCurrentLine ? Colors.white : Colors.grey,
                ),
                child: Text(lyric.text, textAlign: TextAlign.center),
              ),
            );
          },
        ),

        // Gradient overlay at top
        Positioned(
          top: 0,
          left: 0,
          right: 0,
          height: 80,
          child: Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  Colors.black.withOpacity(1.0),
                  Colors.black.withOpacity(0.0),
                ],
              ),
            ),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16.0),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  IconButton(
                    icon: const Icon(Icons.arrow_back),
                    onPressed: widget.onClose,
                  ),
                  const Text(
                    'Lyrics',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                  IconButton(
                    icon: const Icon(Icons.refresh),
                    onPressed: widget.onRefresh,
                  ),
                ],
              ),
            ),
          ),
        ),

        // Gradient overlay at bottom
        Positioned(
          bottom: 0,
          left: 0,
          right: 0,
          height: 80,
          child: Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.bottomCenter,
                end: Alignment.topCenter,
                colors: [
                  Colors.black.withOpacity(1.0),
                  Colors.black.withOpacity(0.0),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }
}
