import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:provider/provider.dart';
import '../services/storage_service.dart';
import '../services/youtube_service.dart';
import '../models/youtube_video.dart';
import '../theme/aura_theme.dart';
import '../widgets/video_card.dart';
import 'video_detail_screen.dart';

class SubscriptionsScreen extends StatefulWidget {
  const SubscriptionsScreen({super.key});

  @override
  State<SubscriptionsScreen> createState() => _SubscriptionsScreenState();
}

class _SubscriptionsScreenState extends State<SubscriptionsScreen> {
  List<YouTubeVideo> _feedVideos = [];
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _loadSubscriptionFeed();
  }

  Future<void> _loadSubscriptionFeed() async {
    final storage = context.read<StorageService>();
    if (storage.subscriptions.isEmpty) return;

    setState(() => _isLoading = true);
    final List<YouTubeVideo> aggregated = [];

    try {
      for (final sub in storage.subscriptions.take(5)) {
        final results = await YouTubeService.searchVideos(sub.name);
        aggregated.addAll(results.take(3));
      }
      if (mounted) {
        setState(() {
          _feedVideos = aggregated;
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

    return Scaffold(
      backgroundColor: AuraColors.obsidianBase,
      appBar: AppBar(
        title: const Row(
          children: [
            FaIcon(FontAwesomeIcons.youtube, color: AuraColors.primaryBlueLight, size: 20),
            SizedBox(width: 10),
            Text('Subscriptions'),
          ],
        ),
      ),
      body: storage.subscriptions.isEmpty
          ? Center(
              child: Padding(
                padding: const EdgeInsets.all(28),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Container(
                      padding: const EdgeInsets.all(20),
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: AuraColors.primaryBlue.withValues(alpha: 0.15),
                        border: Border.all(color: AuraColors.primaryBlue.withValues(alpha: 0.4), width: 1.5),
                      ),
                      child: const FaIcon(FontAwesomeIcons.shieldHalved, color: AuraColors.accentCyan, size: 36),
                    ),
                    const SizedBox(height: 18),
                    const Text(
                      'Private Subscriptions',
                      style: TextStyle(
                        color: AuraColors.textPrimary,
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 8),
                    const Text(
                      'Like NewPipe, AuraTube subscriptions are stored 100% locally on your device without needing a Google account or telemetry.',
                      textAlign: TextAlign.center,
                      style: TextStyle(color: AuraColors.textSecondary, fontSize: 13, height: 1.4),
                    ),
                  ],
                ),
              ),
            )
          : RefreshIndicator(
              onRefresh: _loadSubscriptionFeed,
              color: AuraColors.primaryBlueLight,
              child: ListView(
                padding: const EdgeInsets.all(16),
                children: [
                  // Channels Horizontal Strip
                  SizedBox(
                    height: 90,
                    child: ListView.builder(
                      scrollDirection: Axis.horizontal,
                      itemCount: storage.subscriptions.length,
                      itemBuilder: (context, i) {
                        final sub = storage.subscriptions[i];
                        return Container(
                          width: 72,
                          margin: const EdgeInsets.only(right: 12),
                          child: Column(
                            children: [
                              Container(
                                width: 50,
                                height: 50,
                                decoration: BoxDecoration(
                                  shape: BoxShape.circle,
                                  gradient: const LinearGradient(colors: [AuraColors.primaryBlue, AuraColors.accentCyan]),
                                  border: Border.all(color: AuraColors.accentCyan.withValues(alpha: 0.5), width: 1.5),
                                ),
                                child: Center(
                                  child: Text(
                                    sub.name.isNotEmpty ? sub.name[0].toUpperCase() : 'C',
                                    style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 18),
                                  ),
                                ),
                              ),
                              const SizedBox(height: 6),
                              Text(
                                sub.name,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                textAlign: TextAlign.center,
                                style: const TextStyle(color: AuraColors.textPrimary, fontSize: 11, fontWeight: FontWeight.w600),
                              ),
                            ],
                          ),
                        );
                      },
                    ),
                  ),
                  const Divider(color: AuraColors.outline, height: 24),

                  // Feed List
                  if (_isLoading)
                    const Center(child: CircularProgressIndicator())
                  else if (_feedVideos.isEmpty)
                    const Center(child: Text('No new uploads from subscriptions yet', style: TextStyle(color: AuraColors.textMuted)))
                  else
                    ..._feedVideos.map(
                      (v) => VideoCard(
                        video: v,
                        onTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(builder: (_) => VideoDetailScreen(video: v)),
                          );
                        },
                      ),
                    ),
                ],
              ),
            ),
    );
  }
}
