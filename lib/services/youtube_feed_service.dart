import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:youtube_explode_dart/youtube_explode_dart.dart' hide Playlist;
import '../models/song.dart';
import '../models/comment.dart';
import 'youtube_importer_service.dart';

class VideoStreamOptions {
  final String? videoMuxedUrl;
  final String? audioOnlyUrl;
  final String selectedQuality;
  final Map<String, String> qualities;

  const VideoStreamOptions({
    this.videoMuxedUrl,
    this.audioOnlyUrl,
    this.selectedQuality = '720p',
    this.qualities = const {},
  });
}

class YouTubeFeedService {
  static final YoutubeExplode _yt = YoutubeExplode();
  static final Map<String, List<Song>> _categoryFeedCache = {};
  static final Map<String, VideoStreamOptions> _streamOptionsCache = {};

  static const List<Map<String, String>> categories = [
    {'id': 'all', 'title': 'All', 'query': 'Trending popular videos 2026'},
    {'id': 'trending', 'title': 'Trending', 'query': 'Top trending viral'},
    {'id': 'music', 'title': 'Music', 'query': 'Official music video hits'},
    {'id': 'gaming', 'title': 'Gaming', 'query': 'Trending gaming gameplay playthrough'},
    {'id': 'tech', 'title': 'Tech', 'query': 'Tech news reviews AI coding hardware'},
    {'id': 'news', 'title': 'News', 'query': 'Global world news headlines live'},
    {'id': 'podcasts', 'title': 'Podcasts', 'query': 'Popular video podcasts full episode'},
    {'id': 'entertainment', 'title': 'Entertainment', 'query': 'Trending movies comedy entertainment'},
  ];

  /// Fetch YouTube Video Feed by Category
  static Future<List<Song>> fetchCategoryFeed(String categoryId, {bool forceRefresh = false}) async {
    if (!forceRefresh && _categoryFeedCache.containsKey(categoryId) && _categoryFeedCache[categoryId]!.isNotEmpty) {
      return _categoryFeedCache[categoryId]!;
    }

    final cat = categories.firstWhere(
      (c) => c['id'] == categoryId,
      orElse: () => categories.first,
    );
    final query = cat['query'] ?? 'Trending popular videos';

    try {
      final searchResults = await _yt.search.search(query);
      final List<Song> list = [];

      for (final item in searchResults) {
        if (item is SearchVideo) {
          final id = item.id.value;
          final title = item.title;
          final author = item.author;
          final duration = item.duration ?? const Duration(minutes: 4, seconds: 20);
          final artwork = 'https://i.ytimg.com/vi/$id/hqdefault.jpg';
          final desc = item.description;

          list.add(
            Song(
              id: id,
              title: title,
              artist: author,
              duration: duration,
              artworkUrl: artwork,
              streamUrl: '',
              channelId: item.channelId.value,
              description: desc,
              uploadDateFormatted: item.uploadDate?.toIso8601String().split('T').first,
              source: 'youtube',
            ),
          );
        }
      }

      if (list.isNotEmpty) {
        _categoryFeedCache[categoryId] = list;
        return list;
      }
    } catch (e) {
      debugPrint('[YouTubeFeedService] fetchCategoryFeed error for $categoryId: $e');
    }

    // Fallback using YouTubeImporterService
    try {
      final fallback = await YouTubeImporterService.searchYouTube(query, limit: 30);
      if (fallback.isNotEmpty) {
        _categoryFeedCache[categoryId] = fallback;
        return fallback;
      }
    } catch (_) {}

    return _categoryFeedCache[categoryId] ?? [];
  }

