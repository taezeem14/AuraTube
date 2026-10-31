import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import '../../providers/player_provider.dart';
import '../../services/storage_service.dart';
import '../../theme/ember_theme.dart';
import '../../widgets/aura_video_card.dart';
import '../settings_screen.dart';

class AuraLibraryTab extends StatefulWidget {
  const AuraLibraryTab({super.key});

  @override
  State<AuraLibraryTab> createState() => _AuraLibraryTabState();
}

class _AuraLibraryTabState extends State<AuraLibraryTab> {
  String _activeSection = 'History'; // 'History', 'Downloads', 'Liked', 'Subscriptions'

  @override
  Widget build(BuildContext context) {
    final player = context.watch<PlayerProvider>();
    final storage = context.watch<StorageService>();
    final subscriptions = storage.loadSubscriptions();
    final history = player.history;
    final downloads = player.downloads;
    final favorites = player.favorites;

    return Scaffold(
      backgroundColor: EmberColors.obsidianBase,
      appBar: AppBar(
        backgroundColor: EmberColors.obsidianBase,
        elevation: 0,
        titleSpacing: 16,
        title: const Text(
          'Library & Subscriptions',
          style: TextStyle(
            fontFamily: 'Sora',
            color: EmberColors.textPrimary,
            fontSize: 20,
            fontWeight: FontWeight.bold,
          ),
        ),
        actions: [
          IconButton(
            icon: const FaIcon(FontAwesomeIcons.gear, size: 16, color: EmberColors.textPrimary),
            tooltip: 'Settings',
            onPressed: () => SettingsScreen.show(context),
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        children: [
          // 1. Subscribed Channels Bar (Private Local Subscriptions)
          if (subscriptions.isNotEmpty) ...[
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'SUBSCRIPTIONS',
                  style: TextStyle(
                    color: EmberColors.textMuted,
                    fontSize: 11,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 1.2,
                  ),
                ),
                Text(
                  '${subscriptions.length} channels',
                  style: const TextStyle(color: EmberColors.textMuted, fontSize: 11),
                ),
              ],
            ),
            const SizedBox(height: 10),
            SizedBox(
              height: 90,
              child: ListView.builder(
                scrollDirection: Axis.horizontal,
                itemCount: subscriptions.length,
                itemBuilder: (context, index) {
                  final sub = subscriptions[index];
                  return Padding(
                    padding: const EdgeInsets.only(right: 14),
                    child: InkWell(
                      borderRadius: BorderRadius.circular(12),
                      onTap: () {
                        player.search(sub.name);
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text('Showing videos for "${sub.name}"'),
                            backgroundColor: EmberColors.surfaceContainerHigh,
                          ),
                        );
                      },
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Container(
                            width: 52,
                            height: 52,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              gradient: const LinearGradient(
                                colors: [EmberColors.primaryBlue, EmberColors.secondaryCyan],
                              ),
                              border: Border.all(color: EmberColors.primaryBlueHi, width: 1.5),
                            ),
                            alignment: Alignment.center,
                            child: Text(
                              sub.name.isNotEmpty ? sub.name[0].toUpperCase() : 'C',
                              style: const TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold),
                            ),
                          ),
                          const SizedBox(height: 6),
                          SizedBox(
                            width: 60,
                            child: Text(
                              sub.name,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              textAlign: TextAlign.center,
                              style: const TextStyle(color: EmberColors.textSecondary, fontSize: 11, fontWeight: FontWeight.w500),
                            ),
                          ),
                        ],
                      ),
                    ),
                  );
                },
              ),
            ),
            const SizedBox(height: 16),
          ],

          // 2. Section Selector Chips
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: ['History', 'Downloads', 'Liked', 'Subscriptions'].map((sec) {
                final isSelected = _activeSection == sec;
                return Padding(
                  padding: const EdgeInsets.only(right: 8),
                  child: InkWell(
                    borderRadius: BorderRadius.circular(10),
                    onTap: () {
                      setState(() {
                        _activeSection = sec;
                      });
                    },
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 180),
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                      decoration: BoxDecoration(
                        color: isSelected ? EmberColors.primaryBlue : EmberColors.surfaceContainerLow,
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(
                          color: isSelected ? EmberColors.primaryBlueHi : Colors.white.withValues(alpha: 0.08),
                          width: 1,
                        ),
                      ),
                      child: Text(
                        sec,
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
          const SizedBox(height: 16),

          // 3. Section Content
          if (_activeSection == 'History') ...[
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'WATCH HISTORY (${history.length})',
                  style: const TextStyle(color: EmberColors.textMuted, fontSize: 11, fontWeight: FontWeight.bold, letterSpacing: 1.2),
                ),
                if (history.isNotEmpty)
                  TextButton(
                    onPressed: () {
                      player.clearHistory();
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('Watch history cleared'), backgroundColor: EmberColors.surfaceContainerHigh),
                      );
                    },
                    child: const Text('Clear', style: TextStyle(color: EmberColors.textMuted, fontSize: 12)),
                  ),
              ],
            ),
            const SizedBox(height: 8),
            if (history.isEmpty)
              _buildEmptyState(
                icon: FontAwesomeIcons.clockRotateLeft,
                title: 'No watch history yet',
                subtitle: 'Videos you watch in AuraTube will appear here.',
              )
            else
              ...history.map((video) => AuraVideoCard(video: video)),
          ] else if (_activeSection == 'Downloads') ...[
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'OFFLINE DOWNLOADS (${downloads.length})',
                  style: const TextStyle(color: EmberColors.textMuted, fontSize: 11, fontWeight: FontWeight.bold, letterSpacing: 1.2),
                ),
              ],
            ),
            const SizedBox(height: 8),
            if (downloads.isEmpty)
              _buildEmptyState(
                icon: FontAwesomeIcons.download,
                title: 'No offline downloads yet',
                subtitle: 'Tap the Download button on any video to download MP4 or M4A for offline playback.',
              )
            else
              ...downloads.map((video) => AuraVideoCard(video: video)),
          ] else if (_activeSection == 'Liked') ...[
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'LIKED VIDEOS (${favorites.length})',
                  style: const TextStyle(color: EmberColors.textMuted, fontSize: 11, fontWeight: FontWeight.bold, letterSpacing: 1.2),
                ),
              ],
            ),
            const SizedBox(height: 8),
            if (favorites.isEmpty)
              _buildEmptyState(
                icon: FontAwesomeIcons.heart,
                title: 'No liked videos yet',
                subtitle: 'Tap Like on videos you enjoy to save them here.',
              )
            else
              ...favorites.map((video) => AuraVideoCard(video: video)),
          ] else if (_activeSection == 'Subscriptions') ...[
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'SUBSCRIBED CHANNELS (${subscriptions.length})',
                  style: const TextStyle(color: EmberColors.textMuted, fontSize: 11, fontWeight: FontWeight.bold, letterSpacing: 1.2),
                ),
              ],
            ),
            const SizedBox(height: 8),
            if (subscriptions.isEmpty)
              _buildEmptyState(
                icon: FontAwesomeIcons.bell,
                title: 'No channel subscriptions yet',
                subtitle: 'Tap Subscribe on any video to follow creators privately on your device.',
              )
            else
              ...subscriptions.map((sub) {
                return Padding(
                  padding: const EdgeInsets.only(bottom: 12),
                  child: Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: EmberColors.surfaceContainerLow,
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(color: Colors.white.withValues(alpha: 0.05)),
                    ),
                    child: Row(
                      children: [
                        Container(
                          width: 44,
                          height: 44,
                          decoration: const BoxDecoration(
                            shape: BoxShape.circle,
                            gradient: LinearGradient(
                              colors: [EmberColors.primaryBlue, EmberColors.secondaryCyan],
                            ),
                          ),
                          alignment: Alignment.center,
                          child: Text(
                            sub.name.isNotEmpty ? sub.name[0].toUpperCase() : 'C',
                            style: const TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold),
                          ),
                        ),
                        const SizedBox(width: 14),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                sub.name,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: const TextStyle(color: EmberColors.textPrimary, fontSize: 14, fontWeight: FontWeight.bold),
                              ),
                              const SizedBox(height: 2),
                              const Text('Local private subscription', style: TextStyle(color: EmberColors.textMuted, fontSize: 11.5)),
                            ],
                          ),
                        ),
                        TextButton(
                          onPressed: () async {
                            await storage.toggleSubscription(sub);
                            setState(() {});
                          },
                          child: const Text('Unsubscribe', style: TextStyle(color: EmberColors.error, fontSize: 12)),
                        ),
                      ],
                    ),
                  ),
                );
              }),
          ],
        ],
      ),
    );
  }

  Widget _buildEmptyState({
    required FaIconData icon,
    required String title,
    required String subtitle,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 48, horizontal: 24),
      alignment: Alignment.center,
      child: Column(
        children: [
          FaIcon(icon, size: 36, color: EmberColors.textMuted),
          const SizedBox(height: 14),
          Text(title, style: const TextStyle(color: EmberColors.textPrimary, fontSize: 14, fontWeight: FontWeight.bold)),
          const SizedBox(height: 6),
          Text(subtitle, textAlign: TextAlign.center, style: const TextStyle(color: EmberColors.textMuted, fontSize: 12, height: 1.4)),
        ],
      ),
    );
  }
}
