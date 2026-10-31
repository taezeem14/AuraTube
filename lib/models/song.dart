import 'package:flutter/foundation.dart';

@immutable
class Song {
  final String id;
  final String title;
  final String artist;
  final Duration duration;
  final String artworkUrl;
  final String streamUrl;
  final String? lyrics;
  final bool isFavorite;
  final String source;
  final String? instrumentalVideoId;
  final String? acapellaVideoId;
  
  // YouTube Video Rich Metadata
  final String? channelId;
  final String? description;
  final int? viewCount;
  final String? viewCountFormatted;
  final String? uploadDateFormatted;
  final String? videoStreamUrl;
  final String? videoQuality;

  const Song({
    required this.id,
    required this.title,
    required this.artist,
    required this.duration,
    required this.artworkUrl,
    required this.streamUrl,
    this.lyrics,
    this.isFavorite = false,
    this.source = 'youtube',
    this.instrumentalVideoId,
    this.acapellaVideoId,
    this.channelId,
    this.description,
    this.viewCount,
    this.viewCountFormatted,
    this.uploadDateFormatted,
    this.videoStreamUrl,
    this.videoQuality,
  });

  bool get isYouTube => source == 'youtube' || source.isEmpty;
  bool get isUnknown => false;

  String get formattedViews {
    if (viewCountFormatted != null && viewCountFormatted!.isNotEmpty) {
      return viewCountFormatted!;
    }
    if (viewCount != null && viewCount! > 0) {
      final v = viewCount!;
      if (v >= 1000000000) return '${(v / 1000000000).toStringAsFixed(1)}B views';
      if (v >= 1000000) return '${(v / 1000000).toStringAsFixed(1)}M views';
      if (v >= 1000) return '${(v / 1000).toStringAsFixed(1)}K views';
      return '$v views';
    }
    return '';
  }

  String get formattedDuration {
    final h = duration.inHours;
    final m = duration.inMinutes % 60;
    final s = duration.inSeconds % 60;
    if (h > 0) {
      return '$h:${m.toString().padLeft(2, '0')}:${s.toString().padLeft(2, '0')}';
    }
    return '$m:${s.toString().padLeft(2, '0')}';
  }

  Song copyWith({
    String? id,
    String? title,
    String? artist,
    Duration? duration,
    String? artworkUrl,
    String? streamUrl,
    String? lyrics,
    bool? isFavorite,
    String? source,
    String? instrumentalVideoId,
    String? acapellaVideoId,
    String? channelId,
    String? description,
    int? viewCount,
    String? viewCountFormatted,
    String? uploadDateFormatted,
    String? videoStreamUrl,
    String? videoQuality,
  }) {
    return Song(
      id: id ?? this.id,
      title: title ?? this.title,
      artist: artist ?? this.artist,
      duration: duration ?? this.duration,
      artworkUrl: artworkUrl ?? this.artworkUrl,
      streamUrl: streamUrl ?? this.streamUrl,
      lyrics: lyrics ?? this.lyrics,
      isFavorite: isFavorite ?? this.isFavorite,
      source: source ?? this.source,
      instrumentalVideoId: instrumentalVideoId ?? this.instrumentalVideoId,
      acapellaVideoId: acapellaVideoId ?? this.acapellaVideoId,
      channelId: channelId ?? this.channelId,
      description: description ?? this.description,
      viewCount: viewCount ?? this.viewCount,
      viewCountFormatted: viewCountFormatted ?? this.viewCountFormatted,
      uploadDateFormatted: uploadDateFormatted ?? this.uploadDateFormatted,
      videoStreamUrl: videoStreamUrl ?? this.videoStreamUrl,
      videoQuality: videoQuality ?? this.videoQuality,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'title': title,
      'artist': artist,
      'duration_ms': duration.inMilliseconds,
      'artwork_url': artworkUrl,
      'stream_url': streamUrl,
      'lyrics': lyrics,
      'is_favorite': isFavorite,
      'source': source,
      'instrumental_video_id': instrumentalVideoId,
      'acapella_video_id': acapellaVideoId,
      'channel_id': channelId,
      'description': description,
      'view_count': viewCount,
      'view_count_formatted': viewCountFormatted,
      'upload_date_formatted': uploadDateFormatted,
      'video_stream_url': videoStreamUrl,
      'video_quality': videoQuality,
    };
  }

