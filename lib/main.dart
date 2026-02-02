import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:panal_flutter_app/layout/main.layout.dart';
import 'package:panal_flutter_app/utils/app_theme.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();

  SystemChrome.setEnabledSystemUIMode(
    SystemUiMode.manual,
    overlays: [SystemUiOverlay.top],
  );

  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Panal App',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.lightTheme,
      home: const MainLayout(),
    );
  }
}
