import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:provider/provider.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../../models/playlist.dart';
import '../../providers/player_provider.dart';
import '../../theme/ember_theme.dart';
import '../playlist_detail_sheet.dart';

class AuraBookmarksTab extends StatelessWidget {
  const AuraBookmarksTab({super.key});

  void _showCreatePlaylistDialog(BuildContext context, PlayerProvider player) {
    final controller = TextEditingController();
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: EmberColors.surfaceContainerLow,
        title: const Text('Create New Playlist', style: TextStyle(color: EmberColors.textPrimary)),
        content: TextField(
          controller: controller,
          autofocus: true,
          style: const TextStyle(color: EmberColors.textPrimary),
          decoration: const InputDecoration(
            hintText: 'Playlist name...',
            hintStyle: TextStyle(color: EmberColors.textMuted),
            focusedBorder: UnderlineInputBorder(borderSide: BorderSide(color: EmberColors.primaryBlue)),
          ),
        ),
        actions: [
          TextButton(
            child: const Text('Cancel', style: TextStyle(color: EmberColors.textMuted)),
            onPressed: () => Navigator.pop(ctx),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: EmberColors.primaryBlue),
            child: const Text('Create'),
            onPressed: () {
              final name = controller.text.trim();
              if (name.isNotEmpty) {
                player.createPlaylist(name);
                Navigator.pop(ctx);
              }
            },
          ),
        ],
      ),
    );
  }

  void _showImportPlaylistDialog(BuildContext context, PlayerProvider player) {
    final controller = TextEditingController();
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: EmberColors.surfaceContainerLow,
        title: const Text('Import YouTube Playlist', style: TextStyle(color: EmberColors.textPrimary)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Paste a YouTube playlist link or ID to bookmark and save it for instant offline/online playback:',
              style: TextStyle(color: EmberColors.textMuted, fontSize: 12),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: controller,
              autofocus: true,
              style: const TextStyle(color: EmberColors.textPrimary, fontSize: 13),
              decoration: const InputDecoration(
                hintText: 'https://youtube.com/playlist?list=...',
                hintStyle: TextStyle(color: EmberColors.textMuted, fontSize: 12),
                focusedBorder: UnderlineInputBorder(borderSide: BorderSide(color: EmberColors.primaryBlue)),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            child: const Text('Cancel', style: TextStyle(color: EmberColors.textMuted)),
            onPressed: () => Navigator.pop(ctx),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: EmberColors.primaryBlue),
            child: const Text('Import'),
            onPressed: () async {
              final url = controller.text.trim();
              if (url.isNotEmpty) {
                Navigator.pop(ctx);
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Importing YouTube playlist...'),
                    backgroundColor: EmberColors.surfaceContainerHigh,
                    duration: Duration(seconds: 2),
                  ),
                );
                final res = await player.importYouTubePlaylist(url);
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text(res != null
                          ? 'Imported "${res.name}" with ${res.songs.length} tracks'
                          : 'Failed to import playlist. Verify the URL is public.'),
                      backgroundColor: EmberColors.surfaceContainerHigh,
                    ),
                  );
                }
              }
            },
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final player = context.watch<PlayerProvider>();
    final favorites = player.favorites;
    final playlists = player.playlists;

    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 80),
      children: [
        // Top Action Buttons (Create Playlist & Import YouTube Playlist)
        Row(
          children: [
            Expanded(
              child: ElevatedButton.icon(
                onPressed: () => _showCreatePlaylistDialog(context, player),
                icon: const FaIcon(FontAwesomeIcons.plus, size: 13, color: Colors.white),
                label: const Text('New Playlist', style: TextStyle(fontSize: 12.5, fontWeight: FontWeight.bold)),
                style: ElevatedButton.styleFrom(
                  backgroundColor: EmberColors.surfaceContainerHigh,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                    side: BorderSide(color: EmberColors.primaryBlue.withValues(alpha: 0.3)),
                  ),
                ),
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: ElevatedButton.icon(
                onPressed: () => _showImportPlaylistDialog(context, player),
                icon: const FaIcon(FontAwesomeIcons.youtube, size: 14, color: EmberColors.secondaryCyan),
                label: const Text('Import URL', style: TextStyle(fontSize: 12.5, fontWeight: FontWeight.bold)),
                style: ElevatedButton.styleFrom(
                  backgroundColor: EmberColors.surfaceContainerHigh,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                    side: BorderSide(color: EmberColors.secondaryCyan.withValues(alpha: 0.3)),
                  ),
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 20),

        // Default System Bookmarks: Favorites
        _BookmarkTile(
          icon: FontAwesomeIcons.heart,
          iconColor: Colors.redAccent,
          title: 'Favorites',
          subtitle: '${favorites.length} saved items',
          onTap: () {
            final pl = Playlist(
              id: 'favorites_virtual',
              title: 'Favorites',
              songs: favorites,
              createdAt: DateTime.now(),
            );
            PlaylistDetailSheet.show(context, pl);
          },
          onPlay: favorites.isNotEmpty
              ? () => player.playPlaylist(
                    Playlist(
                      id: 'favorites_virtual',
                      title: 'Favorites',
                      songs: favorites,
                      createdAt: DateTime.now(),
                    ),
                  )
              : null,
        ),
        const SizedBox(height: 10),

        // Playlists List
        if (playlists.isEmpty)
          Container(
            margin: const EdgeInsets.only(top: 30),
            padding: const EdgeInsets.all(24),
            alignment: Alignment.center,
            child: Column(
              children: [
                FaIcon(FontAwesomeIcons.bookmark, size: 36, color: EmberColors.textMuted.withValues(alpha: 0.4)),
                const SizedBox(height: 12),
                const Text(
                  'No Bookmarked Playlists',
                  style: TextStyle(color: EmberColors.textPrimary, fontSize: 15, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 6),
                const Text(
                  'Import a YouTube playlist or create custom playlists to organize your library.',
                  textAlign: TextAlign.center,
                  style: TextStyle(color: EmberColors.textMuted, fontSize: 12.5),
                ),
              ],
            ),
          )
        else ...[
          const Padding(
            padding: EdgeInsets.symmetric(vertical: 8),
            child: Text(
              'SAVED & LOCAL PLAYLISTS',
              style: TextStyle(color: EmberColors.textMuted, fontSize: 11, letterSpacing: 1.2, fontWeight: FontWeight.bold),
            ),
          ),
          for (final pl in playlists)
            Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: _BookmarkTile(
                icon: FontAwesomeIcons.listUl,
                iconColor: EmberColors.primaryBlue,
                title: pl.name,
                subtitle: '${pl.songs.length} videos',
                coverUrl: pl.coverUrl,
                onTap: () => PlaylistDetailSheet.show(context, pl),
                onPlay: pl.songs.isNotEmpty ? () => player.playPlaylist(pl) : null,
              ),
            ),
        ],
      ],
    );
  }
}

