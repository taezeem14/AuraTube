import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../../providers/player_provider.dart';
import '../../theme/ember_theme.dart';
import '../playlist_detail_sheet.dart';

class AuraMixesTab extends StatefulWidget {
  const AuraMixesTab({super.key});

  @override
  State<AuraMixesTab> createState() => _AuraMixesTabState();
}

class _AuraMixesTabState extends State<AuraMixesTab> {
  final TextEditingController _importController = TextEditingController();

  void _showCreatePlaylistDialog(BuildContext context, PlayerProvider player) {
    final titleController = TextEditingController();
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: EmberColors.surfaceContainerLow,
        title: const Text('Create New Playlist', style: TextStyle(color: EmberColors.textPrimary, fontWeight: FontWeight.bold)),
        content: TextField(
          controller: titleController,
          autofocus: true,
          style: const TextStyle(color: EmberColors.textPrimary),
          decoration: const InputDecoration(
            hintText: 'Playlist Title',
            hintStyle: TextStyle(color: EmberColors.textMuted),
            enabledBorder: UnderlineInputBorder(borderSide: BorderSide(color: EmberColors.primaryBlue)),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel', style: TextStyle(color: EmberColors.textMuted)),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: EmberColors.primaryBlue),
            onPressed: () {
              final title = titleController.text.trim();
              if (title.isNotEmpty) {
                player.createPlaylist(title);
                Navigator.pop(ctx);
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text('Created "$title"'), backgroundColor: EmberColors.surfaceContainerHigh),
                );
              }
            },
            child: const Text('Create'),
          ),
        ],
      ),
    );
  }

  void _showImportPlaylistDialog(BuildContext context, PlayerProvider player) {
    _importController.clear();
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: EmberColors.surfaceContainerLow,
        title: const Text('Import YouTube Playlist / Mix', style: TextStyle(color: EmberColors.textPrimary, fontWeight: FontWeight.bold)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Paste any YouTube playlist or mix link (e.g. youtube.com/playlist?list=... or RDAMVM...):',
              style: TextStyle(color: EmberColors.textMuted, fontSize: 12),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _importController,
              autofocus: true,
              style: const TextStyle(color: EmberColors.textPrimary, fontSize: 13),
              decoration: const InputDecoration(
                hintText: 'https://www.youtube.com/playlist?list=...',
                hintStyle: TextStyle(color: EmberColors.textMuted),
                enabledBorder: UnderlineInputBorder(borderSide: BorderSide(color: EmberColors.primaryBlue)),
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
            style: ElevatedButton.styleFrom(backgroundColor: EmberColors.primaryBlue),
            onPressed: () async {
              final url = _importController.text.trim();
              if (url.isNotEmpty) {
                Navigator.pop(ctx);
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Importing YouTube playlist...'), backgroundColor: EmberColors.surfaceContainerHigh),
                );
                final msg = await player.importYouTubeUrl(url);
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text(msg),
                      backgroundColor: msg.startsWith('Import failed')
                          ? EmberColors.error
                          : EmberColors.surfaceContainerHigh,
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
  void dispose() {
    _importController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final player = context.watch<PlayerProvider>();
    final playlists = player.playlists;

    return Scaffold(
      backgroundColor: EmberColors.obsidianBase,
      appBar: AppBar(
        backgroundColor: EmberColors.obsidianBase,
        elevation: 0,
        titleSpacing: 16,
        title: const Text(
          'Mixes & Playlists',
          style: TextStyle(
            fontFamily: 'Sora',
            color: EmberColors.textPrimary,
            fontSize: 20,
            fontWeight: FontWeight.bold,
          ),
        ),
        actions: [
          IconButton(
            icon: const FaIcon(FontAwesomeIcons.link, size: 16, color: EmberColors.secondaryCyan),
            tooltip: 'Import YouTube Playlist URL',
            onPressed: () => _showImportPlaylistDialog(context, player),
          ),
          IconButton(
            icon: const FaIcon(FontAwesomeIcons.plus, size: 16, color: EmberColors.primaryBlue),
            tooltip: 'Create New Playlist',
            onPressed: () => _showCreatePlaylistDialog(context, player),
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        children: [
          // 1. YouTube Mix Generator Card
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(18),
              gradient: LinearGradient(
                colors: [
                  EmberColors.primaryBlue.withValues(alpha: 0.25),
                  EmberColors.secondaryCyan.withValues(alpha: 0.15),
                ],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              border: Border.all(color: EmberColors.primaryBlue.withValues(alpha: 0.4), width: 1.2),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: const BoxDecoration(
                        color: EmberColors.primaryBlue,
                        shape: BoxShape.circle,
                      ),
                      child: const FaIcon(FontAwesomeIcons.arrowsSpin, size: 14, color: Colors.white),
                    ),
                    const SizedBox(width: 10),
                    const Text(
                      'Endless YouTube Mix (NewPipe RDAMVM)',
                      style: TextStyle(color: Colors.white, fontSize: 15, fontWeight: FontWeight.bold),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                const Text(
                  'Continuous, dynamic YouTube recommendations powered by NewPipe mix protocols. Plays forever without interrupting.',
                  style: TextStyle(color: EmberColors.textSecondary, fontSize: 12.5, height: 1.3),
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    ElevatedButton.icon(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: EmberColors.primaryBlue,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                      icon: const FaIcon(FontAwesomeIcons.play, size: 12),
                      label: const Text('Start Mix from Current Video', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12)),
                      onPressed: () {
                        if (player.currentSong != null) {
                          player.startMixFromSong(player.currentSong!);
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text('Starting YouTube Mix for "${player.currentSong!.title}"'),
                              backgroundColor: EmberColors.surfaceContainerHigh,
                            ),
                          );
                        } else {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text('Pick a video from Home feed first to start its endless Mix!'),
                              backgroundColor: EmberColors.surfaceContainerHigh,
                            ),
                          );
                        }
                      },
                    ),
                  ],
                ),
              ],
            ),
          ),

          const SizedBox(height: 24),

          // 2. Playlists Section
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'YOUR PLAYLISTS',
                style: TextStyle(
                  color: EmberColors.textMuted,
                  fontSize: 11,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 1.2,
                ),
              ),
              Text(
                '${playlists.length} playlists',
                style: const TextStyle(color: EmberColors.textMuted, fontSize: 11),
              ),
            ],
          ),
          const SizedBox(height: 12),

          if (playlists.isEmpty)
            Container(
              padding: const EdgeInsets.symmetric(vertical: 36),
              alignment: Alignment.center,
              child: Column(
                children: [
                  const FaIcon(FontAwesomeIcons.folderPlus, size: 36, color: EmberColors.textMuted),
                  const SizedBox(height: 12),
                  const Text('No playlists yet', style: TextStyle(color: EmberColors.textPrimary, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 4),
                  const Text('Create playlists or import YouTube playlist URLs above.', style: TextStyle(color: EmberColors.textMuted, fontSize: 12)),
                  const SizedBox(height: 16),
                  ElevatedButton(
                    style: ElevatedButton.styleFrom(backgroundColor: EmberColors.primaryBlue),
                    onPressed: () => _showCreatePlaylistDialog(context, player),
                    child: const Text('Create Playlist'),
                  ),
                ],
              ),
            )
          else
            ...playlists.map((pl) {
              return Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: InkWell(
                  borderRadius: BorderRadius.circular(14),
                  onTap: () {
                    PlaylistDetailSheet.show(context, pl);
                  },
                  child: Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: EmberColors.surfaceContainerLow,
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(color: Colors.white.withValues(alpha: 0.05)),
                    ),
                    child: Row(
                      children: [
                        ClipRRect(
                          borderRadius: BorderRadius.circular(10),
                          child: Container(
                            width: 54,
                            height: 54,
                            color: EmberColors.surfaceContainerHigh,
                            child: pl.songs.isNotEmpty && pl.songs.first.artworkUrl.isNotEmpty
                                ? CachedNetworkImage(
                                    imageUrl: pl.songs.first.artworkUrl,
                                    fit: BoxFit.cover,
                                    errorWidget: (context, url, error) => const Center(
                                      child: FaIcon(FontAwesomeIcons.listCheck, size: 20, color: EmberColors.primaryBlue),
                                    ),
                                  )
                                : const Center(
                                    child: FaIcon(FontAwesomeIcons.listCheck, size: 20, color: EmberColors.primaryBlue),
                                  ),
                          ),
                        ),
                        const SizedBox(width: 14),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                pl.title,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: const TextStyle(
                                  color: EmberColors.textPrimary,
                                  fontSize: 14,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                '${pl.songs.length} videos',
                                style: const TextStyle(
                                  color: EmberColors.textMuted,
                                  fontSize: 12,
                                ),
                              ),
                            ],
                          ),
                        ),
                        IconButton(
                          icon: const FaIcon(FontAwesomeIcons.circlePlay, size: 22, color: EmberColors.primaryBlue),
                          onPressed: () {
                            if (pl.songs.isNotEmpty) {
                              player.playPlaylist(pl, startIndex: 0);
                            }
                          },
                        ),
                      ],
                    ),
                  ),
                ),
              );
            }),
        ],
      ),
    );
  }
}
