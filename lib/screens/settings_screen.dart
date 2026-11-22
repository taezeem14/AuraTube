import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:provider/provider.dart';
import '../providers/player_provider.dart';
import '../theme/ember_theme.dart';
import '../widgets/upi_donation_view.dart';
import 'car_mode_screen.dart';
import 'diagnostics_log_screen.dart';
import 'downloads_screen.dart';
import 'equalizer_screen.dart';
import 'history_screen.dart';
import 'playback_speed_sheet.dart';
import 'sponsorblock_screen.dart';
import 'stats_screen.dart';

class SettingsScreen extends StatefulWidget {
  final int initialTab;
  const SettingsScreen({super.key, this.initialTab = 0});

  static void show(BuildContext context, {int initialTab = 0}) {
    showModalBottomSheet(
      context: context,
      backgroundColor: EmberColors.obsidianBase,
      isScrollControlled: true,
      useSafeArea: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (_) => SettingsScreen(initialTab: initialTab),
    );
  }

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this, initialIndex: widget.initialTab);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return DraggableScrollableSheet(
      initialChildSize: 0.92,
      minChildSize: 0.5,
      maxChildSize: 0.96,
      expand: false,
      builder: (context, scrollController) {
        return Column(
          children: [
            Container(
              width: 38,
              height: 4,
              margin: const EdgeInsets.symmetric(vertical: 12),
              decoration: BoxDecoration(
                color: EmberColors.outline,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 4),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(10),
                      color: EmberColors.surfaceContainerHigh,
                    ),
                    child: const FaIcon(FontAwesomeIcons.gear, color: EmberColors.monoWhite, size: 16),
                  ),
                  const SizedBox(width: 12),
                  const Expanded(
                    child: Text(
                      'Settings & Architecture',
                      style: TextStyle(
                        color: EmberColors.textPrimary,
                        fontSize: 17,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                  IconButton(
                    icon: const FaIcon(FontAwesomeIcons.xmark, color: EmberColors.textMuted, size: 17),
                    onPressed: () => Navigator.of(context).pop(),
                  ),
                ],
              ),
            ),
            Container(
              margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              padding: const EdgeInsets.all(4),
              decoration: BoxDecoration(
                color: EmberColors.surfaceContainerLow,
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: EmberColors.outlineVariant),
              ),
              child: TabBar(
                controller: _tabController,
                indicator: BoxDecoration(
                  color: EmberColors.monoWhite,
                  borderRadius: BorderRadius.circular(10),
                ),
                indicatorSize: TabBarIndicatorSize.tab,
                dividerColor: Colors.transparent,
                labelColor: EmberColors.onAccent,
                unselectedLabelColor: EmberColors.textSecondary,
                labelStyle: const TextStyle(fontWeight: FontWeight.w700, fontSize: 12.5),
                unselectedLabelStyle: const TextStyle(fontWeight: FontWeight.w600, fontSize: 12.5),
                tabs: const [
                  Tab(
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        FaIcon(FontAwesomeIcons.sliders, size: 12),
                        SizedBox(width: 8),
                        Text('Preferences'),
                      ],
                    ),
                  ),
                  Tab(
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        FaIcon(FontAwesomeIcons.heart, size: 12),
                        SizedBox(width: 8),
                        Text('Support (UPI)'),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const Divider(color: EmberColors.borderSubtle, height: 10),
            Expanded(
              child: TabBarView(
                controller: _tabController,
                children: [
                  SettingsContent(
                    scrollController: scrollController,
                    onNavigateToDonate: () => _tabController.animateTo(1),
                  ),
                  SingleChildScrollView(
                    controller: scrollController,
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    child: const UpiDonationView(),
                  ),
                ],
              ),
            ),
          ],
        );
      },
    );
  }
}

class SettingsContent extends StatelessWidget {
  final ScrollController? scrollController;
  final VoidCallback? onNavigateToDonate;

  const SettingsContent({
    super.key,
    this.scrollController,
    this.onNavigateToDonate,
  });

