import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:iconsax/iconsax.dart';
import 'package:provider/provider.dart';
import '../../core/models/transfer_item.dart';
import '../../core/services/connection_service.dart';
import '../../core/services/file_transfer_service.dart';
import '../../core/theme/app_theme.dart';
import '../../core/widgets/common_widgets.dart';

class FilesScreen extends StatelessWidget {
  const FilesScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Consumer2<FileTransferService, ConnectionService>(
        builder: (context, fileService, connectionService, _) {
          return Column(
            children: [
              _buildHeader(context, fileService, connectionService),
              Expanded(
                child: fileService.transfers.isEmpty
                    ? _buildEmptyState(context, fileService, connectionService)
                    : _buildTransferList(context, fileService),
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _buildHeader(
    BuildContext context,
    FileTransferService fileService,
    ConnectionService connectionService,
  ) {
    final isConnected = connectionService.isConnected;

    return Padding(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Files',
                style: Theme.of(context).textTheme.displayMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
              if (fileService.transfers.isNotEmpty)
                IconButton(
                  icon: const Icon(Iconsax.trash),
                  onPressed: () => fileService.clearCompleted(),
                  tooltip: 'Clear completed',
                ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            'Send and receive files securely',
            style: Theme.of(
              context,
            ).textTheme.bodyMedium?.copyWith(color: AppTheme.darkTextSecondary),
          ),
          const SizedBox(height: 20),
          _buildUploadArea(context, fileService, isConnected),
        ],
      ),
    );
  }

  Widget _buildUploadArea(
    BuildContext context,
    FileTransferService fileService,
    bool isConnected,
  ) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return GestureDetector(
          onTap: isConnected ? () => fileService.pickAndSendFiles() : null,
          child: Container(
            width: double.infinity,
            padding: const EdgeInsets.all(32),
            decoration: BoxDecoration(
              color: isConnected
                  ? AppTheme.primaryColor.withAlpha(13)
                  : (isDark
                        ? AppTheme.darkSurfaceVariant
                        : AppTheme.lightSurfaceVariant),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: isConnected
                    ? AppTheme.primaryColor.withAlpha(51)
                    : (isDark ? AppTheme.darkBorder : AppTheme.lightBorder),
                width: 2,
                strokeAlign: BorderSide.strokeAlignCenter,
              ),
            ),
            child: Column(
              children: [
                Container(
                  width: 64,
                  height: 64,
                  decoration: BoxDecoration(
                    color: isConnected
                        ? AppTheme.primaryColor.withAlpha(26)
                        : Colors.transparent,
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    Iconsax.document_upload,
                    size: 32,
                    color: isConnected
                        ? AppTheme.primaryColor
                        : AppTheme.darkTextSecondary,
                  ),
                ),
                const SizedBox(height: 16),
                Text(
                  isConnected
                      ? 'Tap to select files'
                      : 'Connect a device to send files',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    color: isConnected ? null : AppTheme.darkTextSecondary,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  isConnected
                      ? 'Files will be encrypted before sending'
                      : 'Pair with another device first',
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: isDark
                        ? AppTheme.darkTextSecondary
                        : AppTheme.lightTextSecondary,
                  ),
                ),
              ],
            ),
          ),
        )
        .animate()
        .fadeIn(duration: 400.ms)
        .scale(begin: const Offset(0.98, 0.98), end: const Offset(1, 1));
  }

  Widget _buildEmptyState(
    BuildContext context,
    FileTransferService fileService,
    ConnectionService connectionService,
  ) {
    return EmptyState(
      icon: Iconsax.folder_2,
      title: 'No transfers yet',
      subtitle: connectionService.isConnected
          ? 'Select files to send to connected device'
          : 'Connect a device to start sharing files',
      action: connectionService.isConnected
          ? GradientButton(
              text: 'Select Files',
              icon: Iconsax.document_upload,
              onPressed: () => fileService.pickAndSendFiles(),
            )
          : null,
    );
  }

