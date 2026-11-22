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
import '../screens/lyrics_sheet.dart';
import '../screens/track_options_sheet.dart';

/// Production-Level Monochromatic Video Stream Card (NewPipe + Metrolist Aesthetic)
class AuraVideoCard extends StatelessWidget {
  final Song video;
  final VoidCallback? onTap;

  const AuraVideoCard({
    super.key,
    required this.video,
    this.onTap,
  });

  void _showContextMenu(BuildContext context, PlayerProvider player) {
    HapticFeedback.selectionClick();
    showModalBottomSheet(
      context: context,
      backgroundColor: EmberColors.surfaceContainerLow,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (ctx) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 38,
                height: 4,
                margin: const EdgeInsets.only(bottom: 14),
                decoration: BoxDecoration(
                  color: EmberColors.outline,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                child: Row(
                  children: [
                    ClipRRect(
                      borderRadius: BorderRadius.circular(8),
                      child: CachedNetworkImage(
                        imageUrl: video.artworkUrl.isNotEmpty
                            ? video.artworkUrl
                            : 'https://i.ytimg.com/vi/${video.id}/hqdefault.jpg',
                        width: 60,
                        height: 36,
                        fit: BoxFit.cover,
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
                            style: const TextStyle(color: EmberColors.textPrimary, fontSize: 13.5, fontWeight: FontWeight.w700),
                          ),
                          Text(
                            video.artist,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(color: EmberColors.textMuted, fontSize: 11.5),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              const Divider(color: EmberColors.borderSubtle, height: 20),
              _MenuActionTile(
                icon: FontAwesomeIcons.headphones,
                title: 'Play in Background (Audio)',
                subtitle: 'Screen-off playback with Priority-1000 EQ',
                onTap: () {
                  Navigator.pop(ctx);
                  player.playSong(video);
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('Playing "${video.title}" in background audio')),
                  );
                },
              ),
              _MenuActionTile(
                icon: FontAwesomeIcons.alignLeft,
                title: 'View Synced Lyrics (BetterLyrics)',
                subtitle: 'Word-by-word karaoke, translation & romanization',
                onTap: () {
                  Navigator.pop(ctx);
                  LyricsSheet.show(context, video);
                },
              ),
              _MenuActionTile(
                icon: FontAwesomeIcons.film,
                title: 'Download Video (MP4)',
                subtitle: 'Save HD video + audio offline',
                onTap: () async {
                  Navigator.pop(ctx);
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('Downloading video "${video.title}"...')),
                  );
                  await DownloadService.downloadVideo(video);
                },
              ),
              _MenuActionTile(
                icon: FontAwesomeIcons.download,
                title: 'Download Audio (M4A)',
                subtitle: 'Save high-bitrate audio offline',
                onTap: () async {
                  Navigator.pop(ctx);
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('Downloading audio "${video.title}"...')),
                  );
                  await player.downloadAudio(video);
                },
              ),
              _MenuActionTile(
                icon: FontAwesomeIcons.bookmark,
                title: 'Save to Playlist / Favorite',
                subtitle: 'Bookmark into local playlists or favorites',
                onTap: () {
                  Navigator.pop(ctx);
                  TrackOptionsSheet.show(context, video);
                },
              ),
              _MenuActionTile(
                icon: FontAwesomeIcons.shareNodes,
                title: 'Copy YouTube URL',
                subtitle: 'https://www.youtube.com/watch?v=${video.id}',
                onTap: () {
                  Navigator.pop(ctx);
                  final cleanId = video.id.startsWith('yt_') ? video.id.substring(3) : video.id;
                  Clipboard.setData(ClipboardData(text: 'https://www.youtube.com/watch?v=$cleanId'));
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Link copied to clipboard')),
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
    final cleanId = video.id.startsWith('yt_') ? video.id.substring(3) : video.id;

    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onLongPress: () => _showContextMenu(context, player),
      onTap: onTap ??
          () {
            Navigator.of(context).push(
              MaterialPageRoute(
                builder: (_) => AuraVideoPlayerScreen(video: video),
              ),
            );
          },
      child: Padding(
        padding: const EdgeInsets.only(bottom: 18),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // 1. Crisp 16:9 Thumbnail with Hairline Border & Duration Badge
            AspectRatio(
              aspectRatio: 16 / 9,
              child: Container(
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: EmberColors.hairline, width: 0.8),
                  color: EmberColors.surfaceContainerLow,
                ),
                clipBehavior: Clip.antiAlias,
                child: Stack(
                  fit: StackFit.expand,
                  children: [
                    CachedNetworkImage(
                      imageUrl: video.artworkUrl.isNotEmpty
                          ? video.artworkUrl
                          : 'https://i.ytimg.com/vi/$cleanId/hqdefault.jpg',
                      fit: BoxFit.cover,
                      placeholder: (ctx, url) => Container(
                        color: EmberColors.surfaceContainerLow,
                        child: const Center(
                          child: SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(strokeWidth: 1.8, color: EmberColors.monoSilver),
                          ),
                        ),
                      ),
                      errorWidget: (ctx, url, err) => Container(
                        color: EmberColors.surfaceContainerLow,
                        child: const Center(
                          child: FaIcon(FontAwesomeIcons.play, size: 26, color: EmberColors.textMuted),
                        ),
                      ),
                    ),
                    // Subtle Bottom Vignette
                    Positioned(
                      left: 0,
                      right: 0,
                      bottom: 0,
                      height: 48,
                      child: DecoratedBox(
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            begin: Alignment.topCenter,
                            end: Alignment.bottomCenter,
                            colors: [
                              Colors.transparent,
                              Colors.black.withValues(alpha: 0.72),
                            ],
                          ),
                        ),
                      ),
                    ),
                    // Duration Pill
                    Positioned(
                      right: 8,
                      bottom: 8,
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
                        decoration: BoxDecoration(
                          color: Colors.black.withValues(alpha: 0.86),
                          borderRadius: BorderRadius.circular(6),
                          border: Border.all(color: Colors.white.withValues(alpha: 0.14), width: 0.7),
                        ),
                        child: Text(
                          video.formattedDuration,
                          style: const TextStyle(
                            color: EmberColors.monoWhite,
                            fontSize: 10.5,
                            fontWeight: FontWeight.w700,
                            letterSpacing: 0.3,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 10),

            // 2. Video Metadata Row
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 2),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Monochrome Monogram Channel Avatar
                  Container(
                    width: 36,
                    height: 36,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: EmberColors.surfaceContainerHigh,
                      border: Border.all(color: EmberColors.outlineVariant, width: 1),
                    ),
                    alignment: Alignment.center,
                    child: Text(
                      video.artist.isNotEmpty ? video.artist[0].toUpperCase() : 'A',
                      style: const TextStyle(
                        color: EmberColors.monoWhite,
                        fontSize: 14,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ),
                  const SizedBox(width: 11),

                  // Title & Channel Metadata
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
                            height: 1.28,
                            letterSpacing: -0.15,
                          ),
                        ),
                        const SizedBox(height: 3),
                        Text(
                          [
                            video.artist,
                            if (video.formattedViews.isNotEmpty) video.formattedViews,
                            if (video.uploadDateFormatted != null && video.uploadDateFormatted!.isNotEmpty)
                              video.uploadDateFormatted!,
                          ].join(' · '),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            color: EmberColors.textMuted,
                            fontSize: 11.5,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                  ),

                  // Overflow Action Menu
                  IconButton(
                    padding: EdgeInsets.zero,
                    constraints: const BoxConstraints(minWidth: 32, minHeight: 32),
                    icon: const FaIcon(FontAwesomeIcons.ellipsisVertical, size: 14, color: EmberColors.textMuted),
                    onPressed: () => _showContextMenu(context, player),
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

class _MenuActionTile extends StatelessWidget {
  final FaIconData icon;
  final String title;
  final String subtitle;
  final VoidCallback onTap;

  const _MenuActionTile({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return ListTile(
      dense: true,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      leading: Container(
        width: 34,
        height: 34,
        decoration: BoxDecoration(
          color: EmberColors.surfaceContainerHigh,
          borderRadius: BorderRadius.circular(9),
        ),
        child: Center(child: FaIcon(icon, size: 13, color: EmberColors.monoWhite)),
      ),
      title: Text(title, style: const TextStyle(color: EmberColors.textPrimary, fontSize: 13.5, fontWeight: FontWeight.w600)),
      subtitle: Text(subtitle, maxLines: 1, overflow: TextOverflow.ellipsis, style: const TextStyle(color: EmberColors.textMuted, fontSize: 11)),
      onTap: onTap,
    );
  }
}
