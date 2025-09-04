import 'package:flutter/material.dart';
import '../../ui/widgets.dart';
import '../../api.dart';
import 'package:frontend/ui/error_widget.dart';
import 'package:frontend/utils/prefers.dart';

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
        title: const Text('Progreso del usuario'),
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
            return ErrorRetryWidget(
              icon: Icons.error_outline,
              message:
                  'No se pudo conectar con el servidor.\nRevisa tu conexión e intenta nuevamente.',
              onRetry: _reload,
            );
          }

          final data = snap.data ?? const {};
          final summary = (data['summary'] ?? {}) as Map<String, dynamic>;
          final categories = (data['categories'] ?? []) as List<dynamic>;

          final totalSessions = (summary['totalSessions'] ?? 0) as num;
          final totalAnswers = (summary['totalAnswers'] ?? 0) as num;
          final avgScore = (summary['avgScore'] ?? 0) as num;
          final totalProgressPoints = (summary['totalProgressPoints'] ?? 0) as num;
          final level              = (summary['level'] ?? 1) as num;
          final levelProgress      = ((summary['levelProgress'] ?? 0) as num).toDouble();


          


          // --- EMPTY ---
          final isEmpty =
              (totalSessions == 0 && totalAnswers == 0) && (categories.isEmpty);
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
                
                FutureBuilder<String>(
                  future: getUsername(),
                  builder: (_, s) => ProgressSummaryCard(
                    totalPoints: totalProgressPoints.toInt(),
                    level: level.toInt(),
                    progress: levelProgress.clamp(0, 1),
                    username: s.data,
                  ),
                ),

                _SummaryCards(
                  totalSessions: totalSessions,
                  avgScore: avgScore,
                ),

                Text(
                  'Gráfico (promedio % por categoría)',
                  style: Theme.of(context).textTheme.titleMedium,
                ),
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
                Text(
                  'Por categoría',
                  style: Theme.of(context).textTheme.titleMedium,
                ),
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
                            Text(
                              catAvg.toStringAsFixed(1),
                              style: const TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 16,
                              ),
                            ),
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
    required this.avgScore,
  });

  final num totalSessions;
  final num avgScore;

  @override
  Widget build(BuildContext context) {
    final items = [
      (_StatTileData(
        'Sesiones',
        totalSessions.toString(),
        Icons.event_available,
      )),
      (_StatTileData(
        'Promedio',
        avgScore.toStringAsFixed(1)     ,
        Icons.bar_chart,
      )),
    ];

    return LayoutBuilder(
      builder: (_, c) {
        return Wrap(
          spacing: 12,
          runSpacing: 12,
          alignment: WrapAlignment.center,
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
                            Text(
                              it.title,
                              style: Theme.of(context).textTheme.labelMedium,
                            ),
                            const SizedBox(height: 4),
                            Text(
                              it.value,
                              style: Theme.of(context).textTheme.titleLarge
                                  ?.copyWith(fontWeight: FontWeight.bold),
                            ),
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
            ],
          ],
        ),
      ),
    );
  }
}

class ProgressSummaryCard extends StatelessWidget {
  const ProgressSummaryCard({
    super.key,
    required this.totalPoints,
    required this.level,
    required this.progress, // 0..1
    this.username,
  });

  final int totalPoints;
  final int level;
  final double progress;
  final String? username;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(color: theme.colorScheme.outlineVariant, width: 1),
      ),
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(16),
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              theme.colorScheme.primary.withOpacity(.14),
              theme.colorScheme.tertiary.withOpacity(.10),
            ],
          ),
        ),
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            // Encabezado
            Row(
              children: [
                const CircleAvatar(radius: 22, child: Icon(Icons.person)),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Mi Progreso',
                        style: theme.textTheme.titleLarge?.copyWith(
                          fontWeight: FontWeight.w800,
                        )),
                      Text(
                        username == null ? '¡Mira qué bien lo haces!' : '¡Sigue así, $username!',
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: theme.colorScheme.onSurface.withOpacity(.7),
                        ),
                      ),
                    ],
                  ),
                ),
                _chip(icon: Icons.cloud_done, label: 'Conectado'),
              ],
            ),
            const SizedBox(height: 16),

            // Tarjeta interna "Mis Números"
            Container(
              width: double.infinity,
              decoration: BoxDecoration(
                color: theme.colorScheme.surface,
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: theme.colorScheme.outlineVariant),
                boxShadow: [BoxShadow(
                  color: Colors.black.withOpacity(.06),
                  blurRadius: 8, offset: const Offset(0, 3),
                )],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Banda superior
                  Container(
                    padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 14),
                    decoration: BoxDecoration(
                      borderRadius: const BorderRadius.vertical(top: Radius.circular(14)),
                      gradient: LinearGradient(colors: [Colors.orange.shade400, Colors.orange.shade600]),
                    ),
                    child: Row(
                      children: [
                        const Icon(Icons.emoji_events_outlined, color: Colors.white),
                        const SizedBox(width: 8),
                        Text('Mis Números',
                          style: theme.textTheme.titleMedium?.copyWith(
                            color: Colors.white, fontWeight: FontWeight.w800,
                          )),
                      ],
                    ),
                  ),

                  // Contenido
                  Padding(
                    padding: const EdgeInsets.all(14),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _rowMetric(
                          context,
                          title: 'Puntos Totales',
                          trailing: _chip(
                            icon: Icons.star_rounded,
                            label: '$totalPoints',
                            bg: Colors.amber.shade400, fg: Colors.black,
                          ),
                        ),
                        const SizedBox(height: 10),
                        _rowMetric(
                          context,
                          title: 'Mi Nivel',
                          trailing: _chip(
                            icon: Icons.track_changes_rounded,
                            label: 'Nivel $level',
                            bg: const Color(0xFF9C6BFF), fg: Colors.white,
                          ),
                        ),
                        const SizedBox(height: 14),
                        Text('Siguiente Nivel', style: theme.textTheme.bodyMedium),
                        const SizedBox(height: 6),
                        ClipRRect(
                          borderRadius: BorderRadius.circular(6),
                          child: LinearProgressIndicator(
                            value: progress.clamp(0, 1), minHeight: 10,
                          ),
                        ),
                        const SizedBox(height: 6),
                        Text('${(progress * 100).toStringAsFixed(0)}% • ¡Ya casi llegas!',
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: theme.colorScheme.onSurface.withOpacity(.7),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  static Widget _rowMetric(BuildContext context, {required String title, required Widget trailing}) {
    final theme = Theme.of(context);
    return Row(
      children: [
        Expanded(child: Text(title, style: theme.textTheme.bodyLarge?.copyWith(fontWeight: FontWeight.w600))),
        trailing,
      ],
    );
  }

  static Widget _chip({required IconData icon, required String label, Color? bg, Color? fg}) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: bg ?? const Color(0xFFEDEEF2),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: Colors.black.withOpacity(.06)),
      ),
      child: Row(mainAxisSize: MainAxisSize.min, children: [
        Icon(icon, size: 16, color: fg ?? Colors.black87),
        const SizedBox(width: 6),
        Text(label, style: TextStyle(color: fg ?? Colors.black87, fontWeight: FontWeight.w800)),
      ]),
    );
  }
}
