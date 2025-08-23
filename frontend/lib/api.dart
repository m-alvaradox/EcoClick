import 'dart:convert';
import 'package:http/http.dart' as http;
import 'config.dart';

class EcoClickAPI {
  // USERS
  static Future<List<dynamic>> getUsers() async {
    final r = await http.get(Uri.parse('$baseUrl/users'));
    if (r.statusCode >= 400)
      throw Exception('Error ${r.statusCode}: ${r.body}');
    return jsonDecode(r.body) as List<dynamic>;
  }

  // ACHIEVEMENTS (catálogo maestro)
  static Future<List<dynamic>> getAllAchievements() async {
    final r = await http.get(Uri.parse('$baseUrl/achievements'));
    if (r.statusCode >= 400)
      throw Exception('Error ${r.statusCode}: ${r.body}');
    return jsonDecode(r.body) as List<dynamic>;
  }

  // USER ACHIEVEMENTS
  static Future<List<Map<String, dynamic>>> getUserAchievements(
    int userId,
  ) async {
    final r = await http.get(
      Uri.parse('$baseUrl/userAchievements?userId=$userId'),
    );
    if (r.statusCode >= 400)
      throw Exception('Error ${r.statusCode}: ${r.body}');
    final items = (jsonDecode(r.body)['items'] as List<dynamic>);
    return items.map((e) => Map<String, dynamic>.from(e as Map)).toList();
  }

  // PROGRESS -> registra un logro para un user
  static Future<Map<String, dynamic>> postProgress({
    required int userId,
    required int achievementId,
    required String date,
  }) async {
    final r = await http.post(
      Uri.parse('$baseUrl/progress'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({
        'userId': userId,
        'achievementId': achievementId,
        'date': date,
      }),
    );
    if (r.statusCode == 409) {
      throw Exception('409: Progreso ya registrado');
    }
    if (r.statusCode >= 400)
      throw Exception('Error ${r.statusCode}: ${r.body}');
    return jsonDecode(r.body) as Map<String, dynamic>;
  }

  // QUIZZES
  static Future<List<dynamic>> getQuizzes() async {
    final r = await http.get(Uri.parse('$baseUrl/quizzes'));
    if (r.statusCode >= 400)
      throw Exception('Error ${r.statusCode}: ${r.body}');
    return jsonDecode(r.body) as List<dynamic>;
  }

  static Future<Map<String, dynamic>> getQuiz(String id) async {
    final r = await http.get(Uri.parse('$baseUrl/quizzes/$id'));
    if (r.statusCode >= 400)
      throw Exception('Error ${r.statusCode}: ${r.body}');
    return (jsonDecode(r.body)['item'] as Map<String, dynamic>);
  }

  // NEW: enviar respuestas del juego
  static Future<Map<String, dynamic>> postAnswers({
    required String quizId,
    required int userId,
    required List<Map<String, dynamic>> answers,
    required int score,
    required int timeSec,
  }) async {
    final r = await http.post(
      Uri.parse('$baseUrl/games/$quizId/answers'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({
        'userId': userId,
        'answers': answers,
        'score': score,
        'timeSec': timeSec,
      }),
    );
    if (r.statusCode >= 400)
      throw Exception('Error ${r.statusCode}: ${r.body}');
    return jsonDecode(r.body) as Map<String, dynamic>;
  }

  // NEW: obtener feedback ecológico
  static Future<List<dynamic>> getFeedback({String? topic}) async {
    final url = (topic == null || topic.isEmpty)
        ? '$baseUrl/feedback'
        : '$baseUrl/feedback?topic=$topic';
    final r = await http.get(Uri.parse(url));
    if (r.statusCode >= 400)
      throw Exception('Error ${r.statusCode}: ${r.body}');
    return (jsonDecode(r.body)['items'] as List<dynamic>);
  }
}
