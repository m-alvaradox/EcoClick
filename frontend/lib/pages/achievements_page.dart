import 'package:flutter/material.dart';
import '../api.dart';

class AchievementsPage extends StatelessWidget {
  final int userId;
  const AchievementsPage({super.key, required this.userId});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Mis Logros')),
      body: FutureBuilder<List<dynamic>>(
        future: EcoClickAPI.getUserAchievements(userId),
        builder: (context, snap) {
          if (snap.connectionState != ConnectionState.done) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snap.hasError) {
            return Center(child: Text('Error: ${snap.error}'));
          }
          final achievements = snap.data ?? [];
          if (achievements.isEmpty) {
            return const Center(child: Text('No hay logros'));
          }
          return ListView.separated(
            padding: const EdgeInsets.all(12),
            itemCount: achievements.length,
            separatorBuilder: (_, __) => const SizedBox(height: 8),
            itemBuilder: (context, index) {
              final a = achievements[index];
              return Card(
                child: ListTile(
                  title: Text(a['name'] ?? 'Sin nombre'),
                  subtitle: Text('${a['description'] ?? ''}\nPuntos: ${a['points'] ?? 0}'),
                  trailing: Text('${a['date'].substring(0, 10)}'),
                ),
              );
            },
          );
        },
      ),
    );
  }
}
