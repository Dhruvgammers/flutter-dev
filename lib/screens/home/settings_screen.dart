import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:iconsax/iconsax.dart';
import 'package:provider/provider.dart';
import '../../core/services/connection_service.dart';
import '../../core/services/clipboard_service.dart';
import '../../core/services/encryption_service.dart';
import '../../core/theme/app_theme.dart';
import '../../core/widgets/common_widgets.dart';
import '../../core/utils/responsive_utils.dart';

class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final isDesktop = ResponsiveUtils.useDesktopLayout(context);
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return SafeArea(
      child: isDesktop
          ? _buildDesktopLayout(context, isDark)
          : _buildMobileLayout(context, isDark),
    );
  }

  Widget _buildMobileLayout(BuildContext context, bool isDark) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildHeader(context, isDark),
          const SizedBox(height: 24),
          _buildDeviceInfo(context, isDark),
          const SizedBox(height: 24),
          _buildSyncSettings(context, isDark),
          const SizedBox(height: 24),
          _buildSecuritySettings(context, isDark),
          const SizedBox(height: 24),
          _buildAboutSection(context, isDark),
        ],
      ),
    );
  }

  Widget _buildDesktopLayout(BuildContext context, bool isDark) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(32),
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 1000),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildDesktopHeader(context, isDark),
              const SizedBox(height: 32),
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Left column - Device & Sync
                  Expanded(
                    child: Column(
                      children: [
                        _buildDeviceInfo(context, isDark),
                        const SizedBox(height: 24),
                        _buildSyncSettings(context, isDark),
                      ],
                    ),
                  ),
                  const SizedBox(width: 24),
                  // Right column - Security & About
                  Expanded(
                    child: Column(
                      children: [
                        _buildSecuritySettings(context, isDark),
                        const SizedBox(height: 24),
                        _buildAboutSection(context, isDark),
                      ],
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildDesktopHeader(BuildContext context, bool isDark) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Settings',
              style: Theme.of(
                context,
              ).textTheme.displayMedium?.copyWith(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 4),
            Text(
              'Configure your preferences and security',
              style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                color: isDark
                    ? AppTheme.darkTextSecondary
                    : AppTheme.lightTextSecondary,
              ),
            ),
          ],
        ),
      ],
    ).animate().fadeIn(duration: 400.ms);
  }

  Widget _buildHeader(BuildContext context, bool isDark) {
    return Text(
      'Settings',
      style: Theme.of(
        context,
      ).textTheme.displayMedium?.copyWith(fontWeight: FontWeight.bold),
    ).animate().fadeIn(duration: 400.ms).slideX(begin: -0.1, end: 0);
  }

  Widget _buildDeviceInfo(BuildContext context, bool isDark) {
    return Consumer<ConnectionService>(
      builder: (context, connectionService, _) {
        final device = connectionService.currentDevice;

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _SectionHeader(title: 'This Device', isDark: isDark),
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
                                  ?.copyWith(
                                    color: isDark
                                        ? AppTheme.darkTextSecondary
                                        : AppTheme.lightTextSecondary,
                                  ),
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
                    isDark: isDark,
                  ),
                  const SizedBox(height: 12),
                  _InfoRow(
                    icon: Iconsax.key,
                    label: 'Device ID',
                    value: device?.id.substring(0, 12) ?? 'Unknown',
                    isDark: isDark,
                  ),
                ],
              ),
            ),
          ],
        ).animate().fadeIn(delay: 100.ms, duration: 400.ms);
      },
    );
  }

  Widget _buildSyncSettings(BuildContext context, bool isDark) {
    return Consumer<ClipboardService>(
      builder: (context, clipboardService, _) {
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _SectionHeader(title: 'Sync Settings', isDark: isDark),
            const SizedBox(height: 12),
            _SettingsTile(
              icon: Iconsax.refresh,
              title: 'Auto-sync Clipboard',
              subtitle: 'Automatically sync clipboard when connected',
              isDark: isDark,
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
              isDark: isDark,
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

  Widget _buildSecuritySettings(BuildContext context, bool isDark) {
    return Consumer<EncryptionService>(
      builder: (context, encryptionService, _) {
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _SectionHeader(title: 'Security', isDark: isDark),
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
              isDark: isDark,
              onTap: () => _showRegenerateKeysDialog(context),
            ),
            const SizedBox(height: 12),
            _SettingsTile(
              icon: Iconsax.shield_tick,
              title: 'Trusted Devices',
              subtitle: 'Manage paired devices',
              isDark: isDark,
              onTap: () {},
            ),
          ],
        ).animate().fadeIn(delay: 300.ms, duration: 400.ms);
      },
    );
  }

  Widget _buildAboutSection(BuildContext context, bool isDark) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _SectionHeader(title: 'About', isDark: isDark),
        const SizedBox(height: 12),
        _SettingsTile(
          icon: Iconsax.info_circle,
          title: 'Version',
          subtitle: '1.0.0',
          isDark: isDark,
        ),
        const SizedBox(height: 12),
        _SettingsTile(
          icon: Iconsax.document_text,
          title: 'Privacy Policy',
          isDark: isDark,
          onTap: () {},
        ),
        const SizedBox(height: 12),
        _SettingsTile(
          icon: Iconsax.book,
          title: 'Terms of Service',
          isDark: isDark,
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
                  color: isDark
                      ? AppTheme.darkTextSecondary
                      : AppTheme.lightTextSecondary,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'Built with Flutter 💙',
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: isDark
                      ? AppTheme.darkTextSecondary
                      : AppTheme.lightTextSecondary,
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
  final bool isDark;

  const _SectionHeader({required this.title, this.isDark = true});

  @override
  Widget build(BuildContext context) {
    return Text(
      title,
      style: Theme.of(context).textTheme.titleMedium?.copyWith(
        color: isDark
            ? AppTheme.darkTextSecondary
            : AppTheme.lightTextSecondary,
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
  final bool isDark;

  const _SettingsTile({
    required this.icon,
    required this.title,
    this.subtitle,
    this.trailing,
    this.onTap,
    this.isDark = true,
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
                      color: isDark
                          ? AppTheme.darkTextSecondary
                          : AppTheme.lightTextSecondary,
                    ),
                  ),
              ],
            ),
          ),
          if (trailing != null)
            trailing!
          else if (onTap != null)
            Icon(
              Icons.chevron_right_rounded,
              color: isDark
                  ? AppTheme.darkTextSecondary
                  : AppTheme.lightTextSecondary,
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
  final bool isDark;

  const _InfoRow({
    required this.icon,
    required this.label,
    required this.value,
    this.isDark = true,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(
          icon,
          size: 18,
          color: isDark
              ? AppTheme.darkTextSecondary
              : AppTheme.lightTextSecondary,
        ),
        const SizedBox(width: 12),
        Text(
          label,
          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
            color: isDark
                ? AppTheme.darkTextSecondary
                : AppTheme.lightTextSecondary,
          ),
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
