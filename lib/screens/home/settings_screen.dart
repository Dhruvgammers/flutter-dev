import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:iconsax/iconsax.dart';
import 'package:provider/provider.dart';
import '../../core/services/connection_service.dart';
import '../../core/services/clipboard_service.dart';
import '../../core/services/encryption_service.dart';
import '../../core/theme/app_theme.dart';
import '../../core/widgets/common_widgets.dart';

class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildHeader(context),
            const SizedBox(height: 24),
            _buildDeviceInfo(context),
            const SizedBox(height: 24),
            _buildSyncSettings(context),
            const SizedBox(height: 24),
            _buildSecuritySettings(context),
            const SizedBox(height: 24),
            _buildAboutSection(context),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader(BuildContext context) {
    return Text(
      'Settings',
      style: Theme.of(
        context,
      ).textTheme.displayMedium?.copyWith(fontWeight: FontWeight.bold),
    ).animate().fadeIn(duration: 400.ms).slideX(begin: -0.1, end: 0);
  }

  Widget _buildDeviceInfo(BuildContext context) {
    return Consumer<ConnectionService>(
      builder: (context, connectionService, _) {
        final device = connectionService.currentDevice;

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _SectionHeader(title: 'This Device'),
            const SizedBox(height: 12),
            GlassCard(
              child: Column(
                children: [
                  Row(
                    children: [
                      Container(
                        width: 56,
                        height: 56,
                        decoration: BoxDecoration(
                          gradient: const LinearGradient(
                            colors: [
                              AppTheme.primaryColor,
                              AppTheme.primaryLight,
                            ],
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                          ),
                          borderRadius: BorderRadius.circular(14),
                        ),
                        child: const Icon(
                          Iconsax.monitor,
                          color: Colors.white,
                          size: 28,
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              device?.name ?? 'Unknown Device',
                              style: Theme.of(context).textTheme.titleLarge,
                            ),
                            Text(
                              '${device?.platform.toUpperCase() ?? 'UNKNOWN'} • ${device?.displayType ?? 'Unknown'}',
                              style: Theme.of(context).textTheme.bodyMedium
                                  ?.copyWith(color: AppTheme.darkTextSecondary),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  const Divider(),
                  const SizedBox(height: 16),
                  _InfoRow(
                    icon: Iconsax.global,
                    label: 'IP Address',
                    value: device?.ipAddress ?? 'Unknown',
                  ),
                  const SizedBox(height: 12),
                  _InfoRow(
                    icon: Iconsax.key,
                    label: 'Device ID',
                    value: device?.id.substring(0, 12) ?? 'Unknown',
                  ),
                ],
              ),
            ),
          ],
        ).animate().fadeIn(delay: 100.ms, duration: 400.ms);
      },
    );
  }

  Widget _buildSyncSettings(BuildContext context) {
    return Consumer<ClipboardService>(
      builder: (context, clipboardService, _) {
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _SectionHeader(title: 'Sync Settings'),
            const SizedBox(height: 12),
            _SettingsTile(
              icon: Iconsax.refresh,
              title: 'Auto-sync Clipboard',
              subtitle: 'Automatically sync clipboard when connected',
              trailing: Switch(
                value: clipboardService.autoSync,
                onChanged: (_) => clipboardService.toggleAutoSync(),
                activeColor: AppTheme.primaryColor,
              ),
            ),
            const SizedBox(height: 12),
            _SettingsTile(
              icon: Iconsax.notification,
              title: 'Transfer Notifications',
              subtitle: 'Show notifications for file transfers',
              trailing: Switch(
                value: true,
                onChanged: (_) {},
                activeColor: AppTheme.primaryColor,
              ),
            ),
          ],
        ).animate().fadeIn(delay: 200.ms, duration: 400.ms);
      },
    );
  }

  Widget _buildSecuritySettings(BuildContext context) {
    return Consumer<EncryptionService>(
      builder: (context, encryptionService, _) {
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _SectionHeader(title: 'Security'),
            const SizedBox(height: 12),
            GlassCard(
              borderColor: AppTheme.successColor.withAlpha(77),
              child: Row(
                children: [
                  Container(
                    width: 48,
                    height: 48,
                    decoration: BoxDecoration(
                      color: AppTheme.successColor.withAlpha(26),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Icon(
                      Iconsax.shield_tick5,
                      color: AppTheme.successColor,
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'End-to-End Encryption',
                          style: Theme.of(context).textTheme.titleMedium
                              ?.copyWith(color: AppTheme.successColor),
                        ),
                        Text(
                          'All data is encrypted using AES-256-GCM',
                          style: Theme.of(context).textTheme.bodyMedium,
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 12),
            _SettingsTile(
              icon: Iconsax.key_square,
              title: 'Regenerate Keys',
              subtitle:
                  'Generate new encryption keys (disconnects all devices)',
              onTap: () => _showRegenerateKeysDialog(context),
            ),
            const SizedBox(height: 12),
            _SettingsTile(
              icon: Iconsax.shield_tick,
              title: 'Trusted Devices',
              subtitle: 'Manage paired devices',
              onTap: () {},
            ),
          ],
        ).animate().fadeIn(delay: 300.ms, duration: 400.ms);
      },
    );
  }

  Widget _buildAboutSection(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _SectionHeader(title: 'About'),
        const SizedBox(height: 12),
        _SettingsTile(
          icon: Iconsax.info_circle,
          title: 'Version',
          subtitle: '1.0.0',
        ),
        const SizedBox(height: 12),
        _SettingsTile(
          icon: Iconsax.document_text,
          title: 'Privacy Policy',
          onTap: () {},
        ),
        const SizedBox(height: 12),
        _SettingsTile(
          icon: Iconsax.book,
          title: 'Terms of Service',
          onTap: () {},
        ),
        const SizedBox(height: 32),
        Center(
          child: Column(
            children: [
              Text(
                'Conto',
                style: Theme.of(
                  context,
                ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 4),
              Text(
                'Secure Cross-Device Sharing',
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: AppTheme.darkTextSecondary,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'Built with Flutter 💙',
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: AppTheme.darkTextSecondary,
                ),
              ),
            ],
          ),
        ),
      ],
    ).animate().fadeIn(delay: 400.ms, duration: 400.ms);
  }

  void _showRegenerateKeysDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Regenerate Keys?'),
        content: const Text(
          'This will generate new encryption keys and disconnect all paired devices. '
          'You will need to pair with devices again.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              // Regenerate keys
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: AppTheme.errorColor,
            ),
            child: const Text('Regenerate'),
          ),
        ],
      ),
    );
  }
}