class _BookmarkTile extends StatelessWidget {
  final FaIconData icon;
  final Color iconColor;
  final String title;
  final String subtitle;
  final String? coverUrl;
  final VoidCallback onTap;
  final VoidCallback? onPlay;

  const _BookmarkTile({
    required this.icon,
    required this.iconColor,
    required this.title,
    required this.subtitle,
    this.coverUrl,
    required this.onTap,
    this.onPlay,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: EmberColors.surfaceContainerLow,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: Colors.white.withValues(alpha: 0.05)),
          ),
          child: Row(
            children: [
              ClipRRect(
                borderRadius: BorderRadius.circular(8),
                child: coverUrl != null && coverUrl!.isNotEmpty
                    ? CachedNetworkImage(
                        imageUrl: coverUrl!,
                        width: 48,
                        height: 48,
                        fit: BoxFit.cover,
                        errorWidget: (context, url, error) => Container(
                          width: 48,
                          height: 48,
                          color: EmberColors.surfaceContainerHigh,
                          child: Center(child: FaIcon(icon, size: 20, color: iconColor)),
                        ),
                      )
                    : Container(
                        width: 48,
                        height: 48,
                        color: EmberColors.surfaceContainerHigh,
                        child: Center(child: FaIcon(icon, size: 20, color: iconColor)),
                      ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: const TextStyle(
                        color: EmberColors.textPrimary,
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 3),
                    Text(
                      subtitle,
                      style: const TextStyle(color: EmberColors.textMuted, fontSize: 11.5),
                    ),
                  ],
                ),
              ),
              if (onPlay != null)
                IconButton(
                  icon: const FaIcon(FontAwesomeIcons.play, size: 14, color: EmberColors.primaryBlue),
                  onPressed: onPlay,
                ),
            ],
          ),
        ),
      ),
    );
  }
}
