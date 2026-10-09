import 'dart:convert';
import 'package:http/http.dart' as http;
import 'auth_storage.dart';

class ApiService {
  // Use 'http://localhost:8080' if testing on your local machine.
  // If running on an Android Emulator, use 'http://10.0.2.2:8080'.
  static const String baseUrl = 'http://127.0.0.1:8001';

  // Fetch all notices from the backend, optionally filtered by category
  static Future<List<dynamic>> fetchNotices({String? category}) async {
    // Uri handles encoding, so categories like "Lost & Found" are sent correctly
    final uri = Uri.parse('$baseUrl/notices').replace(
      queryParameters: category != null ? {'category': category} : null,
    );

    try {
      final response = await http.get(uri);
      if (response.statusCode == 200) {
        return jsonDecode(response.body);
      } else {
        throw Exception('Failed to load notices: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Connection error: $e');
    }
  }

  // Create a new notice as the logged-in user (author comes from the token)
  static Future<Map<String, dynamic>> createNotice({
    required String title,
    required String body,
    required String category,
  }) async {
    if (!AuthStorage.isLoggedIn) {
      throw Exception('You must be logged in to post a notice');
    }

    try {
      final response = await http.post(
        Uri.parse('$baseUrl/notices'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer ${AuthStorage.token}',
        },
        body: jsonEncode({
          'title': title,
          'body': body,
          'category': category,
        }),
      );

      if (response.statusCode == 201) {
        return jsonDecode(response.body);
      } else {
        throw Exception('Failed to post notice: ${response.body}');
      }
    } catch (e) {
      throw Exception('Connection error: $e');
    }
  }
}