  void _showRestoreBackupDialog(BuildContext context, PlayerProvider player) {
    final controller = TextEditingController();
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: EmberColors.surfaceContainerLow,
        title: const Text('Restore JSON Backup', style: TextStyle(color: EmberColors.textPrimary, fontWeight: FontWeight.w700)),
        content: TextField(
          controller: controller,
          maxLines: 6,
          style: const TextStyle(color: EmberColors.textPrimary, fontSize: 11.5),
          decoration: const InputDecoration(
            hintText: 'Paste exported AuraTube JSON backup here...',
            hintStyle: TextStyle(color: EmberColors.textMuted),
            border: OutlineInputBorder(borderSide: BorderSide(color: EmberColors.outlineVariant)),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel', style: TextStyle(color: EmberColors.textMuted)),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: EmberColors.monoWhite, foregroundColor: EmberColors.onAccent),
            onPressed: () async {
              final raw = controller.text.trim();
              if (raw.isEmpty) return;
              final ok = await player.importBackup(raw);
              if (ctx.mounted) Navigator.pop(ctx);
              if (context.mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text(ok
                        ? 'Backup restored cleanly (Playlists, Subs, Favorites & Settings).'
                        : 'Invalid JSON backup payload.'),
                  ),
                );
              }
            },
            child: const Text('Restore'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final player = context.watch<PlayerProvider>();

    return ListView(
      controller: scrollController,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      children: [
        // ==========================================
        // AUTHOR & CREATOR SHOWCASE CARD
        // ==========================================
        Container(
          margin: const EdgeInsets.only(bottom: 18),
          padding: const EdgeInsets.all(18),
          decoration: BoxDecoration(
            color: EmberColors.surfaceContainerLow,
            borderRadius: BorderRadius.circular(18),
            border: Border.all(color: EmberColors.outlineVariant, width: 1.0),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    width: 48,
                    height: 48,
                    decoration: BoxDecoration(
                      color: EmberColors.monoWhite,
                      borderRadius: BorderRadius.circular(14),
                    ),
                    child: const Center(
                      child: FaIcon(FontAwesomeIcons.play, size: 20, color: EmberColors.onAccent),
                    ),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Row(
                          children: [
                            Flexible(
                              child: Text(
                                'Muhammad Taezeem Tariq',
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: TextStyle(
                                  color: EmberColors.monoWhite,
                                  fontSize: 15.5,
                                  fontWeight: FontWeight.w800,
                                  letterSpacing: -0.2,
                                ),
                              ),
                            ),
                            SizedBox(width: 6),
                            FaIcon(FontAwesomeIcons.solidCircleCheck, color: EmberColors.monoWhite, size: 13),
                          ],
                        ),
                        const SizedBox(height: 4),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
                          decoration: BoxDecoration(
                            color: EmberColors.surfaceContainerHigh,
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: const Text(
                            'ARCHITECT & CREATOR · @TAEZEEM14',
                            style: TextStyle(
                              color: EmberColors.monoSilver,
                              fontSize: 9.5,
                              fontWeight: FontWeight.w700,
                              letterSpacing: 0.7,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 14),
              const Text(
                'AuraTube v1.0.4 Monochrome Edition combines NewPipe video extraction, Zemer-Cipher unthrottling, Audile acoustic recognition, BetterLyrics word-sync karaoke, SponsorBlock skipping, Metrolist insights, and Sine Priority-1000 6-band DSP.',
                style: TextStyle(color: EmberColors.textSecondary, fontSize: 12.5, height: 1.45),
              ),
              const SizedBox(height: 12),
              const Row(
                children: [
                  FaIcon(FontAwesomeIcons.github, size: 13, color: EmberColors.textMuted),
                  SizedBox(width: 7),
                  Text(
                    'github.com/taezeem14/AuraTube',
                    style: TextStyle(color: EmberColors.monoSilver, fontSize: 12, fontWeight: FontWeight.w600),
                  ),
                ],
              ),
              if (onNavigateToDonate != null) ...[
                const SizedBox(height: 14),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton.icon(
                    onPressed: onNavigateToDonate,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: EmberColors.monoWhite,
                      foregroundColor: EmberColors.onAccent,
                      padding: const EdgeInsets.symmetric(vertical: 11),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                    icon: const FaIcon(FontAwesomeIcons.heart, size: 13),
                    label: const Text(
                      'Support via UPI (7006616470@fam)',
                      style: TextStyle(fontWeight: FontWeight.w700, fontSize: 12.5),
                    ),
                  ),
                ),
              ],
            ],
          ),
        ),

        // ==========================================
        // AUDIO ENGINE & HARDWARE DSP
        // ==========================================
        const _SectionHeader(title: 'Audio Engine & Hardware DSP'),
        _SettingsTile(
          icon: FontAwesomeIcons.sliders,
          title: '6-Band Curve Equalizer & Bass Punch',
          subtitle: 'Profile: ${player.eqPreset} · Bass: ${(player.bassBoost * 100).round()}% · Priority-1000 DSP',
          trailing: const FaIcon(FontAwesomeIcons.chevronRight, size: 11, color: EmberColors.textMuted),
          onTap: () => EqualizerScreen.open(context),
        ),
        _SettingsTile(
          icon: FontAwesomeIcons.gaugeHigh,
          title: 'Speed, Pitch, Skip Silence & Sleep Timer',
          subtitle: 'Speed ${player.speed.toStringAsFixed(2)}x · Pitch ${player.pitch.toStringAsFixed(2)}x',
          trailing: const FaIcon(FontAwesomeIcons.chevronRight, size: 11, color: EmberColors.textMuted),
          onTap: () => PlaybackSpeedSheet.show(context),
        ),
        _SettingsTile(
          icon: FontAwesomeIcons.bolt,
          title: 'Autoplay Smart Mix Continuation',
          subtitle: 'Continuously append related tracks when playback ends',
          trailing: Switch(
            value: player.isAutoplayEnabled,
            onChanged: (_) => player.toggleAutoplay(),
          ),
          onTap: () => player.toggleAutoplay(),
        ),

        const SizedBox(height: 16),

        // ==========================================
        // SPONSORBLOCK & HARDWARE GESTURES
        // ==========================================
        const _SectionHeader(title: 'SponsorBlock & Hardware Gestures'),
        _SettingsTile(
          icon: FontAwesomeIcons.forwardFast,
          title: 'SponsorBlock Categories',
          subtitle: '${player.sponsorBlockEnabled ? "Active" : "Paused"} · ${player.sponsorBlockCategories.length}/8 categories · ${player.sponsorSegmentsSkipped} skipped',
          trailing: const FaIcon(FontAwesomeIcons.chevronRight, size: 11, color: EmberColors.textMuted),
          onTap: () => SponsorBlockScreen.open(context),
        ),
        _SettingsTile(
          icon: FontAwesomeIcons.mobileScreenButton,
          title: 'Shake to Skip Next',
          subtitle: 'Accelerometer gesture to advance track hands-free',
          trailing: Switch(
            value: player.shakeToSkip,
            onChanged: (v) => player.setShakeToSkip(v),
          ),
          onTap: () => player.setShakeToSkip(!player.shakeToSkip),
        ),
        _SettingsTile(
          icon: FontAwesomeIcons.rotate,
          title: 'Flip Face-Down to Pause',
          subtitle: 'Instantly pause playback when placing phone face down',
          trailing: Switch(
            value: player.flipToPause,
            onChanged: (v) => player.setFlipToPause(v),
          ),
          onTap: () => player.setFlipToPause(!player.flipToPause),
        ),
        _SettingsTile(
          icon: FontAwesomeIcons.car,
          title: 'Driving / Car Mode',
          subtitle: 'High-contrast monochrome oversized playback controls',
          trailing: const FaIcon(FontAwesomeIcons.chevronRight, size: 11, color: EmberColors.textMuted),
          onTap: () => CarModeScreen.open(context),
        ),

        const SizedBox(height: 16),

        // ==========================================
        // LIBRARY, INSIGHTS & JSON BACKUP
        // ==========================================
        const _SectionHeader(title: 'Library, Insights & Backup'),
        _SettingsTile(
          icon: FontAwesomeIcons.chartSimple,
          title: 'Listening Insights & Stats',
          subtitle: 'Private local listening telemetry & top charts',
          trailing: const FaIcon(FontAwesomeIcons.chevronRight, size: 11, color: EmberColors.textMuted),
          onTap: () => StatsScreen.open(context),
        ),
        _SettingsTile(
          icon: FontAwesomeIcons.download,
          title: 'Offline Downloads',
          subtitle: 'Manage saved MP4 videos & M4A audio files',
          trailing: const FaIcon(FontAwesomeIcons.chevronRight, size: 11, color: EmberColors.textMuted),
          onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const DownloadsScreen())),
        ),
        _SettingsTile(
          icon: FontAwesomeIcons.clockRotateLeft,
          title: 'Watch & Play History',
          subtitle: '${player.history.length} local items recorded',
          trailing: const FaIcon(FontAwesomeIcons.chevronRight, size: 11, color: EmberColors.textMuted),
          onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const HistoryScreen())),
        ),
        _SettingsTile(
          icon: FontAwesomeIcons.fileExport,
          title: 'Export Full JSON Backup',
          subtitle: 'Copy Subscriptions, Playlists, Favorites & Settings to clipboard',
          trailing: const FaIcon(FontAwesomeIcons.copy, size: 12, color: EmberColors.textMuted),
          onTap: () {
            final json = player.exportBackup();
            Clipboard.setData(ClipboardData(text: json));
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('Full AuraTube JSON backup copied to clipboard')),
            );
          },
        ),
        _SettingsTile(
          icon: FontAwesomeIcons.fileImport,
          title: 'Restore Backup from JSON',
          subtitle: 'Import exported AuraTube library & settings',
          trailing: const FaIcon(FontAwesomeIcons.chevronRight, size: 11, color: EmberColors.textMuted),
          onTap: () => _showRestoreBackupDialog(context, player),
        ),
        _SettingsTile(
          icon: FontAwesomeIcons.broom,
          title: 'Purge Cache & Temp Buffers',
          subtitle: 'Clear cached stream URLs & placeholder entries',
          trailing: const FaIcon(FontAwesomeIcons.chevronRight, size: 11, color: EmberColors.textMuted),
          onTap: () async {
            await player.purgePlaceholders();
            if (context.mounted) {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Stream caches & temp buffers cleared')),
              );
            }
          },
        ),

        const SizedBox(height: 16),

        // ==========================================
        // SYSTEM & OPEN-SOURCE ARCHITECTURE
        // ==========================================
        const _SectionHeader(title: 'System & Open-Source Stack'),
        const _SettingsTile(
          icon: FontAwesomeIcons.mobileScreen,
          title: 'AuraTube Version',
          subtitle: 'v1.0.4 (Monochrome Studio Release)',
          trailing: Text('1.0.4', style: TextStyle(color: EmberColors.monoWhite, fontSize: 12, fontWeight: FontWeight.w700)),
        ),
        const _SettingsTile(
          icon: FontAwesomeIcons.layerGroup,
          title: 'Integrated Open-Source Architecture',
          subtitle: 'NewPipe · Metrolist · Audile · BetterLyrics · SponsorBlock · Zemer-Cipher · YoutubeExplode · just_audio · audio_service · Sine',
        ),
        _SettingsTile(
          icon: FontAwesomeIcons.terminal,
          title: 'Diagnostics & Log Extractor',
          subtitle: 'Live ExoPlayer telemetry, cipher status & stream inspector',
          trailing: const FaIcon(FontAwesomeIcons.chevronRight, size: 11, color: EmberColors.textMuted),
          onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const DiagnosticsLogScreen())),
        ),
        const SizedBox(height: 28),
      ],
    );
  }
}

