import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import '../theme/ember_theme.dart';
import '../providers/player_provider.dart';
import '../widgets/spotify_graph_equalizer.dart';

/// Production-Level Monochromatic 6-Band Graphic Equalizer & DSP Studio.
/// Integrates patched priority-1000 just_audio AndroidEqualizer, LoudnessEnhancer,
/// Studio Stem Isolation, Clipping Protection, and System/Custom ROM EQ Bridge.
class EqualizerScreen extends StatefulWidget {
  const EqualizerScreen({super.key});

  static void open(BuildContext context) {
    Navigator.of(context).push(
      MaterialPageRoute(builder: (_) => const EqualizerScreen()),
    );
  }

  @override
  State<EqualizerScreen> createState() => _EqualizerScreenState();
}

class _EqualizerScreenState extends State<EqualizerScreen> {
  bool _isDraggingGraph = false;
  double? _draggingBass;
  DateTime _lastBassSent = DateTime.fromMillisecondsSinceEpoch(0);

  void _showDspInfoDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: EmberColors.surfaceContainerLow,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
          side: const BorderSide(color: EmberColors.outlineVariant),
        ),
        title: const Row(
          children: [
            FaIcon(FontAwesomeIcons.sliders, color: EmberColors.monoWhite, size: 16),
            SizedBox(width: 12),
            Expanded(
              child: Text(
                'Hardware DSP Architecture',
                style: TextStyle(color: EmberColors.textPrimary, fontSize: 16, fontWeight: FontWeight.bold),
              ),
            ),
          ],
        ),
        content: const Text(
          'AuraTube embeds a custom-patched Android ExoPlayer DSP pipeline:\n\n'
          '• Priority-1000 Hardware Equalizer: Prevents OEM DSPs (Dolby, SoundAlive, Dirac) from silently overriding your EQ curve.\n'
          '• Log-Frequency 6-Band Interpolation: Maps 60 Hz, 150 Hz, 400 Hz, 1 kHz, 2.4 kHz, and 15 kHz cleanly onto any 5-band or 10-band hardware chip.\n'
          '• Session Persistence: Automatically re-binds curves across track switches and Bluetooth reconnects.\n'
          '• Root & Custom ROM Bridge: Broadcasts AudioEffect session intents for Viper4Android, AudioFX, JamesDSP, and Wavelet.',
          style: TextStyle(color: EmberColors.textSecondary, fontSize: 12.5, height: 1.5),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: const Text('Close', style: TextStyle(color: EmberColors.monoWhite, fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final player = context.read<PlayerProvider>();
    final eqEnabled = context.select<PlayerProvider, bool>((p) => p.eqEnabled);
    final bassBoost = context.select<PlayerProvider, double>((p) => p.bassBoost);
    final clippingProtection = context.select<PlayerProvider, bool>((p) => p.clippingProtection);
    final loudnessNorm = context.select<PlayerProvider, bool>((p) => p.loudnessNormalization);
    final isolationMode = context.select<PlayerProvider, IsolationMode>((p) => p.isolationMode);
    final isLoadingStem = context.select<PlayerProvider, bool>((p) => p.isLoadingStem);
    final activeBass = (_draggingBass ?? bassBoost).clamp(0.0, 1.0);

    return Scaffold(
      backgroundColor: EmberColors.obsidianBase,
      appBar: AppBar(
        backgroundColor: EmberColors.obsidianBase,
        elevation: 0,
        leading: IconButton(
          icon: const FaIcon(FontAwesomeIcons.arrowLeft, color: EmberColors.monoWhite, size: 17),
          onPressed: () => Navigator.of(context).pop(),
        ),
        title: const Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Equalizer & DSP',
              style: TextStyle(
                color: EmberColors.textPrimary,
                fontSize: 17,
                fontWeight: FontWeight.w700,
                letterSpacing: -0.3,
              ),
            ),
            Text(
              'PRIORITY-1000 HARDWARE ENGINE',
              style: TextStyle(
                color: EmberColors.textMuted,
                fontSize: 9.5,
                fontWeight: FontWeight.w700,
                letterSpacing: 1.0,
              ),
            ),
          ],
        ),
        actions: [
          IconButton(
            icon: const FaIcon(FontAwesomeIcons.circleInfo, color: EmberColors.textSecondary, size: 16),
            tooltip: 'DSP Engine Architecture',
            onPressed: () => _showDspInfoDialog(context),
          ),
          Transform.scale(
            scale: 0.85,
            child: Switch(
              value: eqEnabled,
              onChanged: (val) {
                HapticFeedback.selectionClick();
                player.setEqualizerEnabled(val);
              },
            ),
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: SafeArea(
        top: false,
        child: SingleChildScrollView(
          physics: _isDraggingGraph ? const NeverScrollableScrollPhysics() : const BouncingScrollPhysics(),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // System / Custom ROM Equalizer Launch Pill
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 8, 16, 10),
                child: InkWell(
                  borderRadius: BorderRadius.circular(12),
                  onTap: () async {
                    final ok = await player.openSystemEqualizer();
                    if (!ok && context.mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('Audio session broadcasted. Internal Priority-1000 DSP is active.'),
                        ),
                      );
                    }
                  },
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 11),
                    decoration: BoxDecoration(
                      color: EmberColors.surfaceContainerLow,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: EmberColors.outlineVariant),
                    ),
                    child: const Row(
                      children: [
                        FaIcon(FontAwesomeIcons.microchip, size: 14, color: EmberColors.monoWhite),
                        SizedBox(width: 10),
                        Expanded(
                          child: Text(
                            'System / Root EQ (Viper4Android · AudioFX · Wavelet)',
                            style: TextStyle(
                              color: EmberColors.textPrimary,
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        FaIcon(FontAwesomeIcons.arrowUpRightFromSquare, size: 11, color: EmberColors.textMuted),
                      ],
                    ),
                  ),
                ),
              ),

              if (!eqEnabled)
                Container(
                  margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 9),
                  decoration: BoxDecoration(
                    color: EmberColors.surfaceContainerLow,
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: EmberColors.outlineVariant),
                  ),
                  child: const Row(
                    children: [
                      FaIcon(FontAwesomeIcons.circleInfo, color: EmberColors.textMuted, size: 13),
                      SizedBox(width: 10),
                      Expanded(
                        child: Text(
                          'Equalizer is bypassed. Toggle the switch or select any studio curve below to activate.',
                          style: TextStyle(color: EmberColors.textSecondary, fontSize: 11.5),
                        ),
                      ),
                    ],
                  ),
                ),

              // Hardware Bass Punch & Loudness Slider
              Container(
                margin: const EdgeInsets.fromLTRB(16, 8, 16, 10),
                padding: const EdgeInsets.fromLTRB(16, 14, 16, 8),
                decoration: BoxDecoration(
                  color: EmberColors.surfaceContainerLow,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: EmberColors.outlineVariant),
                ),
                child: Column(
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Row(
                          children: [
                            FaIcon(FontAwesomeIcons.volumeHigh, size: 13, color: EmberColors.monoWhite),
                            SizedBox(width: 8),
                            Text(
                              'Hardware Bass Punch & Loudness',
                              style: TextStyle(
                                color: EmberColors.textPrimary,
                                fontSize: 13,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ],
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                          decoration: BoxDecoration(
                            color: EmberColors.surfaceContainerHigh,
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: Text(
                            '${(activeBass * 100).round()}%',
                            style: const TextStyle(
                              color: EmberColors.monoWhite,
                              fontSize: 11.5,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ),
                      ],
                    ),
                    Slider(
                      value: activeBass,
                      min: 0.0,
                      max: 1.0,
                      onChanged: (val) {
                        setState(() => _draggingBass = val);
                        final now = DateTime.now();
                        if (now.difference(_lastBassSent).inMilliseconds >= 50) {
                          _lastBassSent = now;
                          player.setBassBoost(val);
                        }
                      },
                      onChangeEnd: (val) {
                        setState(() => _draggingBass = null);
                        player.setBassBoost(val);
                      },
                    ),
                    const Divider(color: EmberColors.outlineVariant, height: 12),
                    Row(
                      children: [
                        Expanded(
                          child: _TogglePill(
                            label: 'Clipping Guard',
                            icon: FontAwesomeIcons.shieldHalved,
                            isActive: clippingProtection,
                            onTap: () => player.setClippingProtection(!clippingProtection),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: _TogglePill(
                            label: 'Normalization',
                            icon: FontAwesomeIcons.waveSquare,
                            isActive: loudnessNorm,
                            onTap: () => player.setLoudnessNormalization(!loudnessNorm),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 6),
                  ],
                ),
              ),

              // Studio Stem Isolation (Sine Feature)
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 4, 16, 12),
                child: Row(
                  children: [
                    Expanded(
                      child: _StemTile(
                        title: 'Vocals Only',
                        subtitle: 'Acapella Isolation',
                        icon: FontAwesomeIcons.microphone,
                        isActive: isolationMode == IsolationMode.vocalsOnly,
                        isLoading: isLoadingStem && isolationMode == IsolationMode.vocalsOnly,
                        onTap: () => player.toggleIsolationMode(IsolationMode.vocalsOnly),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: _StemTile(
                        title: 'Instruments Only',
                        subtitle: 'Karaoke Mode',
                        icon: FontAwesomeIcons.music,
                        isActive: isolationMode == IsolationMode.instrumentsOnly,
                        isLoading: isLoadingStem && isolationMode == IsolationMode.instrumentsOnly,
                        onTap: () => player.toggleIsolationMode(IsolationMode.instrumentsOnly),
                      ),
                    ),
                  ],
                ),
              ),

              // Interactive 6-Band Bezier Graph Equalizer + 25 Studio Presets
              SpotifyGraphEqualizer(
                onDragStateChanged: (dragging) {
                  if (_isDraggingGraph != dragging) {
                    setState(() => _isDraggingGraph = dragging);
                  }
                },
              ),

              const SizedBox(height: 32),
            ],
          ),
        ),
      ),
    );
  }
}

