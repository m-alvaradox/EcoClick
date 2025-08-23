import 'package:flutter/material.dart';
import '../../ui/widgets.dart';
import '../../api.dart';

class UserStatsPage extends StatefulWidget {
  const UserStatsPage({super.key, required this.userId});
  final int userId;

  @override
  State<UserStatsPage> createState() => _UserStatsPageState();
}

class _UserStatsPageState extends State<UserStatsPage> {
  late Future<Map<String, dynamic>> _future;

  @override
  void initState() {
    super.initState();
    _future = EcoClickAPI.getUserStatsResponses(userId: widget.userId);
  }

  void _reload() {
    setState(() {
      _future = EcoClickAPI.getUserStatsResponses(userId: widget.userId);
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Estadísticas del usuario'),
        actions: [
          IconButton(
            tooltip: 'Actualizar',
            onPressed: _reload,
            icon: const Icon(Icons.refresh),
          ),
        ],
      ),
      body: FutureBuilder<Map<String, dynamic>>(
        future: _future,
        builder: (context, snap) {
          // --- LOADING ---
          if (snap.connectionState != ConnectionState.done) {
            return const Center(child: CircularProgressIndicator());
          }

          // --- ERROR ---
          if (snap.hasError) {
            return _StateMessage(
              icon: Icons.error_outline,
              message: 'No se pudieron cargar las estadísticas.\n${snap.error}',
              onRetry: _reload,
            );
          }

          final data = snap.data ?? const {};
          final summary = (data['summary'] ?? {}) as Map<String, dynamic>;
          final categories = (data['categories'] ?? []) as List<dynamic>;

          final totalSessions = (summary['totalSessions'] ?? 0) as num;
          final totalAnswers = (summary['totalAnswers'] ?? 0) as num;
          final avgScore = (summary['avgScore'] ?? 0) as num;

          // --- EMPTY ---
          final isEmpty = (totalSessions == 0 && totalAnswers == 0) &&
              (categories.isEmpty);
          if (isEmpty) {
            return _StateMessage(
              icon: Icons.inbox_outlined,
              message: 'Aún no hay estadísticas para mostrar.',
              onRetry: _reload,
            );
          }

          // --- CONTENT ---
          return RefreshIndicator(
            onRefresh: () async => _reload(),
            child: ListView(
              padding: const EdgeInsets.all(16),
              children: [
              _SummaryCards(
                totalSessions: totalSessions,
                totalAnswers: totalAnswers,
                avgScore: avgScore,
              ),
              const SizedBox(height: 16),

              Text('Gráfico (promedio % por categoría)',
                  style: Theme.of(context).textTheme.titleMedium),
              const SizedBox(height: 8),
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(12.0),
                  child: CategoryBarChart(
                    categories: categories.cast<Map<String, dynamic>>(),
                    height: 260, // puedes ajustar
                  ),
                ),
              ),

const SizedBox(height: 16),
Text('Por categoría', style: Theme.of(context).textTheme.titleMedium),
                const SizedBox(height: 8),
                if (categories.isEmpty)
                  const Text('Sin datos por categoría.')
                else
                  ...categories.map((c) {
                    final m = c as Map<String, dynamic>;
                    final cat = (m['category'] ?? '') as String;
                    final catAvg = (m['avgScore'] ?? 0) as num;
                    final attempts = (m['attempts'] ?? 0) as num;

                    return Card(
                      margin: const EdgeInsets.symmetric(vertical: 6),
                      child: ListTile(
                        leading: const Icon(Icons.label_important_outline),
                        title: Text(cat.isEmpty ? '(sin categoría)' : cat),
                        subtitle: Text('Intentos: $attempts'),
                        trailing: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Text('${catAvg.toStringAsFixed(1)}',
                                style: const TextStyle(
                                    fontWeight: FontWeight.bold, fontSize: 16)),
                            const Text('promedio'),
                          ],
                        ),
                      ),
                    );
                  }),
                const SizedBox(height: 24),
                FilledButton.icon(
                  onPressed: _reload,
                  icon: const Icon(Icons.refresh),
                  label: const Text('Actualizar'),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}

/// --- UI helpers ---

class _SummaryCards extends StatelessWidget {
  const _SummaryCards({
    required this.totalSessions,
    required this.totalAnswers,
    required this.avgScore,
  });

  final num totalSessions;
  final num totalAnswers;
  final num avgScore;

  @override
  Widget build(BuildContext context) {
    final items = [
      (_StatTileData('Sesiones', totalSessions.toString(), Icons.event_available)),
      (_StatTileData('Respuestas', totalAnswers.toString(), Icons.fact_check_outlined)),
      (_StatTileData('Promedio', '${avgScore.toStringAsFixed(1)}', Icons.bar_chart)),
    ];

    return LayoutBuilder(
      builder: (_, c) {
        return Wrap(
          spacing: 12,
          runSpacing: 12,
          children: items.map((it) {
            return SizedBox(
              width: 220, // responsivo simple
              child: Card(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Row(
                    children: [
                      Icon(it.icon, size: 28),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(it.title,
                                style: Theme.of(context).textTheme.labelMedium),
                            const SizedBox(height: 4),
                            Text(it.value,
                                style: Theme.of(context)
                                    .textTheme
                                    .titleLarge
                                    ?.copyWith(fontWeight: FontWeight.bold)),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            );
          }).toList(),
        );
      },
    );
  }
}

class _StatTileData {
  final String title;
  final String value;
  final IconData icon;
  _StatTileData(this.title, this.value, this.icon);
}

class _StateMessage extends StatelessWidget {
  const _StateMessage({
    required this.icon,
    required this.message,
    this.onRetry,
  });

  final IconData icon;
  final String message;
  final VoidCallback? onRetry;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 48, color: Theme.of(context).colorScheme.outline),
            const SizedBox(height: 12),
            Text(message, textAlign: TextAlign.center),
            if (onRetry != null) ...[
              const SizedBox(height: 12),
              OutlinedButton.icon(
                onPressed: onRetry,
                icon: const Icon(Icons.refresh),
                label: const Text('Reintentar'),
              ),
            ]
          ],
        ),
      ),
    );
  }
}
