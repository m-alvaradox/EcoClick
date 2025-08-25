import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

class CommentsPage extends StatefulWidget {
  final int userId;
  final String userName;

  const CommentsPage({Key? key, required this.userId, required this.userName}) : super(key: key);

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

  // Traer comentarios
  Future<List<dynamic>> fetchComments() async {
    final response = await http.get(Uri.parse('http://localhost:4000/comments'));
    if (response.statusCode == 200) {
      return json.decode(response.body);
    } else {
      throw Exception('Error al cargar comentarios');
    }
  }

  // Agregar un comentario
  Future<void> addComment(String commentText) async {
    final response = await http.post(
      Uri.parse('http://localhost:4000/comments'),
      headers: {'Content-Type': 'application/json'},
      body: json.encode({
        'userId': widget.userId,
        'comment': commentText,
      }),
    );

    if (response.statusCode == 201) {
      // Refrescar lista
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
                  return Center(child: Text('Error: ${snapshot.error}'));
                } else if (!snapshot.hasData || snapshot.data!.isEmpty) {
                  return const Center(child: Text('No hay comentarios'));
                }

                final comments = snapshot.data!;
                return ListView.builder(
                  itemCount: comments.length,
                  itemBuilder: (context, index) {
                    final comment = comments[index];
                    return Card(
                      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
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
                      hintText: 'Escribe un comentario...',
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
                  style: ElevatedButton.styleFrom(backgroundColor: Colors.green),
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

