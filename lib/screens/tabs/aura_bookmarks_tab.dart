import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:provider/provider.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../../models/playlist.dart';
import '../../providers/player_provider.dart';
import '../../theme/ember_theme.dart';
import '../../widgets/music_detector_sheet.dart';
import '../downloads_screen.dart';
import '../history_screen.dart';
import '../playlist_detail_sheet.dart';
import '../stats_screen.dart';

/// Production Monochromatic Unified Library Hub:
/// Playlists & Bookmarks · Local Device Audio Scanner · Audile Recognition History
class AuraBookmarksTab extends StatefulWidget {
  const AuraBookmarksTab({super.key});

  @override
  State<AuraBookmarksTab> createState() => _AuraBookmarksTabState();
}

class _AuraBookmarksTabState extends State<AuraBookmarksTab> with AutomaticKeepAliveClientMixin {
  int _sectionIndex = 0; // 0: Playlists, 1: Local Audio, 2: Audile History

  @override
  bool get wantKeepAlive => true;

  void _showCreatePlaylistDialog(BuildContext context, PlayerProvider player) {
    final controller = TextEditingController();
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: EmberColors.surfaceContainerLow,
        title: const Text('New Playlist', style: TextStyle(color: EmberColors.textPrimary, fontWeight: FontWeight.w700)),
        content: TextField(
          controller: controller,
          autofocus: true,
          style: const TextStyle(color: EmberColors.textPrimary),
          decoration: const InputDecoration(
            hintText: 'Playlist title...',
            hintStyle: TextStyle(color: EmberColors.textMuted),
            focusedBorder: UnderlineInputBorder(borderSide: BorderSide(color: EmberColors.monoWhite)),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel', style: TextStyle(color: EmberColors.textMuted)),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: EmberColors.monoWhite, foregroundColor: EmberColors.onAccent),
            onPressed: () {
              final name = controller.text.trim();
              if (name.isNotEmpty) {
                player.createPlaylist(name);
                Navigator.pop(ctx);
              }
            },
            child: const Text('Create'),
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
        title: const Text('Import YouTube Playlist', style: TextStyle(color: EmberColors.textPrimary, fontWeight: FontWeight.w700)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Paste a public YouTube playlist or Mix link to save it directly into your local library:',
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
                focusedBorder: UnderlineInputBorder(borderSide: BorderSide(color: EmberColors.monoWhite)),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel', style: TextStyle(color: EmberColors.textMuted)),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: EmberColors.monoWhite, foregroundColor: EmberColors.onAccent),
            onPressed: () async {
              final url = controller.text.trim();
              if (url.isNotEmpty) {
                Navigator.pop(ctx);
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Importing YouTube playlist...')),
                );
                final res = await player.importYouTubePlaylist(url);
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text(res != null
                          ? 'Imported "${res.title}" (${res.songs.length} items)'
                          : 'Could not import playlist. Check that the link is public.'),
                    ),
                  );
                }
              }
            },
            child: const Text('Import'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);
    final player = context.watch<PlayerProvider>();