  factory Song.fromMap(Map<String, dynamic> map) {
    final rawId = map['id']?.toString() ?? '';
    final rawStream = (map['stream_url'] ?? map['streamUrl'])?.toString() ?? '';
    final explicitSource = (map['source'] ?? map['sourceType'])?.toString();
    final inferredSource = (explicitSource != null && explicitSource.isNotEmpty) ? explicitSource : 'youtube';

    final durationVal = map['duration_ms'] ?? map['durationMs'];
    final int durationMs;
    if (durationVal is num) {
      durationMs = durationVal.toInt();
    } else if (durationVal != null) {
      durationMs = int.tryParse(durationVal.toString()) ?? 0;
    } else {
      durationMs = 0;
    }

    final favVal = map['is_favorite'] ?? map['isFavorite'];
    final bool isFav = favVal is bool
        ? favVal
        : (favVal == 1 || favVal == '1' || favVal == 'true');

    final rawLyrics = map['lyrics']?.toString();
    final rawInst = (map['instrumental_video_id'] ?? map['instrumentalVideoId'])?.toString();
    final rawAcap = (map['acapella_video_id'] ?? map['acapellaVideoId'])?.toString();

    final viewCountVal = map['view_count'] ?? map['viewCount'];
    final int? viewCount = viewCountVal is num
        ? viewCountVal.toInt()
        : (viewCountVal != null ? int.tryParse(viewCountVal.toString()) : null);

    return Song(
      id: rawId,
      title: map['title']?.toString() ?? 'Unknown Title',
      artist: map['artist']?.toString() ?? 'Unknown Artist',
      duration: Duration(milliseconds: durationMs.clamp(0, 86400000)),
      artworkUrl: (map['artwork_url'] ?? map['artworkUrl'])?.toString() ?? '',
      streamUrl: rawStream,
      lyrics: (rawLyrics != null && rawLyrics.trim().isNotEmpty && rawLyrics != 'null') ? rawLyrics.trim() : null,
      isFavorite: isFav,
      source: inferredSource,
      instrumentalVideoId: (rawInst != null && rawInst.isNotEmpty && rawInst != 'null') ? rawInst : null,
      acapellaVideoId: (rawAcap != null && rawAcap.isNotEmpty && rawAcap != 'null') ? rawAcap : null,
      channelId: (map['channel_id'] ?? map['channelId'])?.toString(),
      description: map['description']?.toString(),
      viewCount: viewCount,
      viewCountFormatted: (map['view_count_formatted'] ?? map['viewCountFormatted'])?.toString(),
      uploadDateFormatted: (map['upload_date_formatted'] ?? map['uploadDateFormatted'])?.toString(),
      videoStreamUrl: (map['video_stream_url'] ?? map['videoStreamUrl'])?.toString(),
      videoQuality: (map['video_quality'] ?? map['videoQuality'])?.toString(),
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is Song && runtimeType == other.runtimeType && id == other.id;

  @override
  int get hashCode => id.hashCode;

  @override
  String toString() => 'Song(id: $id, title: $title, artist: $artist)';

  /// Identifies legacy mock/placeholder tracks
  static bool isPlaceholder(Song song) {
    final t = song.title.toLowerCase();
    final a = song.artist.toLowerCase();
    final s = song.streamUrl.toLowerCase();
    final i = song.id.toLowerCase();

    if (i.startsWith('lofi_') ||
        i.startsWith('rain_') ||
        i.startsWith('jazz_') ||
        i.startsWith('fire_') ||
        i.startsWith('amb_') ||
        i.startsWith('aut_') ||
        i.startsWith('mock_')) {
      return true;
    }

    if (s.contains('soundhelix.com')) {
      return true;
    }

    if (t.contains('coffee steam') ||
        t.contains('paper notebook') ||
        t.contains('paper tape') ||
        t.contains('waterdrops on glass') ||
        t.contains('autumn rain in kyoto') ||
        t.contains('smoke & bourbon') ||
        t.contains('embers glowing soft') ||
        t.contains('constellations above') ||
        t.contains('golden leaves falling')) {
      return true;
    }

    if (a.contains('lofi coffee') ||
        a.contains('komorebi') ||
        a.contains('ember collective') ||
        a.contains('petrichor') ||
        a.contains('sora trio') ||
        a.contains('amber quartet') ||
        a.contains('cedar & pine') ||
        a.contains('solaris drift') ||
        a.contains('harvest moon')) {
      return true;
    }

    return false;
  }
}
