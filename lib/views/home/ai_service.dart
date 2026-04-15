import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

class AiService {
  final String baseUrl = "http://10.60.218.30:3000";

  Future<String?> _getToken() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString('auth_token');
  }

  Future<Map<String, dynamic>> sendToAgent(String text) async {
    final token = await _getToken();

    final response = await http.post(
      Uri.parse('$baseUrl/api/ai/agent'),
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token',
      },
      body: jsonEncode({"text": text}),
    );

    if (response.statusCode == 200) {
      return jsonDecode(response.body);
    } else {
      throw Exception(response.body);
    }
  }

  Future<Map<String, dynamic>> sendToPlan(String text) async {
    final token = await _getToken();

    final response = await http.post(
      Uri.parse('$baseUrl/api/ai/agent/plan'),
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token',
      },
      body: jsonEncode({"text": text}),
    );

    if (response.statusCode == 200) {
      return jsonDecode(response.body);
    } else {
      throw Exception(response.body);
    }
  }

  Future<Map<String, dynamic>> confirmTicket(String aiLogId) async {
    final token = await _getToken();

    final response = await http.post(
      Uri.parse('$baseUrl/api/ai/agent/continue'),
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token',
      },
      body: jsonEncode({"ai_log_id": aiLogId}),
    );

    if (response.statusCode == 200) {
      return jsonDecode(response.body);
    } else {
      throw Exception(response.body);
    }
  }
}
