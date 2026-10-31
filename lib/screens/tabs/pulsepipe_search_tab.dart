import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import '../../models/song.dart';
import '../../providers/player_provider.dart';
import '../../theme/ember_theme.dart';
import '../../widgets/aura_video_card.dart';
import '../aura_video_player_screen.dart';

typedef SineSearchTab = PulsePipeSearchTab;

class PulsePipeSearchTab extends StatefulWidget {
  const PulsePipeSearchTab({super.key});

  @override
  State<PulsePipeSearchTab> createState() => _PulsePipeSearchTabState();
}

class _PulsePipeSearchTabState extends State<PulsePipeSearchTab> {
  final TextEditingController _controller = TextEditingController();
  final FocusNode _focusNode = FocusNode();

  final List<GenreBrowseCardData> _browseCategories = const [
    GenreBrowseCardData(
      title: 'Electric & Dance',
      gradient: [Color(0xFF2979FF), Color(0xFF00D4FF)],
      icon: FontAwesomeIcons.bolt,
      query: 'Dance Electronic',
    ),
    GenreBrowseCardData(
      title: 'Today\'s Top Hits',
      gradient: [Color(0xFF304FFE), Color(0xFF536DFE)],
      icon: FontAwesomeIcons.fire,
      query: 'Top Hits',
    ),
    GenreBrowseCardData(
      title: 'Pop Global',
      gradient: [Color(0xFFE91E63), Color(0xFFFF4081)],
      icon: FontAwesomeIcons.star,
      query: 'Pop',
    ),
    GenreBrowseCardData(
      title: 'Hip-Hop & Rap',
      gradient: [Color(0xFFFF6D00), Color(0xFFFF9100)],
      icon: FontAwesomeIcons.microphoneLines,
      query: 'Hip Hop',
    ),
    GenreBrowseCardData(
      title: 'Rock & Alt',
      gradient: [Color(0xFFD50000), Color(0xFFFF1744)],
      icon: FontAwesomeIcons.guitar,
      query: 'Rock',
    ),
    GenreBrowseCardData(
      title: 'Indie Vibes',
      gradient: [Color(0xFF6200EA), Color(0xFF7C4DFF)],
      icon: FontAwesomeIcons.headphones,
      query: 'Indie',
    ),
    GenreBrowseCardData(
      title: 'Chill & Lo-Fi',
      gradient: [Color(0xFF00BFA5), Color(0xFF1DE9B6)],
      icon: FontAwesomeIcons.mugSaucer,
      query: 'Chill Lofi',
    ),
    GenreBrowseCardData(
      title: 'Bollywood Hits',
      gradient: [Color(0xFFC51162), Color(0xFFF50057)],
      icon: FontAwesomeIcons.compactDisc,
      query: 'Bollywood',
    ),
    GenreBrowseCardData(
      title: 'Pakistani Hits',
      gradient: [Color(0xFF00C853), Color(0xFF69F0AE)],
      icon: FontAwesomeIcons.music,
      query: 'Pakistani Music',
    ),
    GenreBrowseCardData(
      title: 'Workout & Hype',
      gradient: [Color(0xFFFFAB00), Color(0xFFFFD740)],
      icon: FontAwesomeIcons.dumbbell,
      query: 'Workout',
    ),
    GenreBrowseCardData(
      title: 'Classical & Piano',
      gradient: [Color(0xFF37474F), Color(0xFF78909C)],
      icon: FontAwesomeIcons.recordVinyl,
      query: 'Classical',
    ),
    GenreBrowseCardData(
      title: 'Acoustic & Folk',
      gradient: [Color(0xFF4E342E), Color(0xFF8D6E63)],
      icon: FontAwesomeIcons.featherPointed,
      query: 'Acoustic',
    ),
  ];

  @override
  void initState() {
    super.initState();
    _focusNode.addListener(_onFocusChange);
  }

  void _onFocusChange() {
    if (mounted) setState(() {});
  }

