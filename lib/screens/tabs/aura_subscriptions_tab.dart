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

class _AuraSubscriptionsTabState extends State<AuraSubscriptionsTab> with AutomaticKeepAliveClientMixin {
  String? _selectedChannelName;
  List<Song> _channelVideos = [];
  bool _isLoadingChannel = false;

  @override
  bool get wantKeepAlive => true;

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
    super.build(context);
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
                width: 68,
                height: 68,
                decoration: BoxDecoration(
                  color: EmberColors.surfaceContainerLow,
                  shape: BoxShape.circle,
                  border: Border.all(color: EmberColors.outlineVariant),
                ),
                child: const Center(
                  child: FaIcon(FontAwesomeIcons.users, size: 26, color: EmberColors.monoWhite),
                ),
              ),
              const SizedBox(height: 18),
              const Text(
                'No Subscriptions Yet',
                style: TextStyle(color: EmberColors.textPrimary, fontSize: 17, fontWeight: FontWeight.w700),
              ),
              const SizedBox(height: 8),
              const Text(
                'Tap Subscribe on any video to store channels privately on-device with NewPipe offline subscriptions.',
                textAlign: TextAlign.center,
                style: TextStyle(color: EmberColors.textMuted, fontSize: 12.5, height: 1.45),
              ),
              const SizedBox(height: 22),
              ElevatedButton.icon(
                onPressed: widget.onBrowseTrending,
                style: ElevatedButton.styleFrom(
                  backgroundColor: EmberColors.monoWhite,
                  foregroundColor: EmberColors.onAccent,
                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
                icon: const FaIcon(FontAwesomeIcons.fire, size: 13),
                label: const Text('Discover Creators', style: TextStyle(fontWeight: FontWeight.w700)),
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
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
            decoration: const BoxDecoration(
              color: EmberColors.surfaceContainerLow,
              border: Border(bottom: BorderSide(color: EmberColors.borderSubtle)),
            ),
            child: Row(
              children: [
                IconButton(
                  icon: const FaIcon(FontAwesomeIcons.arrowLeft, size: 15, color: EmberColors.monoWhite),
                  onPressed: () => setState(() => _selectedChannelName = null),
                ),
                const SizedBox(width: 6),
                Expanded(
                  child: Text(
                    _selectedChannelName!,
                    style: const TextStyle(color: EmberColors.textPrimary, fontSize: 15, fontWeight: FontWeight.w700),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
          ),
          Expanded(
            child: _isLoadingChannel
                ? const Center(child: CircularProgressIndicator(color: EmberColors.monoWhite, strokeWidth: 2))
                : _channelVideos.isEmpty
                    ? const Center(child: Text('No uploads found.', style: TextStyle(color: EmberColors.textMuted)))
                    : ListView.builder(
                        padding: const EdgeInsets.fromLTRB(14, 12, 14, 96),
                        itemCount: _channelVideos.length,
                        itemBuilder: (context, index) => AuraVideoCard(video: _channelVideos[index]),
                      ),
          ),
        ],
      );
    }

    return ListView.separated(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 96),
      itemCount: subs.length,
      separatorBuilder: (context, index) => const Divider(color: EmberColors.borderSubtle, height: 1),
      itemBuilder: (context, index) {
        final sub = subs[index];
        return ListTile(
          contentPadding: const EdgeInsets.symmetric(vertical: 6),
          leading: Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: EmberColors.surfaceContainerHigh,
              border: Border.all(color: EmberColors.outlineVariant),
            ),
            child: sub.avatarUrl.isNotEmpty
                ? ClipOval(
                    child: CachedNetworkImage(
                      imageUrl: sub.avatarUrl,
                      fit: BoxFit.cover,
                      errorWidget: (context, url, error) => Center(
                        child: Text(
                          sub.name.isNotEmpty ? sub.name[0].toUpperCase() : 'C',
                          style: const TextStyle(color: EmberColors.monoWhite, fontWeight: FontWeight.w800, fontSize: 16),
                        ),
                      ),
                    ),
                  )
                : Center(
                    child: Text(
                      sub.name.isNotEmpty ? sub.name[0].toUpperCase() : 'C',
                      style: const TextStyle(color: EmberColors.monoWhite, fontWeight: FontWeight.w800, fontSize: 16),
                    ),
                  ),
          ),
          title: Text(
            sub.name,
            style: const TextStyle(color: EmberColors.textPrimary, fontSize: 14, fontWeight: FontWeight.w600),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
          subtitle: Text(
            sub.subscriberCount.isNotEmpty ? '${sub.subscriberCount} subscribers' : 'Local Subscription',
            style: const TextStyle(color: EmberColors.textMuted, fontSize: 11.5),
          ),
          trailing: TextButton(
            onPressed: () {
              storage.toggleSubscription(sub);
              setState(() {});
            },
            style: TextButton.styleFrom(
              backgroundColor: EmberColors.surfaceContainerHigh,
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
                side: const BorderSide(color: EmberColors.outlineVariant),
              ),
            ),
            child: const Text(
              'Subscribed',
              style: TextStyle(color: EmberColors.monoSilver, fontSize: 11, fontWeight: FontWeight.w700),
            ),
          ),
          onTap: () => _loadChannelVideos(sub.name),
        );
      },
    );
  }
}
