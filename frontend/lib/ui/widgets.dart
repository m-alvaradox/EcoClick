import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import '../api.dart';


/// Espaciados consistentes
class Gaps {
  static const s = SizedBox(height: 8, width: 8);
  static const m = SizedBox(height: 12, width: 12);
  static const l = SizedBox(height: 16, width: 16);
  static const xl = SizedBox(height: 24, width: 24);
}

/// Contenedor responsive con ancho máximo
class Responsive extends StatelessWidget {
  final Widget child;
  final double maxWidth;
  const Responsive({super.key, required this.child, this.maxWidth = 1100});

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, c) {
        final w = c.maxWidth;
        final pad = w > maxWidth ? (w - maxWidth) / 2 : 16.0;
        return Padding(
          padding: EdgeInsets.symmetric(horizontal: pad),
          child: child,
        );
      },
    );
  }
}

/// Estados estándar
class LoadingView extends StatelessWidget {
  final String? message;
  const LoadingView({super.key, this.message});
  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const CircularProgressIndicator(),
          if (message != null) ...[Gaps.m, Text(message!)],
        ],
      ),
    );
  }
}

class EmptyView extends StatelessWidget {
  final IconData icon;
  final String message;
  final VoidCallback? onRetry;
  const EmptyView({
    super.key,
    this.icon = Icons.inbox_outlined,
    required this.message,
    this.onRetry,
  });
  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 48, color: Theme.of(context).colorScheme.outline),
          Gaps.m,
          Text(message, textAlign: TextAlign.center),
          if (onRetry != null) ...[
            Gaps.m,
            OutlinedButton.icon(
              onPressed: onRetry,
              icon: const Icon(Icons.refresh),
              label: const Text('Reintentar'),
            ),
          ],
        ],
      ),
    );
  }
}

class ErrorView extends StatelessWidget {
  final String message;
  final VoidCallback onRetry;
  const ErrorView({super.key, required this.message, required this.onRetry});
  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            Icons.error_outline,
            size: 48,
            color: Theme.of(context).colorScheme.error,
          ),
          Gaps.m,
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Text(message, textAlign: TextAlign.center),
          ),
          Gaps.m,
          FilledButton.icon(
            onPressed: onRetry,
            icon: const Icon(Icons.refresh),
            label: const Text('Reintentar'),
          ),
        ],
      ),
    );
  }
}

/// Tarjeta de estadística simple
class StatCard extends StatelessWidget {
  final String title;
  final String value;
  const StatCard({super.key, required this.title, required this.value});
  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(title, style: const TextStyle(color: Colors.black54)),
            Gaps.s,
            Text(value, style: Theme.of(context).textTheme.headlineSmall),
          ],
        ),
      ),
    );
  }
}

/// Helpers de SnackBars
void showOkSnack(BuildContext ctx, String msg) {
  ScaffoldMessenger.of(ctx).showSnackBar(SnackBar(content: Text(msg)));
}

void showErrSnack(BuildContext ctx, String msg) {
  final scheme = Theme.of(ctx).colorScheme;
  ScaffoldMessenger.of(ctx).showSnackBar(
    SnackBar(
      content: Text(msg),
      backgroundColor: scheme.error,
      behavior: SnackBarBehavior.floating,
    ),
  );
}

// ------------------------------
// Botón para enviar quiz + guardar resultado por categoría
// ------------------------------
class SubmitQuizButton extends StatefulWidget {
  const SubmitQuizButton({
    super.key,
    required this.quizId,
    required this.userId,
    required this.category,
    required this.answers,
    required this.score,
    required this.timeSec,
    this.onSuccess, // opcional: callback cuando todo sale bien
  });

  final String quizId;
  final int userId;
  final String category;
  final List<Map<String, dynamic>> answers;
  final int score;
  final int timeSec;
  final VoidCallback? onSuccess;

  @override
  State<SubmitQuizButton> createState() => _SubmitQuizButtonState();
}

class _SubmitQuizButtonState extends State<SubmitQuizButton> {
  bool _loading = false;

  Future<void> _handleSubmit() async {
    if (_loading) return;
    setState(() => _loading = true);

    try {
      // 1) Enviar respuestas del quiz (flujo existente)
      await EcoClickAPI.postAnswers(
        quizId: widget.quizId,
        userId: widget.userId,
        answers: widget.answers,
        score: widget.score,
        timeSec: widget.timeSec,
      );

      // 2) Guardar el resultado por categoría (NUEVO)
      await EcoClickAPI.postCategoryResult(
        userId: widget.userId,
        category: widget.category,
        score: widget.score,
      );

      if (!mounted) return;
      showOkSnack(context, 'Resultado guardado');
      widget.onSuccess?.call();
    } catch (e) {
      if (!mounted) return;
      showErrSnack(context, 'No se pudo guardar: $e');
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return FilledButton.icon(
      onPressed: _loading ? null : _handleSubmit,
      icon: _loading
          ? const SizedBox(
              width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2))
          : const Icon(Icons.send),
      label: Text(_loading ? 'Enviando…' : 'Enviar quiz'),
    );
  }
}



