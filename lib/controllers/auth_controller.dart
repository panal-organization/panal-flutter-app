import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import '../models/auth_model.dart';

class AuthController {
  // Utilizing the base URL from ApiController or defining it here if it needs to be specific
  // ApiController.baseUrl is 'http://3.19.63.85:3000/api'
  // https://waggish-unsecludedly-jong.ngrok-free.dev
  // Endpoint requested is POST /api/auth/sign-in

  static const String _baseUrl =
      'https://waggish-unsecludedly-jong.ngrok-free.dev/api';

  Future<AuthResponse> signIn(String correo, String contrasena) async {
    try {
      final response = await http.post(
        Uri.parse('$_baseUrl/auth/sign-in'),
        headers: {'Content-Type': 'application/json'},
        body: json.encode({'correo': correo, 'contrasena': contrasena}),
      );

      if (response.statusCode == 200 || response.statusCode == 201) {
        final Map<String, dynamic> body = json.decode(response.body);
        final authResponse = AuthResponse.fromJson(body);

        await _saveSession(authResponse);

        return authResponse;
      } else {
        final Map<String, dynamic> errorBody = json.decode(response.body);
        throw Exception(errorBody['message'] ?? 'Error en inicio de sesión');
      }
    } catch (e) {
      throw e.toString().replaceAll('Exception: ', '');
    }
  }

  Future<void> _saveSession(AuthResponse authResponse) async {
    final prefs = await SharedPreferences.getInstance();
    // The token string from the API is "Bearer <token>".
    // We can save it as is or handle the prefix.
    // Usually standard to save just the token or the full string if used directly.
    await prefs.setString('auth_token', authResponse.token.token);
    await prefs.setString('user_id', authResponse.user.id);
    await prefs.setString('user_name', authResponse.user.nombre);
    await prefs.setString('user_email', authResponse.user.correo);
    await prefs.setString('user_role', authResponse.user.rolId);
    if (authResponse.user.planId != null) {
      await prefs.setString('user_plan', authResponse.user.planId!);
    }
  }

  Future<void> signOut() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.clear();
  }

  Future<bool> isAuthenticated() async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('auth_token');
    return token != null && token.isNotEmpty;
  }

  Future<String?> getToken() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString('auth_token');
  }
}
