import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:provider/provider.dart';
import '../providers/player_provider.dart';
import '../theme/ember_theme.dart';
import '../widgets/aura_video_card.dart';

class HistoryScreen extends StatelessWidget {
  const HistoryScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final player = context.watch<PlayerProvider>();
    final history = player.history;

    return Scaffold(
      backgroundColor: EmberColors.obsidianBase,
      appBar: AppBar(
        backgroundColor: EmberColors.obsidianBase,
        elevation: 0,
        leading: IconButton(
          icon: const FaIcon(FontAwesomeIcons.arrowLeft, size: 16, color: EmberColors.textPrimary),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text(
          'History',
          style: TextStyle(color: EmberColors.textPrimary, fontSize: 17, fontWeight: FontWeight.bold),
        ),
        actions: [
          if (history.isNotEmpty)
            IconButton(
              icon: const FaIcon(FontAwesomeIcons.trashCan, size: 16, color: EmberColors.textMuted),
              tooltip: 'Clear History',
              onPressed: () async {
                final confirm = await showDialog<bool>(
                  context: context,
                  builder: (ctx) => AlertDialog(
                    backgroundColor: EmberColors.surfaceContainerLow,
                    title: const Text('Clear Watch History?', style: TextStyle(color: EmberColors.textPrimary)),
                    content: const Text('This will clear your watch and playback history on this device.'),
                    actions: [
                      TextButton(
                        child: const Text('Cancel', style: TextStyle(color: EmberColors.textMuted)),
                        onPressed: () => Navigator.pop(ctx, false),
                      ),
                      TextButton(
                        child: const Text('Clear', style: TextStyle(color: Colors.redAccent)),
                        onPressed: () => Navigator.pop(ctx, true),
                      ),
                    ],
                  ),
                );

                if (confirm == true) {
                  player.clearHistory();
                }
              },
            ),
        ],
      ),
      body: history.isEmpty
          ? Center(
              child: Padding(
                padding: const EdgeInsets.all(32),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    FaIcon(
                      FontAwesomeIcons.clockRotateLeft,
                      size: 48,
                      color: EmberColors.textMuted.withValues(alpha: 0.4),
                    ),
                    const SizedBox(height: 16),
                    const Text(
                      'No Watch History Yet',
                      style: TextStyle(
                        color: EmberColors.textPrimary,
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 8),
                    const Text(
                      'Videos and songs you play will be listed here.',
                      textAlign: TextAlign.center,
                      style: TextStyle(color: EmberColors.textMuted, fontSize: 13),
                    ),
                  ],
                ),
              ),
            )
          : ListView.builder(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
              itemCount: history.length,
              itemBuilder: (context, index) {
                return AuraVideoCard(video: history[index]);
              },
            ),
    );
  }
}
