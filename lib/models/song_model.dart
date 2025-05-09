class Song {
  final String id;
  final String title;
  final String artist;
  final String album;
  final String albumArt;
  final String previewUrl;
  final String videoId;
  final Duration duration;

  Song({
    required this.id,
    required this.title,
    required this.artist,
    required this.album,
    required this.albumArt,
    required this.previewUrl,
    this.videoId = '',
    this.duration = Duration.zero,
  });

  // Creates a song from iTunes API response
  factory Song.fromJson(Map<String, dynamic> json) {
    return Song(
      id: json['trackId']?.toString() ?? '',
      title: json['trackName'] ?? 'Unknown Title',
      artist: json['artistName'] ?? 'Unknown Artist',
      album: json['collectionName'] ?? 'Unknown Album',
      albumArt:
          json['artworkUrl100']?.toString().replaceAll('100x100', '600x600') ??
          '',
      previewUrl: json['previewUrl'] ?? '',
    );
  }

  String getLyricsUrl() {
    final formattedArtist =
        artist
            .replaceAll(' ', '-')
            .replaceAll('&', 'and')
            .replaceAll('.', '')
            .replaceAll(',', '')
            .replaceAll('/', '')
            .replaceAll("'", '')
            .replaceAll('"', '')
            .replaceAll('(', '')
            .replaceAll(')', '')
            .toLowerCase();

    final formattedTitle =
        title
            .replaceAll(' ', '-')
            .replaceAll('&', 'and')
            .replaceAll('.', '')
            .replaceAll(',', '')
            .replaceAll('(', '')
            .replaceAll(')', '')
            .replaceAll('/', '')
            .replaceAll("'", '')
            .replaceAll('"', '')
            .replaceAll(':', '')
            .replaceAll('?', '')
            .replaceAll('!', '')
            .toLowerCase();

    return 'https://www.musixmatch.com/lyrics/$formattedArtist/$formattedTitle';
  }

  String getYoutubeUrl() {
    return 'https://www.youtube.com/watch?v=$videoId';
  }
}
