import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:provider/provider.dart';
import '../../models/song.dart';
import '../../services/storage_service.dart';
import '../../services/youtube_feed_service.dart';
import '../../theme/ember_theme.dart';
import '../../widgets/aura_video_card.dart';

class AuraFeedTab extends StatefulWidget {
  final VoidCallback? onExploreTrending;

  const AuraFeedTab({super.key, this.onExploreTrending});

  @override
  State<AuraFeedTab> createState() => _AuraFeedTabState();
}

class _AuraFeedTabState extends State<AuraFeedTab> {
  List<Song> _feedVideos = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadFeed();
  }

  Future<void> _loadFeed({bool forceRefresh = false}) async {
    setState(() => _isLoading = true);

    final storage = Provider.of<StorageService>(context, listen: false);
    final subs = storage.loadSubscriptions();

    if (subs.isEmpty) {
      if (mounted) {
        setState(() {
          _feedVideos = [];
          _isLoading = false;
        });
      }
      return;
    }

    try {
      // Fetch latest uploads for the first few subscribed channels or search their names
      final List<Song> combined = [];
      for (final sub in subs.take(5)) {
        final results = await YouTubeFeedService.fetchCategoryFeed('all', forceRefresh: forceRefresh);
        final matches = results.where((s) => s.artist.toLowerCase().contains(sub.name.toLowerCase()));
        combined.addAll(matches);
      }

      // If specific search didn't match, fallback to general fresh feed
      if (combined.isEmpty) {
        final fallback = await YouTubeFeedService.fetchCategoryFeed('all', forceRefresh: forceRefresh);
        combined.addAll(fallback.take(15));
      }

      if (mounted) {
        setState(() {
          _feedVideos = combined;
          _isLoading = false;
        });
      }
    } catch (_) {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final storage = context.watch<StorageService>();
    final subs = storage.loadSubscriptions();

    if (_isLoading) {
      return const Center(
        child: CircularProgressIndicator(color: EmberColors.primaryBlue),
      );
    }

    if (subs.isEmpty || _feedVideos.isEmpty) {
      return RefreshIndicator(
        color: EmberColors.primaryBlue,
        backgroundColor: EmberColors.surfaceContainerHigh,
        onRefresh: () => _loadFeed(forceRefresh: true),
        child: ListView(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 48),
          children: [
            Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    width: 72,
                    height: 72,
                    decoration: BoxDecoration(
                      color: EmberColors.primaryBlue.withValues(alpha: 0.12),
                      shape: BoxShape.circle,
                    ),
                    child: const Center(
                      child: FaIcon(
                        FontAwesomeIcons.rss,
                        size: 32,
                        color: EmberColors.primaryBlue,
                      ),
                    ),
                  ),
                  const SizedBox(height: 20),
                  const Text(
                    "What's New (Feed)",
                    style: TextStyle(
                      color: EmberColors.textPrimary,
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 10),
                  const Text(
                    'Subscribe to YouTube channels to see their latest uploads and notifications right here in your feed.',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      color: EmberColors.textMuted,
                      fontSize: 13,
                      height: 1.4,
                    ),
                  ),
                  const SizedBox(height: 24),
                  ElevatedButton.icon(
                    onPressed: widget.onExploreTrending,
                    icon: const FaIcon(FontAwesomeIcons.fire, size: 14, color: Colors.white),
                    label: const Text('Browse Trending Videos', style: TextStyle(fontWeight: FontWeight.bold)),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: EmberColors.primaryBlue,
                      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      );
    }

    return RefreshIndicator(
      color: EmberColors.primaryBlue,
      backgroundColor: EmberColors.surfaceContainerHigh,
      onRefresh: () => _loadFeed(forceRefresh: true),
      child: ListView.builder(
        padding: const EdgeInsets.fromLTRB(16, 12, 16, 80),
        itemCount: _feedVideos.length,
        itemBuilder: (context, index) {
          return AuraVideoCard(video: _feedVideos[index]);
        },
      ),
    );
  }
}
