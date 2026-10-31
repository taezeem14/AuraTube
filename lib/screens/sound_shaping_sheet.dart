import 'dart:io';
import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:just_audio/just_audio.dart';
import 'package:provider/provider.dart';
import '../services/player_service.dart';
import '../theme/aura_theme.dart';

class SoundShapingSheet extends StatefulWidget {
  const SoundShapingSheet({super.key});

  static void show(BuildContext context) {
    showModalBottomSheet(
      context: context,
      backgroundColor: AuraColors.surface,
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
  Future<AndroidEqualizerParameters>? _parametersFuture;

  final List<String> _presets = ['Flat', 'Bass Heavy', 'Rock', 'Pop', 'Vocal', 'Electronic'];

  @override
  void initState() {
    super.initState();
    final player = context.read<PlayerService>();
    if (Platform.isAndroid) {
      _parametersFuture = player.equalizer.parameters;
    }
  }

  @override
  Widget build(BuildContext context) {
    final player = context.watch<PlayerService>();

    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Sheet Handle
              Center(
                child: Container(
                  width: 40,
                  height: 4,
                  margin: const EdgeInsets.only(bottom: 16),
                  decoration: BoxDecoration(
                    color: AuraColors.textMuted.withValues(alpha: 0.4),
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),

              // Title Row
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: AuraColors.primaryBlue.withValues(alpha: 0.18),
                          shape: BoxShape.circle,
                        ),
                        child: const FaIcon(FontAwesomeIcons.sliders, size: 16, color: AuraColors.primaryBlueLight),
                      ),
                      const SizedBox(width: 12),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Sound Shaping & EQ',
                            style: TextStyle(
                              color: AuraColors.textPrimary,
                              fontWeight: FontWeight.bold,
                              fontSize: 16,
                            ),
                          ),
                          Text(
                            player.eqEnabled ? 'Hardware Multi-Band DSP Active' : 'DSP Bypass Mode',
                            style: TextStyle(
                              color: player.eqEnabled ? AuraColors.accentCyan : AuraColors.textMuted,
                              fontSize: 12,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                  Switch.adaptive(
                    value: player.eqEnabled,
                    activeThumbColor: AuraColors.primaryBlueLight,
                    onChanged: (val) => player.setEqualizerEnabled(val),
                  ),
                ],
              ),
              const Divider(color: AuraColors.outline, height: 24),

              // Bass Boost Slider
              Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: AuraColors.surfaceHigh.withValues(alpha: 0.6),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: AuraColors.outline.withValues(alpha: 0.6)),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Row(
                          children: [
                            FaIcon(FontAwesomeIcons.volumeHigh, size: 14, color: AuraColors.accentCyan),
                            SizedBox(width: 8),
                            Text(
                              'Analog Bass Sub-Boost',
                              style: TextStyle(color: AuraColors.textPrimary, fontWeight: FontWeight.bold, fontSize: 13),
                            ),
                          ],
                        ),
                        Text(
                          '+${(player.bassBoost * 100).toInt()}%',
                          style: const TextStyle(color: AuraColors.accentCyan, fontWeight: FontWeight.bold, fontSize: 13),
                        ),
                      ],
                    ),
                    const SizedBox(height: 6),
                    Slider(
                      value: player.bassBoost,
                      min: 0.0,
                      max: 1.0,
                      divisions: 20,
                      activeColor: AuraColors.accentCyan,
                      inactiveColor: AuraColors.outline,
                      onChanged: player.eqEnabled ? (val) => player.setBassBoost(val) : null,
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 18),

              // Presets Carousel
              const Text(
                'DSP Sound Presets',
                style: TextStyle(color: AuraColors.textSecondary, fontWeight: FontWeight.bold, fontSize: 13),
              ),
              const SizedBox(height: 10),
              SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: Row(
                  children: _presets.map((preset) {
                    final isSelected = player.currentPreset == preset;
                    return GestureDetector(
                      onTap: () => player.applyEqualizerPreset(preset),
                      child: Container(
                        margin: const EdgeInsets.only(right: 8),
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                        decoration: BoxDecoration(
                          color: isSelected ? AuraColors.primaryBlue : AuraColors.surfaceHigh,
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(
                            color: isSelected ? AuraColors.accentCyan : AuraColors.outline,
                            width: isSelected ? 1.4 : 0.8,
                          ),
                          boxShadow: isSelected
                              ? [
                                  BoxShadow(
                                    color: AuraColors.primaryBlue.withValues(alpha: 0.3),
                                    blurRadius: 8,
                                  ),
                                ]
                              : null,
                        ),
                        child: Text(
                          preset,
                          style: TextStyle(
                            color: isSelected ? Colors.white : AuraColors.textPrimary,
                            fontWeight: FontWeight.bold,
                            fontSize: 12,
                          ),
                        ),
                      ),
                    );
                  }).toList(),
                ),
              ),
              const SizedBox(height: 20),

              // Multi-Band Equalizer Sliders
              if (Platform.isAndroid && _parametersFuture != null)
                FutureBuilder<AndroidEqualizerParameters>(
                  future: _parametersFuture,
                  builder: (context, snapshot) {
                    if (snapshot.connectionState == ConnectionState.waiting) {
                      return const Center(child: CircularProgressIndicator());
                    }
                    if (!snapshot.hasData || snapshot.data!.bands.isEmpty) {
                      return _buildSimulatedBands(player);
                    }
                    final params = snapshot.data!;
                    return Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Multi-Band Frequency Tuning',
                          style: TextStyle(color: AuraColors.textSecondary, fontWeight: FontWeight.bold, fontSize: 13),
                        ),
                        const SizedBox(height: 12),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceAround,
                          children: List.generate(params.bands.length, (i) {
                            final band = params.bands[i];
                            final gain = player.customBandGains[i] ?? band.gain;
                            final freq = band.centerFrequency < 1000
                                ? '${band.centerFrequency}Hz'
                                : '${(band.centerFrequency / 1000).toStringAsFixed(1)}kHz';

                            return Column(
                              children: [
                                Text(
                                  '${gain.toStringAsFixed(0)}dB',
                                  style: const TextStyle(color: AuraColors.textMuted, fontSize: 10),
                                ),
                                SizedBox(
                                  height: 140,
                                  child: RotatedBox(
                                    quarterTurns: -1,
                                    child: Slider(
                                      value: gain.clamp(params.minDecibels, params.maxDecibels),
                                      min: params.minDecibels,
                                      max: params.maxDecibels,
                                      activeColor: AuraColors.primaryBlueLight,
                                      inactiveColor: AuraColors.outline,
                                      onChanged: player.eqEnabled
                                          ? (val) => player.setBandGain(i, val)
                                          : null,
                                    ),
                                  ),
                                ),
                                Text(
                                  freq,
                                  style: const TextStyle(color: AuraColors.textPrimary, fontSize: 10, fontWeight: FontWeight.bold),
                                ),
                              ],
                            );
                          }),
                        ),
                      ],
                    );
                  },
                )
              else
                _buildSimulatedBands(player),

              const SizedBox(height: 16),
              Center(
                child: TextButton.icon(
                  onPressed: () => player.resetEqualizer(),
                  icon: const FaIcon(FontAwesomeIcons.rotateLeft, size: 12, color: AuraColors.textMuted),
                  label: const Text('Reset All Bands to Default', style: TextStyle(color: AuraColors.textMuted, fontSize: 12)),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSimulatedBands(PlayerService player) {
    final frequencies = ['60Hz', '230Hz', '910Hz', '3.6kHz', '14kHz'];
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Frequency Band Tuning',
          style: TextStyle(color: AuraColors.textSecondary, fontWeight: FontWeight.bold, fontSize: 13),
        ),
        const SizedBox(height: 12),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceAround,
          children: List.generate(frequencies.length, (i) {
            final gain = player.customBandGains[i] ?? 0.0;
            return Column(
              children: [
                Text(
                  '${gain.toStringAsFixed(0)}dB',
                  style: const TextStyle(color: AuraColors.textMuted, fontSize: 10),
                ),
                SizedBox(
                  height: 130,
                  child: RotatedBox(
                    quarterTurns: -1,
                    child: Slider(
                      value: gain.clamp(-12.0, 12.0),
                      min: -12.0,
                      max: 12.0,
                      activeColor: AuraColors.primaryBlueLight,
                      inactiveColor: AuraColors.outline,
                      onChanged: player.eqEnabled ? (val) => player.setBandGain(i, val) : null,
                    ),
                  ),
                ),
                Text(
                  frequencies[i],
                  style: const TextStyle(color: AuraColors.textPrimary, fontSize: 10, fontWeight: FontWeight.bold),
                ),
              ],
            );
          }),
        ),
      ],
    );
  }
}
