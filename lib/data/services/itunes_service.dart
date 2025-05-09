import 'dart:convert';
import 'package:http/http.dart' as http;
import '../../models/song_model.dart';
import 'package:flutter/foundation.dart';

class ItunesService {
  final String _baseUrl = 'https://itunes.apple.com/search';

  Future<List<Song>> searchSongs(
    String term, {
    String country = 'tw',
    String media = 'music',
  }) async {
    if (term.isEmpty) {
      return [];
    }
    final String encodedTerm = Uri.encodeComponent(term);
    final Uri url = Uri.parse(
      '$_baseUrl?term=$encodedTerm&media=$media&country=$country&limit=20',
    ); // Added limit

    try {
      final response = await http.get(url);

      if (response.statusCode == 200) {
        final Map<String, dynamic> data = json.decode(response.body);
        final List<dynamic> results = data['results'] as List<dynamic>;
        return results
            .map((json) => Song.fromJson(json as Map<String, dynamic>))
            .where(
              (song) => song.previewUrl.isNotEmpty,
            ) // Filter out songs without preview URL
            .toList();
      } else {
        debugPrint('Failed to load songs: ${response.statusCode}');
        throw Exception('Failed to load songs from iTunes API');
      }
    } catch (e) {
      debugPrint('Error in iTunesService: $e');
      throw Exception('Error connecting to iTunes API: $e');
    }
  }
}