  /// Resolve stream options (720p/1080p muxed video & high quality audio) for video player
  static Future<VideoStreamOptions> resolveVideoStreamOptions(String videoId) async {
    if (_streamOptionsCache.containsKey(videoId)) {
      return _streamOptionsCache[videoId]!;
    }

    try {
      final manifest = await _yt.videos.streamsClient.getManifest(
        videoId,
        ytClients: [YoutubeApiClient.android, YoutubeApiClient.ios],
      );

      final Map<String, String> qualities = {};
      String? bestMuxedUrl;
      String? bestAudioUrl;

      // Extract muxed streams (contains both video and audio - ideal for video_player)
      final muxedStreams = manifest.muxed.sortByVideoQuality();
      if (muxedStreams.isNotEmpty) {
        bestMuxedUrl = muxedStreams.first.url.toString();
        for (final s in muxedStreams) {
          final label = s.qualityLabel;
          if (!qualities.containsKey(label)) {
            qualities[label] = s.url.toString();
          }
        }
      }

      // Extract audio-only stream (for background listening / listen mode)
      final audioStreams = manifest.audioOnly.sortByBitrate();
      if (audioStreams.isNotEmpty) {
        bestAudioUrl = audioStreams.first.url.toString();
      } else if (bestMuxedUrl != null) {
        bestAudioUrl = bestMuxedUrl;
      }

      final options = VideoStreamOptions(
        videoMuxedUrl: bestMuxedUrl,
        audioOnlyUrl: bestAudioUrl,
        selectedQuality: qualities.keys.isNotEmpty ? qualities.keys.first : '720p',
        qualities: qualities,
      );

      _streamOptionsCache[videoId] = options;
      return options;
    } catch (e) {
      debugPrint('[YouTubeFeedService] resolveVideoStreamOptions error: $e');
      // Fallback: get audio stream url from importer
      final audioUrl = await YouTubeImporterService.getAudioStreamUrl(videoId);
      final options = VideoStreamOptions(
        videoMuxedUrl: audioUrl,
        audioOnlyUrl: audioUrl,
        selectedQuality: 'Auto',
        qualities: audioUrl != null ? {'Auto': audioUrl} : {},
      );
      return options;
    }
  }

  /// Fetch full video details (description, channel, views)
  static Future<Song> enrichVideoDetails(Song song) async {
    try {
      final video = await _yt.videos.get(song.id);
      return song.copyWith(
        title: video.title,
        artist: video.author,
        channelId: video.channelId.value,
        description: video.description,
        duration: video.duration ?? song.duration,
        viewCount: video.engagement.viewCount,
        uploadDateFormatted: video.uploadDate?.toIso8601String().split('T').first,
        artworkUrl: video.thumbnails.highResUrl.isNotEmpty
            ? video.thumbnails.highResUrl
            : 'https://i.ytimg.com/vi/${song.id}/maxresdefault.jpg',
      );
    } catch (e) {
      debugPrint('[YouTubeFeedService] enrichVideoDetails error: $e');
      return song;
    }
  }

  /// Fetch real YouTube comments
  static Future<List<AuraComment>> fetchComments(String videoId, {int limit = 30}) async {
    try {
      final video = await _yt.videos.get(videoId);
      // ignore: deprecated_member_use
      final commentsList = await _yt.videos.commentsClient.getComments(video);
      if (commentsList == null) return [];

      final List<AuraComment> results = [];
      for (final c in commentsList) {
        results.add(
          AuraComment(
            author: c.author,
            authorThumbnail: '',
            text: c.text,
            likeCount: c.likeCount,
            publishedTime: c.publishedTime,
            channelId: c.channelId.value,
          ),
        );
        if (results.length >= limit) break;
      }
      return results;
    } catch (e) {
      debugPrint('[YouTubeFeedService] fetchComments error: $e');
      return [];
    }
  }

  /// Fetch related videos
  static Future<List<Song>> fetchRelatedVideos(String videoId, {int limit = 20}) async {
    try {
      final video = await _yt.videos.get(videoId);
      final related = await _yt.videos.getRelatedVideos(video);
      if (related != null && related.isNotEmpty) {
        final List<Song> list = [];
        for (final item in related) {
          final id = item.id.value;
          list.add(
            Song(
              id: id,
              title: item.title,
              artist: item.author,
              duration: item.duration ?? const Duration(minutes: 3, seconds: 45),
              artworkUrl: 'https://i.ytimg.com/vi/$id/hqdefault.jpg',
              streamUrl: '',
              channelId: item.channelId.value,
              source: 'youtube',
            ),
          );
          if (list.length >= limit) break;
        }
        if (list.isNotEmpty) return list;
      }
    } catch (e) {
      debugPrint('[YouTubeFeedService] fetchRelatedVideos error: $e');
    }

    // Fallback: search video author or title
    try {
      return await YouTubeImporterService.searchYouTube('More from $videoId', limit: limit);
    } catch (_) {
      return [];
    }
  }
}
