import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../../core/themes/colors.dart';

/// A "Get the app" section meant to sit at the bottom of the home screen.
/// Shows App Store + Google Play badges. Since neither is published yet,
/// both are disabled with a "Coming soon" state — flip [iosUrl] / [androidUrl]
/// to real store links once the app is live and they'll become tappable.
class DownloadAppSection extends StatelessWidget {
  final String? androidUrl;
  final String? iosUrl;

  const DownloadAppSection({
    super.key,
    this.androidUrl,
    this.iosUrl,
  });

  bool get _androidReady => androidUrl != null && androidUrl!.isNotEmpty;
  bool get _iosReady => iosUrl != null && iosUrl!.isNotEmpty;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(vertical: 48, horizontal: 24),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [AppColors.primaryDark, AppColors.primary],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
      ),
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 560),
          child: Column(
            children: [
              Icon(Icons.phone_iphone_rounded, color: Colors.white, size: 40),
              const SizedBox(height: 16),
              const Text(
                'Get The Guy on your phone',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'Find and book trusted professionals faster with the mobile app.',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 15,
                  color: Colors.white.withValues(alpha: 0.85),
                  height: 1.4,
                ),
              ),
              const SizedBox(height: 28),
              Wrap(
                alignment: WrapAlignment.center,
                spacing: 16,
                runSpacing: 16,
                children: [
                  _StoreBadge(
                    icon: Icons.apple,
                    topLine: 'Download on the',
                    bottomLine: 'App Store',
                    ready: _iosReady,
                    onTap: _iosReady ? () => _launch(iosUrl!) : null,
                  ),
                  _StoreBadge(
                    icon: Icons.shop,
                    topLine: 'GET IT ON',
                    bottomLine: 'Google Play',
                    ready: _androidReady,
                    onTap: _androidReady ? () => _launch(androidUrl!) : null,
                  ),
                ],
              ),
              if (!_androidReady && !_iosReady) ...[
                const SizedBox(height: 20),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(Icons.schedule, size: 14, color: Colors.white70),
                      const SizedBox(width: 6),
                      Text(
                        'Coming soon — stay tuned',
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.white.withValues(alpha: 0.85),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _launch(String url) async {
    final uri = Uri.parse(url);
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    }
  }
}

class _StoreBadge extends StatelessWidget {
  final IconData icon;
  final String topLine;
  final String bottomLine;
  final bool ready;
  final VoidCallback? onTap;

  const _StoreBadge({
    required this.icon,
    required this.topLine,
    required this.bottomLine,
    required this.ready,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Opacity(
      opacity: ready ? 1.0 : 0.55,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Container(
          width: 200,
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
          decoration: BoxDecoration(
            color: Colors.black,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: Colors.white24),
          ),
          child: Row(
            children: [
              Icon(icon, color: Colors.white, size: 28),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      topLine,
                      style: const TextStyle(fontSize: 10, color: Colors.white70),
                    ),
                    Text(
                      bottomLine,
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        color: Colors.white,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
