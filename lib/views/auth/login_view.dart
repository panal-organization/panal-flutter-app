import 'package:flutter/material.dart';
import '../../controllers/auth_controller.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'workspace_selection_view.dart';
import '../../utils/app_colors.dart';
import '../../utils/app_toast.dart';

class LoginView extends StatefulWidget {
  const LoginView({super.key});

  @override
  State<LoginView> createState() => _LoginViewState();
}

class _LoginViewState extends State<LoginView> {
  final _formKey = GlobalKey<FormState>();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  final AuthController _authController = AuthController();

  bool _isLoading = false;
  bool _obscurePassword = true;

  @override
  void initState() {
    super.initState();
    _loadSavedEmail();
  }

  Future<void> _loadSavedEmail() async {
    final prefs = await SharedPreferences.getInstance();
    final savedEmail = prefs.getString('user_email');
    if (savedEmail != null) {
      setState(() {
        _emailController.text = savedEmail;
      });
    }
  }

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _handleLogin() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _isLoading = true;
    });

    try {
      await _authController.signIn(
        _emailController.text.trim(),
        _passwordController.text,
      );

      _showToast("Bienvenido", isError: false);

      if (mounted) {
        Navigator.of(context).pushReplacement(
          MaterialPageRoute(builder: (_) => const WorkspaceSelectionView()),
        );
      }
    } catch (e) {
      _showToast(e.toString(), isError: true);
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  void _showToast(String message, {bool isError = false}) {
    AppToast.show(context, message, isError: isError);
  }

  @override
  Widget build(BuildContext context) {
    // Top background color based on app palette
    return Scaffold(
      backgroundColor: AppColors.menuBackground,
      body: Stack(
        children: [
          // Upper Section: Logo and Branding
          Positioned(
            top: 0,
            left: 0,
            right: 0,
            height: MediaQuery.of(context).size.height * 0.45,
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Container(
                  height: 100,
                  width: 100,
                  // Minimalist: No shadow, just the circular image
                  decoration: const BoxDecoration(
                    shape: BoxShape.circle,
                    image: DecorationImage(
                      image: AssetImage('assets/app/icon.png'),
                      fit: BoxFit.cover,
                    ),
                  ),
                ),
                const SizedBox(height: 20),
                const Text(
                  'Panal App',
                  style: TextStyle(
                    fontSize: 28,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                    letterSpacing: 1.2,
                  ),
                ),
              ],
            ),
          ),

          // Bottom Section: White Box with Inputs
          Positioned(
            bottom: 0,
            left: 0,
            right: 0,
            // Takes up more than half the screen to fit contents comfortably
            height: MediaQuery.of(context).size.height * 0.60,
            child: Container(
              padding: const EdgeInsets.fromLTRB(30, 40, 30, 20),
              decoration: const BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.only(
                  topLeft: Radius.circular(40),
                  topRight: Radius.circular(40),
                ),
              ),
              child: Form(
                key: _formKey,
                child: SingleChildScrollView(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      const Text(
                        'Bienvenido de nuevo',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.w700,
                          color: AppColors.textBase,
                        ),
                      ),
                      const SizedBox(height: 8),
                      const Text(
                        'Inicia sesión para continuar',
                        textAlign: TextAlign.center,
                        style: TextStyle(fontSize: 14, color: Colors.grey),
                      ),
                      const SizedBox(height: 40),

                      // Email Input - Minimalist
                      // Using a light grey background, no borders
                      TextFormField(
                        controller: _emailController,
                        keyboardType: TextInputType.emailAddress,
                        style: const TextStyle(color: AppColors.textBase),
                        decoration: InputDecoration(
                          hintText: 'Correo Electrónico',
                          hintStyle: TextStyle(color: Colors.grey.shade400),
                          filled: true,
                          fillColor: AppColors
                              .contentBackground, // or Colors.grey[100]
                          prefixIcon: const Icon(
                            Icons.email_outlined,
                            color: Colors.grey,
                          ),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(15),
                            borderSide: BorderSide.none,
                          ),
                          contentPadding: const EdgeInsets.symmetric(
                            vertical: 20,
                            horizontal: 20,
                          ),
                        ),
                        validator: (value) {
                          if (value == null || value.isEmpty)
                            return 'Requerido';
                          if (!value.contains('@')) return 'Correo inválido';
                          return null;
                        },
                      ),
                      const SizedBox(height: 20),

                      // Password Input - Minimalist
                      TextFormField(
                        controller: _passwordController,
                        obscureText: _obscurePassword,
                        style: const TextStyle(color: AppColors.textBase),
                        decoration: InputDecoration(
                          hintText: 'Contraseña',
                          hintStyle: TextStyle(color: Colors.grey.shade400),
                          filled: true,
                          fillColor: AppColors.contentBackground,
                          prefixIcon: const Icon(
                            Icons.lock_outline,
                            color: Colors.grey,
                          ),
                          suffixIcon: IconButton(
                            icon: Icon(
                              _obscurePassword
                                  ? Icons.visibility_outlined
                                  : Icons.visibility_off_outlined,
                              color: Colors.grey,
                            ),
                            onPressed: () => setState(
                              () => _obscurePassword = !_obscurePassword,
                            ),
                          ),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(15),
                            borderSide: BorderSide.none,
                          ),
                          contentPadding: const EdgeInsets.symmetric(
                            vertical: 20,
                            horizontal: 20,
                          ),
                        ),
                        validator: (value) {
                          if (value == null || value.isEmpty)
                            return 'Requerido';
                          return null;
                        },
                      ),
                      const SizedBox(height: 40),

                      // Sign In Button
                      SizedBox(
                        height: 55,
                        child: ElevatedButton(
                          onPressed: _isLoading ? null : _handleLogin,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppColors.menuBackground,
                            foregroundColor: Colors.white,
                            elevation: 0, // Minimalist: no shadow
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(15),
                            ),
                          ),
                          child: _isLoading
                              ? const SizedBox(
                                  width: 24,
                                  height: 24,
                                  child: CircularProgressIndicator(
                                    color: Colors.white,
                                    strokeWidth: 2,
                                  ),
                                )
                              : const Text(
                                  'Ingresar',
                                  style: TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
