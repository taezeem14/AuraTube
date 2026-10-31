import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:video_player/video_player.dart';
import 'package:provider/provider.dart';
import '../models/youtube_video.dart';
import '../models/youtube_comment.dart';
import '../services/youtube_service.dart';
import '../services/storage_service.dart';
import '../theme/aura_theme.dart';
import '../widgets/comment_tile.dart';
import 'sound_shaping_sheet.dart';

class ShortsScreen extends StatefulWidget {
  const ShortsScreen({super.key});

  @override
  State<ShortsScreen> createState() => _ShortsScreenState();
}

class _ShortsScreenState extends State<ShortsScreen> {
  final PageController _pageController = PageController();
  List<YouTubeVideo> _shorts = [];
  bool _isLoading = true;
  int _currentIndex = 0;

  @override
  void initState() {
    super.initState();
    _loadShorts();
  }

  Future<void> _loadShorts() async {
    setState(() => _isLoading = true);
    try {
      final items = await YouTubeService.getShortsFeed();
      if (mounted) {
        setState(() {
          _shorts = items;
          _isLoading = false;
        });
      }
    } catch (_) {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Scaffold(
        backgroundColor: Colors.black,
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              CircularProgressIndicator(color: AuraColors.primaryBlueLight),
              SizedBox(height: 16),
              Text('Loading YouTube Shorts...', style: TextStyle(color: AuraColors.textSecondary, fontSize: 13)),
            ],
          ),
        ),
      );
    }

    if (_shorts.isEmpty) {
      return Scaffold(
        backgroundColor: Colors.black,
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const FaIcon(FontAwesomeIcons.bolt, color: AuraColors.accentCyan, size: 40),
              const SizedBox(height: 16),
              const Text('No Shorts available right now', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
              const SizedBox(height: 12),
              ElevatedButton(
                onPressed: _loadShorts,
                style: ElevatedButton.styleFrom(backgroundColor: AuraColors.primaryBlue),
                child: const Text('Refresh Feed', style: TextStyle(color: Colors.white)),
              ),
            ],
          ),
        ),
      );
    }

    return Scaffold(
      backgroundColor: Colors.black,
      body: PageView.builder(
        controller: _pageController,
        scrollDirection: Axis.vertical,
        itemCount: _shorts.length,
        onPageChanged: (index) {
          setState(() => _currentIndex = index);
        },
        itemBuilder: (context, index) {
          final short = _shorts[index];
          return ShortPageItem(
            video: short,
            isActive: index == _currentIndex,
          );
        },
      ),
    );
  }
}

class ShortPageItem extends StatefulWidget {
  final YouTubeVideo video;
  final bool isActive;

  const ShortPageItem({super.key, required this.video, required this.isActive});

  @override
  State<ShortPageItem> createState() => _ShortPageItemState();
}

class _ShortPageItemState extends State<ShortPageItem> {
  VideoPlayerController? _controller;
  bool _isInitialized = false;
  List<YouTubeComment> _comments = [];
  bool _isLoadingComments = false;

  @override
  void initState() {
    super.initState();
    if (widget.isActive) {
      _initPlayer();
    }
  }