class _TogglePill extends StatelessWidget {
  final String label;
  final FaIconData icon;
  final bool isActive;
  final VoidCallback onTap;

  const _TogglePill({
    required this.label,
    required this.icon,
    required this.isActive,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      borderRadius: BorderRadius.circular(10),
      onTap: () {
        HapticFeedback.selectionClick();
        onTap();
      },
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 160),
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
        decoration: BoxDecoration(
          color: isActive ? EmberColors.monoWhite : EmberColors.surfaceContainerHigh,
          borderRadius: BorderRadius.circular(10),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            FaIcon(icon, size: 11, color: isActive ? EmberColors.onAccent : EmberColors.textSecondary),
            const SizedBox(width: 6),
            Flexible(
              child: Text(
                label,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  color: isActive ? EmberColors.onAccent : EmberColors.textSecondary,
                  fontSize: 11.5,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _StemTile extends StatelessWidget {
  final String title;
  final String subtitle;
  final FaIconData icon;
  final bool isActive;
  final bool isLoading;
  final VoidCallback onTap;

  const _StemTile({
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.isActive,
    required this.isLoading,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      borderRadius: BorderRadius.circular(14),
      onTap: () {
        HapticFeedback.selectionClick();
        onTap();
      },
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: isActive ? EmberColors.monoWhite : EmberColors.surfaceContainerLow,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: isActive ? EmberColors.monoWhite : EmberColors.outlineVariant,
          ),
        ),
        child: Row(
          children: [
            Container(
              width: 32,
              height: 32,
              decoration: BoxDecoration(
                color: isActive ? Colors.black.withValues(alpha: 0.12) : EmberColors.surfaceContainerHigh,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Center(
                child: isLoading
                    ? SizedBox(
                        width: 14,
                        height: 14,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: isActive ? EmberColors.onAccent : EmberColors.monoWhite,
                        ),
                      )
                    : FaIcon(
                        icon,
                        size: 13,
                        color: isActive ? EmberColors.onAccent : EmberColors.monoWhite,
                      ),
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      color: isActive ? EmberColors.onAccent : EmberColors.textPrimary,
                      fontSize: 12.5,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  Text(
                    subtitle,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      color: isActive ? Colors.black.withValues(alpha: 0.65) : EmberColors.textMuted,
                      fontSize: 10.5,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
