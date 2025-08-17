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

    setState(() {
      submitting = true;
      error = null;
    });

    try {
      await EcoClickAPI.postProgress(
        userId: widget.userId,
        achievementId: selectedAchievementId!,
        date: DateTime.now().toIso8601String(),
      );

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Progreso guardado exitosamente'),
          backgroundColor: Colors.green,
        ),
      );

      // Regresamos true para indicar que se agregó un logro
      Navigator.pop(context, true);
    } catch (e) {
      final msg = e.toString();
      if (msg.contains('Progreso ya registrado')) {
        // Mostrar advertencia de registro duplicado
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Este logro ya ha sido registrado'),
            backgroundColor: Colors.orange,
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
                  decoration: const InputDecoration(
                    labelText: 'Selecciona un logro',
                  ),
                  items: items.map((a) {
                    final map = a as Map<String, dynamic>;
                    return DropdownMenuItem<int>(
                      value: map['id'] as int,
                      child: Text(map['name'] ?? ''),
                    );
                  }).toList(),
                  value: selectedAchievementId,
                  onChanged: (val) => setState(() => selectedAchievementId = val),
                ),
                const SizedBox(height: 16),
                ElevatedButton.icon(
                  onPressed: submitting ? null : _submit,
                  icon: const Icon(Icons.save),
                  label: Text(submitting ? 'Guardando...' : 'Guardar progreso'),
                ),
                if (error != null) ...[
                  const SizedBox(height: 12),
                  Text('Error: $error', style: const TextStyle(color: Colors.red)),
                ]
              ],
            ),
          );
        },
      ),
    );
  }
}
