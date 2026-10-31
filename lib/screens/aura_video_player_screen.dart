import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:video_player/video_player.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:provider/provider.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../models/song.dart';
import '../models/comment.dart';
import '../models/subscription.dart';
import '../providers/player_provider.dart';
import '../services/youtube_feed_service.dart';
import '../services/storage_service.dart';
import '../services/download_service.dart';
import '../theme/ember_theme.dart';
import '../widgets/ambient_glow.dart';
import '../widgets/vinyl_disc.dart';
import 'sound_shaping_sheet.dart';
import 'track_options_sheet.dart';

class AuraVideoPlayerScreen extends StatefulWidget {
  final Song video;

  const AuraVideoPlayerScreen({
    super.key,
    required this.video,
  });

  @override
  State<AuraVideoPlayerScreen> createState() => _AuraVideoPlayerScreenState();
}

class _AuraVideoPlayerScreenState extends State<AuraVideoPlayerScreen> with SingleTickerProviderStateMixin {
  late Song _currentVideo;
  VideoPlayerController? _controller;
  bool _isLoadingVideo = true;
  bool _hasVideoError = false;
  String _errorMessage = '';

  bool _isListenMode = false; // Video mode vs Audio Listen Mode
  bool _showControls = true;
  Timer? _hideControlsTimer;
  bool _isFullscreen = false;
  bool _isLiked = false;
  bool _isDisliked = false;
  bool _isSubscribed = false;

  late TabController _tabController;
  List<Song> _relatedVideos = [];
  bool _isLoadingRelated = true;
  List<AuraComment> _comments = [];
  bool _isLoadingComments = true;
  VideoStreamOptions? _streamOptions;
  String _selectedQuality = '720p';

  @override
  void initState() {
    super.initState();
    _currentVideo = widget.video;
    _tabController = TabController(length: 2, vsync: this);
    _checkSubscriptionStatus();
    _loadVideo();
    _loadMetadata();
  }

  void _checkSubscriptionStatus() {
    final channelId = _currentVideo.channelId ?? _currentVideo.artist;
    final storage = Provider.of<StorageService>(context, listen: false);
    setState(() {
      _isSubscribed = storage.isSubscribed(channelId);
    });
  }

  Future<void> _loadVideo() async {
    setState(() {
      _isLoadingVideo = true;
      _hasVideoError = false;
      _errorMessage = '';
    });

    try {
      // 1. Resolve video stream options (720p/1080p muxed video & audio)
      _streamOptions = await YouTubeFeedService.resolveVideoStreamOptions(_currentVideo.id);

      final videoUrl = _streamOptions?.videoMuxedUrl ?? _streamOptions?.audioOnlyUrl;
      if (videoUrl == null || videoUrl.isEmpty) {
        throw Exception('No playable video stream found for this video.');
      }

      // Dispose previous controller if any
      await _controller?.dispose();

      _controller = VideoPlayerController.networkUrl(
        Uri.parse(videoUrl),
        httpHeaders: {
          'User-Agent': 'com.google.android.youtube/20.10.38 (Linux; U; Android 11)',
          'Accept': '*/*',
        },
      );

      await _controller!.initialize();
      _controller!.addListener(_videoListener);
      await _controller!.play();

      if (mounted) {
        setState(() {
          _isLoadingVideo = false;
        });
        _startHideControlsTimer();
      }
    } catch (e) {
      debugPrint('[AuraVideoPlayer] Load error: $e');
      if (mounted) {
        setState(() {
          _isLoadingVideo = false;
          _hasVideoError = true;
          _errorMessage = e.toString();
        });
      }
    }
  }

  void _videoListener() {
    if (mounted) {
      setState(() {});
    }
  }

