import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:iconsax/iconsax.dart';
import 'package:provider/provider.dart';
import '../../core/services/clipboard_service.dart';
import '../../core/services/connection_service.dart';
import '../../core/theme/app_theme.dart';
import '../../core/widgets/common_widgets.dart';
import '../../core/utils/responsive_utils.dart';

class ClipboardScreen extends StatelessWidget {
  const ClipboardScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final isDesktop = ResponsiveUtils.useDesktopLayout(context);
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return SafeArea(
      child: Consumer2<ClipboardService, ConnectionService>(
        builder: (context, clipboardService, connectionService, _) {
          if (isDesktop) {
            return _buildDesktopLayout(
              context,
              clipboardService,
              connectionService,
              isDark,
            );
          }
          return _buildMobileLayout(
            context,
            clipboardService,
            connectionService,
            isDark,
          );
        },
      ),
    );
  }

  Widget _buildMobileLayout(
    BuildContext context,
    ClipboardService clipboardService,
    ConnectionService connectionService,
    bool isDark,
  ) {
    return Column(
      children: [
        _buildHeader(context, clipboardService, isDark),
        Expanded(
          child: clipboardService.history.isEmpty
              ? _buildEmptyState(context, isDark)
              : _buildClipboardList(context, clipboardService, isDark),
        ),
      ],
    );
  }

  Widget _buildDesktopLayout(
    BuildContext context,
    ClipboardService clipboardService,
    ConnectionService connectionService,
    bool isDark,
  ) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(32),
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 1000),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildDesktopHeader(context, clipboardService, isDark),
              const SizedBox(height: 24),
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Send section
                  Expanded(
                    flex: 2,
                    child: _buildSendSection(context, clipboardService, isDark),
                  ),
                  const SizedBox(width: 24),
                  // History section
                  Expanded(
                    flex: 3,
                    child: _buildHistorySection(
                      context,
                      clipboardService,
                      isDark,
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

  Widget _buildDesktopHeader(
    BuildContext context,
    ClipboardService service,
    bool isDark,
  ) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Clipboard',
              style: Theme.of(
                context,
              ).textTheme.displayMedium?.copyWith(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 4),
            Text(
              'Sync clipboard across your devices',
              style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                color: isDark
                    ? AppTheme.darkTextSecondary
                    : AppTheme.lightTextSecondary,
              ),
            ),
          ],
        ),
        Row(
          children: [
            _SyncToggle(
              isEnabled: service.autoSync,
              onToggle: () => service.toggleAutoSync(),
              isDark: isDark,
            ),
            if (service.history.isNotEmpty) ...[
              const SizedBox(width: 12),
              IconButton(
                icon: const Icon(Iconsax.trash),
                onPressed: () => _showClearDialog(context, service),
                tooltip: 'Clear history',
                color: isDark
                    ? AppTheme.darkTextSecondary
                    : AppTheme.lightTextSecondary,
              ),
            ],
          ],
        ),
      ],
    ).animate().fadeIn(duration: 400.ms);
  }

  Widget _buildHistorySection(
    BuildContext context,
    ClipboardService service,
    bool isDark,
  ) {
    if (service.history.isEmpty) {
      return _buildEmptyState(context, isDark);
    }

    return GlassCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('History', style: Theme.of(context).textTheme.titleLarge),
          const SizedBox(height: 16),
          ...service.history
              .take(10)
              .map(
                (item) => Padding(
                  padding: const EdgeInsets.only(bottom: 8),
                  child: _ClipboardItemCard(
                    item: item,
                    onCopy: () => _copyItem(context, service, item),
                    onSend: () => _sendItem(context, service, item),
                    isDark: isDark,
                  ),
                ),
              ),
        ],
      ),
    ).animate().fadeIn(delay: 200.ms, duration: 400.ms);
  }

  Widget _buildHeader(
    BuildContext context,
    ClipboardService service,
    bool isDark,
  ) {
    return Padding(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Clipboard',
                style: Theme.of(context).textTheme.displayMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
              Row(
                children: [
                  _SyncToggle(
                    isEnabled: service.autoSync,
                    onToggle: () => service.toggleAutoSync(),
                    isDark: isDark,
                  ),
                  if (service.history.isNotEmpty) ...[
                    const SizedBox(width: 8),
                    IconButton(
                      icon: const Icon(Iconsax.trash),
                      onPressed: () => _showClearDialog(context, service),
                      tooltip: 'Clear history',
                    ),
                  ],
                ],
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            'Auto-sync ${service.autoSync ? "enabled" : "disabled"}',
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              color: isDark
                  ? AppTheme.darkTextSecondary
                  : AppTheme.lightTextSecondary,
            ),
          ),
          const SizedBox(height: 16),
          _buildSendSection(context, service, isDark),
        ],
      ),
    );
  }

  Widget _buildSendSection(
    BuildContext context,
    ClipboardService service,
    bool isDark,
  ) {
    final connectionService = context.read<ConnectionService>();
    final isConnected = connectionService.isConnected;

    return GlassCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Send to connected device',
            style: Theme.of(context).textTheme.titleMedium,
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: GradientButton(
                  text: 'Send Current Clipboard',
                  icon: Iconsax.send_2,
                  onPressed: isConnected
                      ? () async {
                          final data = await Clipboard.getData(
                            Clipboard.kTextPlain,
                          );
                          if (data?.text != null && data!.text!.isNotEmpty) {
                            await service.sendClipboard(data.text!);
                            if (context.mounted) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(
                                  content: Text('Clipboard sent!'),
                                ),
                              );
                            }
                          }
                        }
                      : null,
                ),
              ),
            ],
          ),
          if (!isConnected) ...[
            const SizedBox(height: 8),
            Text(
              'Connect a device to send clipboard',
              style: Theme.of(
                context,
              ).textTheme.bodyMedium?.copyWith(color: AppTheme.warningColor),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildEmptyState(BuildContext context, bool isDark) {
    return const EmptyState(
      icon: Iconsax.clipboard_text,
      title: 'No clipboard history',
      subtitle: 'Copy text or receive clipboard from connected device',
    );
  }

  Widget _buildClipboardList(
    BuildContext context,
    ClipboardService service,
    bool isDark,
  ) {
    return ListView.builder(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      itemCount: service.history.length,
      itemBuilder: (context, index) {
        final item = service.history[index];
        return Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: _ClipboardItemCard(
                item: item,
                onCopy: () => _copyItem(context, service, item),
                onSend: () => _sendItem(context, service, item),
                isDark: isDark,
              ),
            )
            .animate()
            .fadeIn(
              delay: Duration(milliseconds: index * 50),
              duration: 300.ms,
            )
            .slideX(begin: 0.05, end: 0);
      },
    );
  }

  void _copyItem(
    BuildContext context,
    ClipboardService service,
    ClipboardItem item,
  ) {
    service.copyFromHistory(item);
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(const SnackBar(content: Text('Copied to clipboard!')));
  }

  void _sendItem(
    BuildContext context,
    ClipboardService service,
    ClipboardItem item,
  ) {
    final connectionService = context.read<ConnectionService>();
    if (connectionService.isConnected) {
      service.sendClipboard(item.content);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Sent to connected device!')),
      );
    }
  }

  void _showClearDialog(BuildContext context, ClipboardService service) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Clear History'),
        content: const Text(
          'Are you sure you want to clear all clipboard history?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              service.clearHistory();
              Navigator.pop(context);
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: AppTheme.errorColor,
            ),
            child: const Text('Clear'),
          ),
        ],
      ),
    );
  }
}