class _SectionHeader extends StatelessWidget {
  final String title;

  const _SectionHeader({required this.title});

  @override
  Widget build(BuildContext context) {
    return Text(
      title,
      style: Theme.of(context).textTheme.titleMedium?.copyWith(
        color: AppTheme.darkTextSecondary,
        fontWeight: FontWeight.w600,
      ),
    );
  }
}

class _SettingsTile extends StatelessWidget {
  final IconData icon;
  final String title;
  final String? subtitle;
  final Widget? trailing;
  final VoidCallback? onTap;

  const _SettingsTile({
    required this.icon,
    required this.title,
    this.subtitle,
    this.trailing,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GlassCard(
      onTap: onTap,
      child: Row(
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: AppTheme.primaryColor.withAlpha(26),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(icon, color: AppTheme.primaryColor, size: 20),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: Theme.of(context).textTheme.titleMedium),
                if (subtitle != null)
                  Text(
                    subtitle!,
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: AppTheme.darkTextSecondary,
                    ),
                  ),
              ],
            ),
          ),
          if (trailing != null)
            trailing!
          else if (onTap != null)
            const Icon(
              Icons.chevron_right_rounded,
              color: AppTheme.darkTextSecondary,
            ),
        ],
      ),
    );
  }
}

class _InfoRow extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;

  const _InfoRow({
    required this.icon,
    required this.label,
    required this.value,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(icon, size: 18, color: AppTheme.darkTextSecondary),
        const SizedBox(width: 12),
        Text(
          label,
          style: Theme.of(
            context,
          ).textTheme.bodyMedium?.copyWith(color: AppTheme.darkTextSecondary),
        ),
        const Spacer(),
        Text(
          value,
          style: Theme.of(
            context,
          ).textTheme.bodyLarge?.copyWith(fontFamily: 'monospace'),
        ),
      ],
    );
  }
}
