import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:provider/provider.dart';
import '../models/song.dart';
import '../providers/player_provider.dart';
import '../theme/ember_theme.dart';
import '../widgets/mini_player.dart';
import '../widgets/music_detector_sheet.dart';
import 'tabs/aura_home_tab.dart';
import 'tabs/aura_feed_tab.dart';
import 'tabs/aura_subscriptions_tab.dart';
import 'tabs/aura_bookmarks_tab.dart';
import 'tabs/pulsepipe_search_tab.dart';
import 'car_mode_screen.dart';
import 'diagnostics_log_screen.dart';
import 'downloads_screen.dart';
import 'equalizer_screen.dart';
import 'history_screen.dart';
import 'settings_screen.dart';
import 'sponsorblock_screen.dart';
import 'stats_screen.dart';

typedef SineShellScreen = PulsePipeShellScreen;
typedef AuraShellScreen = PulsePipeShellScreen;

/// Production-Level Monochromatic Main Shell uniting NewPipe, Metrolist, Audile,
/// BetterLyrics, SponsorBlock, Zemer-Cipher, YoutubeExplode, just_audio, audio_service & Sine.
class PulsePipeShellScreen extends StatefulWidget {
  const PulsePipeShellScreen({super.key});

  @override
  State<PulsePipeShellScreen> createState() => _PulsePipeShellScreenState();
}

