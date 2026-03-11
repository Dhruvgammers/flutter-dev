import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:iconsax/iconsax.dart';
import 'package:provider/provider.dart';
import 'package:qr_flutter/qr_flutter.dart';
import '../../core/services/connection_service.dart';
import '../../core/theme/app_theme.dart';
import '../../core/widgets/common_widgets.dart';
import '../../core/models/device.dart';

class PairingScreen extends StatefulWidget {
  const PairingScreen({super.key});

  @override
  State<PairingScreen> createState() => _PairingScreenState();
}

class _PairingScreenState extends State<PairingScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final TextEditingController _ipController = TextEditingController();
  final TextEditingController _portController = TextEditingController(
    text: '8765',
  );
  bool _isConnecting = false;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _startServer();
  }

  Future<void> _startServer() async {
    try {
      final connectionService = context.read<ConnectionService>();
      await connectionService.startServer();
    } catch (e) {
      debugPrint('Failed to start server: $e');
    }
  }

  @override
  void dispose() {
    _tabController.dispose();
    _ipController.dispose();
    _portController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Connect Device'),
        leading: IconButton(
          icon: const Icon(Icons.close),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: Column(
        children: [
          _buildTabBar(),
          Expanded(
            child: TabBarView(
              controller: _tabController,
              children: [_buildShowQRTab(), _buildManualTab()],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTabBar() {
    return Container(
      margin: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppTheme.darkSurfaceVariant,
        borderRadius: BorderRadius.circular(12),
      ),
      child: TabBar(
        controller: _tabController,
        indicator: BoxDecoration(
          color: AppTheme.primaryColor,
          borderRadius: BorderRadius.circular(12),
        ),
        labelColor: Colors.white,
        unselectedLabelColor: AppTheme.darkTextSecondary,
        indicatorSize: TabBarIndicatorSize.tab,
        dividerColor: Colors.transparent,
        tabs: const [
          Tab(text: 'Show QR Code'),
          Tab(text: 'Manual Connect'),
        ],
      ),
    );
  }

  Widget _buildShowQRTab() {
    return Consumer<ConnectionService>(
      builder: (context, connectionService, _) {
        final device = connectionService.currentDevice;
        final isConnected =
            connectionService.status == ConnectionStatus.connected;

        if (isConnected) {
          return _buildConnectedState(connectionService);
        }

        return SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Column(
            children: [
              Text(
                'Scan from other device',
                style: Theme.of(context).textTheme.titleLarge,
              ),
              const SizedBox(height: 8),
              Text(
                'Open Conto on your other device and scan this QR code',
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: AppTheme.darkTextSecondary,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 32),
              if (device != null) ...[
                Container(
                      padding: const EdgeInsets.all(20),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(20),
                        boxShadow: [
                          BoxShadow(
                            color: AppTheme.primaryColor.withAlpha(51),
                            blurRadius: 30,
                            spreadRadius: 5,
                          ),
                        ],
                      ),
                      child: QrImageView(
                        data: _generateQRData(device),
                        version: QrVersions.auto,
                        size: 200,
                        backgroundColor: Colors.white,
                        eyeStyle: const QrEyeStyle(
                          eyeShape: QrEyeShape.square,
                          color: AppTheme.primaryDark,
                        ),
                        dataModuleStyle: const QrDataModuleStyle(
                          dataModuleShape: QrDataModuleShape.square,
                          color: AppTheme.primaryDark,
                        ),
                      ),
                    )
                    .animate()
                    .fadeIn(duration: 400.ms)
                    .scale(
                      begin: const Offset(0.9, 0.9),
                      end: const Offset(1, 1),
                    ),
                const SizedBox(height: 32),
                GlassCard(
                  child: Column(
                    children: [
                      _ConnectionInfo(
                        icon: Iconsax.monitor,
                        label: 'Device',
                        value: device.name,
                      ),
                      const SizedBox(height: 12),
                      _ConnectionInfo(
                        icon: Iconsax.global,
                        label: 'IP Address',
                        value: device.ipAddress,
                      ),
                      const SizedBox(height: 12),
                      _ConnectionInfo(
                        icon: Iconsax.key,
                        label: 'Port',
                        value: device.port.toString(),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),
                Row(
                  children: [
                    const StatusIndicator(isActive: true, animate: true),
                    const SizedBox(width: 8),
                    Text(
                      'Waiting for connection...',
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: AppTheme.successColor,
                      ),
                    ),
                  ],
                ),
              ],
            ],
          ),
        );
      },
    );
  }

  Widget _buildConnectedState(ConnectionService connectionService) {
    final connectedDevice = connectionService.connectedDevice;

    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 100,
              height: 100,
              decoration: BoxDecoration(
                color: AppTheme.successColor.withAlpha(26),
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Iconsax.tick_circle5,
                color: AppTheme.successColor,
                size: 60,
              ),
            ).animate().scale(duration: 400.ms, curve: Curves.elasticOut),
            const SizedBox(height: 24),
            Text(
              'Connected!',
              style: Theme.of(context).textTheme.headlineLarge?.copyWith(
                color: AppTheme.successColor,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Successfully connected to ${connectedDevice?.name}',
              style: Theme.of(context).textTheme.bodyLarge,
              textAlign: TextAlign.center,
            ),
            if (connectionService.pairingCode != null) ...[
              const SizedBox(height: 24),
              GlassCard(
                borderColor: AppTheme.primaryColor.withAlpha(128),
                child: Column(
                  children: [
                    Text(
                      'Verification Code',
                      style: Theme.of(context).textTheme.bodyMedium,
                    ),
                    const SizedBox(height: 8),
                    Text(
                      connectionService.pairingCode!,
                      style: Theme.of(context).textTheme.headlineMedium
                          ?.copyWith(
                            fontWeight: FontWeight.bold,
                            letterSpacing: 4,
                            fontFamily: 'monospace',
                          ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Make sure this matches on both devices',
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: AppTheme.darkTextSecondary,
                      ),
                    ),
                  ],
                ),
              ),
            ],
            const SizedBox(height: 32),
            GradientButton(
              text: 'Done',
              onPressed: () => Navigator.pop(context),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildManualTab() {
    return Consumer<ConnectionService>(
      builder: (context, connectionService, _) {
        final isConnected =
            connectionService.status == ConnectionStatus.connected;

        if (isConnected) {
          return _buildConnectedState(connectionService);
        }

        return SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Enter device details',
                style: Theme.of(context).textTheme.titleLarge,
              ),
              const SizedBox(height: 8),
              Text(
                'Enter the IP address and port of the device you want to connect to',
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: AppTheme.darkTextSecondary,
                ),
              ),
              const SizedBox(height: 32),
              TextField(
                controller: _ipController,
                decoration: const InputDecoration(
                  labelText: 'IP Address',
                  hintText: '192.168.1.100',
                  prefixIcon: Icon(Iconsax.global),
                ),
                keyboardType: TextInputType.number,
              ),
              const SizedBox(height: 16),
              TextField(
                controller: _portController,
                decoration: const InputDecoration(
                  labelText: 'Port',
                  hintText: '8765',
                  prefixIcon: Icon(Iconsax.key),
                ),
                keyboardType: TextInputType.number,
              ),
              if (_errorMessage != null) ...[
                const SizedBox(height: 16),
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: AppTheme.errorColor.withAlpha(26),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: AppTheme.errorColor.withAlpha(77),
                    ),
                  ),
                  child: Row(
                    children: [
                      const Icon(Iconsax.warning_2, color: AppTheme.errorColor),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          _errorMessage!,
                          style: const TextStyle(color: AppTheme.errorColor),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
              const SizedBox(height: 32),
              SizedBox(
                width: double.infinity,
                child: GradientButton(
                  text: 'Connect',
                  icon: Iconsax.link_2,
                  isLoading: _isConnecting,
                  onPressed: _connect,
                ),
              ),
              const SizedBox(height: 24),
              GlassCard(
                child: Row(
                  children: [
                    Container(
                      width: 40,
                      height: 40,
                      decoration: BoxDecoration(
                        color: AppTheme.infoColor.withAlpha(26),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: const Icon(
                        Iconsax.info_circle,
                        color: AppTheme.infoColor,
                        size: 20,
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Text(
                        'Make sure both devices are on the same WiFi network',
                        style: Theme.of(context).textTheme.bodyMedium,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  String _generateQRData(Device device) {
    return 'conto://${device.ipAddress}:${device.port}?key=${device.publicKey}&name=${Uri.encodeComponent(device.name)}';
  }

  Future<void> _connect() async {
    final ip = _ipController.text.trim();
    final port = int.tryParse(_portController.text.trim()) ?? 8765;

    if (ip.isEmpty) {
      setState(() => _errorMessage = 'Please enter an IP address');
      return;
    }

    setState(() {
      _isConnecting = true;
      _errorMessage = null;
    });

    try {
      final connectionService = context.read<ConnectionService>();
      await connectionService.connectToDevice(ip, port);
    } catch (e) {
      setState(() => _errorMessage = 'Failed to connect: ${e.toString()}');
    } finally {
      setState(() => _isConnecting = false);
    }
  }
}

class _ConnectionInfo extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;

  const _ConnectionInfo({
    required this.icon,
    required this.label,
    required this.value,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(icon, size: 20, color: AppTheme.darkTextSecondary),
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
