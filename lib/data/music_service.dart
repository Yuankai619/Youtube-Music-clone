import 'dart:convert';
import 'package:http/http.dart' as http;
import '../models/song_model.dart';

class MusicService {
  static const String baseUrl = 'https://itunes.apple.com/search';

  Future<List<Song>> searchSongs(String query, {String country = 'tw'}) async {
    if (query.isEmpty) return [];

    final url = Uri.parse(
      '$baseUrl?term=${Uri.encodeComponent(query)}&media=music&country=$country',
    );

    try {
      final response = await http.get(url);
      if (response.statusCode == 200) {
        final Map<String, dynamic> data = json.decode(response.body);
        final results = data['results'] as List;
        return results.map((json) => Song.fromJson(json)).toList();
      } else {
        throw Exception('Failed to load songs: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Failed to search songs: $e');
    }
  }
}
