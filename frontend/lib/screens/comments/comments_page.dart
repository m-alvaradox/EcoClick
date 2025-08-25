import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:frontend/ui/error_widget.dart';
import 'package:frontend/utils/prefers.dart';

class CommentsPage extends StatefulWidget {
  const CommentsPage({super.key, required this.userId});
  final int userId;

  @override
  State<CommentsPage> createState() => _CommentsPageState();
}

class _CommentsPageState extends State<CommentsPage> {
  late Future<List<dynamic>> commentsFuture;
  final TextEditingController _controller = TextEditingController();

  @override
  void initState() {
    super.initState();
    commentsFuture = fetchComments();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  // Traer comentarios
  Future<List<dynamic>> fetchComments() async {
    final response = await http.get(
      Uri.parse('http://localhost:4000/comments'),
    );
    if (response.statusCode == 200) {
      return json.decode(response.body);
    } else {
      throw Exception('Error al cargar comentarios');
    }
  }

  // Agregar un comentario
  Future<void> addComment(String commentText) async {
    final userName = await getUsername(); // Espera el nombre

    final response = await http.post(
      Uri.parse('http://localhost:4000/comments'),
      headers: {'Content-Type': 'application/json'},
      body: json.encode({
        'userId': widget.userId,
        'userName': userName, // Usa el nombre obtenido
        'comment': commentText,
      }),
    );

    if (response.statusCode == 201) {
      setState(() {
        commentsFuture = fetchComments();
        _controller.clear();
      });
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Error al agregar comentario')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Comentarios'),
        backgroundColor: Colors.green,
      ),
      body: Column(
        children: [
          // Lista de comentarios
          Expanded(
            child: FutureBuilder<List<dynamic>>(
              future: commentsFuture,
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                } else if (snapshot.hasError) {
                  // Implementación del ErrorRetryWidget
                  return ErrorRetryWidget(
                    message:
                        'Error al cargar los comentarios. Intenta nuevamente.',
                    onRetry: () {
                      setState(() {
                        commentsFuture = fetchComments();
                      });
                    },
                  );
                } else if (!snapshot.hasData || snapshot.data!.isEmpty) {
                  return const Center(child: Text('No hay comentarios'));
                }

                final comments = snapshot.data!;
                return ListView.builder(
                  itemCount: comments.length,
                  itemBuilder: (context, index) {
                    final comment = comments[index];
                    return Card(
                      margin: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 8,
                      ),
                      child: ListTile(
                        leading: const Icon(Icons.comment, color: Colors.green),
                        title: Text(comment['comment']),
                        subtitle: Text('Por ${comment['userName']}'),
                      ),
                    );
                  },
                );
              },
            ),
          ),

          // Campo de texto para agregar comentario
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _controller,
                    decoration: const InputDecoration(
                      hintText: 'Escribe un comentario.',
                      border: OutlineInputBorder(),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                ElevatedButton(
                  onPressed: () {
                    final text = _controller.text.trim();
                    if (text.isNotEmpty) addComment(text);
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.green,
                  ),
                  child: const Text('Enviar'),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