class _PulsePipeShellScreenState extends State<PulsePipeShellScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  ValueNotifier<Song?>? _errorNotifier;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 4, vsync: this);
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final notifier = Provider.of<PlayerProvider>(context, listen: false).playbackErrorNotifier;
    if (_errorNotifier != notifier) {
      _errorNotifier?.removeListener(_onPlaybackError);
      _errorNotifier = notifier;
      _errorNotifier?.addListener(_onPlaybackError);
    }
  }

  @override
  void dispose() {
    _tabController.dispose();
    _errorNotifier?.removeListener(_onPlaybackError);
    super.dispose();
  }

  void _onPlaybackError() {
    if (!mounted) return;
    final failedSong = _errorNotifier?.value;
    if (failedSong == null) return;

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        backgroundColor: EmberColors.surfaceContainerHigh,
        behavior: SnackBarBehavior.floating,
        duration: const Duration(seconds: 7),
        content: Row(
          children: [
            const FaIcon(FontAwesomeIcons.triangleExclamation, color: EmberColors.error, size: 15),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                'Stream failed for "${failedSong.title}"',
                style: const TextStyle(color: EmberColors.textPrimary, fontSize: 12.5),
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
        action: SnackBarAction(
          label: 'VIEW LOG',
          textColor: EmberColors.monoWhite,
          onPressed: () {
            Navigator.of(context).push(
              MaterialPageRoute(builder: (_) => const DiagnosticsLogScreen()),
            );
          },
        ),
      ),
    );
  }

  void _openSearchScreen() {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => const Scaffold(
          backgroundColor: EmberColors.obsidianBase,
          body: SafeArea(child: PulsePipeSearchTab()),
        ),
      ),
    );
  }

  void _showAboutDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: EmberColors.surfaceContainerLow,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
          side: const BorderSide(color: EmberColors.outlineVariant),
        ),
        title: Row(
          children: [
            Container(
              width: 36,
              height: 36,
              decoration: BoxDecoration(
                color: EmberColors.monoWhite,
                borderRadius: BorderRadius.circular(10),
              ),
              child: const Center(
                child: FaIcon(FontAwesomeIcons.play, size: 14, color: EmberColors.onAccent),
              ),
            ),
            const SizedBox(width: 12),
            const Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('AuraTube', style: TextStyle(color: EmberColors.textPrimary, fontSize: 17, fontWeight: FontWeight.w800)),
                Text('v1.0.4 · MONOCHROME EDITION', style: TextStyle(color: EmberColors.textMuted, fontSize: 9.5, letterSpacing: 1.0)),
              ],
            ),
          ],
        ),
        content: const Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Libre, ad-free YouTube Video & Music studio combining NewPipe extraction, Zemer-Cipher unthrottling, Audile acoustic recognition, BetterLyrics word-sync karaoke, SponsorBlock skipping, Metrolist playback insights, and Sine Priority-1000 6-band DSP.',
              style: TextStyle(color: EmberColors.textSecondary, fontSize: 12.5, height: 1.45),
            ),
            SizedBox(height: 16),
            Text(
              'ARCHITECT & CREATOR',
              style: TextStyle(color: EmberColors.textMuted, fontSize: 10, letterSpacing: 1.1, fontWeight: FontWeight.w700),
            ),
            SizedBox(height: 4),
            Text(
              'Muhammad Taezeem Tariq (@taezeem14)',
              style: TextStyle(color: EmberColors.monoWhite, fontWeight: FontWeight.w700, fontSize: 13.5),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Close', style: TextStyle(color: EmberColors.monoWhite, fontWeight: FontWeight.w700)),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: EmberColors.obsidianBase,
      drawer: _buildMonochromeDrawer(context),
      appBar: AppBar(
        backgroundColor: EmberColors.obsidianBase,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        leading: Builder(
          builder: (ctx) => IconButton(
            icon: const FaIcon(FontAwesomeIcons.bars, size: 17, color: EmberColors.monoWhite),
            tooltip: 'Menu',
            onPressed: () {
              HapticFeedback.selectionClick();
              Scaffold.of(ctx).openDrawer();
            },
          ),
        ),
        titleSpacing: 0,
        title: Row(
          children: [
            Container(
              width: 28,
              height: 28,
              decoration: BoxDecoration(
                color: EmberColors.monoWhite,
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Center(
                child: FaIcon(FontAwesomeIcons.play, size: 11, color: EmberColors.onAccent),
              ),
            ),
            const SizedBox(width: 10),
            const Text(
              'AuraTube',
              style: TextStyle(
                color: EmberColors.monoWhite,
                fontSize: 18,
                fontWeight: FontWeight.w800,
                letterSpacing: -0.5,
              ),
            ),
          ],
        ),
        actions: [
          // Audile Shazam Music Recognizer Trigger
          IconButton(
            icon: const FaIcon(FontAwesomeIcons.waveSquare, size: 16, color: EmberColors.monoWhite),
            tooltip: 'Audile Song Recognition',
            onPressed: () {
              HapticFeedback.selectionClick();
              MusicDetectorSheet.show(context);
            },
          ),
          // Search Trigger
          IconButton(
            icon: const FaIcon(FontAwesomeIcons.magnifyingGlass, size: 16, color: EmberColors.monoWhite),
            tooltip: 'Search YouTube',
            onPressed: _openSearchScreen,
          ),
          // 6-Band Bezier Equalizer Trigger
          IconButton(
            icon: const FaIcon(FontAwesomeIcons.sliders, size: 16, color: EmberColors.monoWhite),
            tooltip: 'Equalizer & DSP',
            onPressed: () => EqualizerScreen.open(context),
          ),
          PopupMenuButton<String>(
            icon: const FaIcon(FontAwesomeIcons.ellipsisVertical, size: 16, color: EmberColors.textSecondary),
            color: EmberColors.surfaceContainerLow,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(14),
              side: const BorderSide(color: EmberColors.outlineVariant),
            ),
            onSelected: (val) {
              switch (val) {
                case 'sponsorblock':
                  SponsorBlockScreen.open(context);
                  break;
                case 'stats':
                  StatsScreen.open(context);
                  break;
                case 'carmode':
                  CarModeScreen.open(context);
                  break;
                case 'history':
                  Navigator.push(context, MaterialPageRoute(builder: (_) => const HistoryScreen()));
                  break;
                case 'downloads':
                  Navigator.push(context, MaterialPageRoute(builder: (_) => const DownloadsScreen()));
                  break;
                case 'settings':
                  SettingsScreen.show(context);
                  break;
                case 'about':
                  _showAboutDialog(context);
                  break;
              }
            },
            itemBuilder: (ctx) => [
              _popupItem('sponsorblock', FontAwesomeIcons.forwardFast, 'SponsorBlock'),
              _popupItem('stats', FontAwesomeIcons.chartSimple, 'Insights & Stats'),
              _popupItem('carmode', FontAwesomeIcons.car, 'Driving Mode'),
              _popupItem('history', FontAwesomeIcons.clockRotateLeft, 'Watch History'),
              _popupItem('downloads', FontAwesomeIcons.download, 'Downloads'),
              _popupItem('settings', FontAwesomeIcons.gear, 'Settings & Backup'),
              _popupItem('about', FontAwesomeIcons.circleInfo, 'About AuraTube'),
            ],
          ),
          const SizedBox(width: 2),
        ],
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(46),
          child: Container(
            decoration: const BoxDecoration(
              border: Border(bottom: BorderSide(color: EmberColors.borderSubtle, width: 1)),
            ),
            child: TabBar(
              controller: _tabController,
              indicatorColor: EmberColors.monoWhite,
              indicatorWeight: 2.5,
              indicatorSize: TabBarIndicatorSize.label,
              dividerColor: Colors.transparent,
              labelColor: EmberColors.monoWhite,
              unselectedLabelColor: EmberColors.textMuted,
              labelStyle: const TextStyle(fontWeight: FontWeight.w700, fontSize: 12, letterSpacing: 0.1),
              unselectedLabelStyle: const TextStyle(fontWeight: FontWeight.w500, fontSize: 12),
              tabs: const [
                Tab(text: 'Feed'),
                Tab(text: "What's New"),
                Tab(text: 'Subs'),
                Tab(text: 'Library'),
              ],
            ),
          ),
        ),
      ),
      body: Stack(
        children: [
          TabBarView(
            controller: _tabController,
            children: [
              AuraHomeTab(
                onOpenSearch: _openSearchScreen,
                onOpenLibrary: () => _tabController.animateTo(3),
              ),
              AuraFeedTab(
                onExploreTrending: () => _tabController.animateTo(0),
              ),
              AuraSubscriptionsTab(
                onBrowseTrending: () => _tabController.animateTo(0),
              ),
              const AuraBookmarksTab(),
            ],
          ),
          const Positioned(
            left: 0,
            right: 0,
            bottom: 0,
            child: MiniPlayer(),
          ),
        ],
      ),
    );
  }

  PopupMenuItem<String> _popupItem(String value, FaIconData icon, String label) {
    return PopupMenuItem(
      value: value,
      child: Row(
        children: [
          SizedBox(
            width: 20,
            child: Center(child: FaIcon(icon, size: 13, color: EmberColors.monoSilver)),
          ),
          const SizedBox(width: 12),
          Text(label, style: const TextStyle(color: EmberColors.textPrimary, fontSize: 13, fontWeight: FontWeight.w500)),
        ],
      ),
    );
  }

  Widget _buildMonochromeDrawer(BuildContext context) {
    return Drawer(
      backgroundColor: EmberColors.obsidianBase,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.horizontal(right: Radius.circular(0)),
      ),
      child: SafeArea(
        child: Column(
          children: [
            // Architectural Monochrome Brand Header
            Container(
              padding: const EdgeInsets.fromLTRB(20, 22, 20, 20),
              decoration: const BoxDecoration(
                color: EmberColors.surfaceContainerLow,
                border: Border(bottom: BorderSide(color: EmberColors.borderSubtle)),
              ),
              child: Row(
                children: [
                  Container(
                    width: 44,
                    height: 44,
                    decoration: BoxDecoration(
                      color: EmberColors.monoWhite,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Center(
                      child: FaIcon(FontAwesomeIcons.play, size: 18, color: EmberColors.onAccent),
                    ),
                  ),
                  const SizedBox(width: 14),
                  const Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'AuraTube',
                          style: TextStyle(
                            color: EmberColors.monoWhite,
                            fontSize: 18,
                            fontWeight: FontWeight.w800,
                            letterSpacing: -0.4,
                          ),
                        ),
                        SizedBox(height: 2),
                        Text(
                          'v1.0.4 · MONOCHROME',
                          style: TextStyle(
                            color: EmberColors.monoSilver,
                            fontSize: 10,
                            fontWeight: FontWeight.w700,
                            letterSpacing: 1.0,
                          ),
                        ),
                        SizedBox(height: 2),
                        Text(
                          'by Muhammad Taezeem Tariq',
                          style: TextStyle(color: EmberColors.textMuted, fontSize: 10.5),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),

            Expanded(
              child: ListView(
                padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 10),
                children: [
                  const _DrawerSectionLabel('DISCOVER'),
                  _DrawerNavTile(
                    icon: FontAwesomeIcons.fire,
                    title: 'Trending Feed',
                    onTap: () {
                      Navigator.pop(context);
                      _tabController.animateTo(0);
                    },
                  ),
                  _DrawerNavTile(
                    icon: FontAwesomeIcons.rss,
                    title: "What's New",
                    onTap: () {
                      Navigator.pop(context);
                      _tabController.animateTo(1);
                    },
                  ),
                  _DrawerNavTile(
                    icon: FontAwesomeIcons.users,
                    title: 'Subscriptions',
                    onTap: () {
                      Navigator.pop(context);
                      _tabController.animateTo(2);
                    },
                  ),
                  _DrawerNavTile(
                    icon: FontAwesomeIcons.bookmark,
                    title: 'Library & Playlists',
                    onTap: () {
                      Navigator.pop(context);
                      _tabController.animateTo(3);
                    },
                  ),

                  const Padding(
                    padding: EdgeInsets.symmetric(vertical: 8),
                    child: Divider(color: EmberColors.borderSubtle, height: 1),
                  ),
                  const _DrawerSectionLabel('STUDIO TOOLS'),
                  _DrawerNavTile(
                    icon: FontAwesomeIcons.waveSquare,
                    title: 'Audile Song Recognizer',
                    subtitle: 'Shazam acoustic fingerprint',
                    onTap: () {
                      Navigator.pop(context);
                      MusicDetectorSheet.show(context);
                    },
                  ),
                  _DrawerNavTile(
                    icon: FontAwesomeIcons.sliders,
                    title: '6-Band Curve Equalizer',
                    subtitle: 'Priority-1000 hardware DSP',
                    onTap: () {
                      Navigator.pop(context);
                      EqualizerScreen.open(context);
                    },
                  ),
                  _DrawerNavTile(
                    icon: FontAwesomeIcons.forwardFast,
                    title: 'SponsorBlock',
                    subtitle: '8 crowd-sourced skip categories',
                    onTap: () {
                      Navigator.pop(context);
                      SponsorBlockScreen.open(context);
                    },
                  ),
                  _DrawerNavTile(
                    icon: FontAwesomeIcons.chartSimple,
                    title: 'Insights & Stats',
                    subtitle: 'Top artists, plays & time saved',
                    onTap: () {
                      Navigator.pop(context);
                      StatsScreen.open(context);
                    },
                  ),
                  _DrawerNavTile(
                    icon: FontAwesomeIcons.car,
                    title: 'Driving Mode',
                    subtitle: 'High-contrast car controls',
                    onTap: () {
                      Navigator.pop(context);
                      CarModeScreen.open(context);
                    },
                  ),

                  const Padding(
                    padding: EdgeInsets.symmetric(vertical: 8),
                    child: Divider(color: EmberColors.borderSubtle, height: 1),
                  ),
                  const _DrawerSectionLabel('MEDIA & SYSTEM'),
                  _DrawerNavTile(
                    icon: FontAwesomeIcons.clockRotateLeft,
                    title: 'Watch History',
                    onTap: () {
                      Navigator.pop(context);
                      Navigator.push(context, MaterialPageRoute(builder: (_) => const HistoryScreen()));
                    },
                  ),
                  _DrawerNavTile(
                    icon: FontAwesomeIcons.download,
                    title: 'Offline Downloads',
                    onTap: () {
                      Navigator.pop(context);
                      Navigator.push(context, MaterialPageRoute(builder: (_) => const DownloadsScreen()));
                    },
                  ),
                  _DrawerNavTile(
                    icon: FontAwesomeIcons.gear,
                    title: 'Settings, Backup & UPI',
                    onTap: () {
                      Navigator.pop(context);
                      SettingsScreen.show(context);
                    },
                  ),
                  _DrawerNavTile(
                    icon: FontAwesomeIcons.terminal,
                    title: 'Diagnostics & Logs',
                    onTap: () {
                      Navigator.pop(context);
                      Navigator.push(context, MaterialPageRoute(builder: (_) => const DiagnosticsLogScreen()));
                    },
                  ),
                  _DrawerNavTile(
                    icon: FontAwesomeIcons.circleInfo,
                    title: 'About AuraTube',
                    onTap: () {
                      Navigator.pop(context);
                      _showAboutDialog(context);
                    },
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

class _DrawerSectionLabel extends StatelessWidget {
  final String text;
  const _DrawerSectionLabel(this.text);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(12, 6, 12, 6),
      child: Text(
        text,
        style: const TextStyle(
          color: EmberColors.textMuted,
          fontSize: 10,
          fontWeight: FontWeight.w700,
          letterSpacing: 1.2,
        ),
      ),
    );
  }
}

class _DrawerNavTile extends StatelessWidget {
  final FaIconData icon;
  final String title;
  final String? subtitle;
  final VoidCallback onTap;

  const _DrawerNavTile({
    required this.icon,
    required this.title,
    this.subtitle,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return ListTile(
      dense: true,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      leading: SizedBox(
        width: 22,
        child: Center(child: FaIcon(icon, size: 14, color: EmberColors.monoSilver)),
      ),
      title: Text(
        title,
        style: const TextStyle(color: EmberColors.textPrimary, fontSize: 13.5, fontWeight: FontWeight.w600),
      ),
      subtitle: subtitle != null
          ? Text(subtitle!, style: const TextStyle(color: EmberColors.textMuted, fontSize: 10.5))
          : null,
      onTap: onTap,
    );
  }
}
