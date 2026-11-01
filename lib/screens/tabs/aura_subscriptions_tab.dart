import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:provider/provider.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../../models/song.dart';
import '../../services/storage_service.dart';
import '../../services/youtube_feed_service.dart';
import '../../theme/ember_theme.dart';
import '../../widgets/aura_video_card.dart';

class AuraSubscriptionsTab extends StatefulWidget {
  final VoidCallback? onBrowseTrending;

  const AuraSubscriptionsTab({super.key, this.onBrowseTrending});

  @override
  State<AuraSubscriptionsTab> createState() => _AuraSubscriptionsTabState();
}

class _AuraSubscriptionsTabState extends State<AuraSubscriptionsTab> {
  String? _selectedChannelName;
  List<Song> _channelVideos = [];
  bool _isLoadingChannel = false;

  Future<void> _loadChannelVideos(String channelName) async {
    setState(() {
      _selectedChannelName = channelName;
      _isLoadingChannel = true;
    });

    final feed = await YouTubeFeedService.fetchCategoryFeed('all');
    final matches = feed.where((s) => s.artist.toLowerCase().contains(channelName.toLowerCase())).toList();

    if (mounted) {
      setState(() {
        _channelVideos = matches.isNotEmpty ? matches : feed.take(10).toList();
        _isLoadingChannel = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final storage = context.watch<StorageService>();
    final subs = storage.loadSubscriptions();

    if (subs.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(32),
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
                    FontAwesomeIcons.users,
                    size: 30,
                    color: EmberColors.primaryBlue,
                  ),
                ),
              ),
              const SizedBox(height: 20),
              const Text(
                'No Subscriptions Yet',
                style: TextStyle(
                  color: EmberColors.textPrimary,
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 10),
              const Text(
                'Subscribe to your favorite YouTube channels while watching videos to build your private offline subscription feed.',
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: EmberColors.textMuted,
                  fontSize: 13,
                  height: 1.4,
                ),
              ),
              const SizedBox(height: 24),
              ElevatedButton.icon(
                onPressed: widget.onBrowseTrending,
                icon: const FaIcon(FontAwesomeIcons.fire, size: 14, color: Colors.white),
                label: const Text('Discover Channels in Trending', style: TextStyle(fontWeight: FontWeight.bold)),
                style: ElevatedButton.styleFrom(
                  backgroundColor: EmberColors.primaryBlue,
                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
              ),
            ],
          ),
        ),
      );
    }

    if (_selectedChannelName != null) {
      return Column(
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            color: EmberColors.surfaceContainerLow,
            child: Row(
              children: [
                IconButton(
                  icon: const FaIcon(FontAwesomeIcons.arrowLeft, size: 15, color: EmberColors.textPrimary),
                  onPressed: () => setState(() => _selectedChannelName = null),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    _selectedChannelName!,
                    style: const TextStyle(
                      color: EmberColors.textPrimary,
                      fontSize: 15,
                      fontWeight: FontWeight.bold,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
          ),
          Expanded(
            child: _isLoadingChannel
                ? const Center(child: CircularProgressIndicator(color: EmberColors.primaryBlue))
                : _channelVideos.isEmpty
                    ? const Center(
                        child: Text('No videos found for this channel.', style: TextStyle(color: EmberColors.textMuted)),
                      )
                    : ListView.builder(
                        padding: const EdgeInsets.fromLTRB(16, 12, 16, 80),
                        itemCount: _channelVideos.length,
                        itemBuilder: (context, index) {
                          return AuraVideoCard(video: _channelVideos[index]);
                        },
                      ),
          ),
        ],
      );
    }

    return ListView.separated(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 80),
      itemCount: subs.length,
      separatorBuilder: (context, index) => const Divider(color: EmberColors.outlineVariant, height: 1),
      itemBuilder: (context, index) {
        final sub = subs[index];
        return ListTile(
          contentPadding: const EdgeInsets.symmetric(vertical: 6),
          leading: Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: const LinearGradient(
                colors: [EmberColors.primaryBlue, EmberColors.secondaryCyan],
              ),
            ),
            child: sub.avatarUrl.isNotEmpty
                ? ClipOval(
                    child: CachedNetworkImage(
                      imageUrl: sub.avatarUrl,
                      fit: BoxFit.cover,
                      errorWidget: (context, url, error) => Center(
                        child: Text(
                          sub.name.isNotEmpty ? sub.name[0].toUpperCase() : 'C',
                          style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 18),
                        ),
                      ),
                    ),
                  )
                : Center(
                    child: Text(
                      sub.name.isNotEmpty ? sub.name[0].toUpperCase() : 'C',
                      style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 18),
                    ),
                  ),
          ),
          title: Text(
            sub.name,
            style: const TextStyle(
              color: EmberColors.textPrimary,
              fontSize: 14.5,
              fontWeight: FontWeight.w600,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
          subtitle: Text(
            sub.subscriberCount.isNotEmpty ? '${sub.subscriberCount} subscribers' : 'Channel Subscribed',
            style: const TextStyle(color: EmberColors.textMuted, fontSize: 12),
          ),
          trailing: TextButton(
            onPressed: () {
              storage.toggleSubscription(sub);
            },
            style: TextButton.styleFrom(
              backgroundColor: EmberColors.surfaceContainerHigh,
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
            ),
            child: const Text(
              'Subscribed',
              style: TextStyle(color: EmberColors.primaryBlueHi, fontSize: 11, fontWeight: FontWeight.bold),
            ),
          ),
          onTap: () => _loadChannelVideos(sub.name),
        );
      },
    );
  }
}
