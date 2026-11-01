import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import '../../models/song.dart';
import '../../services/youtube_feed_service.dart';
import '../../theme/ember_theme.dart';
import '../../widgets/aura_video_card.dart';

typedef AuraTrendingTab = AuraHomeTab;

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

class _AuraHomeTabState extends State<AuraHomeTab> {
  String _selectedCategory = 'all';
  List<Song> _feedVideos = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadFeed();
  }

  Future<void> _loadFeed({bool forceRefresh = false}) async {
    setState(() {
      _isLoading = true;
    });

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
    return Column(
      children: [
        // Category Filter Chips (NewPipe Kiosk / Topic Bar)
        Container(
          color: EmberColors.obsidianBase,
          child: SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
            child: Row(
              children: YouTubeFeedService.categories.map((cat) {
                final catId = cat['id']!;
                final title = cat['title']!;
                final isSelected = _selectedCategory == catId;

                return Padding(
                  padding: const EdgeInsets.only(right: 8),
                  child: InkWell(
                    borderRadius: BorderRadius.circular(8),
                    onTap: () {
                      setState(() {
                        _selectedCategory = catId;
                      });
                      _loadFeed();
                    },
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 180),
                      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
                      decoration: BoxDecoration(
                        color: isSelected ? EmberColors.primaryBlue : EmberColors.surfaceContainerLow,
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(
                          color: isSelected
                              ? EmberColors.primaryBlueHi.withValues(alpha: 0.6)
                              : Colors.white.withValues(alpha: 0.08),
                          width: 1,
                        ),
                      ),
                      child: Text(
                        title,
                        style: TextStyle(
                          color: isSelected ? Colors.white : EmberColors.textSecondary,
                          fontSize: 12,
                          fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
                        ),
                      ),
                    ),
                  ),
                );
              }).toList(),
            ),
          ),
        ),

        // Videos Stream
        Expanded(
          child: RefreshIndicator(
            color: EmberColors.primaryBlue,
            backgroundColor: EmberColors.surfaceContainerHigh,
            onRefresh: () => _loadFeed(forceRefresh: true),
            child: _isLoading
                ? const Center(
                    child: CircularProgressIndicator(color: EmberColors.primaryBlue),
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
                                const FaIcon(FontAwesomeIcons.circleExclamation, size: 36, color: EmberColors.textMuted),
                                const SizedBox(height: 12),
                                const Text(
                                  'Unable to load feed',
                                  style: TextStyle(color: EmberColors.textPrimary, fontSize: 15, fontWeight: FontWeight.bold),
                                ),
                                const SizedBox(height: 8),
                                ElevatedButton.icon(
                                  onPressed: () => _loadFeed(forceRefresh: true),
                                  icon: const FaIcon(FontAwesomeIcons.arrowsRotate, size: 13),
                                  label: const Text('Try Again'),
                                  style: ElevatedButton.styleFrom(backgroundColor: EmberColors.primaryBlue),
                                ),
                              ],
                            ),
                          ),
                        ],
                      )
                    : ListView.builder(
                        padding: const EdgeInsets.fromLTRB(14, 8, 14, 80),
                        itemCount: _feedVideos.length,
                        itemBuilder: (context, index) {
                          return AuraVideoCard(video: _feedVideos[index]);
                        },
                      ),
          ),
        ),
      ],
    );
  }
}
