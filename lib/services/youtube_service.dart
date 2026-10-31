import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:youtube_explode_dart/youtube_explode_dart.dart' as yt_exp;
import '../models/youtube_video.dart';
import '../models/youtube_comment.dart';

class StreamResult {
  final String videoUrl;
  final String audioUrl;
  final List<String> availableResolutions;

  const StreamResult({
    required this.videoUrl,
    required this.audioUrl,
    this.availableResolutions = const [],
  });
}

class YouTubeService {
  static final yt_exp.YoutubeExplode _yt = yt_exp.YoutubeExplode();

  static yt_exp.YoutubeExplode get client => _yt;

  // Formatting helpers
  static String formatViews(int? views) {
    if (views == null || views <= 0) return '0 views';
    if (views >= 1000000000) {
      return '${(views / 1000000000).toStringAsFixed(1)}B views';
    } else if (views >= 1000000) {
      return '${(views / 1000000).toStringAsFixed(1)}M views';
    } else if (views >= 1000) {
      return '${(views / 1000).toStringAsFixed(1)}K views';
    }
    return '$views views';
  }

  static String formatDuration(Duration? d) {
    if (d == null) return '0:00';
    final hours = d.inHours;
    final minutes = d.inMinutes.remainder(60);
    final seconds = d.inSeconds.remainder(60).toString().padLeft(2, '0');
    if (hours > 0) {
      return '$hours:${minutes.toString().padLeft(2, '0')}:$seconds';
    }
    return '$minutes:$seconds';
  }

  static YouTubeVideo _mapVideo(yt_exp.Video v) {
    final dur = v.duration ?? const Duration(minutes: 3);
    final isShort = dur.inSeconds > 0 && dur.inSeconds <= 65;
    return YouTubeVideo(
      id: v.id.value,
      title: v.title,
      author: v.author,
      channelId: v.channelId.value,
      thumbnailUrl: v.thumbnails.highResUrl.isNotEmpty
          ? v.thumbnails.highResUrl
          : v.thumbnails.standardResUrl,
      duration: dur,
      durationString: formatDuration(dur),
      viewCount: v.engagement.viewCount,
      viewCountFormatted: formatViews(v.engagement.viewCount),
      uploadDate: v.uploadDate != null
          ? '${v.uploadDate!.year}-${v.uploadDate!.month.toString().padLeft(2, '0')}-${v.uploadDate!.day.toString().padLeft(2, '0')}'
          : 'Recently',
      description: v.description,
      isShort: isShort,
      likeCount: v.engagement.likeCount ?? 0,
      tags: v.keywords.toList(),
    );
  }

  // 1. Home / Trending / Category Videos
  static Future<List<YouTubeVideo>> getHomeVideos({String category = 'All'}) async {
    try {
      final List<YouTubeVideo> videos = [];
      String searchQuery;
      switch (category.toLowerCase()) {
        case 'trending':
          searchQuery = 'trending';
          break;
        case 'music':
          searchQuery = 'trending music official';
          break;
        case 'gaming':
          searchQuery = 'trending gaming gameplay';
          break;
        case 'tech':
          searchQuery = 'technology science review';
          break;
        case 'news':
          searchQuery = 'world news live';
          break;
        case 'shorts':
          searchQuery = 'shorts #shorts';
          break;
        default:
          searchQuery = 'popular videos today';
      }

      final searchList = await _yt.search.search(searchQuery);
      for (final item in searchList.take(25)) {
        videos.add(_mapVideo(item));
      }
      return videos;
    } catch (e) {
      debugPrint('[YouTubeService] getHomeVideos error: $e');
      return _getFallbackVideos();
    }
  }

  // 2. Search Videos & Suggestions
  static Future<List<YouTubeVideo>> searchVideos(String query) async {
    try {
      final searchList = await _yt.search.search(query);
      return searchList.map(_mapVideo).toList();
    } catch (e) {
      debugPrint('[YouTubeService] searchVideos error: $e');
      return [];
    }
  }

  static Future<List<String>> getSearchSuggestions(String query) async {
    if (query.trim().isEmpty) return [];
    try {
      return await _yt.search.getQuerySuggestions(query);
    } catch (e) {
      debugPrint('[YouTubeService] getSearchSuggestions error: $e');
      return [];
    }
  }

  // 3. YouTube Shorts Feed
  static Future<List<YouTubeVideo>> getShortsFeed() async {
    try {
      final searchList = await _yt.search.search('#shorts viral trending');
      return searchList
          .where((v) => (v.duration?.inSeconds ?? 0) <= 65)
          .map(_mapVideo)
          .toList();
    } catch (e) {
      debugPrint('[YouTubeService] getShortsFeed error: $e');
      return [];
    }
  }

