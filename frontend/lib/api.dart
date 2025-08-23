import 'dart:convert';
import 'package:http/http.dart' as http;
import 'config.dart';

class EcoClickAPI {
  // Ajusta si usas otro puerto/host

  static Future<List<dynamic>> getQuizzes() async {
    final res = await http.get(Uri.parse('$baseUrl/quizzes'));
    if (res.statusCode >= 400)
      throw Exception('Error ${res.statusCode}: ${res.body}');
    final data = jsonDecode(res.body) as Map<String, dynamic>;
    return (data['items'] as List<dynamic>);
  }

  static Future<Map<String, dynamic>> getQuiz(String id) async {
    final res = await http.get(Uri.parse('$baseUrl/quizzes/$id'));
    if (res.statusCode >= 400)
      throw Exception('Error ${res.statusCode}: ${res.body}');
    final data = jsonDecode(res.body) as Map<String, dynamic>;
    return (data['item'] as Map<String, dynamic>);
  }

  // NEW: enviar respuestas del juego
  static Future<Map<String, dynamic>> postAnswers({
    required String quizId,
    required int userId,
    required List<Map<String, dynamic>> answers,
    required int score,
    required int timeSec,
  }) async {
    final res = await http.post(
      Uri.parse('$baseUrl/games/$quizId/answers'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({
        'userId': userId,
        'answers': answers,
        'score': score,
        'timeSec': timeSec,
      }),
    );
    if (res.statusCode >= 400)
      throw Exception('Error ${res.statusCode}: ${res.body}');
    return jsonDecode(res.body) as Map<String, dynamic>;
  }

  // NEW: obtener feedback ecológico
  static Future<List<dynamic>> getFeedback({String? topic}) async {
    final url = (topic == null || topic.isEmpty)
        ? '$baseUrl/feedback'
        : '$baseUrl/feedback?topic=$topic';
    final res = await http.get(Uri.parse(url));
    if (res.statusCode >= 400)
      throw Exception('Error ${res.statusCode}: ${res.body}');
    final data = jsonDecode(res.body) as Map<String, dynamic>;
    return (data['items'] as List<dynamic>);
  }
}
