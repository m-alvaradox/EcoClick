import 'package:flutter/material.dart';
import '../api.dart';
import 'quiz_page.dart';

class QuizzesPage extends StatelessWidget {
  const QuizzesPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Quizzes'), // Título de la página
      ),
      body: FutureBuilder<List<dynamic>>(
        future: EcoClickAPI.getQuizzes(),
        builder: (context, snap) {
          if (snap.connectionState != ConnectionState.done) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snap.hasError) {
            return Center(child: Text('Error: ${snap.error}'));
          }

          final quizzes = snap.data ?? [];
          if (quizzes.isEmpty) {
            return const Center(child: Text('No hay quizzes disponibles'));
          }

          return ListView.builder(
            itemCount: quizzes.length,
            itemBuilder: (context, index) {
              final q = quizzes[index];
              return Card(
                child: ListTile(
                  title: Text(q['title'] ?? ''),
                  subtitle: Text('Categoría: ${q['category']}'),
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(builder: (_) => QuizPage(quiz: q)),
                    );
                  },
                ),
              );
            },
          );
        },
      ),
    );
  }
}
