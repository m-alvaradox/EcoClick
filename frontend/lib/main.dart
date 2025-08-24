import 'package:flutter/material.dart';
import 'api.dart';
import 'ui/theme.dart';
import 'screens/stats/stats_page.dart';
import 'ui/error_widget.dart';
import 'screens/login_page.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:frontend/utils/prefers.dart';

void main() {
  runApp(const EcoClickApp());
}

class EcoClickApp extends StatelessWidget {
  const EcoClickApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'EcoClick',
      theme: AppTheme.light(),
      darkTheme: AppTheme.dark(),
      themeMode: ThemeMode.system,
      debugShowCheckedModeBanner: false,
      home: const InitialScreen(),
    );
  }
}

class InitialScreen extends StatelessWidget {
  const InitialScreen({super.key});

  Future<bool> _hasName() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.containsKey('username');
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<bool>(
      future: _hasName(),
      builder: (context, snapshot) {
        if (!snapshot.hasData) return const CircularProgressIndicator();

        return snapshot.data == true ? const QuizListPage() : const LoginPage();
      },
    );
  }
}

/// LISTA DE QUIZZES
class QuizListPage extends StatefulWidget {
  const QuizListPage({super.key});

  @override
  State<QuizListPage> createState() => _QuizListPageState();
}

class _QuizListPageState extends State<QuizListPage> {
  late Future<List<dynamic>> future;

  @override
  void initState() {
    super.initState();
    future = EcoClickAPI.getQuizzes();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Quizzes EcoClick'),
        actions: [
          IconButton(
            tooltip: 'Estadísticas',
            icon: const Icon(Icons.insights),
            onPressed: () {
              Navigator.of(context).push(
                MaterialPageRoute(
                  builder: (_) => const UserStatsPage(userId: 1),
                ),
              );
            },
          ),
          IconButton(
            tooltip: 'Cambiar usuario',
            icon: const Icon(Icons.logout),
            onPressed: () async {
              final prefs = await SharedPreferences.getInstance();
              await prefs.remove('username');
              if (context.mounted) {
                Navigator.pushAndRemoveUntil(
                  context,
                  MaterialPageRoute(builder: (_) => const LoginPage()),
                  (route) => false,
                );
              }
            },
          ),
        ],
      ),

      body: FutureBuilder<List<dynamic>>(
        future: future,
        builder: (context, snap) {
          if (snap.connectionState != ConnectionState.done) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snap.hasError) {
            return ErrorRetryWidget(
              message:
                  'No se pudo conectar con el servidor.\nRevisa tu conexión e intenta nuevamente.',
              onRetry: () {
                setState(() {
                  future = EcoClickAPI.getQuizzes();
                });
              },
            );
          }

          final items = snap.data ?? [];
          if (items.isEmpty) {
            return const Center(child: Text('No hay quizzes disponibles'));
          }

          // Construimos la lista con un encabezado (saludo) + las cards
          return ListView(
            padding: const EdgeInsets.all(12),
            children: [
              // 👇 Encabezado con saludo al usuario
              Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: FutureBuilder<String>(
                  future: getUsername(),
                  builder: (context, s) {
                    final name = s.data ?? 'Eco-Héroe';
                    return Text(
                      '¡Hola, $name!',
                      style: Theme.of(context).textTheme.titleLarge,
                    );
                  },
                ),
              ),

              // 👇 Lista de quizzes (con separadores manuales)
              for (int i = 0; i < items.length; i++) ...[
                Builder(
                  builder: (_) {
                    final q = items[i] as Map<String, dynamic>;
                    final questions = (q['questions'] as List?)?.length ?? 0;
                    return Card(
                      child: ListTile(
                        title: Text(q['title'] ?? 'Quiz'),
                        subtitle: Text(
                          'Categoría: ${q['category']} • Preguntas: $questions',
                        ),
                        trailing: const Icon(Icons.chevron_right),
                        onTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) =>
                                  QuizDetailPage(quizId: q['id'] as String),
                            ),
                          );
                        },
                      ),
                    );
                  },
                ),
                if (i != items.length - 1) const SizedBox(height: 8),
              ],
            ],
          );
        },
      ),
    );
  }
}

/// DETALLE + RESPUESTAS
class QuizDetailPage extends StatefulWidget {
  final String quizId;
  const QuizDetailPage({super.key, required this.quizId});