    return Column(
      children: [
        // Monochromatic Library Segmented Switcher
        Padding(
          padding: const EdgeInsets.fromLTRB(14, 12, 14, 8),
          child: Row(
            children: [
              _SegmentChip(
                label: 'Playlists',
                icon: FontAwesomeIcons.bookmark,
                isSelected: _sectionIndex == 0,
                onTap: () => setState(() => _sectionIndex = 0),
              ),
              const SizedBox(width: 8),
              _SegmentChip(
                label: 'Local Audio',
                icon: FontAwesomeIcons.hardDrive,
                isSelected: _sectionIndex == 1,
                onTap: () {
                  setState(() => _sectionIndex = 1);
                  if (player.localSongs.isEmpty && !player.isLoadingLocal) {
                    player.scanLocalMusic();
                  }
                },
              ),
              const SizedBox(width: 8),
              _SegmentChip(
                label: 'Recognized',
                icon: FontAwesomeIcons.waveSquare,
                isSelected: _sectionIndex == 2,
                onTap: () => setState(() => _sectionIndex = 2),
              ),
            ],
          ),
        ),
        Expanded(
          child: _sectionIndex == 0
              ? _buildPlaylistsSection(context, player)
              : _sectionIndex == 1
                  ? _buildLocalAudioSection(context, player)
                  : _buildRecognitionHistorySection(context, player),
        ),
      ],
    );
  }

  Widget _buildPlaylistsSection(BuildContext context, PlayerProvider player) {
    final favorites = player.favorites;
    final playlists = player.playlists;

    return ListView(
      padding: const EdgeInsets.fromLTRB(14, 8, 14, 96),
      children: [
        // Quick Shortcuts Bento Row (Downloads, History, Insights)
        Row(
          children: [
            Expanded(
              child: _QuickShortcutTile(
                icon: FontAwesomeIcons.download,
                label: 'Downloads',
                onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const DownloadsScreen())),
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: _QuickShortcutTile(
                icon: FontAwesomeIcons.clockRotateLeft,
                label: 'History',
                onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const HistoryScreen())),
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: _QuickShortcutTile(
                icon: FontAwesomeIcons.chartSimple,
                label: 'Stats',
                onTap: () => StatsScreen.open(context),
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),

        // Create & Import Actions
        Row(
          children: [
            Expanded(
              child: ElevatedButton.icon(
                onPressed: () => _showCreatePlaylistDialog(context, player),
                icon: const FaIcon(FontAwesomeIcons.plus, size: 12),
                label: const Text('New Playlist', style: TextStyle(fontSize: 12.5, fontWeight: FontWeight.w700)),
                style: ElevatedButton.styleFrom(
                  backgroundColor: EmberColors.monoWhite,
                  foregroundColor: EmberColors.onAccent,
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: OutlinedButton.icon(
                onPressed: () => _showImportPlaylistDialog(context, player),
                icon: const FaIcon(FontAwesomeIcons.link, size: 12),
                label: const Text('Import URL', style: TextStyle(fontSize: 12.5, fontWeight: FontWeight.w700)),
                style: OutlinedButton.styleFrom(
                  foregroundColor: EmberColors.monoWhite,
                  side: const BorderSide(color: EmberColors.outline),
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 18),

        // Favorites Bookmark
        _BookmarkTile(
          icon: FontAwesomeIcons.solidHeart,
          title: 'Favorites',
          subtitle: '${favorites.length} saved items',
          onTap: () {
            PlaylistDetailSheet.show(
              context,
              Playlist(
                id: 'favorites_virtual',
                title: 'Favorites',
                songs: favorites,
                createdAt: DateTime.now(),
              ),
            );
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
        const SizedBox(height: 14),

        if (playlists.isEmpty)
          Container(
            margin: const EdgeInsets.only(top: 18),
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: EmberColors.surfaceContainerLow,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: EmberColors.outlineVariant),
            ),
            child: const Column(
              children: [
                FaIcon(FontAwesomeIcons.bookmark, size: 28, color: EmberColors.textMuted),
                SizedBox(height: 12),
                Text(
                  'No Saved Playlists',
                  style: TextStyle(color: EmberColors.textPrimary, fontSize: 15, fontWeight: FontWeight.w700),
                ),
                SizedBox(height: 6),
                Text(
                  'Create custom collections or import public YouTube playlists and endless mixes.',
                  textAlign: TextAlign.center,
                  style: TextStyle(color: EmberColors.textMuted, fontSize: 12),
                ),
              ],
            ),
          )
        else ...[
          const Padding(
            padding: EdgeInsets.only(left: 2, bottom: 8),
            child: Text(
              'BOOKMARKED & LOCAL PLAYLISTS',
              style: TextStyle(color: EmberColors.textMuted, fontSize: 10.5, letterSpacing: 1.1, fontWeight: FontWeight.w700),
            ),
          ),
          for (final pl in playlists)
            Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: _BookmarkTile(
                icon: FontAwesomeIcons.listUl,
                title: pl.title,
                subtitle: '${pl.songs.length} items',
                coverUrl: pl.coverUrl,
                onTap: () => PlaylistDetailSheet.show(context, pl),
                onPlay: pl.songs.isNotEmpty ? () => player.playPlaylist(pl) : null,
              ),
            ),
        ],
      ],
    );
  }

  Widget _buildLocalAudioSection(BuildContext context, PlayerProvider player) {
    if (player.isLoadingLocal) {
      return const Center(
        child: CircularProgressIndicator(color: EmberColors.monoWhite, strokeWidth: 2),
      );
    }

    if (player.localSongs.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const FaIcon(FontAwesomeIcons.hardDrive, size: 36, color: EmberColors.textMuted),
              const SizedBox(height: 14),
              const Text(
                'No Local Audio Files Found',
                style: TextStyle(color: EmberColors.textPrimary, fontSize: 16, fontWeight: FontWeight.w700),
              ),
              const SizedBox(height: 8),
              const Text(
                'Scan device Music and Download folders for offline MP3, M4A, FLAC, and WAV audio files.',
                textAlign: TextAlign.center,
                style: TextStyle(color: EmberColors.textMuted, fontSize: 12.5),
              ),
              const SizedBox(height: 18),
              ElevatedButton.icon(
                onPressed: () => player.scanLocalMusic(),
                icon: const FaIcon(FontAwesomeIcons.arrowsRotate, size: 12),
                label: const Text('Scan Device Storage'),
              ),
            ],
          ),
        ),
      );
    }

    return ListView.separated(
      padding: const EdgeInsets.fromLTRB(14, 8, 14, 96),
      itemCount: player.localSongs.length,
      separatorBuilder: (c, i) => const Divider(color: EmberColors.borderSubtle, height: 1),
      itemBuilder: (context, index) {
        final song = player.localSongs[index];
        return ListTile(
          contentPadding: const EdgeInsets.symmetric(vertical: 4),
          leading: Container(
            width: 42,
            height: 42,
            decoration: BoxDecoration(
              color: EmberColors.surfaceContainerHigh,
              borderRadius: BorderRadius.circular(10),
            ),
            child: const Center(child: FaIcon(FontAwesomeIcons.music, size: 15, color: EmberColors.monoWhite)),
          ),
          title: Text(song.title, maxLines: 1, overflow: TextOverflow.ellipsis, style: const TextStyle(color: EmberColors.textPrimary, fontSize: 13.5, fontWeight: FontWeight.w600)),
          subtitle: Text(song.artist, maxLines: 1, overflow: TextOverflow.ellipsis, style: const TextStyle(color: EmberColors.textMuted, fontSize: 11.5)),
          trailing: const FaIcon(FontAwesomeIcons.play, size: 12, color: EmberColors.monoSilver),
          onTap: () => player.playSong(song, playingFrom: 'Local Storage'),
        );
      },
    );
  }

  Widget _buildRecognitionHistorySection(BuildContext context, PlayerProvider player) {
    final recs = player.recognitionHistory;
    return ListView(
      padding: const EdgeInsets.fromLTRB(14, 8, 14, 96),
      children: [
        Row(
          children: [
            Expanded(
              child: ElevatedButton.icon(
                onPressed: () => MusicDetectorSheet.show(context),
                icon: const FaIcon(FontAwesomeIcons.waveSquare, size: 13),
                label: const Text('Identify Song Now (Audile)', style: TextStyle(fontSize: 12.5, fontWeight: FontWeight.w700)),
                style: ElevatedButton.styleFrom(
                  backgroundColor: EmberColors.monoWhite,
                  foregroundColor: EmberColors.onAccent,
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
              ),
            ),
            if (recs.isNotEmpty) ...[
              const SizedBox(width: 8),
              IconButton(
                icon: const FaIcon(FontAwesomeIcons.trashCan, size: 15, color: EmberColors.textMuted),
                tooltip: 'Clear Recognition History',
                onPressed: () => player.clearRecognitionHistory(),
              ),
            ],
          ],
        ),
        const SizedBox(height: 14),
        if (recs.isEmpty)
          Container(
            padding: const EdgeInsets.all(28),
            decoration: BoxDecoration(
              color: EmberColors.surfaceContainerLow,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: EmberColors.outlineVariant),
            ),
            child: const Column(
              children: [
                FaIcon(FontAwesomeIcons.microphoneLines, size: 30, color: EmberColors.textMuted),
                SizedBox(height: 12),
                Text('No Recognized Tracks Yet', style: TextStyle(color: EmberColors.textPrimary, fontSize: 15, fontWeight: FontWeight.w700)),
                SizedBox(height: 6),
                Text(
                  'Use Audile acoustic fingerprinting to identify songs playing around you. Matches are saved here automatically.',
                  textAlign: TextAlign.center,
                  style: TextStyle(color: EmberColors.textMuted, fontSize: 12),
                ),
              ],
            ),
          )
        else
          for (final rec in recs)
            Container(
              margin: const EdgeInsets.only(bottom: 8),
              decoration: BoxDecoration(
                color: EmberColors.surfaceContainerLow,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: EmberColors.outlineVariant),
              ),
              child: ListTile(
                leading: ClipRRect(
                  borderRadius: BorderRadius.circular(8),
                  child: (rec['artworkUrl']?.toString().isNotEmpty ?? false)
                      ? CachedNetworkImage(
                          imageUrl: rec['artworkUrl'].toString(),
                          width: 44,
                          height: 44,
                          fit: BoxFit.cover,
                          errorWidget: (c, u, e) => Container(
                            width: 44,
                            height: 44,
                            color: EmberColors.surfaceContainerHigh,
                            child: const Center(child: FaIcon(FontAwesomeIcons.music, size: 15, color: EmberColors.monoSilver)),
                          ),
                        )
                      : Container(
                          width: 44,
                          height: 44,
                          color: EmberColors.surfaceContainerHigh,
                          child: const Center(child: FaIcon(FontAwesomeIcons.music, size: 15, color: EmberColors.monoSilver)),
                        ),
                ),
                title: Text(
                  rec['title']?.toString() ?? 'Unknown Track',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(color: EmberColors.textPrimary, fontSize: 13.5, fontWeight: FontWeight.w600),
                ),
                subtitle: Text(
                  rec['artist']?.toString() ?? 'Unknown Artist',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(color: EmberColors.textMuted, fontSize: 11.5),
                ),
              ),
            ),
      ],
    );
  }
}

