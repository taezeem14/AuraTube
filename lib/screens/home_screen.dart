import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import '../services/youtube_service.dart';
import '../models/youtube_video.dart';
import '../theme/aura_theme.dart';
import '../widgets/category_chip.dart';
import '../widgets/video_card.dart';
import 'video_detail_screen.dart';
import 'search_screen.dart';
import 'sound_shaping_sheet.dart';
import 'settings_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final List<String> _categories = ['All', 'Trending', 'Music', 'Gaming', 'Tech', 'News', 'Shorts'];
  String _selectedCategory = 'All';
  List<YouTubeVideo> _videos = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadVideos();
  }

  Future<void> _loadVideos() async {
    setState(() => _isLoading = true);
    try {
      final videos = await YouTubeService.getHomeVideos(category: _selectedCategory);
      if (mounted) {
        setState(() {
          _videos = videos;
          _isLoading = false;
        });
      }
    } catch (_) {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AuraColors.obsidianBase,
      appBar: AppBar(
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(7),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(10),
                gradient: const LinearGradient(
                  colors: [AuraColors.primaryBlue, AuraColors.accentCyan],
                ),
                boxShadow: [
                  BoxShadow(
                    color: AuraColors.primaryBlue.withValues(alpha: 0.4),
                    blurRadius: 10,
                  ),
                ],
              ),
              child: const FaIcon(FontAwesomeIcons.youtube, color: Colors.white, size: 16),
            ),
            const SizedBox(width: 10),
            const Text(
              'AuraTube',
              style: TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.w800,
                fontSize: 20,
                letterSpacing: -0.5,
              ),
            ),
          ],
        ),
        actions: [
          IconButton(
            icon: const FaIcon(FontAwesomeIcons.magnifyingGlass, color: AuraColors.textPrimary, size: 17),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const SearchScreen()),
              );
            },
          ),
          IconButton(
            icon: const FaIcon(FontAwesomeIcons.sliders, color: AuraColors.accentCyan, size: 17),
            tooltip: 'Equalizer DSP',
            onPressed: () => SoundShapingSheet.show(context),
          ),
          IconButton(
            icon: const FaIcon(FontAwesomeIcons.gear, color: AuraColors.textPrimary, size: 17),
            tooltip: 'Settings & Author',
            onPressed: () => SettingsScreen.show(context),
          ),
        ],
      ),
      body: Column(
        children: [
          // Horizontal Category Chips
          Container(
            height: 48,
            padding: const EdgeInsets.symmetric(vertical: 6),
            child: ListView.builder(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 14),
              itemCount: _categories.length,
              itemBuilder: (context, i) {
                final cat = _categories[i];
                return CategoryChip(
                  label: cat,
                  isSelected: _selectedCategory == cat,
                  onTap: () {
                    setState(() => _selectedCategory = cat);
                    _loadVideos();
                  },
                );
              },
            ),
          ),

          // Video Feed List
          Expanded(
            child: _isLoading
                ? const Center(
                    child: CircularProgressIndicator(color: AuraColors.primaryBlueLight),
                  )
                : RefreshIndicator(
                    onRefresh: _loadVideos,
                    color: AuraColors.primaryBlueLight,
                    child: ListView.builder(
                      padding: const EdgeInsets.all(14),
                      itemCount: _videos.length,
                      itemBuilder: (context, i) {
                        final video = _videos[i];
                        return VideoCard(
                          video: video,
                          onTap: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(builder: (_) => VideoDetailScreen(video: video)),
                            );
                          },
                        );
                      },
                    ),
                  ),
          ),
        ],
      ),
    );
  }
}
