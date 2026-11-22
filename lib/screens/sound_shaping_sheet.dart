import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:provider/provider.dart';
import '../providers/player_provider.dart';
import '../theme/ember_theme.dart';
import 'equalizer_screen.dart';
import 'playback_speed_sheet.dart';

/// Quick Monochromatic Sound Shaping Bottom Sheet with instant jump to full 6-Band Bezier EQ.
class SoundShapingSheet extends StatefulWidget {
  const SoundShapingSheet({super.key});

  static void show(BuildContext context) {
    showModalBottomSheet(
      context: context,
      backgroundColor: EmberColors.surfaceContainerLow,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (_) => const SoundShapingSheet(),
    );
  }

  @override
  State<SoundShapingSheet> createState() => _SoundShapingSheetState();
}

class _SoundShapingSheetState extends State<SoundShapingSheet> {
  double? _localBassBoost;
  DateTime _lastBassSent = DateTime.fromMillisecondsSinceEpoch(0);

  @override
  Widget build(BuildContext context) {
    final player = context.watch<PlayerProvider>();
    final bassVal = (_localBassBoost ?? player.bassBoost).clamp(0.0, 1.0);

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
                    child: const FaIcon(FontAwesomeIcons.sliders, size: 15, color: EmberColors.monoWhite),
                  ),
                  const SizedBox(width: 12),
                  const Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Sound Shaping & EQ',
                          style: TextStyle(color: EmberColors.textPrimary, fontSize: 16, fontWeight: FontWeight.w700),
                        ),
                        Text(
                          'PRIORITY-1000 HARDWARE DSP',
                          style: TextStyle(color: EmberColors.textMuted, fontSize: 9.5, letterSpacing: 0.9, fontWeight: FontWeight.w700),
                        ),
                      ],
                    ),
                  ),
                  Switch(
                    value: player.eqEnabled,
                    onChanged: (v) {
                      HapticFeedback.selectionClick();
                      player.setEqualizerEnabled(v);
                    },
                  ),
                ],
              ),
              const SizedBox(height: 16),

              // Primary CTA: Open Full Interactive 6-Band Bezier Graph Equalizer
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: EmberColors.monoWhite,
                    foregroundColor: EmberColors.onAccent,
                    padding: const EdgeInsets.symmetric(vertical: 13),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                  icon: const FaIcon(FontAwesomeIcons.chartArea, size: 14),
                  label: const Text('Open Interactive 6-Band Curve Equalizer', style: TextStyle(fontWeight: FontWeight.w700, fontSize: 13)),
                  onPressed: () {
                    Navigator.of(context).pop();
                    EqualizerScreen.open(context);
                  },
                ),
              ),
              const SizedBox(height: 10),

              // Secondary CTAs: System/Root EQ + Speed/Pitch/Sleep
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton.icon(
                      style: OutlinedButton.styleFrom(
                        foregroundColor: EmberColors.textPrimary,
                        side: const BorderSide(color: EmberColors.outlineVariant),
                        padding: const EdgeInsets.symmetric(vertical: 11),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                      icon: const FaIcon(FontAwesomeIcons.microchip, size: 12),
                      label: const Text('System / Root EQ', style: TextStyle(fontSize: 11.5, fontWeight: FontWeight.w600)),
                      onPressed: () async {
                        final ok = await player.openSystemEqualizer();
                        if (!ok && context.mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(content: Text('Audio session broadcasted. Internal DSP is active.')),
                          );
                        }
                      },
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: OutlinedButton.icon(
                      style: OutlinedButton.styleFrom(
                        foregroundColor: EmberColors.textPrimary,
                        side: const BorderSide(color: EmberColors.outlineVariant),
                        padding: const EdgeInsets.symmetric(vertical: 11),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                      icon: const FaIcon(FontAwesomeIcons.gaugeHigh, size: 12),
                      label: const Text('Speed & Pitch', style: TextStyle(fontSize: 11.5, fontWeight: FontWeight.w600)),
                      onPressed: () {
                        Navigator.of(context).pop();
                        PlaybackSpeedSheet.show(context);
                      },
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 18),
              const Text('QUICK PRESETS', style: TextStyle(color: EmberColors.textMuted, fontSize: 10.5, letterSpacing: 1.1, fontWeight: FontWeight.w700)),
              const SizedBox(height: 10),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  for (final p in ['Flat', 'Bass Boost', 'Hip-Hop', 'Vocal Booster', 'Rock', 'Electronic', 'Lo-Fi', 'Acoustic'])
                    ChoiceChip(
                      label: Text(p),
                      selected: player.eqPreset.toLowerCase() == p.toLowerCase(),
                      showCheckmark: false,
                      selectedColor: EmberColors.monoWhite,
                      backgroundColor: EmberColors.surfaceContainer,
                      labelStyle: TextStyle(
                        color: player.eqPreset.toLowerCase() == p.toLowerCase() ? EmberColors.onAccent : EmberColors.textSecondary,
                        fontWeight: FontWeight.w700,
                        fontSize: 11.5,
                      ),
                      onSelected: (_) {
                        HapticFeedback.selectionClick();
                        if (!player.eqEnabled) player.setEqualizerEnabled(true);
                        player.setEqualizerPreset(p);
                      },
                    ),
                ],
              ),

              const SizedBox(height: 18),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text('Hardware Bass Punch', style: TextStyle(color: EmberColors.textPrimary, fontSize: 13, fontWeight: FontWeight.w600)),
                  Text('${(bassVal * 100).round()}%', style: const TextStyle(color: EmberColors.monoWhite, fontSize: 13, fontWeight: FontWeight.w800)),
                ],
              ),
              Slider(
                value: bassVal,
                min: 0.0,
                max: 1.0,
                onChanged: (val) {
                  setState(() => _localBassBoost = val);
                  final now = DateTime.now();
                  if (now.difference(_lastBassSent).inMilliseconds >= 50) {
                    _lastBassSent = now;
                    player.setBassBoost(val);
                  }
                },
                onChangeEnd: (val) {
                  setState(() => _localBassBoost = null);
                  player.setBassBoost(val);
                },
              ),
            ],
          ),
        ),
      ),
    );
  }
}