  @override
  void dispose() {
    _focusNode.removeListener(_onFocusChange);
    _controller.dispose();
    _focusNode.dispose();
    super.dispose();
  }

  void _onCategoryTap(GenreBrowseCardData category, PlayerProvider player) {
    _controller.text = category.query;
    player.search(category.query);
  }



  @override
  Widget build(BuildContext context) {
    final player = context.watch<PlayerProvider>();
    final isSearching = _controller.text.trim().isNotEmpty;

    return Scaffold(
      backgroundColor: EmberColors.obsidianBase,
      body: SafeArea(
        bottom: false,
        child: CustomScrollView(
          slivers: [
            // 1. Header Title "Search"
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(16, 20, 16, 12),
                child: Row(
                  children: [
                    Text(
                      'Search',
                      style: TextStyle(
                        color: EmberColors.textPrimary,
                        fontSize: 30,
                        fontWeight: FontWeight.w800,
                        letterSpacing: -0.8,
                      ),
                    ),
                    const Spacer(),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                      decoration: BoxDecoration(
                        color: const Color(0xFF00E5FF).withValues(alpha: 0.15),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: const Color(0xFF00E5FF).withValues(alpha: 0.4),
                          width: 1,
                        ),
                      ),
                      child: const Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          FaIcon(FontAwesomeIcons.bolt, size: 11, color: Color(0xFF00E5FF)),
                          SizedBox(width: 5),
                          Text(
                            'Opus HD',
                            style: TextStyle(
                              color: Color(0xFF00E5FF),
                              fontSize: 11,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),

            // 2. Persistent Search Input Box
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(16, 8, 16, 12),
                child: Container(
                  height: 48,
                  decoration: BoxDecoration(
                    color: EmberColors.charcoalCard,
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(
                      color: _focusNode.hasFocus
                          ? EmberColors.electricBlue
                          : EmberColors.glassBorder.withValues(alpha: 0.3),
                      width: 1.2,
                    ),
                  ),
                  padding: const EdgeInsets.symmetric(horizontal: 14),
                  child: Row(
                    children: [
                      const FaIcon(
                        FontAwesomeIcons.magnifyingGlass,
                        size: 16,
                        color: EmberColors.textSecondary,
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: TextField(
                          controller: _controller,
                          focusNode: _focusNode,
                          style: const TextStyle(
                            color: EmberColors.textPrimary,
                            fontSize: 15,
                            fontWeight: FontWeight.w500,
                          ),
                          decoration: const InputDecoration(
                            hintText: 'Search songs, artists, albums...',
                            hintStyle: TextStyle(
                              color: EmberColors.textMuted,
                              fontSize: 14,
                              fontWeight: FontWeight.w400,
                            ),
                            border: InputBorder.none,
                            isDense: true,
                            contentPadding: EdgeInsets.zero,
                          ),
                          onChanged: (text) {
                            player.search(text);
                            setState(() {});
                          },
                        ),
                      ),
                      if (_controller.text.isNotEmpty)
                        GestureDetector(
                          onTap: () {
                            _controller.clear();
                            player.search('');
                            setState(() {});
                          },
                          child: Container(
                            padding: const EdgeInsets.all(4),
                            child: const FaIcon(
                              FontAwesomeIcons.xmark,
                              size: 16,
                              color: EmberColors.textMuted,
                            ),
                          ),
                        ),
                    ],
                  ),
                ),
              ),
            ),

            // 3. Search Results or Browse Categories
            if (isSearching) ...[
              if (player.isSearching && player.searchResults.isEmpty)
                const SliverFillRemaining(
                  hasScrollBody: false,
                  child: Center(
                    child: CircularProgressIndicator(
                      valueColor: AlwaysStoppedAnimation<Color>(EmberColors.electricBlue),
                      strokeWidth: 2.5,
                    ),
                  ),
                )
              else if (player.searchResults.isEmpty)
                SliverFillRemaining(
                  hasScrollBody: false,
                  child: Center(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const FaIcon(FontAwesomeIcons.compactDisc, size: 48, color: EmberColors.textMuted),
                        const SizedBox(height: 16),
                        Text(
                          'Couldn\'t find that song',
                          style: TextStyle(
                            color: EmberColors.textPrimary,
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'Try searching for a different title, artist, or paste a YouTube link.',
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            color: EmberColors.textMuted.withValues(alpha: 0.8),
                            fontSize: 13,
                          ),
                        ),
                      ],
                    ),
                  ),
                )
              else ...[
                Builder(
                  builder: (context) {
                    final searchResultsSnapshot = List<Song>.from(player.searchResults);
                    return SliverMainAxisGroup(
                      slivers: [
                        SliverPadding(
                          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                          sliver: SliverToBoxAdapter(
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Text(
                                  'Top Results',
                                  style: TextStyle(
                                    color: EmberColors.textPrimary,
                                    fontSize: 18,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                Text(
                                  '${searchResultsSnapshot.length} tracks',
                                  style: const TextStyle(
                                    color: EmberColors.textMuted,
                                    fontSize: 12,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                        SliverPadding(
                          padding: const EdgeInsets.fromLTRB(14, 0, 14, 150),
                          sliver: SliverList(
                            delegate: SliverChildBuilderDelegate(
                              (context, index) {
                                final song = searchResultsSnapshot[index];
                                return AuraVideoCard(
                                  video: song,
                                  onTap: () {
                                    Navigator.of(context).push(
                                      MaterialPageRoute(
                                        builder: (_) => AuraVideoPlayerScreen(video: song),
                                      ),
                                    );
                                  },
                                );
                              },
                              childCount: searchResultsSnapshot.length,
                            ),
                          ),
                        ),
                      ],
                    );
                  },
                ),
              ],
            ] else ...[
              // Idle Browse Mode: "Browse all"
              const SliverPadding(
                padding: EdgeInsets.fromLTRB(16, 20, 16, 12),
                sliver: SliverToBoxAdapter(
                  child: Text(
                    'Browse all',
                    style: TextStyle(
                      color: EmberColors.textPrimary,
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),
              SliverPadding(
                padding: const EdgeInsets.fromLTRB(16, 0, 16, 150),
                sliver: SliverGrid(
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 2,
                    mainAxisSpacing: 12,
                    crossAxisSpacing: 12,
                    childAspectRatio: 1.7,
                  ),
                  delegate: SliverChildBuilderDelegate(
                    (context, index) {
                      final cat = _browseCategories[index];
                      return _GenreCard(
                        category: cat,
                        onTap: () => _onCategoryTap(cat, player),
                      );
                    },
                    childCount: _browseCategories.length,
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class GenreBrowseCardData {
  final String title;
  final List<Color> gradient;
  final FaIconData icon;
  final String query;

  const GenreBrowseCardData({
    required this.title,
    required this.gradient,
    required this.icon,
    required this.query,
  });
}

class _GenreCard extends StatelessWidget {
  final GenreBrowseCardData category;
  final VoidCallback onTap;

  const _GenreCard({
    required this.category,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: ClipRRect(
        borderRadius: BorderRadius.circular(10),
        child: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: category.gradient,
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
          ),
          padding: const EdgeInsets.all(12),
          child: Stack(
            children: [
              Text(
                category.title,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 15,
                  fontWeight: FontWeight.bold,
                  letterSpacing: -0.3,
                ),
              ),
              Positioned(
                bottom: -4,
                right: -4,
                child: Transform.rotate(
                  angle: 0.35,
                  child: Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: Colors.black.withValues(alpha: 0.22),
                      shape: BoxShape.circle,
                    ),
                    child: FaIcon(
                      category.icon,
                      size: 26,
                      color: Colors.white.withValues(alpha: 0.9),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
