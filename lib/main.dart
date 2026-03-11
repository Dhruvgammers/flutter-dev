import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'core/theme/app_theme.dart';
import 'core/services/encryption_service.dart';
import 'core/services/connection_service.dart';
import 'core/services/clipboard_service.dart';
import 'core/services/file_transfer_service.dart';
import 'screens/splash_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Set preferred orientations
  await SystemChrome.setPreferredOrientations([
    DeviceOrientation.portraitUp,
    DeviceOrientation.portraitDown,
    DeviceOrientation.landscapeLeft,
    DeviceOrientation.landscapeRight,
  ]);

  // Set system UI overlay style
  SystemChrome.setSystemUIOverlayStyle(
    const SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
      statusBarIconBrightness: Brightness.light,
      systemNavigationBarColor: AppTheme.darkSurface,
      systemNavigationBarIconBrightness: Brightness.light,
    ),
  );

  // Initialize services
  final encryptionService = EncryptionService();
  await encryptionService.initialize();

  final connectionService = ConnectionService(encryption: encryptionService);
  await connectionService.initialize();

  final clipboardService = ClipboardService(
    connectionService: connectionService,
  );

  final fileTransferService = FileTransferService(
    connectionService: connectionService,
    encryptionService: encryptionService,
  );

  runApp(
    MultiProvider(
      providers: [
        Provider<EncryptionService>.value(value: encryptionService),
        ChangeNotifierProvider<ConnectionService>.value(
          value: connectionService,
        ),
        ChangeNotifierProvider<ClipboardService>.value(value: clipboardService),
        ChangeNotifierProvider<FileTransferService>.value(
          value: fileTransferService,
        ),
      ],
      child: const ContoApp(),
    ),
  );
}

class ContoApp extends StatefulWidget {
  const ContoApp({super.key});

  @override
  State<ContoApp> createState() => _ContoAppState();
}

class _ContoAppState extends State<ContoApp> {
  final ThemeMode _themeMode = ThemeMode.dark;

  @override
  void initState() {
    super.initState();
    // Start clipboard watching when app starts
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<ClipboardService>().startWatching();
    });
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Conto',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.lightTheme,
      darkTheme: AppTheme.darkTheme,
      themeMode: _themeMode,
      home: const SplashScreen(),
    );
  }
}
