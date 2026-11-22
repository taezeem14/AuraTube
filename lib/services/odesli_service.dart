import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;

/// Cross-platform music links fetched via Odesli (song.link), inspired by Audile.
class OdesliLinks {
  final String? pageUrl;
  final String? youtubeUrl;
  final String? youtubeMusicUrl;
  final String? spotifyUrl;
  final String? appleMusicUrl;
  final String? soundcloudUrl;

  const OdesliLinks({
    this.pageUrl,
    this.youtubeUrl,
    this.youtubeMusicUrl,
    this.spotifyUrl,
    this.appleMusicUrl,
    this.soundcloudUrl,
  });

  bool get hasAnyLink =>
      (pageUrl?.isNotEmpty ?? false) ||
      (youtubeUrl?.isNotEmpty ?? false) ||
      (youtubeMusicUrl?.isNotEmpty ?? false) ||
      (spotifyUrl?.isNotEmpty ?? false) ||
      (appleMusicUrl?.isNotEmpty ?? false);
}

class OdesliService {
  OdesliService._();

  static final Map<String, OdesliLinks> _cache = {};

  /// Fetch cross-platform links for a YouTube video ID or URL via Odesli API.
  static Future<OdesliLinks?> fetchLinksForYouTubeId(String videoId) async {
    if (videoId.trim().isEmpty) return null;
    if (_cache.containsKey(videoId)) return _cache[videoId];

    try {
      final targetUrl = 'https://www.youtube.com/watch?v=$videoId';
      final uri = Uri.https('api.song.link', '/v1-alpha.1/links', {
        'url': targetUrl,
        'userCountry': 'US',
      });
      final resp = await http
          .get(uri, headers: {'User-Agent': 'AuraTube/1.0.4'})
          .timeout(const Duration(seconds: 6));
      if (resp.statusCode != 200) return null;

      final data = jsonDecode(resp.body);
      if (data is! Map<String, dynamic>) return null;
      final linksByPlatform = data['linksByPlatform'] as Map<String, dynamic>? ?? {};

      String? extractUrl(String key) {
        final entry = linksByPlatform[key];
        if (entry is Map && entry['url'] != null) {
          return entry['url'].toString();
        }
        return null;
      }

      final links = OdesliLinks(
        pageUrl: data['pageUrl']?.toString(),
        youtubeUrl: extractUrl('youtube'),
        youtubeMusicUrl: extractUrl('youtubeMusic'),
        spotifyUrl: extractUrl('spotify'),
        appleMusicUrl: extractUrl('appleMusic'),
        soundcloudUrl: extractUrl('soundcloud'),
      );
      _cache[videoId] = links;
      return links;
    } catch (e) {
      debugPrint('[OdesliService] Error fetching platform links: $e');
      return null;
    }
  }
}
