import 'dart:convert';
import 'package:http/http.dart' as http;

class ApiService {
  // Use 'http://localhost:8080' if testing on your local machine.
  // If running on an Android Emulator, use 'http://10.0.2.2:8080'.
  static const String baseUrl = 'http://127.0.0.1:8001';

  // Fetch all notices from the backend
  static Future<List<dynamic>> fetchNotices({String? category}) async {
    final url = category != null 
        ? '$baseUrl/notices/?category=$category' 
        : '$baseUrl/notices/';
        
    try {
      final response = await http.get(Uri.parse(url));
      if (response.statusCode == 200) {
        return jsonDecode(response.body);
      } else {
        throw Exception('Failed to load notices: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Connection error: $e');
    }
  }

  // Create a new notice
  static Future<Map<String, dynamic>> createNotice({
    required String title,
    required String body,
    required String category,
    required int authorId,
  }) async {
    final url = '$baseUrl/notices/?author_id=$authorId';
    
    try {
      final response = await http.post(
        Uri.parse(url),
        headers: {'Content-Type': 'application/json'},
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
