import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:provider/provider.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../providers/player_provider.dart';
import '../theme/ember_theme.dart';
import 'aura_video_player_screen.dart';

/// Metrolist-inspired Listening Insights, Telemetry & Top Charts Dashboard
class StatsScreen extends StatelessWidget {
  const StatsScreen({super.key});

  static void open(BuildContext context) {
    Navigator.of(context).push(
      MaterialPageRoute(builder: (_) => const StatsScreen()),
    );
  }

  String _formatDuration(int totalSeconds) {
    if (totalSeconds < 60) return '${totalSeconds}s';
    final mins = totalSeconds ~/ 60;
    if (mins < 60) return '${mins}m';
    final hrs = mins ~/ 60;
    final remMins = mins % 60;
    return '${hrs}h ${remMins}m';
  }

  @override
  Widget build(BuildContext context) {
    final player = context.watch<PlayerProvider>();
    final totalPlays = player.playCounts.values.fold<int>(0, (a, b) => a + b);
    final topArtists = player.topArtists;
    final topSongs = player.topSongs;
    final maxArtistCount = topArtists.isNotEmpty ? topArtists.first.value : 1;

    return Scaffold(
      backgroundColor: EmberColors.obsidianBase,
      appBar: AppBar(
        backgroundColor: EmberColors.obsidianBase,
        elevation: 0,
        leading: IconButton(
          icon: const FaIcon(FontAwesomeIcons.arrowLeft, size: 17, color: EmberColors.monoWhite),
          onPressed: () => Navigator.of(context).pop(),
        ),
        title: const Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Insights & Stats',
              style: TextStyle(color: EmberColors.textPrimary, fontSize: 17, fontWeight: FontWeight.w700),
            ),
            Text(
              'OFFLINE LOCAL TELEMETRY · ZERO TRACKING',
              style: TextStyle(color: EmberColors.textMuted, fontSize: 9.5, letterSpacing: 0.9, fontWeight: FontWeight.w700),
            ),
          ],
        ),
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 12, 16, 40),
        children: [
          // 2x2 Architectural Monochrome Bento Grid
          Row(
            children: [
              Expanded(
                child: _MetricCard(
                  icon: FontAwesomeIcons.clock,
                  label: 'LISTEN TIME',
                  value: _formatDuration(player.totalListeningSeconds),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: _MetricCard(
                  icon: FontAwesomeIcons.play,
                  label: 'TOTAL PLAYS',
                  value: '$totalPlays',
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              Expanded(
                child: _MetricCard(
                  icon: FontAwesomeIcons.forwardFast,
                  label: 'SPONSORS SKIPPED',
                  value: '${player.sponsorSegmentsSkipped}',
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: _MetricCard(
                  icon: FontAwesomeIcons.waveSquare,
                  label: 'SONGS DETECTED',
                  value: '${player.recognitionHistory.length}',
                ),
              ),
            ],
          ),

          const SizedBox(height: 24),
          const Text(
            'TOP CREATORS & ARTISTS',
            style: TextStyle(color: EmberColors.textMuted, fontSize: 11, letterSpacing: 1.2, fontWeight: FontWeight.w700),
          ),
          const SizedBox(height: 10),
          if (topArtists.isEmpty)
            const _EmptyBlock(text: 'Play videos or music to build your private local charts.')
          else
            Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: EmberColors.surfaceContainerLow,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: EmberColors.outlineVariant),
              ),
              child: Column(
                children: [
                  for (int i = 0; i < topArtists.length; i++) ...[
                    Padding(
                      padding: const EdgeInsets.symmetric(vertical: 7),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              SizedBox(
                                width: 22,
                                child: Text(
                                  '${i + 1}.',
                                  style: const TextStyle(color: EmberColors.textMuted, fontSize: 12, fontWeight: FontWeight.w700),
                                ),
                              ),
                              Expanded(
                                child: Text(
                                  topArtists[i].key,
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: const TextStyle(color: EmberColors.textPrimary, fontSize: 13.5, fontWeight: FontWeight.w600),
                                ),
                              ),
                              Text(
                                '${topArtists[i].value} plays',
                                style: const TextStyle(color: EmberColors.textSecondary, fontSize: 11.5, fontWeight: FontWeight.w600),
                              ),
                            ],
                          ),
                          const SizedBox(height: 6),
                          ClipRRect(
                            borderRadius: BorderRadius.circular(4),
                            child: LinearProgressIndicator(
                              value: (topArtists[i].value / maxArtistCount).clamp(0.05, 1.0),
                              minHeight: 3,
                              backgroundColor: EmberColors.surfaceContainerHigh,
                              valueColor: const AlwaysStoppedAnimation<Color>(EmberColors.monoWhite),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ],
              ),
            ),

          const SizedBox(height: 24),
          const Text(
            'MOST PLAYED VIDEOS & TRACKS',
            style: TextStyle(color: EmberColors.textMuted, fontSize: 11, letterSpacing: 1.2, fontWeight: FontWeight.w700),
          ),
          const SizedBox(height: 10),
          if (topSongs.isEmpty)
            const _EmptyBlock(text: 'Your most-played tracks will appear here automatically.')
          else
            for (final song in topSongs)
              Container(
                margin: const EdgeInsets.only(bottom: 8),
                decoration: BoxDecoration(
                  color: EmberColors.surfaceContainerLow,
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: EmberColors.outlineVariant),
                ),
                child: ListTile(
                  leading: ClipRRect(
                    borderRadius: BorderRadius.circular(8),
                    child: CachedNetworkImage(
                      imageUrl: song.artworkUrl.isNotEmpty
                          ? song.artworkUrl
                          : 'https://i.ytimg.com/vi/${song.id}/hqdefault.jpg',
                      width: 56,
                      height: 38,
                      fit: BoxFit.cover,
                      errorWidget: (context, url, error) => Container(
                        width: 56,
                        height: 38,
                        color: EmberColors.surfaceContainerHigh,
                        child: const Center(child: FaIcon(FontAwesomeIcons.play, size: 12, color: EmberColors.textMuted)),
                      ),
                    ),
                  ),
                  title: Text(
                    song.title,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(color: EmberColors.textPrimary, fontSize: 13, fontWeight: FontWeight.w600),
                  ),
                  subtitle: Text(
                    '${song.artist} • ${player.playCounts[song.id] ?? 1} plays',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(color: EmberColors.textMuted, fontSize: 11.5),
                  ),
                  onTap: () {
                    Navigator.of(context).push(
                      MaterialPageRoute(builder: (_) => AuraVideoPlayerScreen(video: song)),
                    );
                  },
                ),
              ),
        ],
      ),
    );
  }
}

class _MetricCard extends StatelessWidget {
  final FaIconData icon;
  final String label;
  final String value;

  const _MetricCard({
    required this.icon,
    required this.label,
    required this.value,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: EmberColors.surfaceContainerLow,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: EmberColors.outlineVariant),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          FaIcon(icon, size: 14, color: EmberColors.monoSilver),
          const SizedBox(height: 12),
          Text(
            value,
            style: const TextStyle(
              color: EmberColors.monoWhite,
              fontSize: 24,
              fontWeight: FontWeight.w800,
              letterSpacing: -0.6,
            ),
          ),
          const SizedBox(height: 3),
          Text(
            label,
            style: const TextStyle(
              color: EmberColors.textMuted,
              fontSize: 9.5,
              fontWeight: FontWeight.w700,
              letterSpacing: 1.0,
            ),
          ),
        ],
      ),
    );
  }
}

class _EmptyBlock extends StatelessWidget {
  final String text;
  const _EmptyBlock({required this.text});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: EmberColors.surfaceContainerLow,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: EmberColors.outlineVariant),
      ),
      child: Text(
        text,
        textAlign: TextAlign.center,
        style: const TextStyle(color: EmberColors.textMuted, fontSize: 12.5),
      ),
    );
  }
}
