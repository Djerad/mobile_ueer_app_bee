import 'dart:convert';
import 'package:http/http.dart' as http;

class AuthService {
  final String baseUrl = "http:/ip:8000/api/auth";

  Future<Map<String, dynamic>> login(String email, String password) async {
    final Uri url = Uri.parse("$baseUrl/login/");

    final response = await http.post(
      url,
      headers: {"Content-Type": "application/json"},
      body: jsonEncode({
        "email": email,
        "password": password,
      }),
    );

    if (response.statusCode == 200) {
      return jsonDecode(response.body); // return JSON
    } else {
      throw Exception("Invalid email or password");
    }
  }
}
