import 'dart:convert';
import 'package:http/http.dart' as http;
import 'auth_storage.dart';

class ApiService {
  // Use 'http://localhost:8080' if testing on your local machine.
  // If running on an Android Emulator, use 'http://10.0.2.2:8080'.
  static const String baseUrl = 'http://127.0.0.1:8001';

  static Map<String, String> get _authHeaders => {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer ${AuthStorage.token}',
      };

  // Turns a FastAPI error response into a readable message
  static String _errorMessage(http.Response response, String fallback) {
    try {
      final detail = jsonDecode(response.body)['detail'];
      if (detail is String) return detail;
    } catch (_) {}
    return fallback;
  }

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

    final response = await _send(() => http.post(
          Uri.parse('$baseUrl/notices'),
          headers: _authHeaders,
          body: jsonEncode({'title': title, 'body': body, 'category': category}),
        ));
    if (response.statusCode == 201) {
      return jsonDecode(response.body);
    }
    throw Exception(_errorMessage(response, 'Could not post the notice.'));
  }

  // Delete one of your own notices
  static Future<void> deleteNotice(int noticeId) async {
    final response = await _send(() => http.delete(
          Uri.parse('$baseUrl/notices/$noticeId'),
          headers: _authHeaders,
        ));
    if (response.statusCode != 204) {
      throw Exception(_errorMessage(response, 'Could not delete the notice.'));
    }
  }

  // Comments on a notice, oldest first
  static Future<List<dynamic>> fetchComments(int noticeId) async {
    final response = await _send(() => http.get(
          Uri.parse('$baseUrl/notices/$noticeId/comments'),
        ));
    if (response.statusCode == 200) {
      return jsonDecode(response.body);
    }
    throw Exception(_errorMessage(response, 'Could not load comments.'));
  }

  static Future<Map<String, dynamic>> addComment(int noticeId, String content) async {
    final response = await _send(() => http.post(
          Uri.parse('$baseUrl/notices/$noticeId/comments'),
          headers: _authHeaders,
          body: jsonEncode({'content': content}),
        ));
    if (response.statusCode == 201) {
      return jsonDecode(response.body);
    }
    throw Exception(_errorMessage(response, 'Could not add the comment.'));
  }

  // Runs a request and turns network failures into a readable exception
  static Future<http.Response> _send(Future<http.Response> Function() request) async {
    try {
      return await request();
    } catch (e) {
      throw Exception('Cannot connect to server. Is the backend running?');
    }
  }
}
