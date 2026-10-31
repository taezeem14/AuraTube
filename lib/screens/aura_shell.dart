import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:provider/provider.dart';
import '../services/player_service.dart';
import '../theme/aura_theme.dart';
import 'home_screen.dart';
import 'shorts_screen.dart';
import 'subscriptions_screen.dart';
import 'library_screen.dart';
import 'video_detail_screen.dart';
import 'sound_shaping_sheet.dart';

class AuraShell extends StatefulWidget {
  const AuraShell({super.key});

  @override
  State<AuraShell> createState() => _AuraShellState();
}

class _AuraShellState extends State<AuraShell> {
  int _currentIndex = 0;

  final List<Widget> _pages = const [
    HomeScreen(),
    ShortsScreen(),
    SubscriptionsScreen(),
    LibraryScreen(),
  ];

  @override
  Widget build(BuildContext context) {
    final player = context.watch<PlayerService>();

    return Scaffold(
      backgroundColor: AuraColors.obsidianBase,
      body: Stack(
        children: [
          IndexedStack(
            index: _currentIndex,
            children: _pages,
          ),

          // Persistent Floating Mini-Player Bar (When background audio is active)
          if (player.currentVideo != null && player.mode == PlayerMode.backgroundAudio)
            Positioned(
              left: 12,
              right: 12,
              bottom: 8,
              child: GestureDetector(
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (_) => VideoDetailScreen(video: player.currentVideo!)),
                  );
                },
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                  decoration: BoxDecoration(
                    color: AuraColors.surfaceHigh.withValues(alpha: 0.95),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: AuraColors.primaryBlue.withValues(alpha: 0.6), width: 1.2),
                    boxShadow: [
                      BoxShadow(
                        color: AuraColors.primaryBlue.withValues(alpha: 0.25),
                        blurRadius: 16,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: Row(
                    children: [
                      Container(
                        width: 36,
                        height: 36,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: AuraColors.primaryBlue,
                        ),
                        child: const Center(
                          child: FaIcon(FontAwesomeIcons.headphones, color: Colors.white, size: 16),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(
                              player.currentVideo!.title,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(color: AuraColors.textPrimary, fontWeight: FontWeight.bold, fontSize: 13),
                            ),
                            Text(
                              '${player.currentVideo!.author} • DSP EQ Active',
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(color: AuraColors.accentCyan, fontSize: 11),
                            ),
                          ],
                        ),
                      ),
                      IconButton(
                        icon: const FaIcon(FontAwesomeIcons.sliders, color: AuraColors.accentCyan, size: 14),
                        onPressed: () => SoundShapingSheet.show(context),
                      ),
                      IconButton(
                        icon: FaIcon(
                          player.isPlaying ? FontAwesomeIcons.pause : FontAwesomeIcons.play,
                          color: Colors.white,
                          size: 16,
                        ),
                        onPressed: () => player.togglePlayPause(),
                      ),
                    ],
                  ),
                ),
              ),
            ),
        ],
      ),
      bottomNavigationBar: Container(
        decoration: const BoxDecoration(
          border: Border(top: BorderSide(color: AuraColors.outline, width: 0.8)),
        ),
        child: BottomNavigationBar(
          currentIndex: _currentIndex,
          onTap: (index) => setState(() => _currentIndex = index),
          items: const [
            BottomNavigationBarItem(
              icon: FaIcon(FontAwesomeIcons.house, size: 18),
              activeIcon: FaIcon(FontAwesomeIcons.house, size: 18, color: AuraColors.primaryBlueLight),
              label: 'Home',
            ),
            BottomNavigationBarItem(
              icon: FaIcon(FontAwesomeIcons.bolt, size: 18),
              activeIcon: FaIcon(FontAwesomeIcons.bolt, size: 18, color: AuraColors.accentCyan),
              label: 'Shorts',
            ),
            BottomNavigationBarItem(
              icon: FaIcon(FontAwesomeIcons.youtube, size: 18),
              activeIcon: FaIcon(FontAwesomeIcons.youtube, size: 18, color: AuraColors.primaryBlueLight),
              label: 'Subscriptions',
            ),
            BottomNavigationBarItem(
              icon: FaIcon(FontAwesomeIcons.folder, size: 18),
              activeIcon: FaIcon(FontAwesomeIcons.folder, size: 18, color: AuraColors.primaryBlueLight),
              label: 'Library',
            ),
          ],
        ),
      ),
    );
  }
}