class CategoryBarChart extends StatelessWidget {
  const CategoryBarChart({
    super.key,
    required this.categories, // List<Map>: [{category, avgScore, attempts}, ...]
    this.height = 260,
  });

  final List<Map<String, dynamic>> categories;
  final double height;

  @override
  Widget build(BuildContext context) {
    if (categories.isEmpty) {
      return const Text('Sin datos para graficar.');
    }

    // Extrae labels y valores
    final labels = <String>[];
    final rawValues = <double>[];
    for (final m in categories) {
      labels.add('${(m['category'] ?? '').toString()}');
      final v = (m['avgScore'] ?? 0);
      rawValues.add(v is num ? v.toDouble() : double.tryParse('$v') ?? 0);
    }

    // Normaliza si vienen como 0..1 → multiplica a %
    final maxRaw = rawValues.fold<double>(0, (p, c) => c > p ? c : p);
    final values = maxRaw <= 1.0
        ? rawValues.map((e) => e * 100).toList()
        : rawValues;

    // maxY redondeado hacia arriba al múltiplo de 10 más cercano (mínimo 100)
    double maxY = values.fold<double>(0, (p, c) => c > p ? c : p);
    maxY = maxY < 100 ? 100 : (maxY / 10).ceil() * 10;
    final interval = (maxY / 5).clamp(10, 50);

    String _short(String s, int max) =>
        s.length <= max ? s : s.substring(0, max - 1) + '…';

    return LayoutBuilder(
      builder: (context, c) {
        final veryTight = c.maxWidth < 330;
        final tight = c.maxWidth < 380;
        final barWidth = veryTight ? 10.0 : (tight ? 14.0 : 18.0);
        final textStyle = Theme.of(context).textTheme.bodySmall;

        final barColor = Theme.of(context).colorScheme.primary;

        return SizedBox(
          height: height,
          child: BarChart(
            BarChartData(
              minY: 0,
              maxY: maxY,
              groupsSpace: 12,
              alignment: BarChartAlignment.spaceAround,
              barTouchData: BarTouchData(
                enabled: true,
                touchTooltipData: BarTouchTooltipData(
                  tooltipBgColor: Colors.black87,
                  getTooltipItem: (group, gi, rod, ri) => BarTooltipItem(
                    '${labels[gi]}\n${rod.toY.toStringAsFixed(1)}%',
                    const TextStyle(color: Colors.white),
                  ),
                ),
              ),
              titlesData: FlTitlesData(
                topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                leftTitles: AxisTitles(
                  axisNameWidget: Text('%', style: textStyle),
                  sideTitles: SideTitles(
                    showTitles: true,
                    reservedSize: 36,
                    interval: interval.toDouble(),
                    getTitlesWidget: (value, meta) => Text(
                      '${value.toInt()}',
                      style: textStyle,
                    ),
                  ),
                ),
                bottomTitles: AxisTitles(
                  sideTitles: SideTitles(
                    showTitles: true,
                    getTitlesWidget: (value, meta) {
                      final i = value.toInt();
                      if (i < 0 || i >= labels.length) {
                        return const SizedBox.shrink();
                      }
                      final label = veryTight
                          ? _short(labels[i], 6)
                          : (tight ? _short(labels[i], 10) : labels[i]);
                      return SideTitleWidget(
                        axisSide: meta.axisSide,
                        space: 8,
                        child: Transform.rotate(
                          angle: tight ? -0.6 : 0, // ~-34° en pantallas estrechas
                          child: Text(label, style: textStyle, textAlign: TextAlign.center),
                        ),
                      );
                    },
                  ),
                ),
              ),
              gridData: FlGridData(
                show: true,
                drawVerticalLine: false,
                horizontalInterval: interval.toDouble(),
              ),
              borderData: FlBorderData(
                show: true,
                border: Border.all(
                  color: Theme.of(context).dividerColor,
                ),
              ),
              barGroups: List.generate(values.length, (i) {
                return BarChartGroupData(
                  x: i,
                  barRods: [
                    BarChartRodData(
                      toY: values[i],
                      width: barWidth,
                      color: barColor,
                      borderRadius: BorderRadius.circular(4),
                    ),
                  ],
                );
              }),
            ),
          ),
        );
      },
    );
  }
}
