import 'dart:convert';
import 'package:http/http.dart' as http;

class AiService {
  final String baseUrl = "https://lending-bandwidth-commercial-seekers.trycloudflare.com";

  Future<Map<String, dynamic>> generatePlan(String text) async {
    final response = await http.post(
      Uri.parse('$baseUrl/api/ai/agent/plan'),
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer TU_TOKEN',
      },
      body: jsonEncode({
        "text": text,
      }),
    );

    if (response.statusCode == 200) {
      return jsonDecode(response.body);
    } else {
      throw Exception(response.body);
    }
  }
}