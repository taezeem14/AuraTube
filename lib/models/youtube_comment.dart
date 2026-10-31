class YouTubeComment {
  final String id;
  final String author;
  final String channelId;
  final String avatarUrl;
  final String text;
  final String publishedTime;
  final String likeCountFormatted;
  final int replyCount;
  final bool isHearted;
  final bool isPinned;

  const YouTubeComment({
    required this.id,
    required this.author,
    this.channelId = '',
    this.avatarUrl = '',
    required this.text,
    this.publishedTime = 'Just now',
    this.likeCountFormatted = '0',
    this.replyCount = 0,
    this.isHearted = false,
    this.isPinned = false,
  });

  factory YouTubeComment.fromJson(Map<String, dynamic> json) => YouTubeComment(
    id: json['id'] as String? ?? '',
    author: json['author'] as String? ?? 'Anonymous',
    channelId: json['channelId'] as String? ?? '',
    avatarUrl: json['avatarUrl'] as String? ?? '',
    text: json['text'] as String? ?? '',
    publishedTime: json['publishedTime'] as String? ?? 'Recently',
    likeCountFormatted: json['likeCountFormatted'] as String? ?? '0',
    replyCount: json['replyCount'] as int? ?? 0,
    isHearted: json['isHearted'] as bool? ?? false,
    isPinned: json['isPinned'] as bool? ?? false,
  );
}
