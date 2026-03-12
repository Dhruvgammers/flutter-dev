import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:iconsax/iconsax.dart';
import 'package:provider/provider.dart';
import '../../core/services/connection_service.dart';
import '../../core/services/clipboard_service.dart';
import '../../core/services/file_transfer_service.dart';
import '../../core/theme/app_theme.dart';
import '../../core/widgets/common_widgets.dart';
import '../../core/utils/responsive_utils.dart';
import '../../core/models/device.dart';
import 'clipboard_screen.dart';
import 'files_screen.dart';
import 'settings_screen.dart';
import 'pairing_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int _currentIndex = 0;

  final List<Widget> _screens = const [
    _DashboardTab(),
    ClipboardScreen(),
    FilesScreen(),
    SettingsScreen(),
  ];

  final List<AdaptiveDestination> _destinations = const [
    AdaptiveDestination(
      icon: Iconsax.home_2,
      selectedIcon: Iconsax.home_25,
      label: 'Home',
    ),
    AdaptiveDestination(
      icon: Iconsax.clipboard_text,
      selectedIcon: Iconsax.clipboard_text5,
      label: 'Clipboard',
    ),
    AdaptiveDestination(
      icon: Iconsax.folder_2,
      selectedIcon: Iconsax.folder5,
      label: 'Files',
    ),
    AdaptiveDestination(
      icon: Iconsax.setting_2,
      selectedIcon: Iconsax.setting5,
      label: 'Settings',
    ),
  ];

  @override
  Widget build(BuildContext context) {
    // Use the adaptive scaffold for platform-specific layouts
    return AdaptiveScaffold(
      currentIndex: _currentIndex,
      destinations: _destinations,
      body: _screens,
      onDestinationSelected: (index) => setState(() => _currentIndex = index),
    );
  }
}

class _DashboardTab extends StatelessWidget {
  const _DashboardTab();

  @override
  Widget build(BuildContext context) {
    final isDesktop = ResponsiveUtils.useDesktopLayout(context);
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Consumer3<ConnectionService, ClipboardService, FileTransferService>(
      builder: (context, connectionService, clipboardService, fileService, _) {
        if (isDesktop) {
          return _buildDesktopDashboard(
            context,
            connectionService,
            clipboardService,
            fileService,
            isDark,
          );
        }
        return _buildMobileDashboard(
          context,
          connectionService,
          clipboardService,
          fileService,
          isDark,
        );
      },
    );
  }

