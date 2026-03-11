import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:iconsax/iconsax.dart';
import 'package:provider/provider.dart';
import '../../core/services/connection_service.dart';
import '../../core/services/clipboard_service.dart';
import '../../core/services/file_transfer_service.dart';
import '../../core/theme/app_theme.dart';
import '../../core/widgets/common_widgets.dart';
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: AnimatedSwitcher(
        duration: const Duration(milliseconds: 300),
        child: _screens[_currentIndex],
      ),
      bottomNavigationBar: _buildBottomNav(context),
    );
  }

  Widget _buildBottomNav(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Container(
      decoration: BoxDecoration(
        color: isDark ? AppTheme.darkSurface : AppTheme.lightSurface,
        border: Border(
          top: BorderSide(
            color: isDark ? AppTheme.darkBorder : AppTheme.lightBorder,
            width: 1,
          ),
        ),
      ),
      child: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _NavItem(
                icon: Iconsax.home_2,
                activeIcon: Iconsax.home_25,
                label: 'Home',
                isActive: _currentIndex == 0,
                onTap: () => setState(() => _currentIndex = 0),
              ),
              _NavItem(
                icon: Iconsax.clipboard_text,
                activeIcon: Iconsax.clipboard_text5,
                label: 'Clipboard',
                isActive: _currentIndex == 1,
                onTap: () => setState(() => _currentIndex = 1),
              ),
              _NavItem(
                icon: Iconsax.folder_2,
                activeIcon: Iconsax.folder5,
                label: 'Files',
                isActive: _currentIndex == 2,
                onTap: () => setState(() => _currentIndex = 2),
              ),
              _NavItem(
                icon: Iconsax.setting_2,
                activeIcon: Iconsax.setting5,
                label: 'Settings',
                isActive: _currentIndex == 3,
                onTap: () => setState(() => _currentIndex = 3),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _NavItem extends StatelessWidget {
  final IconData icon;
  final IconData activeIcon;
  final String label;
  final bool isActive;
  final VoidCallback onTap;

  const _NavItem({
    required this.icon,
    required this.activeIcon,
    required this.label,
    required this.isActive,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          color: isActive
              ? AppTheme.primaryColor.withAlpha(26)
              : Colors.transparent,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              isActive ? activeIcon : icon,
              color: isActive
                  ? AppTheme.primaryColor
                  : AppTheme.darkTextSecondary,
              size: 24,
            ),
            const SizedBox(height: 4),
            Text(
              label,
              style: TextStyle(
                fontSize: 12,
                fontWeight: isActive ? FontWeight.w600 : FontWeight.normal,
                color: isActive
                    ? AppTheme.primaryColor
                    : AppTheme.darkTextSecondary,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _DashboardTab extends StatelessWidget {
  const _DashboardTab();

  @override
  Widget build(BuildContext context) {
    return Consumer3<ConnectionService, ClipboardService, FileTransferService>(
      builder: (context, connectionService, clipboardService, fileService, _) {
        return SafeArea(
          child: CustomScrollView(
            slivers: [
              SliverPadding(
                padding: const EdgeInsets.all(20),
                sliver: SliverList(
                  delegate: SliverChildListDelegate([
                    _buildHeader(context),
                    const SizedBox(height: 24),
                    _buildConnectionCard(context, connectionService),
                    const SizedBox(height: 24),
                    _buildQuickActions(context, connectionService, fileService),
                    const SizedBox(height: 24),
                    _buildRecentActivity(
                      context,
                      clipboardService,
                      fileService,
                    ),
                  ]),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildHeader(BuildContext context) {
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
          style: Theme.of(
            context,
          ).textTheme.bodyLarge?.copyWith(color: AppTheme.darkTextSecondary),
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
            color: enabled ? color.withAlpha(51) : Colors.transparent,
            width: 1,
          ),
        ),
        child: Column(
          children: [
            Icon(
              icon,
              color: enabled ? color : AppTheme.darkTextSecondary,
              size: 32,
            ),
            const SizedBox(height: 12),
            Text(
              label,
              style: TextStyle(
                color: enabled ? color : AppTheme.darkTextSecondary,
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
