import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import '../providers/player_provider.dart';
import '../screens/aura_video_player_screen.dart';
import '../theme/ember_theme.dart';

typedef AuraMiniPlayer = MiniPlayer;

class MiniPlayer extends StatelessWidget {
  const MiniPlayer({super.key});

  @override
  Widget build(BuildContext context) {
    final player = context.watch<PlayerProvider>();
    final song = player.currentSong;

    if (song == null) {
      return const SizedBox.shrink();
    }

    final double progress = player.duration.inMilliseconds > 0
        ? (player.position.inMilliseconds / player.duration.inMilliseconds).clamp(0.0, 1.0)
        : 0.0;

    return GestureDetector(
      onLongPress: () {
        player.stopPlayback();
      },
      onHorizontalDragEnd: (details) {
        if (details.primaryVelocity != null) {
          if (details.primaryVelocity! < -200) {
            player.skipNext();
          } else if (details.primaryVelocity! > 200) {
            player.skipPrevious();
          }
        }
      },
      onTap: () {
        Navigator.of(context).push(
          PageRouteBuilder(
            pageBuilder: (context, anim, secAnim) => AuraVideoPlayerScreen(video: song),
            transitionsBuilder: (context, anim, secAnim, child) {
              const begin = Offset(0.0, 1.0);
              const end = Offset.zero;
              const curve = Curves.easeOutCubic;
              final tween = Tween(begin: begin, end: end).chain(CurveTween(curve: curve));
              return SlideTransition(position: anim.drive(tween), child: child);
            },
          ),
        );
      },
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          color: EmberColors.surfaceContainerLow.withValues(alpha: 0.95),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: EmberColors.primaryBlue.withValues(alpha: 0.3)),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.5),
              blurRadius: 16,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        clipBehavior: Clip.antiAlias,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Electric Blue Progress Indicator
            LinearProgressIndicator(
              value: progress,
              minHeight: 2.5,
              backgroundColor: Colors.white.withValues(alpha: 0.08),
              valueColor: const AlwaysStoppedAnimation<Color>(EmberColors.primaryBlue),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
              child: Row(
                children: [
                  // 16:9 Mini Thumbnail with Play Overlay
                  ClipRRect(
                    borderRadius: BorderRadius.circular(8),
                    child: SizedBox(
                      width: 52,
                      height: 32,
                      child: Stack(
                        fit: StackFit.expand,
                        children: [
                          CachedNetworkImage(
                            imageUrl: song.artworkUrl.isNotEmpty
                                ? song.artworkUrl
                                : 'https://i.ytimg.com/vi/${song.id}/hqdefault.jpg',
                            fit: BoxFit.cover,
                            placeholder: (context, url) => Container(color: EmberColors.surfaceContainer),
                            errorWidget: (context, url, error) => Container(
                              color: EmberColors.surfaceContainer,
                              child: const Center(
                                child: FaIcon(FontAwesomeIcons.youtube, size: 14, color: EmberColors.primaryBlue),
                              ),
                            ),
                          ),
                          Container(
                            color: Colors.black.withValues(alpha: 0.25),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(width: 10),

                  // Title and Channel Name
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          song.title,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            color: EmberColors.textPrimary,
                            fontSize: 12.5,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 1),
                              decoration: BoxDecoration(
                                color: EmberColors.primaryBlue.withValues(alpha: 0.2),
                                borderRadius: BorderRadius.circular(4),
                              ),
                              child: const Text(
                                'AUDIO MODE',
                                style: TextStyle(
                                  color: EmberColors.secondaryCyan,
                                  fontSize: 8.5,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                            const SizedBox(width: 6),
                            Flexible(
                              child: Text(
                                song.artist,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: const TextStyle(
                                  color: EmberColors.textMuted,
                                  fontSize: 11,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),

                  // Controls
                  IconButton(
                    iconSize: 20,
                    icon: FaIcon(
                      player.isPlaying ? FontAwesomeIcons.pause : FontAwesomeIcons.play,
                      color: EmberColors.textPrimary,
                      size: 16,
                    ),
                    onPressed: () {
                      if (player.isPlaying) {
                        player.pause();
                      } else {
                        player.resume();
                      }
                    },
                  ),
                  IconButton(
                    iconSize: 18,
                    icon: const FaIcon(
                      FontAwesomeIcons.xmark,
                      color: EmberColors.textMuted,
                      size: 15,
                    ),
                    onPressed: () {
                      player.stopPlayback();
                    },
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
