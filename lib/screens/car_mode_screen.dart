import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:provider/provider.dart';
import '../providers/player_provider.dart';
import '../theme/ember_theme.dart';
import '../widgets/music_detector_sheet.dart';

/// Ultra-high-contrast OLED Monochrome Car / Driving Mode (from Sine & Metrolist).
class CarModeScreen extends StatelessWidget {
  const CarModeScreen({super.key});

  static void open(BuildContext context) {
    Navigator.of(context).push(
      MaterialPageRoute(builder: (_) => const CarModeScreen()),
    );
  }

  @override
  Widget build(BuildContext context) {
    final player = context.watch<PlayerProvider>();
    final song = player.currentSong;
    final progress = player.duration.inMilliseconds > 0
        ? (player.position.inMilliseconds / player.duration.inMilliseconds).clamp(0.0, 1.0)
        : 0.0;

    return Scaffold(
      backgroundColor: EmberColors.obsidianBase,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Header
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Row(
                    children: [
                      FaIcon(FontAwesomeIcons.car, size: 18, color: EmberColors.monoWhite),
                      SizedBox(width: 10),
                      Text(
                        'DRIVING MODE',
                        style: TextStyle(
                          color: EmberColors.monoWhite,
                          fontSize: 13,
                          fontWeight: FontWeight.w800,
                          letterSpacing: 1.6,
                        ),
                      ),
                    ],
                  ),
                  InkWell(
                    borderRadius: BorderRadius.circular(24),
                    onTap: () => Navigator.of(context).pop(),
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                      decoration: BoxDecoration(
                        color: EmberColors.surfaceContainerHigh,
                        borderRadius: BorderRadius.circular(24),
                        border: Border.all(color: EmberColors.outline),
                      ),
                      child: const Row(
                        children: [
                          FaIcon(FontAwesomeIcons.xmark, size: 14, color: EmberColors.monoWhite),
                          SizedBox(width: 8),
                          Text('Exit', style: TextStyle(color: EmberColors.monoWhite, fontWeight: FontWeight.w700)),
                        ],
                      ),
                    ),
                  ),
                ],
              ),

              const Spacer(),

              // Track Info
              Text(
                song?.title ?? 'No Active Track',
                maxLines: 2,
                textAlign: TextAlign.center,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  color: EmberColors.monoWhite,
                  fontSize: 28,
                  fontWeight: FontWeight.w800,
                  height: 1.2,
                  letterSpacing: -0.5,
                ),
              ),
              const SizedBox(height: 10),
              Text(
                song?.artist ?? 'Select a video or track to begin',
                maxLines: 1,
                textAlign: TextAlign.center,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  color: EmberColors.textSecondary,
                  fontSize: 18,
                  fontWeight: FontWeight.w500,
                ),
              ),

              const SizedBox(height: 28),

              // Thick High-Contrast Progress Bar
              ClipRRect(
                borderRadius: BorderRadius.circular(6),
                child: LinearProgressIndicator(
                  value: progress,
                  minHeight: 8,
                  backgroundColor: EmberColors.surfaceContainerHigh,
                  valueColor: const AlwaysStoppedAnimation<Color>(EmberColors.monoWhite),
                ),
              ),

              const Spacer(),

              // Giant Tactile Transport Row
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  _GiantControl(
                    icon: FontAwesomeIcons.backwardStep,
                    size: 74,
                    onTap: () {
                      HapticFeedback.mediumImpact();
                      player.skipPrevious();
                    },
                  ),
                  _GiantControl(
                    icon: player.isPlaying ? FontAwesomeIcons.pause : FontAwesomeIcons.play,
                    size: 98,
                    inverted: true,
                    onTap: () {
                      HapticFeedback.heavyImpact();
                      player.togglePlayPause();
                    },
                  ),
                  _GiantControl(
                    icon: FontAwesomeIcons.forwardStep,
                    size: 74,
                    onTap: () {
                      HapticFeedback.mediumImpact();
                      player.skipNext();
                    },
                  ),
                ],
              ),

              const SizedBox(height: 28),

              // Bottom Big Utility Buttons
              Row(
                children: [
                  Expanded(
                    child: _UtilityBarButton(
                      icon: song != null && player.isFavorite(song.id)
                          ? FontAwesomeIcons.solidHeart
                          : FontAwesomeIcons.heart,
                      label: song != null && player.isFavorite(song.id) ? 'Saved' : 'Favorite',
                      onTap: () {
                        if (song != null) {
                          HapticFeedback.selectionClick();
                          player.toggleFavorite(song);
                        }
                      },
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _UtilityBarButton(
                      icon: FontAwesomeIcons.waveSquare,
                      label: 'Detect Song',
                      onTap: () {
                        HapticFeedback.selectionClick();
                        MusicDetectorSheet.show(context);
                      },
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _GiantControl extends StatelessWidget {
  final FaIconData icon;
  final double size;
  final bool inverted;
  final VoidCallback onTap;

  const _GiantControl({
    required this.icon,
    required this.size,
    this.inverted = false,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: size,
        height: size,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: inverted ? EmberColors.monoWhite : EmberColors.surfaceContainerLow,
          border: Border.all(
            color: inverted ? EmberColors.monoWhite : EmberColors.outline,
            width: 1.5,
          ),
        ),
        child: Center(
          child: FaIcon(
            icon,
            size: inverted ? 34 : 26,
            color: inverted ? EmberColors.onAccent : EmberColors.monoWhite,
          ),
        ),
      ),
    );
  }
}

class _UtilityBarButton extends StatelessWidget {
  final FaIconData icon;
  final String label;
  final VoidCallback onTap;

  const _UtilityBarButton({
    required this.icon,
    required this.label,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      borderRadius: BorderRadius.circular(16),
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 18),
        decoration: BoxDecoration(
          color: EmberColors.surfaceContainerLow,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: EmberColors.outlineVariant),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            FaIcon(icon, size: 17, color: EmberColors.monoWhite),
            const SizedBox(width: 10),
            Text(
              label,
              style: const TextStyle(color: EmberColors.monoWhite, fontSize: 15, fontWeight: FontWeight.w700),
            ),
          ],
        ),
      ),
    );
  }
}
