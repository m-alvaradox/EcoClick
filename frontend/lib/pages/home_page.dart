import 'package:flutter/material.dart';
import '../api.dart';
import 'achievements_page.dart';
import 'progress_page.dart';
import 'quizzes_page.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});
  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  late Future<List<dynamic>> futureUsers;
  int? selectedUserId;

  @override
  void initState() {
    super.initState();
    futureUsers = EcoClickAPI.getUsers();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('EcoClick')),
      body: FutureBuilder<List<dynamic>>(
        future: futureUsers,
        builder: (context, snap) {
          if (snap.connectionState != ConnectionState.done) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snap.hasError) {
            return Center(child: Text('Error: ${snap.error}'));
          }
          final users = snap.data ?? [];
          return Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                DropdownButtonFormField<int>(
                  decoration: const InputDecoration(labelText: 'Elige un usuario'),
                  items: users.map((u) {
                    final m = u as Map<String, dynamic>;
                    return DropdownMenuItem<int>(
                      value: m['id'] as int,
                      child: Text(m['name'] ?? 'User'),
                    );
                  }).toList(),
                  value: selectedUserId,
                  onChanged: (v) => setState(() => selectedUserId = v),
                ),
                const SizedBox(height: 20),
                FilledButton.icon(
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(builder: (_) => const QuizzesPage()),
                    );
                  },
                  icon: const Icon(Icons.quiz),
                  label: const Text('Ver Quizzes'),
                ),
                const SizedBox(height: 8),
                FilledButton.icon(
                  onPressed: selectedUserId == null ? null : () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(builder: (_) => AchievementsPage(userId: selectedUserId!)),
                    );
                  },
                  icon: const Icon(Icons.emoji_events),
                  label: const Text('Ver Logros'),
                ),
                const SizedBox(height: 8),
                FilledButton.icon(
                  onPressed: selectedUserId == null ? null : () async {
                    final changed = await Navigator.push<bool>(
                      context,
                      MaterialPageRoute(builder: (_) => ProgressForm(userId: selectedUserId!)),
                    );
                    if (changed == true && mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('Logro registrado')),
                      );
                    }
                  },
                  icon: const Icon(Icons.add_task),
                  label: const Text('Registrar Logro'),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}
