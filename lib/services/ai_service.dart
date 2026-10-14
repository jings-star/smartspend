import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;

// Chrome / Windows / iOS simulator: 127.0.0.1
// Android emulator: 10.0.2.2
// Real phone: your PC's IP, e.g. 'http://192.168.1.5:8000'
String get baseUrl => kIsWeb
    ? 'http://127.0.0.1:8000'
    : (defaultTargetPlatform == TargetPlatform.android
        ? 'http://10.0.2.2:8000'
        : 'http://127.0.0.1:8000');

Future<Map<String, dynamic>> categorize(String text, {String? userId}) async {
  final res = await http
      .post(
        Uri.parse('$baseUrl/categorize'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'text': text, 'user_id': userId}),
      )
      .timeout(const Duration(seconds: 10));
  if (res.statusCode != 200) throw Exception(res.body);
  return jsonDecode(res.body) as Map<String, dynamic>;
}

/// Tell the server which category the user chose, so it remembers next time.
/// Failures are ignored: learning must never block saving.
Future<void> learnCategory(
    String userId, String title, String category,
    {String type = 'expense'}) async {
  try {
    await http
        .post(
          Uri.parse('$baseUrl/learn'),
          headers: {'Content-Type': 'application/json'},
          body: jsonEncode({
            'user_id': userId,
            'title': title,
            'category': category,
            'type': type,
          }),
        )
        .timeout(const Duration(seconds: 10));
  } catch (_) {}
}

Future<String> sendChat(String userId, String message) async {
  final res = await http
      .post(
        Uri.parse('$baseUrl/chat'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'user_id': userId, 'message': message}),
      )
      .timeout(const Duration(seconds: 15));
  if (res.statusCode != 200) throw Exception(res.body);
  return jsonDecode(res.body)['reply'] as String;
}