  Widget _buildMobileDashboard(
    BuildContext context,
    ConnectionService connectionService,
    ClipboardService clipboardService,
    FileTransferService fileService,
    bool isDark,
  ) {
    return SafeArea(
      child: CustomScrollView(
        slivers: [
          SliverPadding(
            padding: const EdgeInsets.all(20),
            sliver: SliverList(
              delegate: SliverChildListDelegate([
                _buildHeader(context, isDark),
                const SizedBox(height: 24),
                _buildConnectionCard(context, connectionService),
                const SizedBox(height: 24),
                _buildQuickActions(context, connectionService, fileService),
                const SizedBox(height: 24),
                _buildRecentActivity(context, clipboardService, fileService),
              ]),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDesktopDashboard(
    BuildContext context,
    ConnectionService connectionService,
    ClipboardService clipboardService,
    FileTransferService fileService,
    bool isDark,
  ) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(32),
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 1200),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildDesktopHeader(context, isDark),
              const SizedBox(height: 32),
              // Grid layout for desktop
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Left column - Connection & Quick Actions
                  Expanded(
                    flex: 3,
                    child: Column(
                      children: [
                        _buildConnectionCard(context, connectionService),
                        const SizedBox(height: 24),
                        _buildDesktopQuickActions(
                          context,
                          connectionService,
                          fileService,
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 24),
                  // Right column - Recent Activity & Stats
                  Expanded(
                    flex: 2,
                    child: Column(
                      children: [
                        _buildStatsCard(
                          context,
                          clipboardService,
                          fileService,
                          isDark,
                        ),
                        const SizedBox(height: 24),
                        _buildRecentActivity(
                          context,
                          clipboardService,
                          fileService,
                        ),
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
    final greeting = _getGreeting();

    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              greeting,
              style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                color: isDark
                    ? AppTheme.darkTextSecondary
                    : AppTheme.lightTextSecondary,
              ),
            ).animate().fadeIn(duration: 400.ms),
            const SizedBox(height: 4),
            Text(
              'Welcome to Conto',
              style: Theme.of(
                context,
              ).textTheme.displayMedium?.copyWith(fontWeight: FontWeight.bold),
            ).animate().fadeIn(duration: 400.ms).slideX(begin: -0.1, end: 0),
          ],
        ),
        // Connection status indicator
        Consumer<ConnectionService>(
          builder: (context, service, _) {
            final isConnected = service.isConnected;
            return Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
              decoration: BoxDecoration(
                color: isConnected
                    ? AppTheme.successColor.withAlpha(26)
                    : (isDark
                          ? AppTheme.darkSurfaceVariant
                          : AppTheme.lightSurfaceVariant),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: isConnected
                      ? AppTheme.successColor.withAlpha(51)
                      : (isDark ? AppTheme.darkBorder : AppTheme.lightBorder),
                ),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  StatusIndicator(isActive: isConnected, size: 10),
                  const SizedBox(width: 8),
                  Text(
                    isConnected ? 'Connected' : 'Not Connected',
                    style: TextStyle(
                      color: isConnected
                          ? AppTheme.successColor
                          : (isDark
                                ? AppTheme.darkTextSecondary
                                : AppTheme.lightTextSecondary),
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
            );
          },
        ),
      ],
    );
  }

  String _getGreeting() {
    final hour = DateTime.now().hour;
    if (hour < 12) return 'Good morning';
    if (hour < 17) return 'Good afternoon';
    return 'Good evening';
  }

  Widget _buildStatsCard(
    BuildContext context,
    ClipboardService clipboardService,
    FileTransferService fileService,
    bool isDark,
  ) {
    return GlassCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Statistics', style: Theme.of(context).textTheme.titleLarge),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: _StatItem(
                  icon: Iconsax.clipboard_text,
                  value: '${clipboardService.history.length}',
                  label: 'Clipboard Items',
                  color: AppTheme.primaryColor,
                  isDark: isDark,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: _StatItem(
                  icon: Iconsax.document,
                  value: '${fileService.transfers.length}',
                  label: 'File Transfers',
                  color: AppTheme.secondaryColor,
                  isDark: isDark,
                ),
              ),
            ],
          ),
        ],
      ),
    ).animate().fadeIn(delay: 200.ms, duration: 400.ms);
  }

  Widget _buildDesktopQuickActions(
    BuildContext context,
    ConnectionService connectionService,
    FileTransferService fileService,
  ) {
    final isConnected = connectionService.isConnected;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return GlassCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Quick Actions', style: Theme.of(context).textTheme.titleLarge),
          const SizedBox(height: 20),
          Row(
            children: [
              Expanded(
                child: _DesktopActionButton(
                  icon: Iconsax.clipboard_tick,
                  label: 'Sync Clipboard',
                  description: 'Share clipboard instantly',
                  color: AppTheme.primaryColor,
                  enabled: isConnected,
                  isDark: isDark,
                  onTap: () {},
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: _DesktopActionButton(
                  icon: Iconsax.document_upload,
                  label: 'Send Files',
                  description: 'Encrypted file transfer',
                  color: AppTheme.secondaryColor,
                  enabled: isConnected,
                  isDark: isDark,
                  onTap: () => fileService.pickAndSendFiles(),
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: _DesktopActionButton(
                  icon: Iconsax.scan_barcode,
                  label: 'Scan QR',
                  description: 'Pair with mobile',
                  color: AppTheme.accentColor,
                  enabled: true,
                  isDark: isDark,
                  onTap: () => _showPairingSheet(context),
                ),
              ),
            ],
          ),
        ],
      ),
    ).animate().fadeIn(delay: 300.ms, duration: 400.ms);
  }

  Widget _buildHeader(BuildContext context, bool isDark) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Conto',
          style: Theme.of(
            context,
          ).textTheme.displayMedium?.copyWith(fontWeight: FontWeight.bold),
        ).animate().fadeIn(duration: 400.ms).slideX(begin: -0.1, end: 0),
        const SizedBox(height: 4),
        Text(
          'Secure cross-device sharing',
          style: Theme.of(context).textTheme.bodyLarge?.copyWith(
            color: isDark
                ? AppTheme.darkTextSecondary
                : AppTheme.lightTextSecondary,
          ),
        ).animate().fadeIn(delay: 100.ms, duration: 400.ms),
      ],
    );
  }

  Widget _buildConnectionCard(BuildContext context, ConnectionService service) {
    final isConnected = service.status == ConnectionStatus.connected;
    final device = service.connectedDevice;

    return ConnectionBanner(
          isConnected: isConnected,
          deviceName: device?.name,
          pairingCode: service.pairingCode,
          onConnect: () => _showPairingSheet(context),
          onDisconnect: () => service.disconnect(),
        )
        .animate()
        .fadeIn(delay: 200.ms, duration: 400.ms)
        .slideY(begin: 0.1, end: 0);
  }

  Widget _buildQuickActions(
    BuildContext context,
    ConnectionService connectionService,
    FileTransferService fileService,
  ) {
    final isConnected = connectionService.isConnected;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Quick Actions', style: Theme.of(context).textTheme.titleLarge),
        const SizedBox(height: 16),
        Row(
          children: [
            Expanded(
              child: _QuickActionButton(
                icon: Iconsax.clipboard_tick,
                label: 'Sync Clipboard',
                color: AppTheme.primaryColor,
                enabled: isConnected,
                onTap: () {
                  // Navigate to clipboard tab
                },
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: _QuickActionButton(
                icon: Iconsax.document_upload,
                label: 'Send Files',
                color: AppTheme.secondaryColor,
                enabled: isConnected,
                onTap: () => fileService.pickAndSendFiles(),
              ),
            ),
          ],
        ),
      ],
    ).animate().fadeIn(delay: 300.ms, duration: 400.ms);
  }

  Widget _buildRecentActivity(
    BuildContext context,
    ClipboardService clipboardService,
    FileTransferService fileService,
  ) {
    final recentClipboard = clipboardService.history.take(3).toList();
    final recentTransfers = fileService.transfers.take(3).toList();

    final hasActivity =
        recentClipboard.isNotEmpty || recentTransfers.isNotEmpty;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Recent Activity', style: Theme.of(context).textTheme.titleLarge),
        const SizedBox(height: 16),
        if (!hasActivity)
          const EmptyState(
            icon: Iconsax.activity,
            title: 'No recent activity',
            subtitle: 'Your clipboard and file transfers will appear here',
          )
        else ...[
          ...recentClipboard.map(
            (item) => Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: _ActivityItem(
                icon: Iconsax.clipboard_text,
                title: item.preview,
                subtitle: item.timeFormatted,
                iconColor: AppTheme.primaryColor,
              ),
            ),
          ),
          ...recentTransfers.map(
            (item) => Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: _ActivityItem(
                icon: item.senderId == fileService.transfers.first.senderId
                    ? Iconsax.document_upload
                    : Iconsax.document_download,
                title: item.fileName ?? 'File transfer',
                subtitle: item.fileSizeFormatted,
                iconColor: AppTheme.secondaryColor,
              ),
            ),
          ),
        ],
      ],
    ).animate().fadeIn(delay: 400.ms, duration: 400.ms);
  }

  void _showPairingSheet(BuildContext context) {
    Navigator.of(
      context,
    ).push(MaterialPageRoute(builder: (_) => const PairingScreen()));
  }
}

