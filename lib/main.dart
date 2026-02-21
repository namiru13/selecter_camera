import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'services/permission_service.dart';
import 'views/camera/camera_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  // 画面の向きをポートレートに固定（一般的なカメラアプリと同じ挙動）
  await SystemChrome.setPreferredOrientations([DeviceOrientation.portraitUp]);
  runApp(const ProviderScope(child: MyApp()));
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Skier Camera',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.blue),
        useMaterial3: true,
      ),
      home: const PermissionGate(),
    );
  }
}

/// パーミッションチェックゲート
///
/// アプリ起動時に必要な権限をリクエストし、
/// 付与された場合のみカメラ画面へ遷移する。
class PermissionGate extends StatefulWidget {
  const PermissionGate({super.key});

  @override
  State<PermissionGate> createState() => _PermissionGateState();
}

class _PermissionGateState extends State<PermissionGate> {
  final PermissionService _permissionService = PermissionService();
  bool _isGranted = false;
  bool _isChecking = true;
  bool _isPermanentlyDenied = false;

  @override
  void initState() {
    super.initState();
    _checkPermissions();
  }

  Future<void> _checkPermissions() async {
    final granted = await _permissionService.requestAllPermissions();
    final permanentlyDenied = await _permissionService.isAnyPermanentlyDenied();

    if (mounted) {
      setState(() {
        _isGranted = granted;
        _isChecking = false;
        _isPermanentlyDenied = permanentlyDenied;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isChecking) {
      return const Scaffold(
        backgroundColor: Colors.black,
        body: Center(child: CircularProgressIndicator(color: Colors.white)),
      );
    }

    if (_isGranted) {
      return const CameraScreen();
    }

    // 権限が拒否された場合のUI
    return Scaffold(
      backgroundColor: Colors.black,
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(32.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(
                Icons.camera_alt_outlined,
                color: Colors.white54,
                size: 80,
              ),
              const SizedBox(height: 24),
              const Text(
                'カメラとマイクの\nアクセス許可が必要です',
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 12),
              const Text(
                '動画撮影にはカメラとマイクへの\nアクセス許可が必要です。',
                textAlign: TextAlign.center,
                style: TextStyle(color: Colors.white70, fontSize: 14),
              ),
              const SizedBox(height: 32),
              if (_isPermanentlyDenied)
                ElevatedButton.icon(
                  onPressed: () => _permissionService.openSettings(),
                  icon: const Icon(Icons.settings),
                  label: const Text('設定を開く'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.blue,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(
                      horizontal: 24,
                      vertical: 12,
                    ),
                  ),
                )
              else
                ElevatedButton.icon(
                  onPressed: _checkPermissions,
                  icon: const Icon(Icons.refresh),
                  label: const Text('許可をリクエスト'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.blue,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(
                      horizontal: 24,
                      vertical: 12,
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}
