import 'package:http/http.dart' as http;
import 'dart:convert';
import '../models/song_model.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';

class YouTubeService {
  // Replace with your actual API key
  final String API_KEY = dotenv.env['YOUTUBE_API_KEY']!;

  static const String BASE_URL = 'https://www.googleapis.com/youtube/v3';

  Future<List<Song>> searchSongs(String query) async {
    if (query.isEmpty) return [];

    print('Searching for: $query');

    try {
      // Search for videos
      final searchUrl = Uri.parse(
        '$BASE_URL/search?part=snippet&maxResults=20'
        '&q=$query&type=video&videoCategoryId=10&key=$API_KEY',
      );

      final searchResponse = await http.get(searchUrl);

      if (searchResponse.statusCode != 200) {
        print(
          'API Error: ${searchResponse.statusCode} - ${searchResponse.body}',
        );
        return [];
      }

      final searchData = json.decode(searchResponse.body);

      // Safely check if items exists
      if (searchData == null || searchData['items'] == null) {
        print('No search results found or invalid response format');
        return [];
      }

      // Extract video IDs
      final items = searchData['items'] as List;
      if (items.isEmpty) {
        print('No videos found for query: $query');
        return [];
      }

      final List<String> videoIds = [];

      for (var item in items) {
        if (item != null &&
            item['id'] != null &&
            item['id']['videoId'] != null) {
          videoIds.add(item['id']['videoId']);
        }
      }

      if (videoIds.isEmpty) {
        print('No valid video IDs found');
        return [];
      }

      // Get video details
      final videoDetailsUrl = Uri.parse(
        '$BASE_URL/videos?part=snippet,contentDetails,statistics'
        '&id=${videoIds.join(",")}&key=$API_KEY',
      );

      final videoDetailsResponse = await http.get(videoDetailsUrl);

      if (videoDetailsResponse.statusCode != 200) {
        print(
          'API Error fetching video details: ${videoDetailsResponse.statusCode}',
        );
        return [];
      }

      final videoData = json.decode(videoDetailsResponse.body);
      if (videoData == null || videoData['items'] == null) {
        print('Invalid video details response');
        return [];
      }

      final videoItems = videoData['items'] as List;
      final List<Song> songs = [];

      for (var video in videoItems) {
        try {
          if (video != null &&
              video['id'] != null &&
              video['snippet'] != null) {
            final snippet = video['snippet'];
            final String videoId = video['id'];
            final String title = snippet['title'] ?? 'Unknown Title';
            final String channelTitle =
                snippet['channelTitle'] ?? 'Unknown Artist';

            // Get thumbnail with highest resolution
            String thumbnailUrl = '';
            if (snippet['thumbnails'] != null) {
              final thumbnails = snippet['thumbnails'];
              if (thumbnails['high'] != null &&
                  thumbnails['high']['url'] != null) {
                thumbnailUrl = thumbnails['high']['url'];
              } else if (thumbnails['medium'] != null &&
                  thumbnails['medium']['url'] != null) {
                thumbnailUrl = thumbnails['medium']['url'];
              } else if (thumbnails['default'] != null &&
                  thumbnails['default']['url'] != null) {
                thumbnailUrl = thumbnails['default']['url'];
              }
            }

            String duration = 'Unknown';
            if (video['contentDetails'] != null &&
                video['contentDetails']['duration'] != null) {
              duration = video['contentDetails']['duration'];
            }

            songs.add(
              Song(
                id: videoId,
                title: title,
                artist: channelTitle,
                album: 'YouTube Music',
                albumArt: thumbnailUrl,
                previewUrl: 'https://www.youtube.com/watch?v=$videoId',
                videoId: videoId,
                duration: _parseDuration(duration),
              ),
            );
          }
        } catch (e) {
          print('Error parsing video: $e');
        }
      }

      print('Found ${songs.length} songs');
      return songs;
    } catch (e) {
      print('Error searching YouTube videos: $e');
      return [];
    }
  }

  // Helper method to parse ISO 8601 duration format
  Duration _parseDuration(String isoDuration) {
    try {
      if (isoDuration == 'Unknown') return Duration.zero;

      final regex = RegExp(r'PT(?:(\d+)H)?(?:(\d+)M)?(?:(\d+)S)?');
      final match = regex.firstMatch(isoDuration);

      if (match == null) return Duration.zero;

      final hours = match.group(1) != null ? int.parse(match.group(1)!) : 0;
      final minutes = match.group(2) != null ? int.parse(match.group(2)!) : 0;
      final seconds = match.group(3) != null ? int.parse(match.group(3)!) : 0;

      return Duration(hours: hours, minutes: minutes, seconds: seconds);
    } catch (e) {
      print('Error parsing duration: $e');
      return Duration.zero;
    }
  }
}

// API Key authentication client
class ApiKeyClient extends http.BaseClient {
  final http.Client _inner;
  final String _apiKey;

  ApiKeyClient(this._inner, this._apiKey);

  @override
  Future<http.StreamedResponse> send(http.BaseRequest request) {
    final url = request.url;
    final uri = url.replace(
      queryParameters: {...url.queryParameters, 'key': _apiKey},
    );

    final newRequest =
        http.Request(request.method, uri)
          ..headers.addAll(request.headers)
          ..bodyBytes = request.bodyBytes!;

    return _inner.send(newRequest);
  }
}

extension on http.BaseRequest {
  List<int>? get bodyBytes => null;
}
