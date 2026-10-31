import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:provider/provider.dart';
import '../services/storage_service.dart';
import '../models/youtube_video.dart';
import '../theme/aura_theme.dart';
import 'video_detail_screen.dart';
import 'settings_screen.dart';

class LibraryScreen extends StatelessWidget {
  const LibraryScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final storage = context.watch<StorageService>();

    return Scaffold(
      backgroundColor: AuraColors.obsidianBase,
      appBar: AppBar(
        title: const Row(
          children: [
            FaIcon(FontAwesomeIcons.folder, color: AuraColors.primaryBlueLight, size: 18),
            SizedBox(width: 10),
            Text('Library'),
          ],
        ),
        actions: [
          IconButton(
            icon: const FaIcon(FontAwesomeIcons.gear, color: AuraColors.textPrimary, size: 18),
            onPressed: () => SettingsScreen.show(context),
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        children: [
          // ==========================================
          // HISTORY SECTION
          // ==========================================
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Row(
                children: [
                  FaIcon(FontAwesomeIcons.clockRotateLeft, size: 14, color: AuraColors.accentCyan),
                  SizedBox(width: 8),
                  Text('History', style: TextStyle(color: AuraColors.textPrimary, fontWeight: FontWeight.bold, fontSize: 16)),
                ],
              ),
              if (storage.history.isNotEmpty)
                TextButton(
                  onPressed: () => storage.clearHistory(),
                  child: const Text('Clear All', style: TextStyle(color: AuraColors.textMuted, fontSize: 12)),
                ),
            ],
          ),
          const SizedBox(height: 10),
          if (storage.history.isEmpty)
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: AuraColors.surface,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: AuraColors.outline.withValues(alpha: 0.5)),
              ),
              child: const Center(
                child: Text('No watch history yet', style: TextStyle(color: AuraColors.textMuted, fontSize: 13)),
              ),
            )
          else
            SizedBox(
              height: 140,
              child: ListView.builder(
                scrollDirection: Axis.horizontal,
                itemCount: storage.history.length,
                itemBuilder: (context, i) {
                  final v = storage.history[i];
                  return GestureDetector(
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(builder: (_) => VideoDetailScreen(video: v)),
                      );
                    },
                    child: Container(
                      width: 150,
                      margin: const EdgeInsets.only(right: 12),
                      decoration: BoxDecoration(
                        color: AuraColors.surface,
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(color: AuraColors.outline.withValues(alpha: 0.5)),
                      ),
                      clipBehavior: Clip.antiAlias,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          AspectRatio(
                            aspectRatio: 16 / 9,
                            child: CachedNetworkImage(
                              imageUrl: v.thumbnailUrl,
                              fit: BoxFit.cover,
                            ),
                          ),
                          Padding(
                            padding: const EdgeInsets.all(8),
                            child: Text(
                              v.title,
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(color: AuraColors.textPrimary, fontSize: 11, fontWeight: FontWeight.bold),
                            ),
                          ),
                        ],
                      ),
                    ),
                  );
                },
              ),
            ),
          const SizedBox(height: 24),

          // ==========================================
          // ACTION TILES (Downloads, Watch Later, Liked)
          // ==========================================
          _buildLibraryTile(
            context,
            icon: FontAwesomeIcons.download,
            iconColor: AuraColors.accentCyan,
            title: 'Downloads',
            subtitle: '${storage.downloads.length} items saved locally',
            videos: storage.downloads,
          ),
          const SizedBox(height: 10),
          _buildLibraryTile(
            context,
            icon: FontAwesomeIcons.clock,
            iconColor: AuraColors.primaryBlueLight,
            title: 'Watch Later',
            subtitle: '${storage.watchLater.length} videos',
            videos: storage.watchLater,
          ),
          const SizedBox(height: 10),
          _buildLibraryTile(
            context,
            icon: FontAwesomeIcons.thumbsUp,
            iconColor: AuraColors.primaryBlue,
            title: 'Liked Videos',
            subtitle: '${storage.likedVideos.length} videos',
            videos: storage.likedVideos,
          ),
        ],
      ),
    );
  }

  Widget _buildLibraryTile(
    BuildContext context, {
    required FaIconData icon,
    required Color iconColor,
    required String title,
    required String subtitle,
    required List<YouTubeVideo> videos,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: AuraColors.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AuraColors.outline.withValues(alpha: 0.6)),
      ),
      child: ListTile(
        leading: Container(
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: iconColor.withValues(alpha: 0.15),
          ),
          child: FaIcon(icon, color: iconColor, size: 16),
        ),
        title: Text(title, style: const TextStyle(color: AuraColors.textPrimary, fontWeight: FontWeight.bold, fontSize: 14)),
        subtitle: Text(subtitle, style: const TextStyle(color: AuraColors.textMuted, fontSize: 12)),
        trailing: const FaIcon(FontAwesomeIcons.chevronRight, size: 12, color: AuraColors.textMuted),
        onTap: () {
          if (videos.isNotEmpty) {
            Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => VideoDetailScreen(video: videos.first)),
            );
          } else {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text('No $title saved yet'), backgroundColor: AuraColors.surfaceHigh),
            );
          }
        },
      ),
    );
  }
}