  @override
  State<QuizDetailPage> createState() => _QuizDetailPageState();
}

class _QuizDetailPageState extends State<QuizDetailPage> {
  Map<String, dynamic>? quiz;
  final Map<int, int> chosen = {}; // questionId -> chosenIndex
  final Stopwatch timer = Stopwatch();
  bool submitting = false;
  String? error;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    try {
      final item = await EcoClickAPI.getQuiz(widget.quizId);
      setState(() => quiz = item);
      timer
        ..reset()
        ..start();
    } catch (e) {
      setState(() => error = e.toString());
    }
  }

  int _calcScore() {
    if (quiz == null) return 0;
    final qs = (quiz!['questions'] as List<dynamic>)
        .cast<Map<String, dynamic>>();
    int correct = 0;
    for (final q in qs) {
      final id = q['id'] as int;
      final correctIndex = q['answerIndex'] as int?;
      if (correctIndex != null && chosen[id] == correctIndex) correct++;
    }
    return qs.isEmpty ? 0 : ((correct * 100) / qs.length).round();
  }

  Future<void> _submit() async {
    if (quiz == null) return;
    setState(() {
      submitting = true;
      error = null;
    });
    timer.stop();

    final answersList = chosen.entries
        .map((e) => {'questionId': e.key, 'chosenIndex': e.value})
        .toList();

    try {
      final score = _calcScore();
      final timeSec = (timer.elapsedMilliseconds / 1000).round();

      // 1) Enviar respuestas del quiz (flujo existente)
      await EcoClickAPI.postAnswers(
        quizId: quiz!['id'],
        userId: 1,
        answers: answersList,
        score: score,
        timeSec: timeSec,
      );

      // 2) NUEVO: guardar resultado por categoría
      await EcoClickAPI.postCategoryResult(
        userId: 1,
        category: quiz!['category'] as String, // ej: 'reciclaje'
        score: score,
      );

      // 3) SnackBar de confirmación del issue
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text('Resultado guardado')));
      }

      // 4) (opcional) feedback como ya lo hacías
      final fb = await EcoClickAPI.getFeedback(topic: quiz!['category']);
      final msg = fb.isNotEmpty
          ? (fb.first['message'] ?? '')
          : '¡Gracias por participar!';

      if (!mounted) return;
      showDialog(
        context: context,
        builder: (_) => AlertDialog(
          title: const Text('¡Respuestas enviadas!'),
          content: Text('Puntaje: $score%\nConsejo: $msg'),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('OK'),
            ),
          ],
        ),
      );
    } catch (e) {
      setState(() => error = e.toString());
    } finally {
      if (mounted) setState(() => submitting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (error != null) {
      return Scaffold(
        appBar: AppBar(title: const Text('Error')),
        body: ErrorRetryWidget(
          message:
              'No se pudo conectar con el servidor.\nRevisa tu conexión e intenta nuevamente.',
          onRetry: () {
            setState(() {
              error = null;
              quiz = null;
            });
            _load();
          },
        ),
      );
    }

    if (quiz == null) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    final questions = (quiz!['questions'] as List<dynamic>)
        .cast<Map<String, dynamic>>();
    return Scaffold(
      appBar: AppBar(title: Text(quiz!['title'] ?? 'Quiz')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Text('Categoría: ${quiz!['category']}'),
          const Divider(height: 24),
          ...questions.map((q) {
            final qid = q['id'] as int;
            final options = (q['options'] as List<dynamic>).cast<String>();
            return Card(
              margin: const EdgeInsets.symmetric(vertical: 8),
              child: Padding(
                padding: const EdgeInsets.all(8),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      q['text'] ?? '',
                      style: const TextStyle(fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 6),
                    ...List.generate(options.length, (i) {
                      return RadioListTile<int>(
                        title: Text(options[i]),
                        value: i,
                        groupValue: chosen[qid],
                        onChanged: (val) => setState(() => chosen[qid] = val!),
                      );
                    }),
                  ],
                ),
              ),
            );
          }),
          const SizedBox(height: 12),
          FilledButton.icon(
            onPressed: submitting ? null : _submit,
            icon: const Icon(Icons.send),
            label: Text(submitting ? 'Enviando...' : 'Enviar respuestas'),
          ),
        ],
      ),
    );
  }
}
