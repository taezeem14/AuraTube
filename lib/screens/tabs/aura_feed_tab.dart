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

class _AuraFeedTabState extends State<AuraFeedTab> with AutomaticKeepAliveClientMixin {
  List<Song> _feedVideos = [];
  bool _isLoading = true;

  @override
  bool get wantKeepAlive => true;

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
      final List<Song> combined = [];
      for (final sub in subs.take(5)) {
        final results = await YouTubeFeedService.fetchCategoryFeed('all', forceRefresh: forceRefresh);
        final matches = results.where((s) => s.artist.toLowerCase().contains(sub.name.toLowerCase()));
        combined.addAll(matches);
      }

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
    super.build(context);
    final storage = context.watch<StorageService>();
    final subs = storage.loadSubscriptions();

    if (_isLoading) {
      return const Center(
        child: CircularProgressIndicator(color: EmberColors.monoWhite, strokeWidth: 2),
      );
    }

    if (subs.isEmpty || _feedVideos.isEmpty) {
      return RefreshIndicator(
        color: EmberColors.monoWhite,
        backgroundColor: EmberColors.surfaceContainerHigh,
        onRefresh: () => _loadFeed(forceRefresh: true),
        child: ListView(
          padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 56),
          children: [
            Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    width: 68,
                    height: 68,
                    decoration: BoxDecoration(
                      color: EmberColors.surfaceContainerLow,
                      shape: BoxShape.circle,
                      border: Border.all(color: EmberColors.outlineVariant),
                    ),
                    child: const Center(
                      child: FaIcon(FontAwesomeIcons.rss, size: 26, color: EmberColors.monoWhite),
                    ),
                  ),
                  const SizedBox(height: 18),
                  const Text(
                    "What's New Feed",
                    style: TextStyle(
                      color: EmberColors.textPrimary,
                      fontSize: 17,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    'Subscribe to YouTube creators locally to aggregate their latest uploads here with zero account tracking.',
                    textAlign: TextAlign.center,
                    style: TextStyle(color: EmberColors.textMuted, fontSize: 12.5, height: 1.45),
                  ),
                  const SizedBox(height: 22),
                  ElevatedButton.icon(
                    onPressed: widget.onExploreTrending,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: EmberColors.monoWhite,
                      foregroundColor: EmberColors.onAccent,
                      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                    icon: const FaIcon(FontAwesomeIcons.fire, size: 13),
                    label: const Text('Explore Trending', style: TextStyle(fontWeight: FontWeight.w700)),
                  ),
                ],
              ),
            ),
          ],
        ),
      );
    }

    return RefreshIndicator(
      color: EmberColors.monoWhite,
      backgroundColor: EmberColors.surfaceContainerHigh,
      onRefresh: () => _loadFeed(forceRefresh: true),
      child: ListView.builder(
        padding: const EdgeInsets.fromLTRB(14, 12, 14, 96),
        itemCount: _feedVideos.length,
        itemBuilder: (context, index) => AuraVideoCard(video: _feedVideos[index]),
      ),
    );
  }
}
