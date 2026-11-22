import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:provider/provider.dart';
import '../providers/player_provider.dart';
import '../services/sponsorblock_service.dart';
import '../theme/ember_theme.dart';

/// Full SponsorBlock Control Center powered by https://sponsor.ajay.app/
class SponsorBlockScreen extends StatelessWidget {
  const SponsorBlockScreen({super.key});

  static void open(BuildContext context) {
    Navigator.of(context).push(
      MaterialPageRoute(builder: (_) => const SponsorBlockScreen()),
    );
  }

  String _formatSaved(double secs) {
    final total = secs.round();
    if (total < 60) return '${total}s';
    final mins = total ~/ 60;
    final rem = total % 60;
    if (mins < 60) return '${mins}m ${rem}s';
    final hrs = mins ~/ 60;
    return '${hrs}h ${mins % 60}m';
  }

  @override
  Widget build(BuildContext context) {
    final player = context.watch<PlayerProvider>();

    return Scaffold(
      backgroundColor: EmberColors.obsidianBase,
      appBar: AppBar(
        backgroundColor: EmberColors.obsidianBase,
        elevation: 0,
        leading: IconButton(
          icon: const FaIcon(FontAwesomeIcons.arrowLeft, size: 17, color: EmberColors.monoWhite),
          onPressed: () => Navigator.of(context).pop(),
        ),
        title: const Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'SponsorBlock',
              style: TextStyle(color: EmberColors.textPrimary, fontSize: 17, fontWeight: FontWeight.w700),
            ),
            Text(
              'SPONSOR.AJAY.APP CROWD-SOURCED SKIPPER',
              style: TextStyle(color: EmberColors.textMuted, fontSize: 9.5, letterSpacing: 0.9, fontWeight: FontWeight.w700),
            ),
          ],
        ),
        actions: [
          Switch(
            value: player.sponsorBlockEnabled,
            onChanged: (v) {
              HapticFeedback.selectionClick();
              player.toggleSponsorBlock(v);
            },
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 10, 16, 32),
        children: [
          // Telemetry Bento Card
          Container(
            padding: const EdgeInsets.all(18),
            decoration: BoxDecoration(
              color: EmberColors.surfaceContainerLow,
              borderRadius: BorderRadius.circular(18),
              border: Border.all(color: EmberColors.outlineVariant),
            ),
            child: Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'SEGMENTS SKIPPED',
                        style: TextStyle(color: EmberColors.textMuted, fontSize: 10, letterSpacing: 1.1, fontWeight: FontWeight.w700),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        '${player.sponsorSegmentsSkipped}',
                        style: const TextStyle(
                          color: EmberColors.monoWhite,
                          fontSize: 28,
                          fontWeight: FontWeight.w800,
                          letterSpacing: -0.8,
                        ),
                      ),
                    ],
                  ),
                ),
                Container(width: 1, height: 42, color: EmberColors.outlineVariant),
                const SizedBox(width: 18),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'TIME SAVED',
                        style: TextStyle(color: EmberColors.textMuted, fontSize: 10, letterSpacing: 1.1, fontWeight: FontWeight.w700),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        _formatSaved(player.sponsorSecondsSaved),
                        style: const TextStyle(
                          color: EmberColors.monoWhite,
                          fontSize: 28,
                          fontWeight: FontWeight.w800,
                          letterSpacing: -0.8,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 20),
          const Padding(
            padding: EdgeInsets.only(left: 4, bottom: 10),
            child: Text(
              'AUTO-SKIP CATEGORIES (VIDEO & AUDIO)',
              style: TextStyle(color: EmberColors.textMuted, fontSize: 11, letterSpacing: 1.1, fontWeight: FontWeight.w700),
            ),
          ),

          for (final cat in SponsorBlockService.allCategories) ...[
            Container(
              margin: const EdgeInsets.only(bottom: 8),
              decoration: BoxDecoration(
                color: EmberColors.surfaceContainerLow,
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: EmberColors.outlineVariant),
              ),
              child: SwitchListTile(
                contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 2),
                title: Text(
                  SponsorBlockService.categoryTitles[cat] ?? cat,
                  style: TextStyle(
                    color: player.sponsorBlockEnabled ? EmberColors.textPrimary : EmberColors.textMuted,
                    fontSize: 13.5,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                subtitle: Text(
                  'Category ID: $cat',
                  style: const TextStyle(color: EmberColors.textMuted, fontSize: 11),
                ),
                value: player.sponsorBlockCategories.contains(cat),
                onChanged: player.sponsorBlockEnabled
                    ? (_) {
                        HapticFeedback.selectionClick();
                        player.toggleSponsorBlockCategory(cat);
                      }
                    : null,
              ),
            ),
          ],
        ],
      ),
    );
  }
}
