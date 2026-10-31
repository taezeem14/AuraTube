import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'theme/aura_theme.dart';
import 'services/player_service.dart';
import 'services/storage_service.dart';
import 'services/download_service.dart';
import 'screens/aura_shell.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  final storageService = StorageService();
  await storageService.init();

  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider<StorageService>.value(value: storageService),
        ChangeNotifierProvider<PlayerService>(create: (_) => PlayerService()),
        ChangeNotifierProvider<DownloadService>(create: (_) => DownloadService()),
      ],
      child: const AuraTubeApp(),
    ),
  );
}

class AuraTubeApp extends StatelessWidget {
  const AuraTubeApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'AuraTube',
      debugShowCheckedModeBanner: false,
      theme: AuraTheme.darkTheme,
      home: const AuraShell(),
    );
  }
}
