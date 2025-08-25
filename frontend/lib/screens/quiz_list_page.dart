import 'package:flutter/material.dart';
import 'package:video_player/video_player.dart';
import 'package:animate_do/animate_do.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../api.dart';
import '../ui/error_widget.dart';
import 'quiz_detail_page.dart';
import 'stats/stats_page.dart';
import 'login_page.dart';
import 'package:frontend/screens/comments/comments_page.dart';

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
            tooltip: 'Comentarios',
            icon: const Icon(Icons.comment),
            onPressed: () async {
              final prefs = await SharedPreferences.getInstance();
              final username = prefs.getString('username') ?? 'Eco-Héroe';
              final userId =
                  prefs.getInt('userId') ?? 1; // ID temporal si no hay login

              Navigator.of(context).push(
                MaterialPageRoute(
                  builder: (_) =>
                      CommentsPage(userId: userId, userName: username),
                ),
              );
            },
          ),

          IconButton(
            tooltip: 'Progreso',
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
                  crossAxisCount: 3,
                  childAspectRatio: 0.8,
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
                    duration: Duration(milliseconds: 400 + index * 100),
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
                                aspectRatio: 1.2,
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