  Future<void> _loadMetadata() async {
    // Enrich video details (description, viewCount)
    YouTubeFeedService.enrichVideoDetails(_currentVideo).then((enriched) {
      if (mounted) {
        setState(() {
          _currentVideo = enriched;
        });
      }
    });

    // Fetch related videos
    YouTubeFeedService.fetchRelatedVideos(_currentVideo.id).then((list) {
      if (mounted) {
        setState(() {
          _relatedVideos = list;
          _isLoadingRelated = false;
        });
      }
    });

    // Fetch comments
    YouTubeFeedService.fetchComments(_currentVideo.id).then((cList) {
      if (mounted) {
        setState(() {
          _comments = cList;
          _isLoadingComments = false;
        });
      }
    });
  }

  void _startHideControlsTimer() {
    _hideControlsTimer?.cancel();
    _hideControlsTimer = Timer(const Duration(seconds: 4), () {
      if (mounted && _controller != null && _controller!.value.isPlaying) {
        setState(() {
          _showControls = false;
        });
      }
    });
  }

  void _toggleControls() {
    setState(() {
      _showControls = !_showControls;
    });
    if (_showControls) {
      _startHideControlsTimer();
    }
  }

  void _togglePlayPause() {
    if (_controller == null) return;
    if (_controller!.value.isPlaying) {
      _controller!.pause();
      setState(() => _showControls = true);
      _hideControlsTimer?.cancel();
    } else {
      _controller!.play();
      _startHideControlsTimer();
    }
    setState(() {});
  }

  void _seekRelative(Duration delta) {
    if (_controller == null) return;
    final newPos = _controller!.value.position + delta;
    _controller!.seekTo(newPos);
    _startHideControlsTimer();
  }

