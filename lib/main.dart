import 'package:flutter/material.dart';
import 'package:panal_flutter_app/layout/main.layout.dart'; // Ensure this import is correct based on your project structure
import 'package:panal_flutter_app/controllers/auth_controller.dart';
import 'package:panal_flutter_app/views/auth/login_view.dart';
import 'package:panal_flutter_app/views/auth/workspace_selection_view.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'utils/app_theme.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
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
      home: const AuthCheck(),
    );
  }
}

class AuthCheck extends StatefulWidget {
  const AuthCheck({super.key});

  @override
  State<AuthCheck> createState() => _AuthCheckState();
}

class _AuthCheckState extends State<AuthCheck> {
  bool _isLoading = true;
  bool _isLoggedIn = false;
  bool _hasWorkspace = false;

  @override
  void initState() {
    super.initState();
    _checkAuth();
  }

  Future<void> _checkAuth() async {
    final authController = AuthController();
    final isLoggedIn = await authController.isAuthenticated();
    bool hasWorkspace = false;
    
    if (isLoggedIn) {
      final prefs = await SharedPreferences.getInstance();
      hasWorkspace = prefs.getString('selected_workspace_id') != null;
    }

    if (mounted) {
      setState(() {
        _isLoggedIn = isLoggedIn;
        _hasWorkspace = hasWorkspace;
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }
    
    if (!_isLoggedIn) {
      return const LoginView();
    }
    
    return _hasWorkspace ? const MainLayout() : const WorkspaceSelectionView();
  }
}
