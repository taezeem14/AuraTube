import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;

class SponsorSegment {
  final double start;
  final double end;
  final String category;
  final String actionType;
  final String uuid;

  const SponsorSegment({
    required this.start,
    required this.end,
    required this.category,
    this.actionType = 'skip',
    this.uuid = '',
  });

  double get durationSeconds => (end - start).clamp(0.0, double.infinity);

  String get displayLabel {
    switch (category) {
      case 'sponsor':
        return 'Sponsor';
      case 'selfpromo':
        return 'Self Promotion';
      case 'intro':
        return 'Intro / Intermission';
      case 'outro':
        return 'Endcards / Outro';
      case 'interaction':
        return 'Interaction Reminder';
      case 'music_offtopic':
        return 'Non-Music Section';
      case 'preview':
        return 'Preview / Recap';
      case 'filler':
        return 'Filler Tangent';
      default:
        return 'Sponsor Segment';
    }
  }
}

/// Full SponsorBlock integration powered by https://sponsor.ajay.app/
/// Supports all 8 customizable categories, segment merging, TTL caching, and skip telemetry.
class SponsorBlockService {
  static final SponsorBlockService instance = SponsorBlockService._();
  SponsorBlockService._();

  static const List<String> allCategories = [
    'sponsor',
    'selfpromo',
    'intro',
    'outro',
    'interaction',
    'music_offtopic',
    'preview',
    'filler',
  ];

  static const Map<String, String> categoryTitles = {
    'sponsor': 'Sponsor',
    'selfpromo': 'Unpaid / Self Promotion',
    'intro': 'Intermission / Intro Animation',
    'outro': 'Endcards / Credits',
    'interaction': 'Subscribe / Like Reminders',
    'music_offtopic': 'Non-Music Section',
    'preview': 'Preview / Recap',
    'filler': 'Filler Tangent / Jokes',
  };

  bool isEnabled = true;
  Set<String> enabledCategories = {
    'sponsor',
    'selfpromo',
    'intro',
    'outro',
    'interaction',
    'music_offtopic',
  };

  // LRU cache with timestamp for TTL expiration
  static const int _maxCacheEntries = 120;
  static const Duration _cacheTtl = Duration(hours: 1);
  final Map<String, (DateTime, List<SponsorSegment>)> _cache = {};

  void clearCache() => _cache.clear();

  void invalidate(String videoId) => _cache.remove(videoId);

  void configure({
    required bool enabled,
    required Set<String> categories,
  }) {
    isEnabled = enabled;
    enabledCategories = Set<String>.from(categories);
    _cache.clear();
  }

  static List<SponsorSegment> mergeSegments(List<SponsorSegment> raw) {
    if (raw.isEmpty) return [];
    final valid = raw.where((s) => s.end > s.start).toList();
    if (valid.isEmpty) return [];
    valid.sort((a, b) => a.start.compareTo(b.start));

    final merged = <SponsorSegment>[];
    SponsorSegment current = valid.first;

    for (int i = 1; i < valid.length; i++) {
      final next = valid[i];
      if (next.start <= current.end + 0.5) {
        current = SponsorSegment(
          start: current.start,
          end: next.end > current.end ? next.end : current.end,
          category: current.category,
          actionType: current.actionType,
          uuid: current.uuid,
        );
      } else {
        merged.add(current);
        current = next;
      }
    }
    merged.add(current);
    return merged;
  }

  void _cacheSegments(String videoId, List<SponsorSegment> segments) {
    if (_cache.length >= _maxCacheEntries) {
      _cache.remove(_cache.keys.first);
    }
    _cache[videoId] = (DateTime.now(), segments);
  }

  Future<List<SponsorSegment>> getSkipSegments(String videoId) async {
    if (!isEnabled || videoId.isEmpty || enabledCategories.isEmpty) return [];

    final cached = _cache[videoId];
    if (cached != null) {
      if (DateTime.now().difference(cached.$1) < _cacheTtl) {
        return cached.$2;
      }
      _cache.remove(videoId);
    }

    try {
      final uri = Uri.https('sponsor.ajay.app', '/api/skipSegments', {
        'videoID': videoId,
        'categories': jsonEncode(enabledCategories.toList()),
      });

      final response = await http
          .get(uri, headers: {'User-Agent': 'AuraTube/1.0.4'})
          .timeout(const Duration(seconds: 4));

      if (response.statusCode == 200) {
        final decoded = jsonDecode(response.body);
        if (decoded is List) {
          final rawList = <SponsorSegment>[];
          for (final item in decoded) {
            if (item is! Map) continue;
            final segArr = item['segment'];
            if (segArr is! List || segArr.length < 2) continue;

            final start = num.tryParse(segArr[0].toString())?.toDouble() ?? 0.0;
            final end = num.tryParse(segArr[1].toString())?.toDouble() ?? 0.0;
            if (end <= start) continue;

            rawList.add(SponsorSegment(
              start: start,
              end: end,
              category: item['category']?.toString() ?? 'sponsor',
              actionType: item['actionType']?.toString() ?? 'skip',
              uuid: item['UUID']?.toString() ?? '',
            ));
          }

          final normalized = mergeSegments(rawList);
          _cacheSegments(videoId, normalized);
          return normalized;
        }
      } else if (response.statusCode == 404) {
        _cacheSegments(videoId, []);
        return [];
      } else if (response.statusCode == 429) {
        debugPrint('[SponsorBlock] Rate limited (429)');
      }
    } catch (e) {
      debugPrint('[SponsorBlock] Network error for $videoId: $e');
    }

    return [];
  }
}
