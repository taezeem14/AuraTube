import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import '../providers/player_provider.dart';
import '../screens/aura_video_player_screen.dart';
import '../screens/now_playing_screen.dart';
import '../theme/ember_theme.dart';

typedef AuraMiniPlayer = MiniPlayer;

/// Production-Level Anchored Monochromatic MiniPlayer (NewPipe + Metrolist Style)
class MiniPlayer extends StatelessWidget {
  const MiniPlayer({super.key});

  @override
  Widget build(BuildContext context) {
    final player = context.watch<PlayerProvider>();
    final song = player.currentSong;

    if (song == null) {
      return const SizedBox.shrink();
    }

    final cleanId = song.id.startsWith('yt_') ? song.id.substring(3) : song.id;
    final double progress = player.duration.inMilliseconds > 0
        ? (player.position.inMilliseconds / player.duration.inMilliseconds).clamp(0.0, 1.0)
        : 0.0;

    return GestureDetector(
      onLongPress: () {
        HapticFeedback.mediumImpact();
        Navigator.of(context).push(
          MaterialPageRoute(builder: (_) => const NowPlayingScreen()),
        );
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
        decoration: BoxDecoration(
          color: EmberColors.surfaceContainerLow.withValues(alpha: 0.98),
          border: const Border(
            top: BorderSide(color: EmberColors.outlineVariant, width: 1.0),
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.75),
              blurRadius: 18,
              offset: const Offset(0, -4),
            ),
          ],
        ),
        child: SafeArea(
          top: false,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Stark White Precision Progress Line
              LinearProgressIndicator(
                value: progress,
                minHeight: 2.0,
                backgroundColor: EmberColors.surfaceContainerHigh,
                valueColor: const AlwaysStoppedAnimation<Color>(EmberColors.monoWhite),
              ),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                child: Row(
                  children: [
                    // 16:9 Mini Thumbnail
                    ClipRRect(
                      borderRadius: BorderRadius.circular(7),
                      child: SizedBox(
                        width: 54,
                        height: 34,
                        child: CachedNetworkImage(
                          imageUrl: song.artworkUrl.isNotEmpty
                              ? song.artworkUrl
                              : 'https://i.ytimg.com/vi/$cleanId/hqdefault.jpg',
                          fit: BoxFit.cover,
                          placeholder: (context, url) => Container(color: EmberColors.surfaceContainer),
                          errorWidget: (context, url, error) => Container(
                            color: EmberColors.surfaceContainer,
                            child: const Center(
                              child: FaIcon(FontAwesomeIcons.music, size: 12, color: EmberColors.monoSilver),
                            ),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),

                    // Title & Metadata
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
                              fontWeight: FontWeight.w700,
                              letterSpacing: -0.1,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Row(
                            children: [
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1),
                                decoration: BoxDecoration(
                                  color: EmberColors.monoWhite,
                                  borderRadius: BorderRadius.circular(4),
                                ),
                                child: const Text(
                                  'AUDIO',
                                  style: TextStyle(
                                    color: EmberColors.onAccent,
                                    fontSize: 8.0,
                                    fontWeight: FontWeight.w800,
                                    letterSpacing: 0.4,
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

                    // Play / Pause
                    IconButton(
                      visualDensity: VisualDensity.compact,
                      icon: FaIcon(
                        player.isPlaying ? FontAwesomeIcons.pause : FontAwesomeIcons.play,
                        color: EmberColors.monoWhite,
                        size: 15,
                      ),
                      onPressed: () {
                        HapticFeedback.selectionClick();
                        if (player.isPlaying) {
                          player.pause();
                        } else {
                          player.resume();
                        }
                      },
                    ),
                    // Next Track
                    IconButton(
                      visualDensity: VisualDensity.compact,
                      icon: const FaIcon(
                        FontAwesomeIcons.forwardStep,
                        color: EmberColors.textSecondary,
                        size: 14,
                      ),
                      onPressed: () {
                        HapticFeedback.selectionClick();
                        player.skipNext();
                      },
                    ),
                    // Close
                    IconButton(
                      visualDensity: VisualDensity.compact,
                      icon: const FaIcon(
                        FontAwesomeIcons.xmark,
                        color: EmberColors.textMuted,
                        size: 14,
                      ),
                      onPressed: () {
                        HapticFeedback.selectionClick();
                        player.stopPlayback();
                      },
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