class _SyncToggle extends StatelessWidget {
  final bool isEnabled;
  final VoidCallback onToggle;
  final bool isDark;

  const _SyncToggle({
    required this.isEnabled,
    required this.onToggle,
    this.isDark = true,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onToggle,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color: isEnabled
              ? AppTheme.successColor.withAlpha(26)
              : (isDark
                    ? AppTheme.darkSurfaceVariant
                    : AppTheme.lightSurfaceVariant),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: isEnabled
                ? AppTheme.successColor
                : (isDark ? AppTheme.darkBorder : AppTheme.lightBorder),
            width: 1,
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              isEnabled ? Iconsax.refresh5 : Iconsax.refresh,
              size: 16,
              color: isEnabled
                  ? AppTheme.successColor
                  : (isDark
                        ? AppTheme.darkTextSecondary
                        : AppTheme.lightTextSecondary),
            ),
            const SizedBox(width: 6),
            Text(
              isEnabled ? 'Auto' : 'Manual',
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: isEnabled
                    ? AppTheme.successColor
                    : (isDark
                          ? AppTheme.darkTextSecondary
                          : AppTheme.lightTextSecondary),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ClipboardItemCard extends StatelessWidget {
  final ClipboardItem item;
  final VoidCallback onCopy;
  final VoidCallback onSend;
  final bool isDark;

  const _ClipboardItemCard({
    required this.item,
    required this.onCopy,
    required this.onSend,
    this.isDark = true,
  });

  @override
  Widget build(BuildContext context) {
    return GlassCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: item.isSent
                      ? AppTheme.primaryColor.withAlpha(26)
                      : AppTheme.secondaryColor.withAlpha(26),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      item.isSent ? Iconsax.arrow_up_2 : Iconsax.arrow_down_2,
                      size: 12,
                      color: item.isSent
                          ? AppTheme.primaryColor
                          : AppTheme.secondaryColor,
                    ),
                    const SizedBox(width: 4),
                    Text(
                      item.isSent ? 'Sent' : 'Received',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w500,
                        color: item.isSent
                            ? AppTheme.primaryColor
                            : AppTheme.secondaryColor,
                      ),
                    ),
                  ],
                ),
              ),
              const Spacer(),
              Text(
                item.timeFormatted,
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: isDark
                      ? AppTheme.darkTextSecondary
                      : AppTheme.lightTextSecondary,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            item.content,
            style: Theme.of(context).textTheme.bodyLarge,
            maxLines: 5,
            overflow: TextOverflow.ellipsis,
          ),
          const SizedBox(height: 12),
          Row(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              TextButton.icon(
                onPressed: onCopy,
                icon: const Icon(Iconsax.copy, size: 16),
                label: const Text('Copy'),
              ),
              const SizedBox(width: 8),
              TextButton.icon(
                onPressed: onSend,
                icon: const Icon(Iconsax.send_2, size: 16),
                label: const Text('Send'),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
