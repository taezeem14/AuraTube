import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:url_launcher/url_launcher.dart';
import '../theme/aura_theme.dart';

class UpiDonationView extends StatefulWidget {
  final ScrollController? scrollController;

  const UpiDonationView({super.key, this.scrollController});

  @override
  State<UpiDonationView> createState() => _UpiDonationViewState();
}

class _UpiDonationViewState extends State<UpiDonationView> {
  static const String upiId = '7006616470@fam';
  static const String payeeName = 'Muhammad Taezeem Tariq';

  final List<int> _presetAmounts = [21, 50, 100, 250, 500];
  int? _selectedAmount = 100;
  final TextEditingController _customAmountController = TextEditingController();
  bool _isCustomAmount = false;

  @override
  void dispose() {
    _customAmountController.dispose();
    super.dispose();
  }

  String get _currentAmountString {
    if (_isCustomAmount) {
      final custom = _customAmountController.text.trim();
      if (custom.isNotEmpty && double.tryParse(custom) != null && double.parse(custom) > 0) {
        return custom;
      }
      return '100';
    }
    return (_selectedAmount ?? 100).toString();
  }

  String _buildUpiUri({String scheme = 'upi'}) {
    final amount = _currentAmountString;
    final encodedPayee = Uri.encodeComponent(payeeName);
    final note = Uri.encodeComponent('Donation for AuraTube Development');
    return '$scheme://pay?pa=$upiId&pn=$encodedPayee&tn=$note&am=$amount&cu=INR';
  }

  Future<void> _launchPayment({String scheme = 'upi'}) async {
    final uriString = _buildUpiUri(scheme: scheme);
    final uri = Uri.parse(uriString);

    try {
      final launched = await launchUrl(uri, mode: LaunchMode.externalApplication);
      if (!launched && scheme != 'upi') {
        final fallbackUri = Uri.parse(_buildUpiUri(scheme: 'upi'));
        await launchUrl(fallbackUri, mode: LaunchMode.externalApplication);
      }
    } catch (_) {
      Clipboard.setData(const ClipboardData(text: upiId));
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('UPI intent unavailable. Copied UPI ID (7006616470@fam) to clipboard!'),
            backgroundColor: AuraColors.surfaceHigh,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return ListView(
      controller: widget.scrollController,
      padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 12),
      children: [
        // Header Banner
        Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [
                AuraColors.primaryBlue.withValues(alpha: 0.22),
                AuraColors.surfaceHigh.withValues(alpha: 0.9),
              ],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: AuraColors.primaryBlue.withValues(alpha: 0.5), width: 1.2),
          ),
          child: Column(
            children: [
              Container(
                width: 56,
                height: 56,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: AuraColors.primaryBlue,
                  boxShadow: [
                    BoxShadow(
                      color: AuraColors.primaryBlue.withValues(alpha: 0.4),
                      blurRadius: 16,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: const Center(
                  child: FaIcon(FontAwesomeIcons.heart, color: Colors.white, size: 24),
                ),
              ),
              const SizedBox(height: 12),
              const Text(
                'Support AuraTube & Creator',
                style: TextStyle(
                  color: AuraColors.textPrimary,
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 4),
              const Text(
                'Direct support for Muhammad Taezeem Tariq',
                style: TextStyle(color: AuraColors.accentCyan, fontSize: 13, fontWeight: FontWeight.w600),
              ),
              const SizedBox(height: 14),

              // UPI ID badge with copy button
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                decoration: BoxDecoration(
                  color: AuraColors.obsidianBase,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: AuraColors.outline),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const FaIcon(FontAwesomeIcons.wallet, size: 14, color: AuraColors.accentCyan),
                    const SizedBox(width: 8),
                    const Text(
                      upiId,
                      style: TextStyle(color: AuraColors.textPrimary, fontWeight: FontWeight.bold, fontSize: 14),
                    ),
                    const SizedBox(width: 8),
                    GestureDetector(
                      onTap: () {
                        Clipboard.setData(const ClipboardData(text: upiId));
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text('UPI ID copied to clipboard!'),
                            backgroundColor: AuraColors.surfaceHigh,
                          ),
                        );
                      },
                      child: const FaIcon(FontAwesomeIcons.copy, size: 14, color: AuraColors.textSecondary),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 20),

        // Select Amount Chips
        const Text(
          'Select Contribution Amount (INR)',
          style: TextStyle(color: AuraColors.textSecondary, fontWeight: FontWeight.bold, fontSize: 13),
        ),
        const SizedBox(height: 10),
        Wrap(
          spacing: 10,
          runSpacing: 10,
          children: _presetAmounts.map((amt) {
            final isSelected = !_isCustomAmount && _selectedAmount == amt;
            return GestureDetector(
              onTap: () {
                setState(() {
                  _isCustomAmount = false;
                  _selectedAmount = amt;
                });
              },
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 180),
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                decoration: BoxDecoration(
                  color: isSelected ? AuraColors.primaryBlue : AuraColors.surfaceHigh,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(
                    color: isSelected ? AuraColors.accentCyan : AuraColors.outline,
                    width: isSelected ? 1.4 : 0.8,
                  ),
                  boxShadow: isSelected
                      ? [
                          BoxShadow(
                            color: AuraColors.primaryBlue.withValues(alpha: 0.35),
                            blurRadius: 10,
                          ),
                        ]
                      : null,
                ),
                child: Text(
                  '₹$amt',
                  style: TextStyle(
                    color: isSelected ? Colors.white : AuraColors.textPrimary,
                    fontWeight: FontWeight.bold,
                    fontSize: 14,
                  ),
                ),
              ),
            );
          }).toList(),
        ),
        const SizedBox(height: 16),

        // Custom Amount Input
        TextField(
          controller: _customAmountController,
          keyboardType: TextInputType.number,
          style: const TextStyle(color: AuraColors.textPrimary),
          decoration: InputDecoration(
            hintText: 'Enter custom amount (₹)',
            hintStyle: const TextStyle(color: AuraColors.textMuted),
            prefixIcon: const Icon(Icons.currency_rupee, color: AuraColors.primaryBlueLight, size: 18),
            filled: true,
            fillColor: AuraColors.surfaceContainerLow,
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: const BorderSide(color: AuraColors.outline)),
            enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: const BorderSide(color: AuraColors.outline)),
            focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: const BorderSide(color: AuraColors.accentCyan, width: 1.5)),
          ),
          onChanged: (val) {
            if (val.trim().isNotEmpty) {
              setState(() => _isCustomAmount = true);
            }
          },
        ),
        const SizedBox(height: 20),

        // Pay Button
        ElevatedButton(
          onPressed: () => _launchPayment(),
          style: ElevatedButton.styleFrom(
            backgroundColor: AuraColors.primaryBlue,
            foregroundColor: Colors.white,
            padding: const EdgeInsets.symmetric(vertical: 16),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
            elevation: 8,
            shadowColor: AuraColors.primaryBlue.withValues(alpha: 0.5),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const FaIcon(FontAwesomeIcons.bolt, size: 16),
              const SizedBox(width: 10),
              Text(
                'Pay ₹$_currentAmountString via UPI',
                style: const TextStyle(fontSize: 15, fontWeight: FontWeight.bold),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
