import 'package:flutter/material.dart';
import '../api.dart';

class ProgressForm extends StatefulWidget {
  final int userId;
  const ProgressForm({super.key, required this.userId});

  @override
  State<ProgressForm> createState() => _ProgressFormState();
}

class _ProgressFormState extends State<ProgressForm> {
  int? selectedAchievementId;
  bool submitting = false;
  String? error;

  late Future<List<dynamic>> futureAchievements;

  @override
  void initState() {
    super.initState();
    futureAchievements = EcoClickAPI.getAllAchievements();
  }

  Future<void> _submit() async {
    if (selectedAchievementId == null) return;

    setState(() { submitting = true; error = null; });

    try {
      await EcoClickAPI.postProgress(
        userId: widget.userId,
        achievementId: selectedAchievementId!,
        date: DateTime.now().toIso8601String(),
      );

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Progreso guardado exitosamente')),
      );
      Navigator.pop(context, true);
    } catch (e) {
      final msg = e.toString();
      if (msg.contains('409')) {
        showDialog(
          context: context,
          builder: (_) => AlertDialog(
            title: const Text('Ya registrado'),
            content: const Text('Este logro ya está registrado para este usuario.'),
            actions: [TextButton(onPressed: ()=>Navigator.pop(context), child: const Text('OK'))],
          ),
        );
      } else {
        setState(() => error = msg);
      }
    } finally {
      if (mounted) setState(() => submitting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Registrar progreso')),
      body: FutureBuilder<List<dynamic>>(
        future: futureAchievements,
        builder: (context, snap) {
          if (snap.connectionState != ConnectionState.done) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snap.hasError) {
            return Center(child: Text('Error: ${snap.error}'));
          }
          final items = snap.data ?? [];
          if (items.isEmpty) {
            return const Center(child: Text('No hay logros disponibles'));
          }
          return Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              children: [
                DropdownButtonFormField<int>(
                  decoration: const InputDecoration(labelText: 'Selecciona un logro'),
                  items: items.map((a) {
                    final m = a as Map<String, dynamic>;
                    return DropdownMenuItem<int>(
                      value: m['id'] as int,
                      child: Text('${m['name']} (${m['points']} pts)'),
                    );
                  }).toList(),
                  value: selectedAchievementId,
                  onChanged: (v) => setState(() => selectedAchievementId = v),
                ),
                const SizedBox(height: 16),
                FilledButton.icon(
                  onPressed: submitting ? null : _submit,
                  icon: const Icon(Icons.save),
                  label: Text(submitting ? 'Guardando...' : 'Guardar progreso'),
                ),
                if (error != null) ...[
                  const SizedBox(height: 12),
                  Text('Error: $error', style: const TextStyle(color: Colors.red)),
                ],
              ],
            ),
          );
        },
      ),
    );
  }
}
