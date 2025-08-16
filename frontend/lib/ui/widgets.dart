import 'package:flutter/material.dart';

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
