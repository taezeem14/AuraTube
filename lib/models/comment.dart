class AuraComment {
  final String author;
  final String authorThumbnail;
  final String text;
  final int likeCount;
  final String publishedTime;
  final String? channelId;

  const AuraComment({
    required this.author,
    required this.authorThumbnail,
    required this.text,
    required this.likeCount,
    required this.publishedTime,
    this.channelId,
  });

  String get formattedLikes {
    if (likeCount >= 1000000) return '${(likeCount / 1000000).toStringAsFixed(1)}M';
    if (likeCount >= 1000) return '${(likeCount / 1000).toStringAsFixed(1)}K';
    if (likeCount > 0) return '$likeCount';
    return '';
  }
}
