import 'dart:io';
import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:provider/provider.dart';
import '../models/song.dart';
import '../providers/player_provider.dart';
import '../services/download_service.dart';
import '../theme/ember_theme.dart';
import 'aura_video_player_screen.dart';

class DownloadsScreen extends StatefulWidget {
  const DownloadsScreen({super.key});

  @override
  State<DownloadsScreen> createState() => _DownloadsScreenState();
}

class _DownloadsScreenState extends State<DownloadsScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  List<File> _audioFiles = [];
  List<File> _videoFiles = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _loadFiles();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _loadFiles() async {
    setState(() => _isLoading = true);
    final audio = await DownloadService.getDownloadedFiles(isVideo: false);
    final video = await DownloadService.getDownloadedFiles(isVideo: true);
    if (mounted) {
      setState(() {
        _audioFiles = audio;
        _videoFiles = video;
        _isLoading = false;
      });
    }
  }

  String _formatFileSize(int bytes) {
    if (bytes < 1024) return '$bytes B';
    if (bytes < 1024 * 1024) return '${(bytes / 1024).toStringAsFixed(1)} KB';
    return '${(bytes / (1024 * 1024)).toStringAsFixed(1)} MB';
  }

  String _cleanFileName(String path) {
    final name = path.split(Platform.pathSeparator).last;
    return name.replaceAll(RegExp(r'_[a-zA-Z0-9]+\.(mp4|webm|m4a|mp3)$'), '');
  }

  Widget _buildFileList({required bool isVideo, required List<File> files}) {
    final player = Provider.of<PlayerProvider>(context, listen: false);

    if (_isLoading) {
      return const Center(
        child: CircularProgressIndicator(color: EmberColors.primaryBlue),
      );
    }

    if (files.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              FaIcon(
                isVideo ? FontAwesomeIcons.film : FontAwesomeIcons.headphones,
                size: 48,
                color: EmberColors.textMuted.withValues(alpha: 0.4),
              ),
              const SizedBox(height: 16),
              Text(
                'No Downloaded ${isVideo ? "Videos" : "Audio"}',
                style: const TextStyle(
                  color: EmberColors.textPrimary,
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'Downloaded ${isVideo ? "videos" : "songs"} will appear here for offline playback.',
                textAlign: TextAlign.center,
                style: const TextStyle(color: EmberColors.textMuted, fontSize: 13),
              ),
            ],
          ),
        ),
      );
    }

    return ListView.separated(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      itemCount: files.length,
      separatorBuilder: (context, index) => const Divider(color: EmberColors.outlineVariant, height: 1),
      itemBuilder: (context, index) {
        final file = files[index];
        final fileName = _cleanFileName(file.path);
        final size = file.lengthSync();

        return ListTile(
          contentPadding: const EdgeInsets.symmetric(vertical: 4),
          leading: Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: isVideo
                  ? EmberColors.secondaryCyan.withValues(alpha: 0.15)
                  : EmberColors.primaryBlue.withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Center(
              child: FaIcon(
                isVideo ? FontAwesomeIcons.video : FontAwesomeIcons.music,
                size: 18,
                color: isVideo ? EmberColors.secondaryCyan : EmberColors.primaryBlue,
              ),
            ),
          ),
          title: Text(
            fileName,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
              color: EmberColors.textPrimary,
              fontSize: 13.5,
              fontWeight: FontWeight.w600,
            ),
          ),
          subtitle: Row(
            children: [
              Text(
                _formatFileSize(size),
                style: const TextStyle(color: EmberColors.textMuted, fontSize: 11),
              ),
              const SizedBox(width: 8),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1),
                decoration: BoxDecoration(
                  color: EmberColors.surfaceContainerHigh,
                  borderRadius: BorderRadius.circular(4),
                ),
                child: Text(
                  file.path.split('.').last.toUpperCase(),
                  style: const TextStyle(color: EmberColors.primaryBlueHi, fontSize: 9.5, fontWeight: FontWeight.bold),
                ),
              ),
            ],
          ),
          trailing: IconButton(
            icon: const FaIcon(FontAwesomeIcons.trashCan, size: 15, color: EmberColors.textMuted),
            onPressed: () async {
              final confirm = await showDialog<bool>(
                context: context,
                builder: (ctx) => AlertDialog(
                  backgroundColor: EmberColors.surfaceContainerLow,
                  title: const Text('Delete Download?', style: TextStyle(color: EmberColors.textPrimary)),
                  content: Text('Delete "$fileName" from device storage?'),
                  actions: [
                    TextButton(
                      child: const Text('Cancel', style: TextStyle(color: EmberColors.textMuted)),
                      onPressed: () => Navigator.pop(ctx, false),
                    ),
                    TextButton(
                      child: const Text('Delete', style: TextStyle(color: Colors.redAccent)),
                      onPressed: () => Navigator.pop(ctx, true),
                    ),
                  ],
                ),
              );

              if (confirm == true) {
                await DownloadService.deleteDownloadedFile(file);
                _loadFiles();
              }
            },
          ),
          onTap: () {
            if (isVideo) {
              final dummySong = Song(
                id: file.path.hashCode.abs().toString(),
                title: fileName,
                artist: 'Offline Video',
                artworkUrl: '',
                duration: Duration.zero,
                streamUrl: file.path,
                videoStreamUrl: file.path,
              );
              Navigator.of(context).push(
                MaterialPageRoute(builder: (_) => AuraVideoPlayerScreen(video: dummySong)),
              );
            } else {
              final dummySong = Song(
                id: file.path.hashCode.abs().toString(),
                title: fileName,
                artist: 'Offline Audio',
                artworkUrl: '',
                duration: Duration.zero,
                streamUrl: file.path,
              );
              player.playSong(dummySong);
            }
          },
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: EmberColors.obsidianBase,
      appBar: AppBar(
        backgroundColor: EmberColors.obsidianBase,
        elevation: 0,
        leading: IconButton(
          icon: const FaIcon(FontAwesomeIcons.arrowLeft, size: 16, color: EmberColors.textPrimary),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text(
          'Downloads',
          style: TextStyle(color: EmberColors.textPrimary, fontSize: 17, fontWeight: FontWeight.bold),
        ),
        actions: [
          IconButton(
            icon: const FaIcon(FontAwesomeIcons.arrowsRotate, size: 15, color: EmberColors.primaryBlue),
            onPressed: _loadFiles,
          ),
        ],
        bottom: TabBar(
          controller: _tabController,
          indicatorColor: EmberColors.primaryBlue,
          indicatorWeight: 3,
          labelColor: EmberColors.primaryBlue,
          unselectedLabelColor: EmberColors.textMuted,
          labelStyle: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
          tabs: [
            Tab(
              icon: const FaIcon(FontAwesomeIcons.music, size: 16),
              text: 'Audio (${_audioFiles.length})',
            ),
            Tab(
              icon: const FaIcon(FontAwesomeIcons.video, size: 16),
              text: 'Video (${_videoFiles.length})',
            ),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _buildFileList(isVideo: false, files: _audioFiles),
          _buildFileList(isVideo: true, files: _videoFiles),
        ],
      ),
    );
  }
}