class _SectionHeader extends StatelessWidget {
  final String title;
  const _SectionHeader({required this.title});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(left: 4, bottom: 8, top: 4),
      child: Text(
        title.toUpperCase(),
        style: const TextStyle(
          color: EmberColors.textMuted,
          fontSize: 10.5,
          fontWeight: FontWeight.w700,
          letterSpacing: 1.2,
        ),
      ),
    );
  }
}

class _SettingsTile extends StatelessWidget {
  final FaIconData icon;
  final String title;
  final String subtitle;
  final Widget? trailing;
  final VoidCallback? onTap;

  const _SettingsTile({
    required this.icon,
    required this.title,
    required this.subtitle,
    this.trailing,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(vertical: 4),
      decoration: BoxDecoration(
        color: EmberColors.surfaceContainerLow,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: EmberColors.outlineVariant),
      ),
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 2),
        leading: Container(
          width: 36,
          height: 36,
          decoration: BoxDecoration(
            color: EmberColors.surfaceContainerHigh,
            borderRadius: BorderRadius.circular(10),
          ),
          child: Center(
            child: FaIcon(icon, size: 14, color: EmberColors.monoWhite),
          ),
        ),
        title: Text(
          title,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: const TextStyle(color: EmberColors.textPrimary, fontSize: 13.5, fontWeight: FontWeight.w600),
        ),
        subtitle: Text(
          subtitle,
          maxLines: 3,
          overflow: TextOverflow.ellipsis,
          style: const TextStyle(color: EmberColors.textMuted, fontSize: 11),
        ),
        trailing: trailing,
        onTap: onTap,
      ),
    );
  }
}
