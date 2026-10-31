import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import '../../models/song.dart';
import '../../services/youtube_feed_service.dart';
import '../../theme/ember_theme.dart';
import '../../widgets/aura_video_card.dart';
import '../settings_screen.dart';
import '../sound_shaping_sheet.dart';

class AuraHomeTab extends StatefulWidget {
  final VoidCallback onOpenSearch;
  final VoidCallback onOpenLibrary;

  const AuraHomeTab({
    super.key,
    required this.onOpenSearch,
    required this.onOpenLibrary,
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
    return Scaffold(
      backgroundColor: EmberColors.obsidianBase,
      body: NestedScrollView(
        headerSliverBuilder: (context, innerBoxIsScrolled) => [
          // 1. Sleek Modern YouTube App Bar
          SliverAppBar(
            backgroundColor: EmberColors.obsidianBase.withValues(alpha: 0.95),
            elevation: 0,
            floating: true,
            pinned: false,
            automaticallyImplyLeading: false,
            titleSpacing: 16,
            title: Row(
              children: [
                // Glowing Aura Logo
                Container(
                  width: 34,
                  height: 34,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(10),
                    gradient: const LinearGradient(
                      colors: [EmberColors.primaryBlue, EmberColors.secondaryCyan],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: EmberColors.primaryBlue.withValues(alpha: 0.4),
                        blurRadius: 10,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(10),
                    child: Image.asset(
                      'assets/icon/app_icon.png',
                      fit: BoxFit.cover,
                      errorBuilder: (context, error, stackTrace) => const Center(
                        child: FaIcon(FontAwesomeIcons.play, size: 14, color: Colors.white),
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                // Brand Text
                RichText(
                  text: const TextSpan(
                    style: TextStyle(
                      fontFamily: 'Sora',
                      fontSize: 19,
                      fontWeight: FontWeight.bold,
                      letterSpacing: -0.5,
                    ),
                    children: [
                      TextSpan(text: 'Aura', style: TextStyle(color: Colors.white)),
                      TextSpan(text: 'Tube', style: TextStyle(color: EmberColors.primaryBlueHi)),
                    ],
                  ),
                ),
              ],
            ),
            actions: [
              IconButton(
                icon: const FaIcon(FontAwesomeIcons.magnifyingGlass, size: 16, color: EmberColors.textPrimary),
                tooltip: 'Search Videos',
                onPressed: widget.onOpenSearch,
              ),
              IconButton(
                icon: const FaIcon(FontAwesomeIcons.sliders, size: 16, color: EmberColors.textPrimary),
                tooltip: 'Sound Shaping & Equalizer',
                onPressed: () => SoundShapingSheet.show(context),
              ),
              IconButton(
                icon: const FaIcon(FontAwesomeIcons.gear, size: 16, color: EmberColors.textPrimary),
                tooltip: 'Settings',
                onPressed: () => SettingsScreen.show(context),
              ),
              const SizedBox(width: 6),
            ],
          ),

          // 2. Category Filter Chips (YouTube Video Categories)
          SliverToBoxAdapter(
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              child: Row(
                children: YouTubeFeedService.categories.map((cat) {
                  final catId = cat['id']!;
                  final title = cat['title']!;
                  final isSelected = _selectedCategory == catId;

                  return Padding(
                    padding: const EdgeInsets.only(right: 8),
                    child: InkWell(
                      borderRadius: BorderRadius.circular(10),
                      onTap: () {
                        setState(() {
                          _selectedCategory = catId;
                        });
                        _loadFeed();
                      },
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 180),
                        padding: const EdgeInsets.symmetric(horizontal: 15, vertical: 8),
                        decoration: BoxDecoration(
                          color: isSelected ? EmberColors.primaryBlue : EmberColors.surfaceContainerLow,
                          borderRadius: BorderRadius.circular(10),
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
                            fontSize: 12.5,
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
        ],
        body: RefreshIndicator(
          color: EmberColors.primaryBlue,
          backgroundColor: EmberColors.surfaceContainerHigh,
          onRefresh: () => _loadFeed(forceRefresh: true),
          child: _isLoading
              ? const Center(
                  child: CircularProgressIndicator(color: EmberColors.primaryBlue),
                )
              : _feedVideos.isEmpty
                  ? Center(
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const FaIcon(FontAwesomeIcons.circleExclamation, size: 36, color: EmberColors.textMuted),
                          const SizedBox(height: 12),
                          const Text('No videos found for this category', style: TextStyle(color: EmberColors.textPrimary, fontSize: 14, fontWeight: FontWeight.bold)),
                          const SizedBox(height: 12),
                          ElevatedButton(
                            style: ElevatedButton.styleFrom(backgroundColor: EmberColors.primaryBlue),
                            onPressed: () => _loadFeed(forceRefresh: true),
                            child: const Text('Refresh Feed'),
                          ),
                        ],
                      ),
                    )
                  : ListView.builder(
                      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                      itemCount: _feedVideos.length,
                      itemBuilder: (context, index) {
                        final video = _feedVideos[index];
                        return AuraVideoCard(video: video);
                      },
                    ),
        ),
      ),
    );
  }
}