  Widget _buildTransferList(
    BuildContext context,
    FileTransferService fileService,
  ) {
    return ListView.builder(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      itemCount: fileService.transfers.length,
      itemBuilder: (context, index) {
        final transfer = fileService.transfers[index];
        return Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: _TransferCard(
                transfer: transfer,
                onAccept:
                    transfer.status == TransferStatus.pending &&
                        transfer.receiverId ==
                            fileService.transfers.first.receiverId
                    ? () => fileService.acceptTransfer(transfer.id)
                    : null,
                onReject: transfer.status == TransferStatus.pending
                    ? () => fileService.rejectTransfer(transfer.id)
                    : null,
                onCancel: transfer.status == TransferStatus.inProgress
                    ? () => fileService.cancelTransfer(transfer.id)
                    : null,
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
}

class _TransferCard extends StatelessWidget {
  final TransferItem transfer;
  final VoidCallback? onAccept;
  final VoidCallback? onReject;
  final VoidCallback? onCancel;

  const _TransferCard({
    required this.transfer,
    this.onAccept,
    this.onReject,
    this.onCancel,
  });

  @override
  Widget build(BuildContext context) {
    return GlassCard(
      borderColor: _getBorderColor(),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              _buildIcon(),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      transfer.fileName ?? 'Unknown file',
                      style: Theme.of(context).textTheme.titleMedium,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    Row(
                      children: [
                        _buildStatusBadge(context),
                        if (transfer.fileSize != null) ...[
                          const SizedBox(width: 8),
                          Text(
                            transfer.fileSizeFormatted,
                            style: Theme.of(context).textTheme.bodyMedium,
                          ),
                        ],
                      ],
                    ),
                  ],
                ),
              ),
              _buildActions(),
            ],
          ),
          if (transfer.isInProgress) ...[
            const SizedBox(height: 12),
            ClipRRect(
              borderRadius: BorderRadius.circular(4),
              child: LinearProgressIndicator(
                value: transfer.progress,
                backgroundColor: AppTheme.darkSurfaceVariant,
                valueColor: const AlwaysStoppedAnimation(AppTheme.primaryColor),
                minHeight: 6,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              '${(transfer.progress * 100).toInt()}%',
              style: Theme.of(context).textTheme.bodyMedium,
            ),
          ],
          if (transfer.isFailed && transfer.errorMessage != null) ...[
            const SizedBox(height: 8),
            Text(
              transfer.errorMessage!,
              style: Theme.of(
                context,
              ).textTheme.bodyMedium?.copyWith(color: AppTheme.errorColor),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildIcon() {
    IconData icon;
    Color color;

    switch (transfer.status) {
      case TransferStatus.completed:
        icon = Iconsax.tick_circle5;
        color = AppTheme.successColor;
        break;
      case TransferStatus.failed:
        icon = Iconsax.close_circle5;
        color = AppTheme.errorColor;
        break;
      case TransferStatus.cancelled:
        icon = Iconsax.minus_cirlce5;
        color = AppTheme.warningColor;
        break;
      case TransferStatus.inProgress:
        icon = Iconsax.document5;
        color = AppTheme.primaryColor;
        break;
      default:
        icon = Iconsax.document;
        color = AppTheme.darkTextSecondary;
    }

    return Container(
      width: 48,
      height: 48,
      decoration: BoxDecoration(
        color: color.withAlpha(26),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Icon(icon, color: color, size: 24),
    );
  }

  Widget _buildStatusBadge(BuildContext context) {
    String text;
    Color color;

    switch (transfer.status) {
      case TransferStatus.pending:
        text = 'Pending';
        color = AppTheme.warningColor;
        break;
      case TransferStatus.inProgress:
        text = 'Transferring';
        color = AppTheme.primaryColor;
        break;
      case TransferStatus.completed:
        text = 'Completed';
        color = AppTheme.successColor;
        break;
      case TransferStatus.failed:
        text = 'Failed';
        color = AppTheme.errorColor;
        break;
      case TransferStatus.cancelled:
        text = 'Cancelled';
        color = AppTheme.darkTextSecondary;
        break;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
      decoration: BoxDecoration(
        color: color.withAlpha(26),
        borderRadius: BorderRadius.circular(4),
      ),
      child: Text(
        text,
        style: TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.w500,
          color: color,
        ),
      ),
    );
  }

  Widget _buildActions() {
    if (onAccept != null) {
      return Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          IconButton(
            icon: const Icon(Iconsax.tick_circle, color: AppTheme.successColor),
            onPressed: onAccept,
            tooltip: 'Accept',
          ),
          IconButton(
            icon: const Icon(Iconsax.close_circle, color: AppTheme.errorColor),
            onPressed: onReject,
            tooltip: 'Reject',
          ),
        ],
      );
    }

    if (onCancel != null) {
      return IconButton(
        icon: const Icon(Iconsax.close_circle),
        onPressed: onCancel,
        tooltip: 'Cancel',
      );
    }

    return const SizedBox.shrink();
  }

  Color? _getBorderColor() {
    switch (transfer.status) {
      case TransferStatus.completed:
        return AppTheme.successColor.withAlpha(77);
      case TransferStatus.failed:
        return AppTheme.errorColor.withAlpha(77);
      case TransferStatus.inProgress:
        return AppTheme.primaryColor.withAlpha(77);
      default:
        return null;
    }
  }
}
