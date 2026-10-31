import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:url_launcher/url_launcher.dart';
import '../theme/aura_theme.dart';
import '../widgets/upi_donation_view.dart';
import 'sound_shaping_sheet.dart';

class SettingsScreen extends StatefulWidget {
  final int initialTab;
  const SettingsScreen({super.key, this.initialTab = 0});

  static void show(BuildContext context, {int initialTab = 0}) {
    showModalBottomSheet(
      context: context,
      backgroundColor: AuraColors.obsidianBase,
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
                color: AuraColors.textMuted.withValues(alpha: 0.35),
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
                      shape: BoxShape.circle,
                      color: AuraColors.primaryBlue.withValues(alpha: 0.16),
                    ),
                    child: const FaIcon(FontAwesomeIcons.gear, color: AuraColors.primaryBlueLight, size: 18),
                  ),
                  const SizedBox(width: 12),
                  const Expanded(
                    child: Text(
                      'Settings & About',
                      style: TextStyle(
                        color: AuraColors.textPrimary,
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close_rounded, color: AuraColors.textMuted, size: 20),
                    onPressed: () => Navigator.of(context).pop(),
                  ),
                ],
              ),
            ),
            Container(
              margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              padding: const EdgeInsets.all(4),
              decoration: BoxDecoration(
                color: AuraColors.surfaceHigh,
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: AuraColors.outline.withValues(alpha: 0.5)),
              ),
              child: TabBar(
                controller: _tabController,
                indicator: BoxDecoration(
                  color: AuraColors.primaryBlue,
                  borderRadius: BorderRadius.circular(10),
                  boxShadow: [
                    BoxShadow(
                      color: AuraColors.primaryBlue.withValues(alpha: 0.4),
                      blurRadius: 8,
                    ),
                  ],
                ),
                indicatorSize: TabBarIndicatorSize.tab,
                dividerColor: Colors.transparent,
                labelColor: Colors.white,
                unselectedLabelColor: AuraColors.textSecondary,
                labelStyle: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
                tabs: const [
                  Tab(
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        FaIcon(FontAwesomeIcons.sliders, size: 13),
                        SizedBox(width: 8),
                        Text('Settings'),
                      ],
                    ),
                  ),
                  Tab(
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        FaIcon(FontAwesomeIcons.heart, size: 13),
                        SizedBox(width: 8),
                        Text('Donate (UPI)'),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            Expanded(
              child: TabBarView(
                controller: _tabController,
                children: [
                  SettingsContent(
                    scrollController: scrollController,
                    onNavigateToDonate: () => _tabController.animateTo(1),
                  ),
                  UpiDonationView(scrollController: scrollController),
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

  const SettingsContent({super.key, this.scrollController, this.onNavigateToDonate});

  @override
  Widget build(BuildContext context) {
    return ListView(
      controller: scrollController,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      children: [
        // ==========================================
        // SOLE CREATOR & AUTHOR SPOTLIGHT CARD
        // ==========================================
        Container(
          padding: const EdgeInsets.all(18),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [
                AuraColors.primaryBlue.withValues(alpha: 0.2),
                AuraColors.surfaceHigh.withValues(alpha: 0.85),
              ],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
              color: AuraColors.primaryBlue.withValues(alpha: 0.5),
              width: 1.2,
            ),
            boxShadow: [
              BoxShadow(
                color: AuraColors.primaryBlue.withValues(alpha: 0.1),
                blurRadius: 18,
                offset: const Offset(0, 6),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    width: 52,
                    height: 52,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      gradient: const LinearGradient(
                        colors: [AuraColors.primaryBlue, AuraColors.accentCyan],
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: AuraColors.primaryBlue.withValues(alpha: 0.45),
                          blurRadius: 12,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    child: const Center(
                      child: FaIcon(
                        FontAwesomeIcons.bolt,
                        size: 24,
                        color: Colors.white,
                      ),
                    ),
                  ),
                  const SizedBox(width: 14),
                  const Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Muhammad Taezeem Tariq',
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            color: AuraColors.textPrimary,
                            fontSize: 16,
                            fontWeight: FontWeight.w800,
                            letterSpacing: 0.3,
                          ),
                        ),
                        SizedBox(height: 3),
                        Text(
                          'Architect & Sole Developer of AuraTube',
                          style: TextStyle(
                            color: AuraColors.accentCyan,
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 14),
              const Text(
                'AuraTube is a high-performance, ad-free, libre YouTube and Shorts streaming client engineered with NewPipe extraction architecture, hardware DSP multi-band equalizer, and background streaming.',
                style: TextStyle(
                  color: AuraColors.textSecondary,
                  fontSize: 12.5,
                  height: 1.4,
                ),
              ),
              const SizedBox(height: 14),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: () {
                        launchUrl(
                          Uri.parse('https://github.com/taezeem14/AuraTube'),
                          mode: LaunchMode.externalApplication,
                        );
                      },
                      style: OutlinedButton.styleFrom(
                        foregroundColor: AuraColors.accentCyan,
                        side: BorderSide(color: AuraColors.accentCyan.withValues(alpha: 0.6)),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        padding: const EdgeInsets.symmetric(vertical: 10),
                      ),
                      icon: const FaIcon(FontAwesomeIcons.github, size: 14),
                      label: const Text('GitHub Repo', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: ElevatedButton.icon(
                      onPressed: onNavigateToDonate,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AuraColors.primaryBlue,
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        padding: const EdgeInsets.symmetric(vertical: 10),
                      ),
                      icon: const FaIcon(FontAwesomeIcons.heart, size: 14),
                      label: const Text('Donate (UPI)', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
        const SizedBox(height: 20),

        // Audio & Video Preferences
        const Text(
          'Playback & Features',
          style: TextStyle(color: AuraColors.textSecondary, fontWeight: FontWeight.bold, fontSize: 13),
        ),
        const SizedBox(height: 10),
        ListTile(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
          tileColor: AuraColors.surface,
          leading: const FaIcon(FontAwesomeIcons.sliders, color: AuraColors.primaryBlueLight, size: 18),
          title: const Text('Sound Shaping & Equalizer', style: TextStyle(color: AuraColors.textPrimary, fontWeight: FontWeight.w600)),
          subtitle: const Text('Configure analog bass boost & multi-band DSP', style: TextStyle(color: AuraColors.textMuted, fontSize: 11)),
          trailing: const FaIcon(FontAwesomeIcons.chevronRight, size: 12, color: AuraColors.textMuted),
          onTap: () {
            SoundShapingSheet.show(context);
          },
        ),
        const SizedBox(height: 8),
        ListTile(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
          tileColor: AuraColors.surface,
          leading: const FaIcon(FontAwesomeIcons.shieldHalved, color: AuraColors.accentCyan, size: 18),
          title: const Text('NewPipe Privacy Mode', style: TextStyle(color: AuraColors.textPrimary, fontWeight: FontWeight.w600)),
          subtitle: const Text('No Google tracking, local database storage', style: TextStyle(color: AuraColors.textMuted, fontSize: 11)),
          trailing: const FaIcon(FontAwesomeIcons.check, size: 14, color: AuraColors.accentCyan),
        ),
        const SizedBox(height: 8),
        ListTile(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
          tileColor: AuraColors.surface,
          leading: const FaIcon(FontAwesomeIcons.ban, color: AuraColors.liveRed, size: 18),
          title: const Text('Zero Video Ads', style: TextStyle(color: AuraColors.textPrimary, fontWeight: FontWeight.w600)),
          subtitle: const Text('Direct stream playback without intrusive ads', style: TextStyle(color: AuraColors.textMuted, fontSize: 11)),
          trailing: const FaIcon(FontAwesomeIcons.check, size: 14, color: AuraColors.primaryBlueLight),
        ),
        const SizedBox(height: 20),

        // App Meta
        Center(
          child: Column(
            children: [
              Text(
                'AuraTube v1.0.0 (Build 1)',
                style: TextStyle(color: AuraColors.textMuted.withValues(alpha: 0.8), fontSize: 12, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 4),
              Text(
                'Package: com.taezeem.auratube',
                style: TextStyle(color: AuraColors.textMuted.withValues(alpha: 0.6), fontSize: 11),
              ),
            ],
          ),
        ),
        const SizedBox(height: 20),
      ],
    );
  }
}
