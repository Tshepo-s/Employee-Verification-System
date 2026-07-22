import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

class UserAuthServices {
final String baseUrl = "https://localhost:44317/api";

  Future<bool> login(String email, String password) async {
    final response = await http.post(
      Uri.parse("$baseUrl/login"),
      headers: {"Content-Type": "application/json"},
      body: jsonEncode({
        "emailAddress": email,
        "password": password,
      }),
    );

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString("token", data["token"]);
      await prefs.setString("uid", data["uid"]);
      return true;
    }
    return false;
  }

  Future<bool> register(Map<String, dynamic> employee) async {
    final response = await http.post(
      Uri.parse("$baseUrl/register"),
      headers: {"Content-Type": "application/json"},
      body: jsonEncode(employee),
    );

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString("token", data["token"]);
      await prefs.setString("uid", data["uid"]);
      return true;
    }
    return false;
  }

  Future<void> addLog(Map<String, dynamic> payload) async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString("token") ?? "";

    await http.post(
      Uri.parse("$baseUrl/addlog"),
      headers: {
        "Content-Type": "application/json",
        "token": token,
      },
      body: jsonEncode(payload),
    );
  }

  Future<Map<String, dynamic>?> getLogs() async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString("token") ?? "";

    final response = await http.get(
      Uri.parse("$baseUrl/logs"),
      headers: {
        "Content-Type": "application/json",
        "token": token,
      },
    );

    if (response.statusCode == 200) {
      return jsonDecode(response.body);
    }
    return null;
  }
}
