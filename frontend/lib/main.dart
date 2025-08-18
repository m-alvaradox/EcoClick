import 'package:flutter/material.dart';
import 'api.dart';
import 'ui/theme.dart';
import 'ui/widgets.dart';

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
      home: const QuizListPage(),
    );
  }
}

/// ======================= LISTA DE QUIZZES (READ) =======================
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

  Future<void> _reload() async {
    setState(() => future = EcoClickAPI.getQuizzes());
    await future.catchError((_) {});
  }

  String _friendlyError(Object e) {
    final s = e.toString();
    if (s.contains('Failed host lookup') ||
        s.contains('ClientException') ||
        s.contains('Failed to fetch')) {
      return 'No se pudo conectar con el servidor.\nVerifica que el backend esté en 127.0.0.1:4000';
    }
    return 'Ocurrió un error cargando los quizzes.\n$e';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Quizzes EcoClick')),
      body: FutureBuilder<List<dynamic>>(
        future: future,
        builder: (context, snap) {
          if (snap.connectionState != ConnectionState.done) {
            return const LoadingView(message: 'Cargando quizzes...');
          }
          if (snap.hasError) {
            return ErrorView(
              message: _friendlyError(snap.error!),
              onRetry: _reload,
            );
          }
          final items = snap.data ?? [];
          if (items.isEmpty) {
            return EmptyView(
              message: 'Sin quizzes por ahora.',
              onRetry: _reload,
            );
          }
          return RefreshIndicator(
            onRefresh: _reload,
            child: ListView.separated(
              physics: const AlwaysScrollableScrollPhysics(),
              padding: const EdgeInsets.all(12),
              itemCount: items.length,
              separatorBuilder: (_, __) => const SizedBox(height: 8),
              itemBuilder: (context, i) {
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
          );
        },
      ),
    );
  }
}

/// ======================= DETALLE + ENVÍO + FEEDBACK =======================
class QuizDetailPage extends StatefulWidget {
  final String quizId;
  const QuizDetailPage({super.key, required this.quizId});

  @override
  State<QuizDetailPage> createState() => _QuizDetailPageState();
}

class _QuizDetailPageState extends State<QuizDetailPage> {
  Map<String, dynamic>? quiz;
  Object? error;
  final Map<int, int> chosen = {}; // questionId -> chosenIndex
  final Stopwatch timer = Stopwatch();
  bool submitting = false;

  @override
  void initState() {
    super.initState();
    _load();
  }

  String _friendlyError(Object e) {
    final s = e.toString();
    if (s.contains('Failed host lookup') ||
        s.contains('ClientException') ||
        s.contains('Failed to fetch')) {
      return 'No se pudo conectar con el servidor.\nVerifica que el backend esté en 127.0.0.1:4000';
    }
    return 'Ocurrió un error cargando el quiz.\n$e';
  }

  Future<void> _load() async {
    setState(() {
      quiz = null;
      error = null;
    });
    try {
      final item = await EcoClickAPI.getQuiz(widget.quizId);
      setState(() => quiz = item);
      timer
        ..reset()
        ..start();
    } catch (e) {
      setState(() => error = e);
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
    setState(() => submitting = true);
    timer.stop();

    final answersList = chosen.entries
        .map((e) => {'questionId': e.key, 'chosenIndex': e.value})
        .toList();

    final score = _calcScore();
    final timeSec = (timer.elapsedMilliseconds / 1000).round();

    try {
      await EcoClickAPI.postAnswers(
        quizId: quiz!['id'],
        userId: 1, // TODO: reemplazar cuando tengan auth
        answers: answersList,
        score: score,
        timeSec: timeSec,
      );

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
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error al enviar: $e'),
          backgroundColor: Theme.of(context).colorScheme.error,
        ),
      );
    } finally {
      if (mounted) setState(() => submitting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (error != null) {
      return Scaffold(
        appBar: AppBar(),
        body: ErrorView(message: _friendlyError(error!), onRetry: _load),
      );
    }
    if (quiz == null) {
      return const Scaffold(body: LoadingView(message: 'Cargando quiz...'));
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
                padding: const EdgeInsets.all(12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      q['text'] ?? '',
                      style: const TextStyle(fontWeight: FontWeight.bold),
                    ),
                    Gaps.s,
                    ...List.generate(options.length, (i) {
                      return RadioListTile<int>(
                        title: Text(options[i]),
                        value: i,
                        groupValue: chosen[qid],
                        onChanged: (val) => setState(() => chosen[qid] = val!),
                        dense: true,
                        contentPadding: EdgeInsets.zero,
                      );
                    }),
                  ],
                ),
              ),
            );
          }),
          Gaps.l,
          FilledButton.icon(
            onPressed: submitting ? null : _submit,
            icon: const Icon(Icons.send),
            label: Text(submitting ? 'Enviando...' : 'Enviar respuestas'),
          ),
          Gaps.xl,
        ],
      ),
    );
  }
}
