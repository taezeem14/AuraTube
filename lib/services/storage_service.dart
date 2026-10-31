import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/youtube_video.dart';
import '../models/subscription.dart';

class StorageService extends ChangeNotifier {
  static const String _keySubscriptions = 'auratube_subscriptions';
  static const String _keyHistory = 'auratube_history';
  static const String _keyLiked = 'auratube_liked';
  static const String _keyWatchLater = 'auratube_watch_later';
  static const String _keyDownloads = 'auratube_downloads';

  late SharedPreferences _prefs;
  bool _initialized = false;

  final List<LocalSubscription> _subscriptions = [];
  final List<YouTubeVideo> _history = [];
  final List<YouTubeVideo> _likedVideos = [];
  final List<YouTubeVideo> _watchLater = [];
  final List<YouTubeVideo> _downloads = [];

  List<LocalSubscription> get subscriptions => List.unmodifiable(_subscriptions);
  List<YouTubeVideo> get history => List.unmodifiable(_history);
  List<YouTubeVideo> get likedVideos => List.unmodifiable(_likedVideos);
  List<YouTubeVideo> get watchLater => List.unmodifiable(_watchLater);
  List<YouTubeVideo> get downloads => List.unmodifiable(_downloads);

  Future<void> init() async {
    if (_initialized) return;
    _prefs = await SharedPreferences.getInstance();
    _loadAll();
    _initialized = true;
    notifyListeners();
  }

  void _loadAll() {
    // Subscriptions
    final subsRaw = _prefs.getStringList(_keySubscriptions) ?? [];
    _subscriptions.clear();
    for (final item in subsRaw) {
      try {
        _subscriptions.add(LocalSubscription.fromJson(jsonDecode(item) as Map<String, dynamic>));
      } catch (_) {}
    }

    // History
    final histRaw = _prefs.getStringList(_keyHistory) ?? [];
    _history.clear();
    for (final item in histRaw) {
      try {
        _history.add(YouTubeVideo.fromJson(jsonDecode(item) as Map<String, dynamic>));
      } catch (_) {}
    }

    // Liked
    final likedRaw = _prefs.getStringList(_keyLiked) ?? [];
    _likedVideos.clear();
    for (final item in likedRaw) {
      try {
        _likedVideos.add(YouTubeVideo.fromJson(jsonDecode(item) as Map<String, dynamic>));
      } catch (_) {}
    }

    // Watch Later
    final wlRaw = _prefs.getStringList(_keyWatchLater) ?? [];
    _watchLater.clear();
    for (final item in wlRaw) {
      try {
        _watchLater.add(YouTubeVideo.fromJson(jsonDecode(item) as Map<String, dynamic>));
      } catch (_) {}
    }

    // Downloads
    final dlRaw = _prefs.getStringList(_keyDownloads) ?? [];
    _downloads.clear();
    for (final item in dlRaw) {
      try {
        _downloads.add(YouTubeVideo.fromJson(jsonDecode(item) as Map<String, dynamic>));
      } catch (_) {}
    }
  }

  // Subscriptions
  bool isSubscribed(String channelId) {
    return _subscriptions.any((s) => s.channelId == channelId);
  }

  Future<void> toggleSubscription({
    required String channelId,
    required String name,
    required String avatarUrl,
    String subscriberCount = '',
  }) async {
    final index = _subscriptions.indexWhere((s) => s.channelId == channelId);
    if (index >= 0) {
      _subscriptions.removeAt(index);
    } else {
      _subscriptions.insert(
        0,
        LocalSubscription(
          channelId: channelId,
          name: name,
          avatarUrl: avatarUrl,
          subscriberCount: subscriberCount,
          subscribedAt: DateTime.now(),
        ),
      );
    }
    final rawList = _subscriptions.map((s) => jsonEncode(s.toJson())).toList();
    await _prefs.setStringList(_keySubscriptions, rawList);
    notifyListeners();
  }

  // History
  Future<void> addToHistory(YouTubeVideo video) async {
    _history.removeWhere((v) => v.id == video.id);
    _history.insert(0, video);
    if (_history.length > 200) {
      _history.removeLast();
    }
    final rawList = _history.map((v) => jsonEncode(v.toJson())).toList();
    await _prefs.setStringList(_keyHistory, rawList);
    notifyListeners();
  }

  Future<void> clearHistory() async {
    _history.clear();
    await _prefs.remove(_keyHistory);
    notifyListeners();
  }

  Future<void> removeFromHistory(String videoId) async {
    _history.removeWhere((v) => v.id == videoId);
    final rawList = _history.map((v) => jsonEncode(v.toJson())).toList();
    await _prefs.setStringList(_keyHistory, rawList);
    notifyListeners();
  }

  // Liked Videos
  bool isLiked(String videoId) {
    return _likedVideos.any((v) => v.id == videoId);
  }

  Future<void> toggleLike(YouTubeVideo video) async {
    final index = _likedVideos.indexWhere((v) => v.id == video.id);
    if (index >= 0) {
      _likedVideos.removeAt(index);
    } else {
      _likedVideos.insert(0, video);
    }
    final rawList = _likedVideos.map((v) => jsonEncode(v.toJson())).toList();
    await _prefs.setStringList(_keyLiked, rawList);
    notifyListeners();
  }

  // Watch Later
  bool isInWatchLater(String videoId) {
    return _watchLater.any((v) => v.id == videoId);
  }

  Future<void> toggleWatchLater(YouTubeVideo video) async {
    final index = _watchLater.indexWhere((v) => v.id == video.id);
    if (index >= 0) {
      _watchLater.removeAt(index);
    } else {
      _watchLater.insert(0, video);
    }
    final rawList = _watchLater.map((v) => jsonEncode(v.toJson())).toList();
    await _prefs.setStringList(_keyWatchLater, rawList);
    notifyListeners();
  }

  // Downloads tracking
  Future<void> addDownload(YouTubeVideo video) async {
    _downloads.removeWhere((v) => v.id == video.id);
    _downloads.insert(0, video);
    final rawList = _downloads.map((v) => jsonEncode(v.toJson())).toList();
    await _prefs.setStringList(_keyDownloads, rawList);
    notifyListeners();
  }
}