  @override
  void didUpdateWidget(covariant ShortPageItem oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.isActive && !oldWidget.isActive) {
      _initPlayer();
    } else if (!widget.isActive && oldWidget.isActive) {
      _controller?.pause();
    }
  }

  Future<void> _initPlayer() async {
    try {
      final streams = await YouTubeService.resolveStreams(widget.video.id);
      if (streams != null && mounted) {
        _controller?.dispose();
        _controller = VideoPlayerController.networkUrl(Uri.parse(streams.videoUrl));
        await _controller!.initialize();
        await _controller!.setLooping(true);
        if (mounted && widget.isActive) {
          await _controller!.play();
          setState(() => _isInitialized = true);
        }
      }
    } catch (_) {}
  }

  Future<void> _loadComments() async {
    setState(() => _isLoadingComments = true);
    try {
      final list = await YouTubeService.getComments(widget.video.id);
      if (mounted) setState(() => _comments = list);
    } catch (_) {} finally {
      if (mounted) setState(() => _isLoadingComments = false);
    }
  }

  void _showCommentsModal(BuildContext context) {
    if (_comments.isEmpty) _loadComments();
    showModalBottomSheet(
      context: context,
      backgroundColor: AuraColors.surface,
      isScrollControlled: true,
      useSafeArea: true,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
      builder: (ctx) => DraggableScrollableSheet(
        initialChildSize: 0.8,
        minChildSize: 0.4,
        maxChildSize: 0.95,
        expand: false,
        builder: (_, scrollController) => Column(
          children: [
            Container(
              width: 38,
              height: 4,
              margin: const EdgeInsets.symmetric(vertical: 12),
              decoration: BoxDecoration(color: AuraColors.textMuted.withValues(alpha: 0.4), borderRadius: BorderRadius.circular(2)),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text('Shorts Comments (${_comments.length})', style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16)),
                  IconButton(icon: const Icon(Icons.close_rounded, color: Colors.white70), onPressed: () => Navigator.pop(ctx)),
                ],
              ),
            ),
            const Divider(color: AuraColors.outline, height: 1),
            Expanded(
              child: _isLoadingComments
                  ? const Center(child: CircularProgressIndicator())
                  : _comments.isEmpty
                      ? const Center(child: Text('No comments yet', style: TextStyle(color: AuraColors.textMuted)))
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

  @override
  void dispose() {
    _controller?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final storage = context.watch<StorageService>();
    final isLiked = storage.isLiked(widget.video.id);
    final isSubbed = storage.isSubscribed(widget.video.channelId);

    return Stack(
      fit: StackFit.expand,
      children: [
        // Video Background
        if (_isInitialized && _controller != null)
          GestureDetector(
            onTap: () {
              if (_controller!.value.isPlaying) {
                _controller!.pause();
              } else {
                _controller!.play();
              }
              setState(() {});
            },
            child: Center(
              child: AspectRatio(
                aspectRatio: _controller!.value.aspectRatio,
                child: VideoPlayer(_controller!),
              ),
            ),
          )
        else
          Stack(
            fit: StackFit.expand,
            children: [
              Image.network(widget.video.thumbnailUrl, fit: BoxFit.cover),
              Container(color: Colors.black.withValues(alpha: 0.4)),
              const Center(child: CircularProgressIndicator(color: AuraColors.primaryBlueLight)),
            ],
          ),

        // Gradient Shadow Bottom
        Positioned(
          left: 0,
          right: 0,
          bottom: 0,
          height: 250,
          child: Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [Colors.transparent, Colors.black.withValues(alpha: 0.85)],
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
              ),
            ),
          ),
        ),

        // Bottom Left Info Overlay
        Positioned(
          left: 16,
          bottom: 24,
          right: 80,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    width: 36,
                    height: 36,
                    decoration: const BoxDecoration(
                      shape: BoxShape.circle,
                      gradient: LinearGradient(colors: [AuraColors.primaryBlue, AuraColors.accentCyan]),
                    ),
                    child: Center(
                      child: Text(
                        widget.video.author.isNotEmpty ? widget.video.author[0].toUpperCase() : 'Y',
                        style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                      ),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Flexible(
                    child: Text(
                      widget.video.author,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 14),
                    ),
                  ),
                  const SizedBox(width: 8),
                  GestureDetector(
                    onTap: () {
                      storage.toggleSubscription(
                        channelId: widget.video.channelId,
                        name: widget.video.author,
                        avatarUrl: '',
                      );
                    },
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                      decoration: BoxDecoration(
                        color: isSubbed ? Colors.white24 : AuraColors.primaryBlue,
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: Text(
                        isSubbed ? 'Subscribed' : 'Subscribe',
                        style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 11),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 10),
              Text(
                widget.video.title,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(color: Colors.white, fontSize: 13, height: 1.3),
              ),
            ],
          ),
        ),

        // Right Side Action Column
        Positioned(
          right: 12,
          bottom: 24,
          child: Column(
            children: [
              // Like
              _buildActionButton(
                icon: isLiked ? FontAwesomeIcons.solidThumbsUp : FontAwesomeIcons.thumbsUp,
                color: isLiked ? AuraColors.primaryBlueLight : Colors.white,
                label: isLiked ? 'Liked' : 'Like',
                onTap: () => storage.toggleLike(widget.video),
              ),
              const SizedBox(height: 18),

              // Comments
              _buildActionButton(
                icon: FontAwesomeIcons.comment,
                color: Colors.white,
                label: 'Comments',
                onTap: () => _showCommentsModal(context),
              ),
              const SizedBox(height: 18),

              // Equalizer
              _buildActionButton(
                icon: FontAwesomeIcons.sliders,
                color: AuraColors.accentCyan,
                label: 'EQ',
                onTap: () => SoundShapingSheet.show(context),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildActionButton({
    required FaIconData icon,
    required Color color,
    required String label,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: Colors.black.withValues(alpha: 0.45),
              border: Border.all(color: Colors.white24, width: 0.8),
            ),
            child: FaIcon(icon, color: color, size: 20),
          ),
          const SizedBox(height: 5),
          Text(label, style: const TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.w600)),
        ],
      ),
    );
  }
}
