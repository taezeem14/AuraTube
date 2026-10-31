import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:video_player/video_player.dart';
import 'package:provider/provider.dart';
import '../models/youtube_video.dart';
import '../models/youtube_comment.dart';
import '../services/player_service.dart';
import '../services/youtube_service.dart';
import '../services/storage_service.dart';
import '../services/download_service.dart';
import '../theme/aura_theme.dart';
import '../widgets/comment_tile.dart';
import '../widgets/video_card.dart';
import 'sound_shaping_sheet.dart';

class VideoDetailScreen extends StatefulWidget {
  final YouTubeVideo video;

  const VideoDetailScreen({super.key, required this.video});

  @override
  State<VideoDetailScreen> createState() => _VideoDetailScreenState();
}

class _VideoDetailScreenState extends State<VideoDetailScreen> {
  late YouTubeVideo _currentVideo;
  bool _showControls = true;
  bool _descriptionExpanded = false;
  List<YouTubeVideo> _relatedVideos = [];
  List<YouTubeComment> _comments = [];
  bool _isLoadingComments = false;
  bool _isLoadingRelated = false;

  @override
  void initState() {
    super.initState();
    _currentVideo = widget.video;

    // Start video playback
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final player = context.read<PlayerService>();
      player.playVideo(_currentVideo);
      context.read<StorageService>().addToHistory(_currentVideo);
      _loadRelatedAndComments();
    });
  }

  Future<void> _loadRelatedAndComments() async {
    setState(() {
      _isLoadingRelated = true;
      _isLoadingComments = true;
    });

    try {
      final related = await YouTubeService.getRelatedVideos(_currentVideo.id);
      if (mounted) setState(() => _relatedVideos = related);
    } catch (_) {} finally {
      if (mounted) setState(() => _isLoadingRelated = false);
    }

    try {
      final comments = await YouTubeService.getComments(_currentVideo.id);
      if (mounted) setState(() => _comments = comments);
    } catch (_) {} finally {
      if (mounted) setState(() => _isLoadingComments = false);
    }
  }

  void _showCommentsSheet(BuildContext context) {
    showModalBottomSheet(
      context: context,
      backgroundColor: AuraColors.surface,
      isScrollControlled: true,
      useSafeArea: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (ctx) => DraggableScrollableSheet(
        initialChildSize: 0.85,
        minChildSize: 0.5,
        maxChildSize: 0.95,
        expand: false,
        builder: (_, scrollController) => Column(
          children: [
            Container(
              width: 38,
              height: 4,
              margin: const EdgeInsets.symmetric(vertical: 12),
              decoration: BoxDecoration(
                color: AuraColors.textMuted.withValues(alpha: 0.35),
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: [
                      const FaIcon(FontAwesomeIcons.comment, size: 16, color: AuraColors.primaryBlueLight),
                      const SizedBox(width: 10),
                      Text(
                        'Comments (${_comments.length})',
                        style: const TextStyle(
                          color: AuraColors.textPrimary,
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                  IconButton(
                    icon: const Icon(Icons.close_rounded, color: AuraColors.textMuted),
                    onPressed: () => Navigator.pop(ctx),
                  ),
                ],
              ),
            ),
            const Divider(color: AuraColors.outline, height: 1),
            Expanded(
              child: _isLoadingComments
                  ? const Center(child: CircularProgressIndicator())
                  : _comments.isEmpty
                      ? const Center(
                          child: Text('No comments available', style: TextStyle(color: AuraColors.textMuted)),
                        )
                      : ListView.builder(
                          controller: scrollController,
                          padding: const EdgeInsets.all(16),
                          itemCount: _comments.length,
                          itemBuilder: (_, i) => CommentTile(comment: _comments[i]),
                        ),
            ),
          ],
        ),
      ),
    );
  }

  void _showSpeedPicker(BuildContext context, PlayerService player) {
    final speeds = [0.5, 0.75, 1.0, 1.25, 1.5, 1.75, 2.0];
    showModalBottomSheet(
      context: context,
      backgroundColor: AuraColors.surface,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (ctx) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Padding(
              padding: EdgeInsets.all(16),
              child: Text(
                'Playback Speed',
                style: TextStyle(color: AuraColors.textPrimary, fontWeight: FontWeight.bold, fontSize: 16),
              ),
            ),
            const Divider(color: AuraColors.outline, height: 1),
            ...speeds.map(
              (s) => ListTile(
                title: Text('${s}x', style: TextStyle(color: player.playbackSpeed == s ? AuraColors.accentCyan : AuraColors.textPrimary, fontWeight: FontWeight.bold)),
                trailing: player.playbackSpeed == s ? const FaIcon(FontAwesomeIcons.check, size: 14, color: AuraColors.accentCyan) : null,
                onTap: () {
                  player.setPlaybackSpeed(s);
                  Navigator.pop(ctx);
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final player = context.watch<PlayerService>();
    final storage = context.watch<StorageService>();
    final downloader = context.read<DownloadService>();
    final isSubbed = storage.isSubscribed(_currentVideo.channelId);
    final isLiked = storage.isLiked(_currentVideo.id);

    return Scaffold(
      backgroundColor: AuraColors.obsidianBase,
      body: SafeArea(
        child: Column(
          children: [
            // ==========================================
            // VIDEO PLAYER / STREAM CONTAINER
            // ==========================================
            AspectRatio(
              aspectRatio: 16 / 9,
              child: Container(
                color: Colors.black,
                child: Stack(
                  alignment: Alignment.center,
                  children: [
                    if (player.videoController != null && player.videoController!.value.isInitialized)
                      GestureDetector(
                        onTap: () => setState(() => _showControls = !_showControls),
                        child: VideoPlayer(player.videoController!),
                      )
                    else if (player.mode == PlayerMode.backgroundAudio)
                      Container(
                        color: AuraColors.surfaceHigh,
                        child: const Center(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              FaIcon(FontAwesomeIcons.headphones, size: 40, color: AuraColors.primaryBlueLight),
                              SizedBox(height: 12),
                              Text('Background Audio Mode Active', style: TextStyle(color: AuraColors.textPrimary, fontWeight: FontWeight.bold)),
                              Text('EQ & DSP hardware processing enabled', style: TextStyle(color: AuraColors.accentCyan, fontSize: 12)),
                            ],
                          ),
                        ),
                      )
                    else
                      const Center(child: CircularProgressIndicator(color: AuraColors.primaryBlueLight)),

                    // Controls Overlay
                    if (_showControls && player.videoController != null && player.videoController!.value.isInitialized)
                      Container(
                        color: Colors.black.withValues(alpha: 0.5),
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            // Top Bar inside video
                            Padding(
                              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                              child: Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  IconButton(
                                    icon: const FaIcon(FontAwesomeIcons.chevronDown, color: Colors.white, size: 16),
                                    onPressed: () => Navigator.pop(context),
                                  ),
                                  Row(
                                    children: [
                                      // Background Play Toggle
                                      IconButton(
                                        icon: const FaIcon(FontAwesomeIcons.headphones, color: Colors.white, size: 16),
                                        tooltip: 'Switch to Background Audio',
                                        onPressed: () => player.playBackgroundAudio(_currentVideo),
                                      ),
                                      // Speed
                                      IconButton(
                                        icon: const FaIcon(FontAwesomeIcons.gaugeHigh, color: Colors.white, size: 16),
                                        tooltip: 'Playback Speed',
                                        onPressed: () => _showSpeedPicker(context, player),
                                      ),
                                      // Equalizer
                                      IconButton(
                                        icon: const FaIcon(FontAwesomeIcons.sliders, color: AuraColors.accentCyan, size: 16),
                                        tooltip: 'Sound Shaping EQ',
                                        onPressed: () => SoundShapingSheet.show(context),
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                            ),

                            // Center Play / Pause
                            Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                IconButton(
                                  icon: const FaIcon(FontAwesomeIcons.backward, color: Colors.white, size: 22),
                                  onPressed: () {
                                    final current = player.videoController!.value.position;
                                    player.seek(current - const Duration(seconds: 10));
                                  },
                                ),
                                const SizedBox(width: 24),
                                Container(
                                  width: 52,
                                  height: 52,
                                  decoration: BoxDecoration(
                                    shape: BoxShape.circle,
                                    color: AuraColors.primaryBlue.withValues(alpha: 0.9),
                                  ),
                                  child: IconButton(
                                    icon: FaIcon(
                                      player.videoController!.value.isPlaying
                                          ? FontAwesomeIcons.pause
                                          : FontAwesomeIcons.play,
                                      color: Colors.white,
                                      size: 20,
                                    ),
                                    onPressed: () => player.togglePlayPause(),
                                  ),
                                ),
                                const SizedBox(width: 24),
                                IconButton(
                                  icon: const FaIcon(FontAwesomeIcons.forward, color: Colors.white, size: 22),
                                  onPressed: () {
                                    final current = player.videoController!.value.position;
                                    player.seek(current + const Duration(seconds: 10));
                                  },
                                ),
                              ],
                            ),

                            // Bottom Scrubber Bar & Timers
                            Padding(
                              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 4),
                              child: Row(
                                children: [
                                  Text(
                                    YouTubeService.formatDuration(player.videoController!.value.position),
                                    style: const TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.bold),
                                  ),
                                  Expanded(
                                    child: Slider(
                                      value: player.videoController!.value.position.inMilliseconds
                                          .toDouble()
                                          .clamp(0.0, player.videoController!.value.duration.inMilliseconds.toDouble()),
                                      min: 0.0,
                                      max: player.videoController!.value.duration.inMilliseconds.toDouble() > 0
                                          ? player.videoController!.value.duration.inMilliseconds.toDouble()
                                          : 1.0,
                                      activeColor: AuraColors.primaryBlueLight,
                                      inactiveColor: Colors.white30,
                                      onChanged: (val) {
                                        player.seek(Duration(milliseconds: val.toInt()));
                                      },
                                    ),
                                  ),
                                  Text(
                                    YouTubeService.formatDuration(player.videoController!.value.duration),
                                    style: const TextStyle(color: Colors.white70, fontSize: 11),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                  ],
                ),
              ),
            ),

            // ==========================================
            // VIDEO METADATA & DETAILS
            // ==========================================
            Expanded(
              child: ListView(
                padding: const EdgeInsets.all(14),
                children: [
                  // Title
                  Text(
                    _currentVideo.title,
                    style: const TextStyle(
                      color: AuraColors.textPrimary,
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      height: 1.3,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    '${_currentVideo.viewCountFormatted} • ${_currentVideo.uploadDate}',
                    style: const TextStyle(color: AuraColors.textMuted, fontSize: 12),
                  ),
                  const SizedBox(height: 14),

                  // Channel Strip & Subscribe
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                    decoration: BoxDecoration(
                      color: AuraColors.surface,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: AuraColors.outline.withValues(alpha: 0.6)),
                    ),
                    child: Row(
                      children: [
                        Container(
                          width: 40,
                          height: 40,
                          decoration: const BoxDecoration(
                            shape: BoxShape.circle,
                            gradient: LinearGradient(colors: [AuraColors.primaryBlue, AuraColors.accentCyan]),
                          ),
                          child: Center(
                            child: Text(
                              _currentVideo.author.isNotEmpty ? _currentVideo.author[0].toUpperCase() : 'C',
                              style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16),
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                _currentVideo.author,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: const TextStyle(color: AuraColors.textPrimary, fontWeight: FontWeight.bold, fontSize: 14),
                              ),
                              const Text('Libre Channel', style: TextStyle(color: AuraColors.textMuted, fontSize: 11)),
                            ],
                          ),
                        ),
                        ElevatedButton(
                          onPressed: () {
                            storage.toggleSubscription(
                              channelId: _currentVideo.channelId,
                              name: _currentVideo.author,
                              avatarUrl: '',
                            );
                          },
                          style: ElevatedButton.styleFrom(
                            backgroundColor: isSubbed ? AuraColors.surfaceHigh : AuraColors.primaryBlue,
                            foregroundColor: Colors.white,
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                          ),
                          child: Text(
                            isSubbed ? 'Subscribed' : 'Subscribe',
                            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 14),

                  // Actions Carousel: Like, Share, Download, EQ, Background Play
                  SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    child: Row(
                      children: [
                        // Like Button
                        ElevatedButton.icon(
                          onPressed: () => storage.toggleLike(_currentVideo),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: isLiked ? AuraColors.primaryBlue : AuraColors.surfaceHigh,
                            foregroundColor: Colors.white,
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                          ),
                          icon: FaIcon(
                            isLiked ? FontAwesomeIcons.solidThumbsUp : FontAwesomeIcons.thumbsUp,
                            size: 14,
                            color: isLiked ? Colors.white : AuraColors.textPrimary,
                          ),
                          label: Text(isLiked ? 'Liked' : 'Like', style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
                        ),
                        const SizedBox(width: 8),

                        // Equalizer Button
                        OutlinedButton.icon(
                          onPressed: () => SoundShapingSheet.show(context),
                          style: OutlinedButton.styleFrom(
                            foregroundColor: AuraColors.accentCyan,
                            side: const BorderSide(color: AuraColors.accentCyan),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                          ),
                          icon: const FaIcon(FontAwesomeIcons.sliders, size: 14),
                          label: const Text('Equalizer', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
                        ),
                        const SizedBox(width: 8),

                        // Background Audio Button
                        ElevatedButton.icon(
                          onPressed: () => player.playBackgroundAudio(_currentVideo),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AuraColors.surfaceHigh,
                            foregroundColor: AuraColors.textPrimary,
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                          ),
                          icon: const FaIcon(FontAwesomeIcons.headphones, size: 14, color: AuraColors.primaryBlueLight),
                          label: const Text('Background', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
                        ),
                        const SizedBox(width: 8),

                        // Download Button
                        ElevatedButton.icon(
                          onPressed: () {
                            downloader.downloadVideo(_currentVideo);
                            storage.addDownload(_currentVideo);
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Text('Downloading "${_currentVideo.title}"...'),
                                backgroundColor: AuraColors.surfaceHigh,
                              ),
                            );
                          },
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AuraColors.surfaceHigh,
                            foregroundColor: AuraColors.textPrimary,
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                          ),
                          icon: const FaIcon(FontAwesomeIcons.download, size: 14, color: AuraColors.accentCyan),
                          label: const Text('Download', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 14),

                  // Collapsible Description
                  GestureDetector(
                    onTap: () => setState(() => _descriptionExpanded = !_descriptionExpanded),
                    child: Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: AuraColors.surface,
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(color: AuraColors.outline.withValues(alpha: 0.5)),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              const Text('Description', style: TextStyle(color: AuraColors.textSecondary, fontWeight: FontWeight.bold, fontSize: 13)),
                              FaIcon(
                                _descriptionExpanded ? FontAwesomeIcons.chevronUp : FontAwesomeIcons.chevronDown,
                                size: 12,
                                color: AuraColors.textMuted,
                              ),
                            ],
                          ),
                          const SizedBox(height: 6),
                          Text(
                            _currentVideo.description.isNotEmpty
                                ? _currentVideo.description
                                : 'No description provided.',
                            maxLines: _descriptionExpanded ? null : 3,
                            overflow: _descriptionExpanded ? TextOverflow.visible : TextOverflow.ellipsis,
                            style: const TextStyle(color: AuraColors.textPrimary, fontSize: 12.5, height: 1.35),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 14),

                  // Comments Preview Bar
                  GestureDetector(
                    onTap: () => _showCommentsSheet(context),
                    child: Container(
                      padding: const EdgeInsets.all(14),
                      decoration: BoxDecoration(
                        color: AuraColors.surface,
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: AuraColors.outline.withValues(alpha: 0.6)),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Row(
                                children: [
                                  const FaIcon(FontAwesomeIcons.comment, size: 14, color: AuraColors.primaryBlueLight),
                                  const SizedBox(width: 8),
                                  Text(
                                    'Comments (${_comments.length})',
                                    style: const TextStyle(color: AuraColors.textPrimary, fontWeight: FontWeight.bold, fontSize: 13),
                                  ),
                                ],
                              ),
                              const FaIcon(FontAwesomeIcons.chevronRight, size: 12, color: AuraColors.textMuted),
                            ],
                          ),
                          if (_comments.isNotEmpty) ...[
                            const SizedBox(height: 8),
                            Text(
                              _comments.first.text,
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(color: AuraColors.textSecondary, fontSize: 12),
                            ),
                          ],
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 20),

                  // Related Videos Section
                  const Text(
                    'Up Next',
                    style: TextStyle(color: AuraColors.textPrimary, fontWeight: FontWeight.bold, fontSize: 16),
                  ),
                  const SizedBox(height: 12),
                  if (_isLoadingRelated)
                    const Center(child: CircularProgressIndicator())
                  else
                    ..._relatedVideos.map(
                      (v) => VideoCard(
                        video: v,
                        onTap: () {
                          setState(() {
                            _currentVideo = v;
                          });
                          player.playVideo(v);
                          storage.addToHistory(v);
                          _loadRelatedAndComments();
                        },
                      ),
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
