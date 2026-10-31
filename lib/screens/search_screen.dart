import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import '../services/youtube_service.dart';
import '../models/youtube_video.dart';
import '../theme/aura_theme.dart';
import '../widgets/video_card.dart';
import 'video_detail_screen.dart';

class SearchScreen extends StatefulWidget {
  const SearchScreen({super.key});

  @override
  State<SearchScreen> createState() => _SearchScreenState();
}

class _SearchScreenState extends State<SearchScreen> {
  final TextEditingController _searchController = TextEditingController();
  List<String> _suggestions = [];
  List<YouTubeVideo> _results = [];
  bool _isLoading = false;
  bool _hasSearched = false;

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _onQueryChanged(String query) async {
    if (query.trim().isEmpty) {
      setState(() => _suggestions = []);
      return;
    }
    final suggestions = await YouTubeService.getSearchSuggestions(query);
    if (mounted) {
      setState(() => _suggestions = suggestions);
    }
  }

  Future<void> _performSearch(String query) async {
    if (query.trim().isEmpty) return;
    _searchController.text = query;
    setState(() {
      _isLoading = true;
      _hasSearched = true;
      _suggestions = [];
    });

    try {
      final results = await YouTubeService.searchVideos(query);
      if (mounted) {
        setState(() {
          _results = results;
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
        titleSpacing: 0,
        leading: IconButton(
          icon: const FaIcon(FontAwesomeIcons.arrowLeft, size: 16),
          onPressed: () => Navigator.pop(context),
        ),
        title: Padding(
          padding: const EdgeInsets.only(right: 16),
          child: TextField(
            controller: _searchController,
            autofocus: true,
            style: const TextStyle(color: AuraColors.textPrimary, fontSize: 14),
            decoration: InputDecoration(
              hintText: 'Search YouTube or enter URL...',
              hintStyle: const TextStyle(color: AuraColors.textMuted, fontSize: 13),
              filled: true,
              fillColor: AuraColors.surfaceContainerLow,
              contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(24), borderSide: BorderSide.none),
              suffixIcon: _searchController.text.isNotEmpty
                  ? IconButton(
                      icon: const Icon(Icons.clear, color: AuraColors.textMuted, size: 16),
                      onPressed: () {
                        _searchController.clear();
                        setState(() {
                          _suggestions = [];
                          _results = [];
                          _hasSearched = false;
                        });
                      },
                    )
                  : null,
            ),
            onChanged: _onQueryChanged,
            onSubmitted: _performSearch,
          ),
        ),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator(color: AuraColors.primaryBlueLight))
          : _suggestions.isNotEmpty && !_hasSearched
              ? ListView.separated(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  itemCount: _suggestions.length,
                  separatorBuilder: (_, index) => const Divider(color: AuraColors.outline, height: 1),
                  itemBuilder: (context, i) {
                    final s = _suggestions[i];
                    return ListTile(
                      leading: const FaIcon(FontAwesomeIcons.magnifyingGlass, size: 14, color: AuraColors.textMuted),
                      title: Text(s, style: const TextStyle(color: AuraColors.textPrimary, fontSize: 14)),
                      trailing: const FaIcon(FontAwesomeIcons.arrowUpRightFromSquare, size: 12, color: AuraColors.textMuted),
                      onTap: () => _performSearch(s),
                    );
                  },
                )
              : _hasSearched
                  ? _results.isEmpty
                      ? const Center(
                          child: Text('No results found', style: TextStyle(color: AuraColors.textMuted)),
                        )
                      : ListView.builder(
                          padding: const EdgeInsets.all(16),
                          itemCount: _results.length,
                          itemBuilder: (context, i) {
                            final video = _results[i];
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
                        )
                  : const Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          FaIcon(FontAwesomeIcons.magnifyingGlass, size: 36, color: AuraColors.textMuted),
                          SizedBox(height: 14),
                          Text('Search videos, channels, or paste YouTube links', style: TextStyle(color: AuraColors.textMuted, fontSize: 13)),
                        ],
                      ),
                    ),
    );
  }
}
