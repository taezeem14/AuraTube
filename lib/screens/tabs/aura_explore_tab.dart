import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import '../../models/song.dart';
import '../../services/youtube_feed_service.dart';
import '../../theme/ember_theme.dart';
import '../../widgets/aura_video_card.dart';

class AuraExploreTab extends StatefulWidget {
  const AuraExploreTab({super.key});

  @override
  State<AuraExploreTab> createState() => _AuraExploreTabState();
}

class _AuraExploreTabState extends State<AuraExploreTab> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final Map<String, List<Song>> _cache = {};
  final Map<String, bool> _loading = {};

  final List<Map<String, dynamic>> _sections = [
    {'id': 'trending', 'title': 'Trending', 'icon': FontAwesomeIcons.fire},
    {'id': 'music', 'title': 'Music', 'icon': FontAwesomeIcons.music},
    {'id': 'gaming', 'title': 'Gaming', 'icon': FontAwesomeIcons.gamepad},
    {'id': 'tech', 'title': 'Tech & AI', 'icon': FontAwesomeIcons.robot},
    {'id': 'podcasts', 'title': 'Podcasts', 'icon': FontAwesomeIcons.microphoneLines},
  ];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: _sections.length, vsync: this);
    _tabController.addListener(() {
      if (!_tabController.indexIsChanging) {
        _loadSection(_sections[_tabController.index]['id']);
      }
    });
    _loadSection('trending');
  }

  Future<void> _loadSection(String id, {bool force = false}) async {
    if (!force && _cache.containsKey(id) && _cache[id]!.isNotEmpty) return;

    setState(() {
      _loading[id] = true;
    });

    final list = await YouTubeFeedService.fetchCategoryFeed(id, forceRefresh: force);
    if (mounted) {
      setState(() {
        _cache[id] = list;
        _loading[id] = false;
      });
    }
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: EmberColors.obsidianBase,
      appBar: AppBar(
        backgroundColor: EmberColors.obsidianBase,
        elevation: 0,
        titleSpacing: 16,
        title: const Text(
          'Explore & Trending',
          style: TextStyle(
            fontFamily: 'Sora',
            color: EmberColors.textPrimary,
            fontSize: 20,
            fontWeight: FontWeight.bold,
          ),
        ),
        bottom: TabBar(
          controller: _tabController,
          isScrollable: true,
          indicatorColor: EmberColors.primaryBlue,
          indicatorWeight: 3,
          labelColor: EmberColors.primaryBlueHi,
          unselectedLabelColor: EmberColors.textMuted,
          labelStyle: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
          tabs: _sections.map((sec) {
            return Tab(
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  FaIcon(sec['icon'] as FaIconData, size: 12),
                  const SizedBox(width: 8),
                  Text(sec['title'] as String),
                ],
              ),
            );
          }).toList(),
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: _sections.map((sec) {
          final id = sec['id'] as String;
          final isLoading = _loading[id] ?? false;
          final videos = _cache[id] ?? [];

          if (isLoading) {
            return const Center(child: CircularProgressIndicator(color: EmberColors.primaryBlue));
          }

          if (videos.isEmpty) {
            return Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Text('No trending videos loaded', style: TextStyle(color: EmberColors.textMuted)),
                  const SizedBox(height: 10),
                  ElevatedButton(
                    style: ElevatedButton.styleFrom(backgroundColor: EmberColors.primaryBlue),
                    onPressed: () => _loadSection(id, force: true),
                    child: const Text('Retry'),
                  ),
                ],
              ),
            );
          }

          return RefreshIndicator(
            color: EmberColors.primaryBlue,
            onRefresh: () => _loadSection(id, force: true),
            child: ListView.builder(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
              itemCount: videos.length,
              itemBuilder: (context, index) {
                return AuraVideoCard(video: videos[index]);
              },
            ),
          );
        }).toList(),
      ),
    );
  }
}