class _SegmentChip extends StatelessWidget {
  final String label;
  final FaIconData icon;
  final bool isSelected;
  final VoidCallback onTap;

  const _SegmentChip({
    required this.label,
    required this.icon,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: GestureDetector(
        onTap: () {
          HapticFeedback.selectionClick();
          onTap();
        },
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 160),
          padding: const EdgeInsets.symmetric(vertical: 9),
          decoration: BoxDecoration(
            color: isSelected ? EmberColors.monoWhite : EmberColors.surfaceContainerLow,
            borderRadius: BorderRadius.circular(10),
            border: Border.all(
              color: isSelected ? EmberColors.monoWhite : EmberColors.outlineVariant,
            ),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              FaIcon(icon, size: 11, color: isSelected ? EmberColors.onAccent : EmberColors.textSecondary),
              const SizedBox(width: 6),
              Text(
                label,
                style: TextStyle(
                  color: isSelected ? EmberColors.onAccent : EmberColors.textSecondary,
                  fontSize: 11.5,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _QuickShortcutTile extends StatelessWidget {
  final FaIconData icon;
  final String label;
  final VoidCallback onTap;

  const _QuickShortcutTile({
    required this.icon,
    required this.label,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      borderRadius: BorderRadius.circular(12),
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 12),
        decoration: BoxDecoration(
          color: EmberColors.surfaceContainerLow,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: EmberColors.outlineVariant),
        ),
        child: Column(
          children: [
            FaIcon(icon, size: 14, color: EmberColors.monoWhite),
            const SizedBox(height: 6),
            Text(label, style: const TextStyle(color: EmberColors.textSecondary, fontSize: 11, fontWeight: FontWeight.w600)),
          ],
        ),
      ),
    );
  }
}

class _BookmarkTile extends StatelessWidget {
  final FaIconData icon;
  final String title;
  final String subtitle;
  final String? coverUrl;
  final VoidCallback onTap;
  final VoidCallback? onPlay;

  const _BookmarkTile({
    required this.icon,
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
        borderRadius: BorderRadius.circular(14),
        child: Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: EmberColors.surfaceContainerLow,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: EmberColors.outlineVariant),
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
                          child: Center(child: FaIcon(icon, size: 18, color: EmberColors.monoWhite)),
                        ),
                      )
                    : Container(
                        width: 48,
                        height: 48,
                        color: EmberColors.surfaceContainerHigh,
                        child: Center(child: FaIcon(icon, size: 18, color: EmberColors.monoWhite)),
                      ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: const TextStyle(color: EmberColors.textPrimary, fontSize: 14, fontWeight: FontWeight.w600),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 3),
                    Text(subtitle, style: const TextStyle(color: EmberColors.textMuted, fontSize: 11.5)),
                  ],
                ),
              ),
              if (onPlay != null)
                IconButton(
                  icon: const FaIcon(FontAwesomeIcons.play, size: 13, color: EmberColors.monoWhite),
                  onPressed: onPlay,
                ),
            ],
          ),
        ),
      ),
    );
  }
}
