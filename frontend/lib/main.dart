import 'dart:async';
import 'package:animate_do/animate_do.dart';
import 'package:audioplayers/audioplayers.dart';
import 'package:flutter/material.dart';
import 'package:video_player/video_player.dart';
import 'api.dart';
import 'ui/theme.dart';
import 'screens/stats/stats_page.dart';
import 'ui/error_widget.dart';
import 'screens/login_page.dart';
import 'package:shared_preferences/shared_preferences.dart';

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
  late VideoPlayerController _controller;

  @override
  void initState() {
    super.initState();
    future = EcoClickAPI.getQuizzes();
    _controller = VideoPlayerController.asset('assets/videos/fondo.mp4')
      ..setLooping(true)
      ..setVolume(0)
      ..initialize().then((_) {
        setState(() {});
        _controller.play();
      });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Row(
          children: [
            SizedBox(
              width: 40,
              height: 40,
              child: Image.asset('assets/logo.png'),
            ),
            const SizedBox(width: 8),
            FutureBuilder<String>(
              future: SharedPreferences.getInstance().then(
                (prefs) => prefs.getString('username') ?? 'Eco-Héroe',
              ),
              builder: (context, snapshot) {
                final name = snapshot.data ?? '';
                return Text(
                  '¡Hola, $name!',
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Colors.green,
                  ),
                  overflow: TextOverflow.ellipsis,
                );
              },
            ),
          ],
        ),

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

      body: Stack(
        children: [
          if (_controller.value.isInitialized)
            SizedBox.expand(
              child: FittedBox(
                fit: BoxFit.cover,
                child: SizedBox(
                  width: _controller.value.size.width,
                  height: _controller.value.size.height,
                  child: VideoPlayer(_controller),
                ),
              ),
            ),
          FutureBuilder<List<dynamic>>(
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

              return GridView.builder(
                padding: const EdgeInsets.all(12),
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 3, // ← Ahora son 3 columnas por fila
                  childAspectRatio:
                      0.8, // ← Puedes ajustar este valor para el alto
                  crossAxisSpacing: 12,
                  mainAxisSpacing: 12,
                ),
                itemCount: items.length,
                itemBuilder: (context, index) {
                  final q = items[index] as Map<String, dynamic>;
                  final imagePath = q['image'] ?? 'assets/quizzes/default.jpg';
                  final title = q['title'] ?? 'Quiz';
                  final category = q['category'] ?? 'Sin categoría';
                  final description =
                      q['description'] ?? '¡Diviértete aprendiendo!';

                  return ZoomIn(
                    duration: Duration(
                      milliseconds: 400 + index * 100,
                    ), // efecto escalonado
                    child: Card(
                      color: Colors.lightGreen[50],
                      elevation: 4,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(18),
                      ),
                      child: InkWell(
                        borderRadius: BorderRadius.circular(18),
                        onTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) =>
                                  QuizDetailPage(quizId: q['id'] as String),
                            ),
                          );
                        },
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            ClipRRect(
                              borderRadius: const BorderRadius.only(
                                topLeft: Radius.circular(18),
                                topRight: Radius.circular(18),
                              ),
                              child: AspectRatio(
                                aspectRatio:
                                    1.2, // Imagen más cuadrada y visible
                                child: Image.asset(
                                  imagePath,
                                  fit: BoxFit.cover,
                                  width: double.infinity,
                                ),
                              ),
                            ),
                            Padding(
                              padding: const EdgeInsets.fromLTRB(8, 6, 8, 6),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    category.toUpperCase(),
                                    style: const TextStyle(
                                      fontWeight: FontWeight.bold,
                                      fontSize: 12,
                                      color: Colors.green,
                                      letterSpacing: 1,
                                    ),
                                  ),
                                  Text(
                                    title,
                                    style: const TextStyle(
                                      fontWeight: FontWeight.bold,
                                      fontSize: 13,
                                      color: Colors.black87,
                                    ),
                                  ),
                                  const SizedBox(height: 2),
                                  Text(
                                    description,
                                    style: const TextStyle(
                                      fontSize: 11,
                                      color: Colors.black54,
                                    ),
                                    maxLines: 2,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  );
                },
              );
            },
          ),
        ],
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
  final Map<int, int> chosen = {};
  int currentQuestion = 0;
  bool submitting = false;
  bool finished = false;
  String? error;
  int secondsLeft = 15;
  late List<Map<String, dynamic>> questions;
  late AudioPlayer _audioPlayer;
  late Stopwatch timer;
  late String musicPath;
  Timer? _timer;
  late VideoPlayerController _videoController;

  @override
  void initState() {
    super.initState();
    _load();
    _audioPlayer = AudioPlayer();
    musicPath = 'assets/music/kids_bg.wav';
    //_playMusic();
    _videoController = VideoPlayerController.asset('assets/videos/fondo.mp4')
      ..setLooping(true)
      ..setVolume(0)
      ..initialize().then((_) {
        setState(() {});
        _videoController.play();
      });
  }

  Future<void> _playMusic() async {
    await _audioPlayer.setReleaseMode(ReleaseMode.loop);
    await _audioPlayer.play(AssetSource(musicPath));
  }

  @override
  void dispose() {
    _audioPlayer.stop();
    _timer?.cancel();
    _videoController.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    try {
      final item = await EcoClickAPI.getQuiz(widget.quizId);
      setState(() => quiz = item);
      questions = (item['questions'] as List<dynamic>)
          .cast<Map<String, dynamic>>();
      timer = Stopwatch()..start();
      _startTimer();
    } catch (e) {
      setState(() => error = e.toString());
    }
  }

  void _startTimer() {
    _timer?.cancel();
    setState(() => secondsLeft = 15);
    _timer = Timer.periodic(const Duration(seconds: 1), (t) {
      if (!mounted || finished) {
        t.cancel();
        return;
      }
      setState(() {
        secondsLeft--;
        if (secondsLeft <= 0) {
          t.cancel();
          _nextQuestion();
        }
      });
    });
  }

  void _nextQuestion() {
    if (finished) return;
    _timer?.cancel();
    if (currentQuestion < questions.length - 1) {
      setState(() {
        currentQuestion++;
        secondsLeft = 15;
        _startTimer();
      });
    } else {
      finished = true;
      _submit();
    }
  }

  Future<void> _submit() async {
    if (submitting) return;
    setState(() {
      submitting = true;
      finished = true;
    });
    timer.stop();
    _timer?.cancel();
    final answersList = chosen.entries
        .map((e) => {'questionId': e.key, 'chosenIndex': e.value})
        .toList();
    try {
      final score = _calcScore();
      final timeSec = (timer.elapsedMilliseconds / 1000).round();
      await EcoClickAPI.postAnswers(
        quizId: quiz!['id'],
        userId: 1,
        answers: answersList,
        score: score,
        timeSec: timeSec,
      );
      await EcoClickAPI.postCategoryResult(
        userId: 1,
        category: quiz!['category'] as String,
        score: score,
      );
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text('Resultado guardado')));
      }
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

  int _calcScore() {
    if (quiz == null) return 0;
    int correct = 0;
    for (final q in questions) {
      final id = q['id'] as int;
      final correctIndex = q['answerIndex'] as int?;
      if (correctIndex != null && chosen[id] == correctIndex) correct++;
    }
    return questions.isEmpty ? 0 : ((correct * 100) / questions.length).round();
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

    final imagePath = quiz!['image'] ?? 'assets/quizzes/default.jpg';
    final title = quiz!['title'] ?? 'Quiz';
    final category = quiz!['category'] ?? 'Sin categoría';
    final description = quiz!['description'] ?? '';
    final q = questions[currentQuestion];
    final qid = q['id'] as int;
    final options = (q['options'] as List<dynamic>).cast<String>();
    final refImage = q['refImage'] ?? imagePath;

    return Scaffold(
      appBar: AppBar(title: Text(title)),
      body: Stack(
        children: [
          if (_videoController.value.isInitialized)
            SizedBox.expand(
              child: FittedBox(
                fit: BoxFit.cover,
                child: SizedBox(
                  width: _videoController.value.size.width,
                  height: _videoController.value.size.height,
                  child: VideoPlayer(_videoController),
                ),
              ),
            ),
          Center(
            child: Card(
              color: Colors.lightGreen[100],
              margin: const EdgeInsets.all(24),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(18),
              ),
              child: Padding(
                padding: const EdgeInsets.all(18),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    ClipRRect(
                      borderRadius: BorderRadius.circular(16),
                      child: Image.asset(
                        refImage,
                        width: 220,
                        height: 120,
                        fit: BoxFit.cover,
                      ),
                    ),
                    const SizedBox(height: 12),
                    Text(
                      category.toUpperCase(),
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 15,
                        color: Colors.green,
                      ),
                    ),
                    Text(
                      q['text'] ?? '',
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 20,
                        color: Colors.black87,
                      ),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 8),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(Icons.timer, color: Colors.green),
                        Text(
                          ' $secondsLeft s',
                          style: const TextStyle(
                            fontSize: 16,
                            color: Colors.green,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 14),
                    Wrap(
                      spacing: 12,
                      runSpacing: 12,
                      children: List.generate(options.length, (i) {
                        final isSelected = chosen[qid] == i;
                        return ElevatedButton(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: isSelected
                                ? Colors.green
                                : Colors.white,
                            foregroundColor: isSelected
                                ? Colors.white
                                : Colors.green,
                            minimumSize: const Size(120, 48),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(16),
                              side: BorderSide(
                                color: isSelected
                                    ? Colors.green
                                    : Colors.green.shade200,
                                width: 2,
                              ),
                            ),
                          ),
                          onPressed: () {
                            setState(() => chosen[qid] = i);
                            Future.delayed(
                              const Duration(milliseconds: 400),
                              _nextQuestion,
                            );
                          },
                          child: Text(
                            options[i],
                            style: const TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        );
                      }),
                    ),
                    const SizedBox(height: 18),
                    Text(
                      'Pregunta ${currentQuestion + 1} de ${questions.length}',
                      style: const TextStyle(
                        fontSize: 15,
                        color: Colors.black54,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