class _QuickActionButton extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;
  final bool enabled;
  final VoidCallback? onTap;

  const _QuickActionButton({
    required this.icon,
    required this.label,
    required this.color,
    this.enabled = true,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final disabledColor = isDark
        ? AppTheme.darkTextSecondary
        : AppTheme.lightTextSecondary;

    return GestureDetector(
      onTap: enabled ? onTap : null,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: enabled
              ? color.withAlpha(26)
              : (isDark
                    ? AppTheme.darkSurfaceVariant
                    : AppTheme.lightSurfaceVariant),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: enabled
                ? color.withAlpha(51)
                : (isDark ? AppTheme.darkBorder : AppTheme.lightBorder),
            width: 1,
          ),
        ),
        child: Column(
          children: [
            Icon(icon, color: enabled ? color : disabledColor, size: 32),
            const SizedBox(height: 12),
            Text(
              label,
              style: TextStyle(
                color: enabled ? color : disabledColor,
                fontWeight: FontWeight.w600,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}

class _ActivityItem extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final Color iconColor;

  const _ActivityItem({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.iconColor,
  });

  @override
  Widget build(BuildContext context) {
    return GlassCard(
      padding: const EdgeInsets.all(12),
      child: Row(
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: iconColor.withAlpha(26),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(icon, color: iconColor, size: 20),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: Theme.of(context).textTheme.bodyLarge,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                Text(subtitle, style: Theme.of(context).textTheme.bodyMedium),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/// Statistic item for desktop dashboard
class _StatItem extends StatelessWidget {
  final IconData icon;
  final String value;
  final String label;
  final Color color;
  final bool isDark;

  const _StatItem({
    required this.icon,
    required this.value,
    required this.label,
    required this.color,
    required this.isDark,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: color.withAlpha(13),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withAlpha(26), width: 1),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: color, size: 24),
          const SizedBox(height: 12),
          Text(
            value,
            style: TextStyle(
              fontSize: 28,
              fontWeight: FontWeight.bold,
              color: isDark
                  ? AppTheme.darkTextPrimary
                  : AppTheme.lightTextPrimary,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            label,
            style: TextStyle(
              fontSize: 13,
              color: isDark
                  ? AppTheme.darkTextSecondary
                  : AppTheme.lightTextSecondary,
            ),
          ),
        ],
      ),
    );
  }
}

/// Desktop action button with description
class _DesktopActionButton extends StatelessWidget {
  final IconData icon;
  final String label;
  final String description;
  final Color color;
  final bool enabled;
  final bool isDark;
  final VoidCallback? onTap;

  const _DesktopActionButton({
    required this.icon,
    required this.label,
    required this.description,
    required this.color,
    required this.enabled,
    required this.isDark,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: enabled ? onTap : null,
        borderRadius: BorderRadius.circular(16),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: enabled
                ? color.withAlpha(13)
                : (isDark
                      ? AppTheme.darkSurfaceVariant
                      : AppTheme.lightSurfaceVariant),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: enabled
                  ? color.withAlpha(51)
                  : (isDark ? AppTheme.darkBorder : AppTheme.lightBorder),
              width: 1,
            ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  color: color.withAlpha(26),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(
                  icon,
                  color: enabled
                      ? color
                      : (isDark
                            ? AppTheme.darkTextSecondary
                            : AppTheme.lightTextSecondary),
                  size: 24,
                ),
              ),
              const SizedBox(height: 16),
              Text(
                label,
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: enabled
                      ? (isDark
                            ? AppTheme.darkTextPrimary
                            : AppTheme.lightTextPrimary)
                      : (isDark
                            ? AppTheme.darkTextSecondary
                            : AppTheme.lightTextSecondary),
                ),
              ),
              const SizedBox(height: 4),
              Text(
                description,
                style: TextStyle(
                  fontSize: 13,
                  color: isDark
                      ? AppTheme.darkTextSecondary
                      : AppTheme.lightTextSecondary,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
