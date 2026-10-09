import 'dart:convert';
import 'package:http/http.dart' as http;
import 'auth_storage.dart';

class ApiService {
  static const String baseUrl = 'http://127.0.0.1:8001';

  static Map<String, String> get _authHeaders => {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer ${AuthStorage.token}',
      };

  static String _errorMessage(http.Response response, String fallback) {
    try {
      final detail = jsonDecode(response.body)['detail'];
      if (detail is String) return detail;
    } catch (_) {}
    return fallback;
  }

  static Future<http.Response> _send(Future<http.Response> Function() request) async {
    try {
      return await request();
    } catch (e) {
      throw Exception('Cannot connect to server. Is the backend running?');
    }
  }

  static Future<List<dynamic>> fetchNotices({
    String? category,
    int offset = 0,
    int limit = 20,
  }) async {
    final uri = Uri.parse('$baseUrl/notices').replace(
      queryParameters: {
        'offset': '$offset',
        'limit': '$limit',
        if (category != null) 'category': category,
      },
    );
    final response = await _send(() => http.get(uri));
    if (response.statusCode == 200) {
      return jsonDecode(response.body);
    }
    throw Exception(_errorMessage(response, 'Could not load notices.'));
  }

  static Future<Map<String, dynamic>> createNotice({
    required String title,
    required String body,
    required String category,
  }) async {
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

  static Future<Map<String, dynamic>> updateNotice(
    int noticeId, {
    required String title,
    required String body,
    required String category,
  }) async {
    final response = await _send(() => http.patch(
          Uri.parse('$baseUrl/notices/$noticeId'),
          headers: _authHeaders,
          body: jsonEncode({'title': title, 'body': body, 'category': category}),
        ));
    if (response.statusCode == 200) {
      return jsonDecode(response.body);
    }
    throw Exception(_errorMessage(response, 'Could not update the notice.'));
  }

  static Future<void> deleteNotice(int noticeId) async {
    final response = await _send(() => http.delete(
          Uri.parse('$baseUrl/notices/$noticeId'),
          headers: _authHeaders,
        ));
    if (response.statusCode != 204) {
      throw Exception(_errorMessage(response, 'Could not delete the notice.'));
    }
  }

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

  static Future<void> deleteComment(int commentId) async {
    final response = await _send(() => http.delete(
          Uri.parse('$baseUrl/comments/$commentId'),
          headers: _authHeaders,
        ));
    if (response.statusCode != 204) {
      throw Exception(_errorMessage(response, 'Could not delete the comment.'));
    }
  }
}
