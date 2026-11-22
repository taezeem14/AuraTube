import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:provider/provider.dart';
import '../providers/player_provider.dart';
import '../theme/ember_theme.dart';

/// Metrolist-grade Playback Engine Sheet:
/// Independent Speed, Pitch, Skip Silence, Loudness Normalization, and Fade-Out Sleep Timer.
class PlaybackSpeedSheet extends StatelessWidget {
  const PlaybackSpeedSheet({super.key});

  static void show(BuildContext context) {
    showModalBottomSheet(
      context: context,
      backgroundColor: EmberColors.surfaceContainerLow,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (_) => const PlaybackSpeedSheet(),
    );
  }

  String _formatRemaining(int secs) {
    final m = secs ~/ 60;
    final s = secs % 60;
    return '${m.toString().padLeft(2, '0')}:${s.toString().padLeft(2, '0')}';
  }

  @override
  Widget build(BuildContext context) {
    final player = context.watch<PlayerProvider>();

    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(20, 14, 20, 20),
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: Container(
                  width: 38,
                  height: 4,
                  margin: const EdgeInsets.only(bottom: 16),
                  decoration: BoxDecoration(
                    color: EmberColors.outline,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: EmberColors.surfaceContainerHigh,
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: const FaIcon(FontAwesomeIcons.gaugeHigh, size: 15, color: EmberColors.monoWhite),
                  ),
                  const SizedBox(width: 12),
                  const Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Playback & Audio Engine',
                          style: TextStyle(color: EmberColors.textPrimary, fontSize: 16, fontWeight: FontWeight.w700),
                        ),
                        Text(
                          'TEMPO · PITCH · SKIP SILENCE · SLEEP FADE',
                          style: TextStyle(color: EmberColors.textMuted, fontSize: 9.5, letterSpacing: 0.9, fontWeight: FontWeight.w700),
                        ),
                      ],
                    ),
                  ),
                  TextButton(
                    onPressed: () {
                      player.setSpeed(1.0);
                      player.setPitch(1.0);
                    },
                    child: const Text('Reset', style: TextStyle(color: EmberColors.textSecondary, fontSize: 12)),
                  ),
                ],
              ),
              const SizedBox(height: 18),

              // 1. Speed Slider & Presets
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text('Playback Speed', style: TextStyle(color: EmberColors.textPrimary, fontSize: 13, fontWeight: FontWeight.w600)),
                  Text('${player.speed.toStringAsFixed(2)}x', style: const TextStyle(color: EmberColors.monoWhite, fontSize: 13, fontWeight: FontWeight.w800)),
                ],
              ),
              Slider(
                value: player.speed.clamp(0.25, 2.0),
                min: 0.25,
                max: 2.0,
                divisions: 35,
                onChanged: (v) => player.setSpeed((v * 20).round() / 20.0),
              ),
              Wrap(
                spacing: 8,
                children: [
                  for (final preset in [0.75, 1.0, 1.25, 1.5, 2.0])
                    ChoiceChip(
                      label: Text('${preset}x'),
                      selected: (player.speed - preset).abs() < 0.03,
                      showCheckmark: false,
                      selectedColor: EmberColors.monoWhite,
                      backgroundColor: EmberColors.surfaceContainer,
                      labelStyle: TextStyle(
                        color: (player.speed - preset).abs() < 0.03 ? EmberColors.onAccent : EmberColors.textSecondary,
                        fontSize: 11.5,
                        fontWeight: FontWeight.w700,
                      ),
                      onSelected: (_) {
                        HapticFeedback.selectionClick();
                        player.setSpeed(preset);
                      },
                    ),
                ],
              ),
              const SizedBox(height: 18),

              // 2. Pitch Slider (Metrolist / just_audio native pitch shift)
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text('Audio Pitch', style: TextStyle(color: EmberColors.textPrimary, fontSize: 13, fontWeight: FontWeight.w600)),
                  Text('${player.pitch.toStringAsFixed(2)}x', style: const TextStyle(color: EmberColors.monoWhite, fontSize: 13, fontWeight: FontWeight.w800)),
                ],
              ),
              Slider(
                value: player.pitch.clamp(0.5, 2.0),
                min: 0.5,
                max: 2.0,
                divisions: 30,
                onChanged: (v) => player.setPitch((v * 20).round() / 20.0),
              ),
              const SizedBox(height: 10),

              // 3. Skip Silence & Loudness Normalization
              Container(
                decoration: BoxDecoration(
                  color: EmberColors.surfaceContainer,
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: EmberColors.outlineVariant),
                ),
                child: Column(
                  children: [
                    SwitchListTile(
                      dense: true,
                      title: const Text('Skip Silence', style: TextStyle(color: EmberColors.textPrimary, fontSize: 13, fontWeight: FontWeight.w600)),
                      subtitle: const Text('Automatically trim quiet gaps in podcasts & talks', style: TextStyle(color: EmberColors.textMuted, fontSize: 11)),
                      value: player.skipSilence,
                      onChanged: (v) => player.setSkipSilence(v),
                    ),
                    const Divider(color: EmberColors.outlineVariant, height: 1),
                    SwitchListTile(
                      dense: true,
                      title: const Text('Loudness Normalization', style: TextStyle(color: EmberColors.textPrimary, fontSize: 13, fontWeight: FontWeight.w600)),
                      subtitle: const Text('Keep volume consistent across different uploads', style: TextStyle(color: EmberColors.textMuted, fontSize: 11)),
                      value: player.loudnessNormalization,
                      onChanged: (v) => player.setLoudnessNormalization(v),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 18),

              // 4. Sleep Timer with Smooth 10s Fade-Out
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text('SLEEP TIMER (10s FADE-OUT)', style: TextStyle(color: EmberColors.textMuted, fontSize: 10.5, letterSpacing: 1.1, fontWeight: FontWeight.w700)),
                  if (player.sleepSecondsRemaining > 0)
                    GestureDetector(
                      onTap: () => player.cancelSleepTimer(),
                      child: Text(
                        'Active: ${_formatRemaining(player.sleepSecondsRemaining)} · Cancel',
                        style: const TextStyle(color: EmberColors.monoWhite, fontSize: 11.5, fontWeight: FontWeight.w700),
                      ),
                    ),
                ],
              ),
              const SizedBox(height: 10),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  for (final mins in [5, 15, 30, 45, 60])
                    ActionChip(
                      label: Text('${mins}m'),
                      backgroundColor: EmberColors.surfaceContainer,
                      side: const BorderSide(color: EmberColors.outlineVariant),
                      labelStyle: const TextStyle(color: EmberColors.textPrimary, fontSize: 12, fontWeight: FontWeight.w600),
                      onPressed: () {
                        HapticFeedback.selectionClick();
                        player.startSleepTimer(mins);
                      },
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