  void _toggleFullscreen() {
    setState(() {
      _isFullscreen = !_isFullscreen;
    });
    if (_isFullscreen) {
      SystemChrome.setEnabledSystemUIMode(SystemUiMode.immersiveSticky);
      SystemChrome.setPreferredOrientations([
        DeviceOrientation.landscapeLeft,
        DeviceOrientation.landscapeRight,
      ]);
    } else {
      SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);
      SystemChrome.setPreferredOrientations([
        DeviceOrientation.portraitUp,
      ]);
    }
  }

  void _toggleListenMode() {
    setState(() {
      _isListenMode = !_isListenMode;
    });
    final player = Provider.of<PlayerProvider>(context, listen: false);
    if (_isListenMode) {
      // Pause video controller and hand off to background audio player
      _controller?.pause();
      player.playSong(_currentVideo);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Switched to Listen Mode (Background Audio Active)'),
          backgroundColor: EmberColors.surfaceContainerHigh,
          duration: Duration(seconds: 2),
        ),
      );
    } else {
      player.pause();
      _controller?.play();
    }
  }

  Future<void> _toggleSubscription() async {
    final storage = Provider.of<StorageService>(context, listen: false);
    final sub = LocalSubscription(
      channelId: _currentVideo.channelId ?? _currentVideo.artist,
      name: _currentVideo.artist,
      avatarUrl: _currentVideo.artworkUrl,
      subscribedAt: DateTime.now(),
    );
    final status = await storage.toggleSubscription(sub);
    setState(() {
      _isSubscribed = status;
    });
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(status ? 'Subscribed to ${_currentVideo.artist}' : 'Unsubscribed'),
          backgroundColor: EmberColors.surfaceContainerHigh,
          duration: const Duration(seconds: 2),
        ),
      );
    }
  }

  void _showQualityPicker() {
    if (_streamOptions == null || _streamOptions!.qualities.isEmpty) return;

    showModalBottomSheet(
      context: context,
      backgroundColor: EmberColors.surfaceContainerLow,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Padding(
                padding: EdgeInsets.symmetric(horizontal: 20, vertical: 8),
                child: Text('Video Quality', style: TextStyle(color: EmberColors.textPrimary, fontSize: 16, fontWeight: FontWeight.bold)),
              ),
              const Divider(color: EmberColors.outlineVariant),
              for (final entry in _streamOptions!.qualities.entries)
                ListTile(
                  title: Text(entry.key, style: const TextStyle(color: EmberColors.textPrimary)),
                  trailing: _selectedQuality == entry.key
                      ? const FaIcon(FontAwesomeIcons.check, size: 16, color: EmberColors.primaryBlue)
                      : null,
                  onTap: () async {
                    Navigator.pop(ctx);
                    setState(() {
                      _selectedQuality = entry.key;
                      _isLoadingVideo = true;
                    });
                    final currentPos = _controller?.value.position ?? Duration.zero;
                    await _controller?.dispose();
                    _controller = VideoPlayerController.networkUrl(
                      Uri.parse(entry.value),
                    );
                    await _controller!.initialize();
                    _controller!.addListener(_videoListener);
                    await _controller!.seekTo(currentPos);
                    await _controller!.play();
                    setState(() {
                      _isLoadingVideo = false;
                    });
                  },
                ),
            ],
          ),
        ),
      ),
    );
  }

  void _showDescriptionSheet() {
    showModalBottomSheet(
      context: context,
      backgroundColor: EmberColors.surfaceContainerLow,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) => DraggableScrollableSheet(
        initialChildSize: 0.6,
        minChildSize: 0.4,
        maxChildSize: 0.9,
        expand: false,
        builder: (_, scrollController) => Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
          child: ListView(
            controller: scrollController,
            children: [
              Center(
                child: Container(
                  width: 40,
                  height: 4,
                  margin: const EdgeInsets.only(bottom: 16),
                  decoration: BoxDecoration(
                    color: EmberColors.textMuted.withValues(alpha: 0.4),
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              Text(
                _currentVideo.title,
                style: const TextStyle(color: EmberColors.textPrimary, fontSize: 16, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  if (_currentVideo.formattedViews.isNotEmpty)
                    Text(_currentVideo.formattedViews, style: const TextStyle(color: EmberColors.textSecondary, fontSize: 13, fontWeight: FontWeight.w600)),
                  if (_currentVideo.uploadDateFormatted != null) ...[
                    const Padding(
                      padding: EdgeInsets.symmetric(horizontal: 8),
                      child: Text('•', style: TextStyle(color: EmberColors.textMuted)),
                    ),
                    Text(_currentVideo.uploadDateFormatted!, style: const TextStyle(color: EmberColors.textSecondary, fontSize: 13)),
                  ],
                ],
              ),
              const SizedBox(height: 16),
              const Divider(color: EmberColors.outlineVariant),
              const SizedBox(height: 12),
              SelectableText(
                _currentVideo.description?.isNotEmpty == true
                    ? _currentVideo.description!
                    : 'No description available for this video.',
                style: const TextStyle(color: EmberColors.textPrimary, fontSize: 13.5, height: 1.5),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _playNextVideo(Song next) {
    setState(() {
      _currentVideo = next;
      _isLoadingRelated = true;
      _isLoadingComments = true;
      _relatedVideos.clear();
      _comments.clear();
    });
    _checkSubscriptionStatus();
    _loadVideo();
    _loadMetadata();
  }

  @override
  void dispose() {
    _hideControlsTimer?.cancel();
    _controller?.removeListener(_videoListener);
    _controller?.dispose();
    _tabController.dispose();
    if (_isFullscreen) {
      SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);
      SystemChrome.setPreferredOrientations([DeviceOrientation.portraitUp]);
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (_isFullscreen) {
      return Scaffold(
        backgroundColor: Colors.black,
        body: _buildVideoViewport(),
      );
    }

    return Scaffold(
      backgroundColor: EmberColors.obsidianBase,
      body: SafeArea(
        child: Column(
          children: [
            // 1. Video Player Viewport (16:9 Aspect Ratio)
            _buildVideoViewport(),

            // 2. Video Info & Actions & Tabs
            Expanded(
              child: NestedScrollView(
                headerSliverBuilder: (context, innerBoxIsScrolled) => [
                  SliverToBoxAdapter(
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // Title & Expand arrow
                          GestureDetector(
                            onTap: _showDescriptionSheet,
                            child: Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Expanded(
                                  child: Text(
                                    _currentVideo.title,
                                    maxLines: 2,
                                    overflow: TextOverflow.ellipsis,
                                    style: const TextStyle(
                                      color: EmberColors.textPrimary,
                                      fontSize: 16,
                                      fontWeight: FontWeight.bold,
                                      height: 1.3,
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 8),
                                const FaIcon(FontAwesomeIcons.chevronDown, size: 14, color: EmberColors.textMuted),
                              ],
                            ),
                          ),
                          const SizedBox(height: 6),

                          // Views & Date pill
                          GestureDetector(
                            onTap: _showDescriptionSheet,
                            child: Row(
                              children: [
                                if (_currentVideo.formattedViews.isNotEmpty)
                                  Text(
                                    _currentVideo.formattedViews,
                                    style: const TextStyle(color: EmberColors.textMuted, fontSize: 12),
                                  ),
                                if (_currentVideo.uploadDateFormatted != null) ...[
                                  const Padding(
                                    padding: EdgeInsets.symmetric(horizontal: 6),
                                    child: Text('•', style: TextStyle(color: EmberColors.textMuted, fontSize: 12)),
                                  ),
                                  Text(
                                    _currentVideo.uploadDateFormatted!,
                                    style: const TextStyle(color: EmberColors.textMuted, fontSize: 12),
                                  ),
                                ],
                                const Spacer(),
                                const Text(
                                  'Details...',
                                  style: TextStyle(color: EmberColors.secondaryCyan, fontSize: 12, fontWeight: FontWeight.w600),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(height: 14),

                          // Channel Row with Subscribe Button
                          Row(
                            children: [
                              Container(
                                width: 40,
                                height: 40,
                                decoration: const BoxDecoration(
                                  shape: BoxShape.circle,
                                  gradient: LinearGradient(
                                    colors: [EmberColors.primaryBlue, EmberColors.secondaryCyan],
                                  ),
                                ),
                                alignment: Alignment.center,
                                child: Text(
                                  _currentVideo.artist.isNotEmpty ? _currentVideo.artist[0].toUpperCase() : 'A',
                                  style: const TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold),
                                ),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      _currentVideo.artist,
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                      style: const TextStyle(color: EmberColors.textPrimary, fontSize: 14, fontWeight: FontWeight.bold),
                                    ),
                                    const Text('Creator Channel', style: TextStyle(color: EmberColors.textMuted, fontSize: 11)),
                                  ],
                                ),
                              ),
                              ElevatedButton(
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: _isSubscribed ? EmberColors.surfaceContainerHigh : EmberColors.primaryBlue,
                                  foregroundColor: _isSubscribed ? EmberColors.textMuted : Colors.white,
                                  elevation: 0,
                                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                                ),
                                onPressed: _toggleSubscription,
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    if (_isSubscribed) ...[
                                      const FaIcon(FontAwesomeIcons.check, size: 12, color: EmberColors.textMuted),
                                      const SizedBox(width: 6),
                                    ],
                                    Text(
                                      _isSubscribed ? 'Subscribed' : 'Subscribe',
                                      style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 16),

                          // Action Buttons Bar (Like, Dislike, Download, EQ, Share)
                          SingleChildScrollView(
                            scrollDirection: Axis.horizontal,
                            child: Row(
                              children: [
                                // Like button
                                _buildActionButton(
                                  icon: FontAwesomeIcons.thumbsUp,
                                  label: _isLiked ? 'Liked' : 'Like',
                                  isActive: _isLiked,
                                  onTap: () {
                                    setState(() {
                                      _isLiked = !_isLiked;
                                      if (_isLiked) _isDisliked = false;
                                    });
                                  },
                                ),
                                const SizedBox(width: 8),
                                // Dislike button
                                _buildActionButton(
                                  icon: FontAwesomeIcons.thumbsDown,
                                  label: 'Dislike',
                                  isActive: _isDisliked,
                                  onTap: () {
                                    setState(() {
                                      _isDisliked = !_isDisliked;
                                      if (_isDisliked) _isLiked = false;
                                    });
                                  },
                                ),
                                const SizedBox(width: 8),
                                // Download Button (Video / Audio choice)
                                _buildActionButton(
                                  icon: FontAwesomeIcons.download,
                                  label: 'Download',
                                  onTap: () => _showDownloadOptions(context),
                                ),
                                const SizedBox(width: 8),
                                // Sound Shaping & EQ
                                _buildActionButton(
                                  icon: FontAwesomeIcons.sliders,
                                  label: 'Sound EQ',
                                  onTap: () => SoundShapingSheet.show(context),
                                ),
                                const SizedBox(width: 8),
                                // Share
                                _buildActionButton(
                                  icon: FontAwesomeIcons.shareNodes,
                                  label: 'Share',
                                  onTap: () {
                                    final url = 'https://www.youtube.com/watch?v=${_currentVideo.id}';
                                    Clipboard.setData(ClipboardData(text: url));
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      const SnackBar(
                                        content: Text('YouTube video link copied to clipboard!'),
                                        backgroundColor: EmberColors.surfaceContainerHigh,
                                      ),
                                    );
                                  },
                                ),
                                const SizedBox(width: 8),
                                // Add to playlist
                                _buildActionButton(
                                  icon: FontAwesomeIcons.listCheck,
                                  label: 'Save',
                                  onTap: () => TrackOptionsSheet.show(context, _currentVideo),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(height: 12),
                        ],
                      ),
                    ),
                  ),
                  SliverPersistentHeader(
                    pinned: true,
                    delegate: _SliverTabBarDelegate(
                      TabBar(
                        controller: _tabController,
                        indicatorColor: EmberColors.primaryBlue,
                        indicatorWeight: 3,
                        labelColor: EmberColors.primaryBlueHi,
                        unselectedLabelColor: EmberColors.textMuted,
                        labelStyle: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
                        tabs: const [
                          Tab(text: 'Up Next & Mix'),
                          Tab(text: 'Comments'),
                        ],
                      ),
                    ),
                  ),
                ],
                body: TabBarView(
                  controller: _tabController,
                  children: [
                    // Up Next / Related Videos & YouTube Mix
                    _buildUpNextTab(),

                    // Real YouTube Comments
                    _buildCommentsTab(),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildActionButton({
    required FaIconData icon,
    required String label,
    required VoidCallback onTap,
    bool isActive = false,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(20),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
        decoration: BoxDecoration(
          color: isActive ? EmberColors.primaryBlue.withValues(alpha: 0.2) : EmberColors.surfaceContainerHigh,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: isActive ? EmberColors.primaryBlue : Colors.white.withValues(alpha: 0.08),
            width: 1,
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            FaIcon(
              icon,
              size: 13,
              color: isActive ? EmberColors.primaryBlueHi : EmberColors.textPrimary,
            ),
            const SizedBox(width: 8),
            Text(
              label,
              style: TextStyle(
                color: isActive ? EmberColors.primaryBlueHi : EmberColors.textPrimary,
                fontSize: 12.5,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildVideoViewport() {
    if (_isListenMode) {
      return AspectRatio(
        aspectRatio: 16 / 9,
        child: Container(
          color: Colors.black,
          child: Stack(
            children: [
              Positioned.fill(
                child: AmbientGlow(
                  glowColor: EmberColors.primaryBlue,
                  child: const SizedBox.expand(),
                ),
              ),
              Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const SizedBox(
                      width: 120,
                      height: 120,
                      child: VinylDisc(isPlaying: true),
                    ),
                    const SizedBox(height: 10),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                      decoration: BoxDecoration(
                        color: EmberColors.primaryBlue.withValues(alpha: 0.2),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: EmberColors.primaryBlue.withValues(alpha: 0.4)),
                      ),
                      child: const Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          FaIcon(FontAwesomeIcons.headphones, size: 12, color: EmberColors.secondaryCyan),
                          SizedBox(width: 6),
                          Text('Listen Mode (Background Active)', style: TextStyle(color: EmberColors.secondaryCyan, fontSize: 11, fontWeight: FontWeight.bold)),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              Positioned(
                top: 10,
                right: 10,
                child: IconButton(
                  icon: const FaIcon(FontAwesomeIcons.video, size: 16, color: Colors.white),
                  onPressed: _toggleListenMode,
                  tooltip: 'Switch back to Video',
                ),
              ),
            ],
          ),
        ),
      );
    }

    return AspectRatio(
      aspectRatio: 16 / 9,
      child: Container(
        color: Colors.black,
        child: GestureDetector(
          onTap: _toggleControls,
          behavior: HitTestBehavior.opaque,
          child: Stack(
            children: [
              // The Actual Video Player
              if (_controller != null && _controller!.value.isInitialized)
                Center(
                  child: AspectRatio(
                    aspectRatio: _controller!.value.aspectRatio,
                    child: VideoPlayer(_controller!),
                  ),
                )
              else if (_isLoadingVideo)
                Center(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const CircularProgressIndicator(color: EmberColors.primaryBlue),
                      const SizedBox(height: 12),
                      Text(
                        'Buffering ${_currentVideo.title}...',
                        style: const TextStyle(color: EmberColors.textMuted, fontSize: 12),
                        maxLines: 1,
                      ),
                    ],
                  ),
                )
              else if (_hasVideoError)
                Center(
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const FaIcon(FontAwesomeIcons.triangleExclamation, color: EmberColors.error, size: 28),
                        const SizedBox(height: 8),
                        const Text('Stream playback error', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                        const SizedBox(height: 4),
                        Text(_errorMessage, style: const TextStyle(color: EmberColors.textMuted, fontSize: 11), textAlign: TextAlign.center, maxLines: 2),
                        const SizedBox(height: 12),
                        ElevatedButton(
                          onPressed: _loadVideo,
                          style: ElevatedButton.styleFrom(backgroundColor: EmberColors.primaryBlue),
                          child: const Text('Retry'),
                        ),
                      ],
                    ),
                  ),
                ),

              // Controls HUD Overlay
              if (_showControls && _controller != null && _controller!.value.isInitialized)
                Container(
                  color: Colors.black.withValues(alpha: 0.45),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      // Top Bar in Video
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                        child: Row(
                          children: [
                            IconButton(
                              icon: const FaIcon(FontAwesomeIcons.chevronDown, size: 18, color: Colors.white),
                              onPressed: () {
                                if (_isFullscreen) {
                                  _toggleFullscreen();
                                } else {
                                  Navigator.of(context).pop();
                                }
                              },
                            ),
                            Expanded(
                              child: Text(
                                _currentVideo.title,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: const TextStyle(color: Colors.white, fontSize: 13, fontWeight: FontWeight.bold),
                              ),
                            ),
                            // Quality selector
                            IconButton(
                              icon: const FaIcon(FontAwesomeIcons.gear, size: 16, color: Colors.white),
                              onPressed: _showQualityPicker,
                              tooltip: 'Quality',
                            ),
                            // Listen Mode switch
                            IconButton(
                              icon: const FaIcon(FontAwesomeIcons.headphones, size: 16, color: EmberColors.secondaryCyan),
                              onPressed: _toggleListenMode,
                              tooltip: 'Switch to Background Listen Mode',
                            ),
                          ],
                        ),
                      ),

                      // Center Playback Gestures (Rewind 10s, Play/Pause, Fast Forward 10s)
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          IconButton(
                            iconSize: 32,
                            icon: const FaIcon(FontAwesomeIcons.rotateLeft, color: Colors.white),
                            onPressed: () => _seekRelative(const Duration(seconds: -10)),
                          ),
                          const SizedBox(width: 24),
                          Container(
                            decoration: BoxDecoration(
                              color: Colors.black.withValues(alpha: 0.6),
                              shape: BoxShape.circle,
                            ),
                            child: IconButton(
                              iconSize: 48,
                              icon: FaIcon(
                                _controller!.value.isPlaying ? FontAwesomeIcons.pause : FontAwesomeIcons.play,
                                color: Colors.white,
                              ),
                              onPressed: _togglePlayPause,
                            ),
                          ),
                          const SizedBox(width: 24),
                          IconButton(
                            iconSize: 32,
                            icon: const FaIcon(FontAwesomeIcons.rotateRight, color: Colors.white),
                            onPressed: () => _seekRelative(const Duration(seconds: 10)),
                          ),
                        ],
                      ),

                      // Bottom Progress Scrubber Bar & Fullscreen
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                        child: Row(
                          children: [
                            Text(
                              _formatDuration(_controller!.value.position),
                              style: const TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.bold),
                            ),
                            Expanded(
                              child: VideoProgressIndicator(
                                _controller!,
                                allowScrubbing: true,
                                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                                colors: const VideoProgressColors(
                                  playedColor: EmberColors.primaryBlue,
                                  bufferedColor: Colors.white30,
                                  backgroundColor: Colors.white10,
                                ),
                              ),
                            ),
                            Text(
                              _formatDuration(_controller!.value.duration),
                              style: const TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.bold),
                            ),
                            IconButton(
                              icon: FaIcon(
                                _isFullscreen ? FontAwesomeIcons.compress : FontAwesomeIcons.expand,
                                size: 14,
                                color: Colors.white,
                              ),
                              onPressed: _toggleFullscreen,
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
    );
  }

  Widget _buildUpNextTab() {
    if (_isLoadingRelated) {
      return const Center(child: CircularProgressIndicator(color: EmberColors.primaryBlue));
    }
    if (_relatedVideos.isEmpty) {
      return const Center(
        child: Text('No related videos found.', style: TextStyle(color: EmberColors.textMuted)),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      itemCount: _relatedVideos.length,
      itemBuilder: (context, index) {
        final item = _relatedVideos[index];
        return InkWell(
          onTap: () => _playNextVideo(item),
          child: Padding(
            padding: const EdgeInsets.only(bottom: 14),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                ClipRRect(
                  borderRadius: BorderRadius.circular(10),
                  child: SizedBox(
                    width: 120,
                    height: 68,
                    child: CachedNetworkImage(
                      imageUrl: item.artworkUrl,
                      fit: BoxFit.cover,
                      placeholder: (context, url) => Container(color: EmberColors.surfaceContainer),
                      errorWidget: (context, url, error) => Container(color: EmberColors.surfaceContainer),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        item.title,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(color: EmberColors.textPrimary, fontSize: 13, fontWeight: FontWeight.w600),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        item.artist,
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
        );
      },
    );
  }

  Widget _buildCommentsTab() {
    if (_isLoadingComments) {
      return const Center(child: CircularProgressIndicator(color: EmberColors.primaryBlue));
    }
    if (_comments.isEmpty) {
      return const Center(
        child: Text('Comments are disabled or unavailable for this video.', style: TextStyle(color: EmberColors.textMuted)),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      itemCount: _comments.length,
      itemBuilder: (context, index) {
        final comment = _comments[index];
        return Padding(
          padding: const EdgeInsets.only(bottom: 16),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 32,
                height: 32,
                decoration: const BoxDecoration(
                  shape: BoxShape.circle,
                  color: EmberColors.surfaceContainerHigh,
                ),
                child: ClipOval(
                  child: comment.authorThumbnail.isNotEmpty
                      ? CachedNetworkImage(
                          imageUrl: comment.authorThumbnail,
                          fit: BoxFit.cover,
                          errorWidget: (context, url, error) => const Center(
                            child: FaIcon(FontAwesomeIcons.user, size: 14, color: EmberColors.textMuted),
                          ),
                        )
                      : const Center(
                          child: FaIcon(FontAwesomeIcons.user, size: 14, color: EmberColors.textMuted),
                        ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Text(
                          comment.author,
                          style: const TextStyle(color: EmberColors.textPrimary, fontSize: 12.5, fontWeight: FontWeight.bold),
                        ),
                        const SizedBox(width: 8),
                        Text(
                          comment.publishedTime,
                          style: const TextStyle(color: EmberColors.textMuted, fontSize: 11),
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Text(
                      comment.text,
                      style: const TextStyle(color: EmberColors.textSecondary, fontSize: 12.5, height: 1.3),
                    ),
                    if (comment.likeCount > 0) ...[
                      const SizedBox(height: 6),
                      Row(
                        children: [
                          const FaIcon(FontAwesomeIcons.thumbsUp, size: 10, color: EmberColors.textMuted),
                          const SizedBox(width: 4),
                          Text(comment.formattedLikes, style: const TextStyle(color: EmberColors.textMuted, fontSize: 10.5)),
                        ],
                      ),
                    ],
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  void _showDownloadOptions(BuildContext context) {
    showModalBottomSheet(
      context: context,
      backgroundColor: EmberColors.surfaceContainerLow,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 40,
                height: 4,
                margin: const EdgeInsets.only(bottom: 12),
                decoration: BoxDecoration(
                  color: EmberColors.textMuted.withValues(alpha: 0.3),
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              const Padding(
                padding: EdgeInsets.symmetric(horizontal: 20, vertical: 6),
                child: Text('Download Media', style: TextStyle(color: EmberColors.textPrimary, fontSize: 16, fontWeight: FontWeight.bold)),
              ),
              ListTile(
                leading: Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: EmberColors.secondaryCyan.withValues(alpha: 0.15),
                    shape: BoxShape.circle,
                  ),
                  child: const FaIcon(FontAwesomeIcons.film, size: 14, color: EmberColors.secondaryCyan),
                ),
                title: const Text('Download Video (MP4)', style: TextStyle(color: EmberColors.textPrimary, fontSize: 14, fontWeight: FontWeight.w600)),
                subtitle: const Text('High definition MP4 video with audio directly to Movies folder', style: TextStyle(color: EmberColors.textMuted, fontSize: 11)),
                onTap: () async {
                  Navigator.pop(ctx);
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('Downloading video "${_currentVideo.title}"...'),
                      backgroundColor: EmberColors.surfaceContainerHigh,
                    ),
                  );
                  await DownloadService.downloadVideo(_currentVideo);
                },
              ),
              ListTile(
                leading: Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: EmberColors.primaryBlueHi.withValues(alpha: 0.15),
                    shape: BoxShape.circle,
                  ),
                  child: const FaIcon(FontAwesomeIcons.music, size: 14, color: EmberColors.primaryBlueHi),
                ),
                title: const Text('Download Audio Only (M4A)', style: TextStyle(color: EmberColors.textPrimary, fontSize: 14, fontWeight: FontWeight.w600)),
                subtitle: const Text('High bitrate audio file to Music folder for offline listening', style: TextStyle(color: EmberColors.textMuted, fontSize: 11)),
                onTap: () async {
                  Navigator.pop(ctx);
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('Downloading audio "${_currentVideo.title}"...'),
                      backgroundColor: EmberColors.surfaceContainerHigh,
                    ),
                  );
                  final player = Provider.of<PlayerProvider>(context, listen: false);
                  await player.downloadAudio(_currentVideo);
                },
              ),
            ],
          ),
        ),
      ),
    );
  }

  String _formatDuration(Duration d) {
    final m = d.inMinutes;
    final s = d.inSeconds % 60;
    return '$m:${s.toString().padLeft(2, '0')}';
  }
}

class _SliverTabBarDelegate extends SliverPersistentHeaderDelegate {
  final TabBar _tabBar;

  _SliverTabBarDelegate(this._tabBar);

  @override
  double get minExtent => _tabBar.preferredSize.height;
  @override
  double get maxExtent => _tabBar.preferredSize.height;

  @override
  Widget build(BuildContext context, double shrinkOffset, bool overlapsContent) {
    return Container(
      color: EmberColors.obsidianBase,
      child: _tabBar,
    );
  }

  @override
  bool shouldRebuild(_SliverTabBarDelegate oldDelegate) {
    return false;
  }
}
