import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:provider/provider.dart';
import 'package:flutter/services.dart';
import '../models/song.dart';
import '../providers/player_provider.dart';
import '../services/download_service.dart';
import '../theme/ember_theme.dart';
import '../screens/aura_video_player_screen.dart';

class AuraVideoCard extends StatelessWidget {
  final Song video;
  final VoidCallback? onTap;

  const AuraVideoCard({
    super.key,
    required this.video,
    this.onTap,
  });

  void _showContextMenu(BuildContext context, PlayerProvider player) {
    showModalBottomSheet(
      context: context,
      backgroundColor: EmberColors.surfaceContainerLow,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 40,
                height: 4,
                margin: const EdgeInsets.only(bottom: 12),
                decoration: BoxDecoration(
                  color: EmberColors.textMuted.withValues(alpha: 0.3),
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              ListTile(
                leading: Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: EmberColors.primaryBlue.withValues(alpha: 0.15),
                    shape: BoxShape.circle,
                  ),
                  child: const FaIcon(FontAwesomeIcons.headphones, size: 14, color: EmberColors.primaryBlue),
                ),
                title: const Text('Play in Background (Audio Only)', style: TextStyle(color: EmberColors.textPrimary, fontSize: 14, fontWeight: FontWeight.w600)),
                subtitle: const Text('Saves 80%+ data & plays with screen off', style: TextStyle(color: EmberColors.textMuted, fontSize: 11)),
                onTap: () {
                  Navigator.pop(ctx);
                  player.playSong(video);
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('Playing "${video.title}" in background audio mode'),
                      backgroundColor: EmberColors.surfaceContainerHigh,
                      duration: const Duration(seconds: 2),
                    ),
                  );
                },
              ),
              ListTile(
                leading: Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: EmberColors.secondaryCyan.withValues(alpha: 0.15),
                    shape: BoxShape.circle,
                  ),
                  child: const FaIcon(FontAwesomeIcons.film, size: 14, color: EmberColors.secondaryCyan),
                ),
                title: const Text('Download Video (MP4)', style: TextStyle(color: EmberColors.textPrimary, fontSize: 14, fontWeight: FontWeight.w600)),
                subtitle: const Text('Full HD/720p with audio directly to device', style: TextStyle(color: EmberColors.textMuted, fontSize: 11)),
                onTap: () async {
                  Navigator.pop(ctx);
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('Downloading video "${video.title}"...'),
                      backgroundColor: EmberColors.surfaceContainerHigh,
                    ),
                  );
                  await DownloadService.downloadVideo(video);
                },
              ),
              ListTile(
                leading: Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: EmberColors.primaryBlueHi.withValues(alpha: 0.15),
                    shape: BoxShape.circle,
                  ),
                  child: const FaIcon(FontAwesomeIcons.download, size: 14, color: EmberColors.primaryBlueHi),
                ),
                title: const Text('Download Audio (M4A)', style: TextStyle(color: EmberColors.textPrimary, fontSize: 14, fontWeight: FontWeight.w600)),
                subtitle: const Text('High-bitrate audio for offline listening', style: TextStyle(color: EmberColors.textMuted, fontSize: 11)),
                onTap: () async {
                  Navigator.pop(ctx);
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('Downloading audio "${video.title}"...'),
                      backgroundColor: EmberColors.surfaceContainerHigh,
                    ),
                  );
                  await player.downloadAudio(video);
                },
              ),
              ListTile(
                leading: Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.1),
                    shape: BoxShape.circle,
                  ),
                  child: const FaIcon(FontAwesomeIcons.shareNodes, size: 14, color: EmberColors.textPrimary),
                ),
                title: const Text('Share Video Link', style: TextStyle(color: EmberColors.textPrimary, fontSize: 14, fontWeight: FontWeight.w600)),
                onTap: () {
                  Navigator.pop(ctx);
                  final url = 'https://www.youtube.com/watch?v=${video.id}';
                  Clipboard.setData(ClipboardData(text: url));
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('YouTube video link copied to clipboard!'),
                      backgroundColor: EmberColors.surfaceContainerHigh,
                    ),
                  );
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
    final player = Provider.of<PlayerProvider>(context, listen: false);

    return InkWell(
      onTap: onTap ??
          () {
            Navigator.of(context).push(
              MaterialPageRoute(
                builder: (_) => AuraVideoPlayerScreen(video: video),
              ),
            );
          },
      child: Padding(
        padding: const EdgeInsets.only(bottom: 20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // 1. 16:9 Cinematic Video Thumbnail
            AspectRatio(
              aspectRatio: 16 / 9,
              child: Stack(
                children: [
                  Positioned.fill(
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(16),
                      child: CachedNetworkImage(
                        imageUrl: video.artworkUrl.isNotEmpty
                            ? video.artworkUrl
                            : 'https://i.ytimg.com/vi/${video.id}/hqdefault.jpg',
                        fit: BoxFit.cover,
                        placeholder: (ctx, url) => Container(
                          color: EmberColors.surfaceContainer,
                          child: const Center(
                            child: SizedBox(
                              width: 24,
                              height: 24,
                              child: CircularProgressIndicator(strokeWidth: 2, color: EmberColors.primaryBlue),
                            ),
                          ),
                        ),
                        errorWidget: (ctx, url, err) => Container(
                          color: EmberColors.surfaceContainer,
                          child: const Center(
                            child: FaIcon(FontAwesomeIcons.youtube, size: 36, color: EmberColors.textMuted),
                          ),
                        ),
                      ),
                    ),
                  ),

                  // Luminous gradient sheen
                  Positioned.fill(
                    child: Container(
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(16),
                        gradient: LinearGradient(
                          begin: Alignment.topCenter,
                          end: Alignment.bottomCenter,
                          colors: [
                            Colors.transparent,
                            Colors.transparent,
                            Colors.black.withValues(alpha: 0.65),
                          ],
                        ),
                      ),
                    ),
                  ),

                  // Duration Pill Badge
                  Positioned(
                    right: 10,
                    bottom: 10,
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
                      decoration: BoxDecoration(
                        color: Colors.black.withValues(alpha: 0.85),
                        borderRadius: BorderRadius.circular(6),
                        border: Border.all(color: Colors.white.withValues(alpha: 0.15), width: 0.8),
                      ),
                      child: Text(
                        video.formattedDuration,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 11,
                          fontWeight: FontWeight.w700,
                          letterSpacing: 0.5,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 12),

            // 2. Video Details Row (Avatar + Title + Subtitle + 3-dot context)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 4),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Channel Avatar (Generated or letter fallback)
                  Container(
                    width: 38,
                    height: 38,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      gradient: const LinearGradient(
                        colors: [EmberColors.primaryBlue, EmberColors.secondaryCyan],
                      ),
                      border: Border.all(color: EmberColors.surfaceContainerHigh, width: 1.5),
                    ),
                    alignment: Alignment.center,
                    child: Text(
                      video.artist.isNotEmpty ? video.artist[0].toUpperCase() : 'A',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 15,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),

                  // Title & Metadata
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          video.title,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            color: EmberColors.textPrimary,
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                            height: 1.25,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Row(
                          children: [
                            Flexible(
                              child: Text(
                                video.artist,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: const TextStyle(
                                  color: EmberColors.textSecondary,
                                  fontSize: 12,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ),
                            if (video.formattedViews.isNotEmpty) ...[
                              const Padding(
                                padding: EdgeInsets.symmetric(horizontal: 4),
                                child: Text('•', style: TextStyle(color: EmberColors.textMuted, fontSize: 11)),
                              ),
                              Text(
                                video.formattedViews,
                                style: const TextStyle(
                                  color: EmberColors.textMuted,
                                  fontSize: 12,
                                ),
                              ),
                            ],
                            if (video.uploadDateFormatted != null && video.uploadDateFormatted!.isNotEmpty) ...[
                              const Padding(
                                padding: EdgeInsets.symmetric(horizontal: 4),
                                child: Text('•', style: TextStyle(color: EmberColors.textMuted, fontSize: 11)),
                              ),
                              Text(
                                video.uploadDateFormatted!,
                                style: const TextStyle(
                                  color: EmberColors.textMuted,
                                  fontSize: 12,
                                ),
                              ),
                            ],
                          ],
                        ),
                      ],
                    ),
                  ),

                  // 3-Dot Context Menu
                  IconButton(
                    icon: const FaIcon(FontAwesomeIcons.ellipsisVertical, size: 14, color: EmberColors.textMuted),
                    onPressed: () => _showContextMenu(context, player),
                    padding: EdgeInsets.zero,
                    constraints: const BoxConstraints(minWidth: 32, minHeight: 32),
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
