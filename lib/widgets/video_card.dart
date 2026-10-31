import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:provider/provider.dart';
import '../models/youtube_video.dart';
import '../theme/aura_theme.dart';
import '../services/storage_service.dart';
import '../services/download_service.dart';
import '../services/player_service.dart';

class VideoCard extends StatelessWidget {
  final YouTubeVideo video;
  final VoidCallback onTap;

  const VideoCard({
    super.key,
    required this.video,
    required this.onTap,
  });

  void _showVideoOptions(BuildContext context) {
    final storage = context.read<StorageService>();
    final downloader = context.read<DownloadService>();
    final player = context.read<PlayerService>();

    showModalBottomSheet(
      context: context,
      backgroundColor: AuraColors.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (ctx) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 40,
                height: 4,
                margin: const EdgeInsets.only(bottom: 16),
                decoration: BoxDecoration(
                  color: AuraColors.textMuted.withValues(alpha: 0.4),
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              Row(
                children: [
                  ClipRRect(
                    borderRadius: BorderRadius.circular(10),
                    child: CachedNetworkImage(
                      imageUrl: video.thumbnailUrl,
                      width: 70,
                      height: 42,
                      fit: BoxFit.cover,
                      errorWidget: (_, url, error) => Container(
                        color: AuraColors.surfaceHigh,
                        child: const Icon(Icons.broken_image, size: 20),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          video.title,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            color: AuraColors.textPrimary,
                            fontWeight: FontWeight.bold,
                            fontSize: 14,
                          ),
                        ),
                        Text(
                          video.author,
                          style: const TextStyle(
                            color: AuraColors.textMuted,
                            fontSize: 12,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const Divider(color: AuraColors.outline, height: 24),
              ListTile(
                leading: const FaIcon(FontAwesomeIcons.headphones, color: AuraColors.primaryBlueLight, size: 20),
                title: const Text('Play in Background', style: TextStyle(color: AuraColors.textPrimary)),
                onTap: () {
                  Navigator.pop(ctx);
                  player.playBackgroundAudio(video);
                },
              ),
              ListTile(
                leading: const FaIcon(FontAwesomeIcons.download, color: AuraColors.accentCyan, size: 20),
                title: const Text('Download Video (MP4)', style: TextStyle(color: AuraColors.textPrimary)),
                onTap: () {
                  Navigator.pop(ctx);
                  downloader.downloadVideo(video);
                  storage.addDownload(video);
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('Downloading "${video.title}"...'),
                      backgroundColor: AuraColors.surfaceHigh,
                    ),
                  );
                },
              ),
              ListTile(
                leading: const FaIcon(FontAwesomeIcons.music, color: AuraColors.primaryBlue, size: 20),
                title: const Text('Download Audio Only (M4A)', style: TextStyle(color: AuraColors.textPrimary)),
                onTap: () {
                  Navigator.pop(ctx);
                  downloader.downloadVideo(video, audioOnly: true);
                  storage.addDownload(video);
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('Downloading audio for "${video.title}"...'),
                      backgroundColor: AuraColors.surfaceHigh,
                    ),
                  );
                },
              ),
              ListTile(
                leading: FaIcon(
                  storage.isInWatchLater(video.id) ? FontAwesomeIcons.solidClock : FontAwesomeIcons.clock,
                  color: AuraColors.primaryBlueLight,
                  size: 20,
                ),
                title: Text(
                  storage.isInWatchLater(video.id) ? 'Remove from Watch Later' : 'Save to Watch Later',
                  style: const TextStyle(color: AuraColors.textPrimary),
                ),
                onTap: () {
                  Navigator.pop(ctx);
                  storage.toggleWatchLater(video);
                },
              ),
              ListTile(
                leading: FaIcon(
                  storage.isLiked(video.id) ? FontAwesomeIcons.solidThumbsUp : FontAwesomeIcons.thumbsUp,
                  color: AuraColors.primaryBlueLight,
                  size: 20,
                ),
                title: Text(
                  storage.isLiked(video.id) ? 'Remove from Liked' : 'Add to Liked',
                  style: const TextStyle(color: AuraColors.textPrimary),
                ),
                onTap: () {
                  Navigator.pop(ctx);
                  storage.toggleLike(video);
                },
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.only(bottom: 18),
        decoration: BoxDecoration(
          color: AuraColors.surface,
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: AuraColors.outline.withValues(alpha: 0.6), width: 1),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.35),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        clipBehavior: Clip.antiAlias,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Thumbnail Stack with duration pill
            Stack(
              children: [
                AspectRatio(
                  aspectRatio: 16 / 9,
                  child: CachedNetworkImage(
                    imageUrl: video.thumbnailUrl,
                    fit: BoxFit.cover,
                    placeholder: (_, url) => Container(
                      color: AuraColors.surfaceHigh,
                      child: const Center(
                        child: FaIcon(FontAwesomeIcons.youtube, color: AuraColors.outline, size: 36),
                      ),
                    ),
                    errorWidget: (_, url, error) => Container(
                      color: AuraColors.surfaceHigh,
                      child: const Center(
                        child: FaIcon(FontAwesomeIcons.circleExclamation, color: AuraColors.textMuted, size: 28),
                      ),
                    ),
                  ),
                ),
                Positioned(
                  bottom: 8,
                  right: 8,
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: Colors.black.withValues(alpha: 0.82),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: AuraColors.outline.withValues(alpha: 0.4), width: 0.8),
                    ),
                    child: Text(
                      video.durationString,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 11,
                        fontWeight: FontWeight.bold,
                        letterSpacing: 0.4,
                      ),
                    ),
                  ),
                ),
              ],
            ),

            // Video Meta Row
            Padding(
              padding: const EdgeInsets.all(12),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Channel Avatar Avatar
                  Container(
                    width: 38,
                    height: 38,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      gradient: const LinearGradient(
                        colors: [AuraColors.primaryBlue, AuraColors.accentCyan],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                      border: Border.all(color: AuraColors.accentCyan.withValues(alpha: 0.4), width: 1.2),
                    ),
                    child: Center(
                      child: Text(
                        video.author.isNotEmpty ? video.author[0].toUpperCase() : 'Y',
                        style: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),

                  // Video Title & Channel / Views
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          video.title,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            color: AuraColors.textPrimary,
                            fontSize: 14,
                            fontWeight: FontWeight.w700,
                            height: 1.25,
                          ),
                        ),
                        const SizedBox(height: 5),
                        Text(
                          '${video.author} • ${video.viewCountFormatted} • ${video.uploadDate}',
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            color: AuraColors.textMuted,
                            fontSize: 12,
                          ),
                        ),
                      ],
                    ),
                  ),

                  // 3-dots Menu Button
                  IconButton(
                    icon: const FaIcon(FontAwesomeIcons.ellipsisVertical, color: AuraColors.textSecondary, size: 14),
                    padding: EdgeInsets.zero,
                    constraints: const BoxConstraints(),
                    onPressed: () => _showVideoOptions(context),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
