class YouTubeVideo {
  final String id;
  final String title;
  final String author;
  final String channelId;
  final String thumbnailUrl;
  final Duration duration;
  final String durationString;
  final int viewCount;
  final String viewCountFormatted;
  final String uploadDate;
  final String description;
  final bool isShort;
  final int likeCount;
  final List<String> tags;
  final String? streamUrl;
  final String? audioStreamUrl;

  const YouTubeVideo({
    required this.id,
    required this.title,
    required this.author,
    required this.channelId,
    required this.thumbnailUrl,
    required this.duration,
    required this.durationString,
    this.viewCount = 0,
    this.viewCountFormatted = '0 views',
    this.uploadDate = 'Recently',
    this.description = '',
    this.isShort = false,
    this.likeCount = 0,
    this.tags = const [],
    this.streamUrl,
    this.audioStreamUrl,
  });

  YouTubeVideo copyWith({
    String? streamUrl,
    String? audioStreamUrl,
    String? description,
    int? likeCount,
    List<String>? tags,
  }) {
    return YouTubeVideo(
      id: id,
      title: title,
      author: author,
      channelId: channelId,
      thumbnailUrl: thumbnailUrl,
      duration: duration,
      durationString: durationString,
      viewCount: viewCount,
      viewCountFormatted: viewCountFormatted,
      uploadDate: uploadDate,
      description: description ?? this.description,
      isShort: isShort,
      likeCount: likeCount ?? this.likeCount,
      tags: tags ?? this.tags,
      streamUrl: streamUrl ?? this.streamUrl,
      audioStreamUrl: audioStreamUrl ?? this.audioStreamUrl,
    );
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'title': title,
    'author': author,
    'channelId': channelId,
    'thumbnailUrl': thumbnailUrl,
    'durationSeconds': duration.inSeconds,
    'durationString': durationString,
    'viewCount': viewCount,
    'viewCountFormatted': viewCountFormatted,
    'uploadDate': uploadDate,
    'description': description,
    'isShort': isShort,
    'likeCount': likeCount,
  };

  factory YouTubeVideo.fromJson(Map<String, dynamic> json) => YouTubeVideo(
    id: json['id'] as String,
    title: json['title'] as String? ?? 'Untitled',
    author: json['author'] as String? ?? 'Unknown Creator',
    channelId: json['channelId'] as String? ?? '',
    thumbnailUrl: json['thumbnailUrl'] as String? ?? '',
    duration: Duration(seconds: json['durationSeconds'] as int? ?? 0),
    durationString: json['durationString'] as String? ?? '0:00',
    viewCount: json['viewCount'] as int? ?? 0,
    viewCountFormatted: json['viewCountFormatted'] as String? ?? '0 views',
    uploadDate: json['uploadDate'] as String? ?? 'Recently',
    description: json['description'] as String? ?? '',
    isShort: json['isShort'] as bool? ?? false,
    likeCount: json['likeCount'] as int? ?? 0,
  );
}
