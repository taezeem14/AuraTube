import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:provider/provider.dart';
import '../models/song.dart';
import '../providers/player_provider.dart';
import '../theme/ember_theme.dart';
import '../widgets/mini_player.dart';
import 'tabs/aura_home_tab.dart';
import 'tabs/aura_feed_tab.dart';
import 'tabs/aura_subscriptions_tab.dart';
import 'tabs/aura_bookmarks_tab.dart';
import 'tabs/pulsepipe_search_tab.dart';
import 'diagnostics_log_screen.dart';
import 'downloads_screen.dart';
import 'history_screen.dart';
import 'settings_screen.dart';
import 'sound_shaping_sheet.dart';

typedef SineShellScreen = PulsePipeShellScreen;
typedef AuraShellScreen = PulsePipeShellScreen;

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
        duration: const Duration(seconds: 8),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        content: Row(
          children: [
            const FaIcon(FontAwesomeIcons.triangleExclamation, color: Color(0xFFFF5252), size: 16),
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
          textColor: EmberColors.primaryBlue,
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
        builder: (_) => Scaffold(
          backgroundColor: EmberColors.obsidianBase,
          body: const SafeArea(child: PulsePipeSearchTab()),
        ),
      ),
    );
  }

  void _showAboutDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: EmberColors.surfaceContainerLow,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Row(
          children: [
            Container(
              width: 36,
              height: 36,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(10),
                gradient: const LinearGradient(
                  colors: [EmberColors.primaryBlue, EmberColors.secondaryCyan],
                ),
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(10),
                child: Image.asset(
                  'assets/icon/app_icon.png',
                  fit: BoxFit.cover,
                  errorBuilder: (context, error, stackTrace) => const Center(
                    child: FaIcon(FontAwesomeIcons.play, size: 14, color: Colors.white),
                  ),
                ),
              ),
            ),
            const SizedBox(width: 12),
            const Text('AuraTube', style: TextStyle(color: EmberColors.textPrimary, fontWeight: FontWeight.bold)),
          ],
        ),
        content: const Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'AuraTube v1.0.3',
              style: TextStyle(color: EmberColors.primaryBlueHi, fontWeight: FontWeight.bold, fontSize: 14),
            ),
            SizedBox(height: 6),
            Text(
              'Libre, modern YouTube & Music player built with NewPipe extraction and hardware multi-band DSP equalizer.',
              style: TextStyle(color: EmberColors.textSecondary, fontSize: 12.5),
            ),
            SizedBox(height: 14),
            Text(
              'Author & Lead Architect:',
              style: TextStyle(color: EmberColors.textMuted, fontSize: 11, fontWeight: FontWeight.bold),
            ),
            SizedBox(height: 2),
            Text(
              'Muhammad Taezeem Tariq (@taezeem14)',
              style: TextStyle(color: EmberColors.textPrimary, fontWeight: FontWeight.w600, fontSize: 13),
            ),
          ],
        ),
        actions: [
          TextButton(
            child: const Text('Close', style: TextStyle(color: EmberColors.primaryBlue)),
            onPressed: () => Navigator.pop(ctx),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: EmberColors.obsidianBase,
      // 1. Iconic NewPipe Navigation Drawer
      drawer: Drawer(
        backgroundColor: EmberColors.obsidianBase,
        child: SafeArea(
          child: Column(
            children: [
              // Drawer Header
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
                decoration: BoxDecoration(
                  color: EmberColors.surfaceContainerLow,
                  border: Border(
                    bottom: BorderSide(
                      color: Colors.white.withValues(alpha: 0.08),
                    ),
                  ),
                ),
                child: Row(
                  children: [
                    Container(
                      width: 48,
                      height: 48,
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(14),
                        gradient: const LinearGradient(
                          colors: [EmberColors.primaryBlue, EmberColors.secondaryCyan],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: EmberColors.primaryBlue.withValues(alpha: 0.4),
                            blurRadius: 12,
                            offset: const Offset(0, 2),
                          ),
                        ],
                      ),
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(14),
                        child: Image.asset(
                          'assets/icon/app_icon.png',
                          fit: BoxFit.cover,
                          errorBuilder: (context, error, stackTrace) => const Center(
                            child: FaIcon(FontAwesomeIcons.play, size: 18, color: Colors.white),
                          ),
                        ),
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
                              color: EmberColors.textPrimary,
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              letterSpacing: -0.3,
                            ),
                          ),
                          SizedBox(height: 2),
                          Text(
                            'Libre YouTube & Music',
                            style: TextStyle(
                              color: EmberColors.secondaryCyan,
                              fontSize: 11,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          Text(
                            'v1.0.3 • Muhammad Taezeem Tariq',
                            style: TextStyle(
                              color: EmberColors.textMuted,
                              fontSize: 9.5,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),

              // Drawer Navigation Items
              Expanded(
                child: ListView(
                  padding: const EdgeInsets.symmetric(vertical: 8),
                  children: [
                    ListTile(
                      leading: const FaIcon(FontAwesomeIcons.fire, size: 16, color: EmberColors.primaryBlue),
                      title: const Text('Trending', style: TextStyle(color: EmberColors.textPrimary, fontSize: 14)),
                      onTap: () {
                        Navigator.pop(context);
                        _tabController.animateTo(0);
                      },
                    ),
                    ListTile(
                      leading: const FaIcon(FontAwesomeIcons.rss, size: 16, color: EmberColors.secondaryCyan),
                      title: const Text("What's New (Feed)", style: TextStyle(color: EmberColors.textPrimary, fontSize: 14)),
                      onTap: () {
                        Navigator.pop(context);
                        _tabController.animateTo(1);
                      },
                    ),
                    ListTile(
                      leading: const FaIcon(FontAwesomeIcons.users, size: 16, color: EmberColors.primaryBlueHi),
                      title: const Text('Subscriptions', style: TextStyle(color: EmberColors.textPrimary, fontSize: 14)),
                      onTap: () {
                        Navigator.pop(context);
                        _tabController.animateTo(2);
                      },
                    ),
                    ListTile(
                      leading: const FaIcon(FontAwesomeIcons.bookmark, size: 16, color: EmberColors.tertiaryBlue),
                      title: const Text('Bookmarked Playlists', style: TextStyle(color: EmberColors.textPrimary, fontSize: 14)),
                      onTap: () {
                        Navigator.pop(context);
                        _tabController.animateTo(3);
                      },
                    ),
                    const Divider(color: EmberColors.outlineVariant, height: 16),
                    ListTile(
                      leading: const FaIcon(FontAwesomeIcons.clockRotateLeft, size: 16, color: EmberColors.textSecondary),
                      title: const Text('History', style: TextStyle(color: EmberColors.textPrimary, fontSize: 14)),
                      onTap: () {
                        Navigator.pop(context);
                        Navigator.push(context, MaterialPageRoute(builder: (_) => const HistoryScreen()));
                      },
                    ),
                    ListTile(
                      leading: const FaIcon(FontAwesomeIcons.download, size: 16, color: EmberColors.textSecondary),
                      title: const Text('Downloads', style: TextStyle(color: EmberColors.textPrimary, fontSize: 14)),
                      onTap: () {
                        Navigator.pop(context);
                        Navigator.push(context, MaterialPageRoute(builder: (_) => const DownloadsScreen()));
                      },
                    ),
                    ListTile(
                      leading: const FaIcon(FontAwesomeIcons.sliders, size: 16, color: EmberColors.primaryBlue),
                      title: const Text('Sound Shaping & EQ', style: TextStyle(color: EmberColors.textPrimary, fontSize: 14)),
                      onTap: () {
                        Navigator.pop(context);
                        SoundShapingSheet.show(context);
                      },
                    ),
                    const Divider(color: EmberColors.outlineVariant, height: 16),
                    ListTile(
                      leading: const FaIcon(FontAwesomeIcons.gear, size: 16, color: EmberColors.textSecondary),
                      title: const Text('Settings', style: TextStyle(color: EmberColors.textPrimary, fontSize: 14)),
                      onTap: () {
                        Navigator.pop(context);
                        SettingsScreen.show(context);
                      },
                    ),
                    ListTile(
                      leading: const FaIcon(FontAwesomeIcons.terminal, size: 16, color: EmberColors.textSecondary),
                      title: const Text('Diagnostics & Logs', style: TextStyle(color: EmberColors.textPrimary, fontSize: 14)),
                      onTap: () {
                        Navigator.pop(context);
                        Navigator.push(context, MaterialPageRoute(builder: (_) => const DiagnosticsLogScreen()));
                      },
                    ),
                    ListTile(
                      leading: const FaIcon(FontAwesomeIcons.circleInfo, size: 16, color: EmberColors.primaryBlue),
                      title: const Text('About AuraTube', style: TextStyle(color: EmberColors.textPrimary, fontSize: 14)),
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
      ),

      // 2. NewPipe Unified Top App Bar + Top TabBar
      appBar: AppBar(
        backgroundColor: EmberColors.obsidianBase,
        elevation: 0,
        leading: Builder(
          builder: (ctx) => IconButton(
            icon: const FaIcon(FontAwesomeIcons.bars, size: 18, color: EmberColors.textPrimary),
            tooltip: 'Navigation Menu',
            onPressed: () => Scaffold.of(ctx).openDrawer(),
          ),
        ),
        titleSpacing: 0,
        title: Row(
          children: [
            Container(
              width: 28,
              height: 28,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(8),
                gradient: const LinearGradient(
                  colors: [EmberColors.primaryBlue, EmberColors.secondaryCyan],
                ),
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(8),
                child: Image.asset(
                  'assets/icon/app_icon.png',
                  fit: BoxFit.cover,
                  errorBuilder: (context, error, stackTrace) => const Center(
                    child: FaIcon(FontAwesomeIcons.play, size: 12, color: Colors.white),
                  ),
                ),
              ),
            ),
            const SizedBox(width: 10),
            RichText(
              text: const TextSpan(
                style: TextStyle(
                  fontFamily: 'Sora',
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  letterSpacing: -0.3,
                ),
                children: [
                  TextSpan(text: 'Aura', style: TextStyle(color: Colors.white)),
                  TextSpan(text: 'Tube', style: TextStyle(color: EmberColors.primaryBlueHi)),
                ],
              ),
            ),
          ],
        ),
        actions: [
          IconButton(
            icon: const FaIcon(FontAwesomeIcons.magnifyingGlass, size: 16, color: EmberColors.textPrimary),
            tooltip: 'Search Videos',
            onPressed: _openSearchScreen,
          ),
          IconButton(
            icon: const FaIcon(FontAwesomeIcons.sliders, size: 16, color: EmberColors.textPrimary),
            tooltip: 'Equalizer & DSP',
            onPressed: () => SoundShapingSheet.show(context),
          ),
          PopupMenuButton<String>(
            icon: const FaIcon(FontAwesomeIcons.ellipsisVertical, size: 16, color: EmberColors.textPrimary),
            color: EmberColors.surfaceContainerLow,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            onSelected: (val) {
              switch (val) {
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
              const PopupMenuItem(
                value: 'history',
                child: Row(
                  children: [
                    FaIcon(FontAwesomeIcons.clockRotateLeft, size: 14, color: EmberColors.textSecondary),
                    SizedBox(width: 12),
                    Text('History', style: TextStyle(color: EmberColors.textPrimary, fontSize: 13)),
                  ],
                ),
              ),
              const PopupMenuItem(
                value: 'downloads',
                child: Row(
                  children: [
                    FaIcon(FontAwesomeIcons.download, size: 14, color: EmberColors.textSecondary),
                    SizedBox(width: 12),
                    Text('Downloads', style: TextStyle(color: EmberColors.textPrimary, fontSize: 13)),
                  ],
                ),
              ),
              const PopupMenuItem(
                value: 'settings',
                child: Row(
                  children: [
                    FaIcon(FontAwesomeIcons.gear, size: 14, color: EmberColors.textSecondary),
                    SizedBox(width: 12),
                    Text('Settings', style: TextStyle(color: EmberColors.textPrimary, fontSize: 13)),
                  ],
                ),
              ),
              const PopupMenuItem(
                value: 'about',
                child: Row(
                  children: [
                    FaIcon(FontAwesomeIcons.circleInfo, size: 14, color: EmberColors.primaryBlue),
                    SizedBox(width: 12),
                    Text('About AuraTube', style: TextStyle(color: EmberColors.textPrimary, fontSize: 13)),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(width: 4),
        ],
        // Top TabBar (NewPipe main_tab_layout style)
        bottom: TabBar(
          controller: _tabController,
          indicatorColor: EmberColors.primaryBlue,
          indicatorWeight: 3,
          labelColor: EmberColors.primaryBlueHi,
          unselectedLabelColor: EmberColors.textMuted,
          labelStyle: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12),
          unselectedLabelStyle: const TextStyle(fontWeight: FontWeight.w500, fontSize: 12),
          tabs: const [
            Tab(
              icon: FaIcon(FontAwesomeIcons.fire, size: 16),
              text: 'Trending',
            ),
            Tab(
              icon: FaIcon(FontAwesomeIcons.rss, size: 16),
              text: "What's New",
            ),
            Tab(
              icon: FaIcon(FontAwesomeIcons.users, size: 16),
              text: 'Subs',
            ),
            Tab(
              icon: FaIcon(FontAwesomeIcons.bookmark, size: 16),
              text: 'Bookmarks',
            ),
          ],
        ),
      ),

      // 3. TabBarView + Mini Player Docked at Bottom
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

          // Docked MiniPlayer (NewPipe overlay_layout)
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
}