  // 4. Video Details & Related Videos
  static Future<YouTubeVideo?> getVideoDetails(String videoId) async {
    try {
      final video = await _yt.videos.get(videoId);
      return _mapVideo(video);
    } catch (e) {
      debugPrint('[YouTubeService] getVideoDetails error: $e');
      return null;
    }
  }

  static Future<List<YouTubeVideo>> getRelatedVideos(String videoId) async {
    try {
      final video = await _yt.videos.get(videoId);
      final related = await _yt.videos.getRelatedVideos(video);
      if (related != null && related.isNotEmpty) {
        return related.take(20).map(_mapVideo).toList();
      }
      // Fallback: search by author or title
      return (await _yt.search.search(video.author)).take(15).map(_mapVideo).toList();
    } catch (e) {
      debugPrint('[YouTubeService] getRelatedVideos error: $e');
      return [];
    }
  }

  // 5. Comments Extraction
  static Future<List<YouTubeComment>> getComments(String videoId) async {
    try {
      final video = await _yt.videos.get(videoId);
      // ignore: deprecated_member_use
      final commentsList = await _yt.videos.commentsClient.getComments(video);
      if (commentsList == null) return [];

      final List<YouTubeComment> comments = [];
      for (final c in commentsList.take(40)) {
        comments.add(
          YouTubeComment(
            id: c.channelId.value,
            author: c.author,
            channelId: c.channelId.value,
            avatarUrl: 'https://www.youtube.com/favicon.ico',
            text: c.text,
            publishedTime: c.publishedTime,
            likeCountFormatted: formatViews(c.likeCount),
            replyCount: c.replyCount,
            isHearted: c.isHearted,
            isPinned: false,
          ),
        );
      }
      return comments;
    } catch (e) {
      debugPrint('[YouTubeService] getComments error: $e');
      return [];
    }
  }

  // 6. Direct Stream Resolution (Video & Audio)
  static Future<StreamResult?> resolveStreams(String videoId) async {
    try {
      final manifest = await _yt.videos.streamsClient.getManifest(videoId);

      // Best muxed stream (contains both video and audio in MP4)
      final muxedStreams = manifest.muxed.sortByVideoQuality();
      String? bestVideoUrl;
      final resolutions = <String>[];

      for (final stream in muxedStreams) {
        resolutions.add(stream.videoQuality.name);
      }

      if (muxedStreams.isNotEmpty) {
        bestVideoUrl = muxedStreams.first.url.toString();
      } else if (manifest.videoOnly.isNotEmpty) {
        bestVideoUrl = manifest.videoOnly.sortByVideoQuality().first.url.toString();
      }

      // Best audio stream
      final audioStreams = manifest.audioOnly.sortByBitrate();
      String? bestAudioUrl;
      if (audioStreams.isNotEmpty) {
        bestAudioUrl = audioStreams.first.url.toString();
      } else if (bestVideoUrl != null) {
        bestAudioUrl = bestVideoUrl;
      }

      if (bestVideoUrl == null && bestAudioUrl == null) return null;

      return StreamResult(
        videoUrl: bestVideoUrl ?? bestAudioUrl!,
        audioUrl: bestAudioUrl ?? bestVideoUrl!,
        availableResolutions: resolutions,
      );
    } catch (e) {
      debugPrint('[YouTubeService] resolveStreams error: $e');
      return null;
    }
  }

  // Fallback initial feed in case of network throttle
  static List<YouTubeVideo> _getFallbackVideos() {
    return [
      YouTubeVideo(
        id: 'dQw4w9WgXcQ',
        title: 'Rick Astley - Never Gonna Give You Up (Official Music Video)',
        author: 'Rick Astley',
        channelId: 'UCuAXFkgsw1L7xaCfnd5JJOw',
        thumbnailUrl: 'https://i.ytimg.com/vi/dQw4w9WgXcQ/hqdefault.jpg',
        duration: const Duration(minutes: 3, seconds: 33),
        durationString: '3:33',
        viewCount: 1500000000,
        viewCountFormatted: '1.5B views',
        uploadDate: '2009-10-25',
        description: 'The official video for “Never Gonna Give You Up” by Rick Astley',
      ),
      YouTubeVideo(
        id: 'L_LUpnjgPso',
        title: 'Flutter in 100 Seconds',
        author: 'Fireship',
        channelId: 'UCsBjURrPoezykLs9EqgamOA',
        thumbnailUrl: 'https://i.ytimg.com/vi/L_LUpnjgPso/hqdefault.jpg',
        duration: const Duration(minutes: 2, seconds: 15),
        durationString: '2:15',
        viewCount: 1200000,
        viewCountFormatted: '1.2M views',
        uploadDate: '2021-08-12',
        description: 'Learn Flutter, Google’s multi-platform UI toolkit.',
      ),
    ];
  }
}
