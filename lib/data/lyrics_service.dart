import 'package:http/http.dart' as http;
import '../models/song_model.dart';
import 'package:html/parser.dart' as parser;

class LyricLine {
  final String text;
  final Duration timestamp;
  final Duration endTimestamp;

  LyricLine({
    required this.text,
    required this.timestamp,
    this.endTimestamp = Duration.zero,
  });
}

class LyricsService {
  Future<List<LyricLine>> fetchLyrics(Song song) async {
    try {
      final url = song.getLyricsUrl();
      final response = await http.get(Uri.parse(url));

      if (response.statusCode != 200) {
        print('Failed to load lyrics: ${response.statusCode}');
        return [];
      }

      final document = parser.parse(response.body);

      // Try to find the synchronized lyrics container
      final lyricsElements = document.querySelectorAll(
        '.mxm-lyrics-container span',
      );
      if (lyricsElements.isEmpty) {
        // Try regular lyrics if synchronized ones aren't available
        final regularLyricsElements = document.querySelectorAll(
          '.mxm-lyrics-container p',
        );
        if (regularLyricsElements.isEmpty) {
          return [];
        }

        // Create unsynchronized lyrics (with estimated timestamps)
        final List<LyricLine> lyrics = [];
        int index = 0;
        final estimatedLineDuration =
            (song.duration.inMilliseconds / regularLyricsElements.length);

        for (var element in regularLyricsElements) {
          final lineText = element.text.trim();
          if (lineText.isNotEmpty) {
            final timestamp = Duration(
              milliseconds: (estimatedLineDuration * index).round(),
            );
            final endTimestamp = Duration(
              milliseconds: (estimatedLineDuration * (index + 1)).round(),
            );
            lyrics.add(
              LyricLine(
                text: lineText,
                timestamp: timestamp,
                endTimestamp: endTimestamp,
              ),
            );
            index++;
          }
        }

        return lyrics;
      }

      // Process synchronized lyrics
      final List<LyricLine> syncedLyrics = [];

      // Extract timestamps and lyrics
      for (int i = 0; i < lyricsElements.length; i++) {
        final element = lyricsElements[i];
        final dataStart = element.attributes['data-start'];
        final dataEnd = element.attributes['data-end'];

        if (dataStart != null) {
          final timestamp = Duration(
            milliseconds: (double.parse(dataStart) * 1000).round(),
          );
          final endTimestamp =
              dataEnd != null
                  ? Duration(
                    milliseconds: (double.parse(dataEnd) * 1000).round(),
                  )
                  : Duration.zero;

          syncedLyrics.add(
            LyricLine(
              text: element.text.trim(),
              timestamp: timestamp,
              endTimestamp: endTimestamp,
            ),
          );
        }
      }

      return syncedLyrics;
    } catch (e) {
      print('Error fetching lyrics: $e');
      return [];
    }
  }
}
