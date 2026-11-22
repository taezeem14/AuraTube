import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:provider/provider.dart';
import '../../models/song.dart';
import '../../providers/player_provider.dart';
import '../../services/youtube_feed_service.dart';
import '../../theme/ember_theme.dart';
import '../../widgets/aura_video_card.dart';
import '../aura_video_player_screen.dart';

typedef AuraTrendingTab = AuraHomeTab;

/// Production Monochromatic Feed Tab (NewPipe Kiosk + Metrolist Quick Picks Strip)
class AuraHomeTab extends StatefulWidget {
  final VoidCallback? onOpenSearch;
  final VoidCallback? onOpenLibrary;

  const AuraHomeTab({
    super.key,
    this.onOpenSearch,
    this.onOpenLibrary,
  });

  @override
  State<AuraHomeTab> createState() => _AuraHomeTabState();
}

class _AuraHomeTabState extends State<AuraHomeTab> with AutomaticKeepAliveClientMixin {
  String _selectedCategory = 'all';
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

    final videos = await YouTubeFeedService.fetchCategoryFeed(
      _selectedCategory,
      forceRefresh: forceRefresh,
    );

    if (mounted) {
      setState(() {
        _feedVideos = videos;
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);
    final player = context.watch<PlayerProvider>();
    final quickPicks = player.history.isNotEmpty
        ? player.history.take(8).toList()
        : player.favorites.take(8).toList();

    return Column(
      children: [
        // Monochromatic Category Pill Rail
        Container(
          color: EmberColors.obsidianBase,
          child: SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            physics: const BouncingScrollPhysics(),
            padding: const EdgeInsets.fromLTRB(14, 10, 14, 8),
            child: Row(
              children: YouTubeFeedService.categories.map((cat) {
                final catId = cat['id']!;
                final title = cat['title']!;
                final isSelected = _selectedCategory == catId;

                return Padding(
                  padding: const EdgeInsets.only(right: 8),
                  child: GestureDetector(
                    onTap: () {
                      HapticFeedback.selectionClick();
                      setState(() => _selectedCategory = catId);
                      _loadFeed();
                    },
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 160),
                      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
                      decoration: BoxDecoration(
                        color: isSelected ? EmberColors.monoWhite : EmberColors.surfaceContainerLow,
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(
                          color: isSelected ? EmberColors.monoWhite : EmberColors.outlineVariant,
                          width: 1,
                        ),
                      ),
                      child: Text(
                        title,
                        style: TextStyle(
                          color: isSelected ? EmberColors.onAccent : EmberColors.textSecondary,
                          fontSize: 12,
                          fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                        ),
                      ),
                    ),
                  ),
                );
              }).toList(),
            ),
          ),
        ),

        // Videos Feed + Metrolist Speed Dial Quick Resume
        Expanded(
          child: RefreshIndicator(
            color: EmberColors.monoWhite,
            backgroundColor: EmberColors.surfaceContainerHigh,
            onRefresh: () => _loadFeed(forceRefresh: true),
            child: _isLoading
                ? const Center(
                    child: CircularProgressIndicator(color: EmberColors.monoWhite, strokeWidth: 2),
                  )
                : _feedVideos.isEmpty
                    ? ListView(
                        children: [
                          Container(
                            height: 300,
                            alignment: Alignment.center,
                            child: Column(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                const FaIcon(FontAwesomeIcons.circleExclamation, size: 34, color: EmberColors.textMuted),
                                const SizedBox(height: 12),
                                const Text(
                                  'Unable to load feed',
                                  style: TextStyle(color: EmberColors.textPrimary, fontSize: 15, fontWeight: FontWeight.w700),
                                ),
                                const SizedBox(height: 10),
                                ElevatedButton.icon(
                                  onPressed: () => _loadFeed(forceRefresh: true),
                                  icon: const FaIcon(FontAwesomeIcons.arrowsRotate, size: 12),
                                  label: const Text('Retry'),
                                ),
                              ],
                            ),
                          ),
                        ],
                      )
                    : ListView.builder(
                        padding: const EdgeInsets.fromLTRB(14, 6, 14, 96),
                        itemCount: _feedVideos.length + (quickPicks.isNotEmpty && _selectedCategory == 'all' ? 1 : 0),
                        itemBuilder: (context, index) {
                          if (quickPicks.isNotEmpty && _selectedCategory == 'all') {
                            if (index == 0) {
                              return _QuickPicksStrip(items: quickPicks);
                            }
                            return AuraVideoCard(video: _feedVideos[index - 1]);
                          }
                          return AuraVideoCard(video: _feedVideos[index]);
                        },
                      ),
          ),
        ),
      ],
    );
  }
}

class _QuickPicksStrip extends StatelessWidget {
  final List<Song> items;
  const _QuickPicksStrip({required this.items});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Padding(
          padding: EdgeInsets.fromLTRB(2, 4, 2, 10),
          child: Row(
            children: [
              FaIcon(FontAwesomeIcons.bolt, size: 11, color: EmberColors.monoSilver),
              SizedBox(width: 6),
              Text(
                'KEEP LISTENING & QUICK PICKS',
                style: TextStyle(
                  color: EmberColors.textMuted,
                  fontSize: 10.5,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 1.1,
                ),
              ),
            ],
          ),
        ),
        SizedBox(
          height: 114,
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            physics: const BouncingScrollPhysics(),
            itemCount: items.length,
            separatorBuilder: (context, idx) => const SizedBox(width: 10),
            itemBuilder: (context, i) {
              final item = items[i];
              final cleanId = item.id.startsWith('yt_') ? item.id.substring(3) : item.id;
              return GestureDetector(
                onTap: () {
                  Navigator.of(context).push(
                    MaterialPageRoute(builder: (_) => AuraVideoPlayerScreen(video: item)),
                  );
                },
                child: SizedBox(
                  width: 142,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      ClipRRect(
                        borderRadius: BorderRadius.circular(10),
                        child: Container(
                          width: 142,
                          height: 78,
                          color: EmberColors.surfaceContainerLow,
                          child: CachedNetworkImage(
                            imageUrl: item.artworkUrl.isNotEmpty
                                ? item.artworkUrl
                                : 'https://i.ytimg.com/vi/$cleanId/hqdefault.jpg',
                            fit: BoxFit.cover,
                            errorWidget: (c, u, e) => const Center(
                              child: FaIcon(FontAwesomeIcons.play, size: 16, color: EmberColors.textMuted),
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(height: 5),
                      Text(
                        item.title,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          color: EmberColors.textPrimary,
                          fontSize: 11.5,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      Text(
                        item.artist,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(color: EmberColors.textMuted, fontSize: 10),
                      ),
                    ],
                  ),
                ),
              );
            },
          ),
        ),
        const SizedBox(height: 14),
        const Divider(color: EmberColors.borderSubtle, height: 1),
        const SizedBox(height: 14),
      ],
    );
  }
}
