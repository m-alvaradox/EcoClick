import 'package:flutter/material.dart';

class QuizPage extends StatefulWidget {
  final Map<String, dynamic> quiz;
  const QuizPage({super.key, required this.quiz});

  @override
  State<QuizPage> createState() => _QuizPageState();
}

class _QuizPageState extends State<QuizPage> {
  late List<dynamic> questions;
  late List<int?> selectedOptions; // índice de opción seleccionada por pregunta
  bool submitted = false;
  int score = 0;

  @override
  void initState() {
    super.initState();
    questions = widget.quiz['questions'] as List<dynamic>;
    selectedOptions = List<int?>.filled(questions.length, null);
  }

  void _submit() {
    int totalScore = 0;
    for (int i = 0; i < questions.length; i++) {
      if (selectedOptions[i] == questions[i]['answerIndex']) {
        totalScore++;
      }
    }
    setState(() {
      score = totalScore;
      submitted = true;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(widget.quiz['title'])),
      body: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          children: [
            Expanded(
              child: ListView.separated(
                itemCount: questions.length,
                separatorBuilder: (_, __) => const SizedBox(height: 12),
                itemBuilder: (context, i) {
                  final q = questions[i];
                  return Card(
                    child: Padding(
                      padding: const EdgeInsets.all(12),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(q['text'], style: const TextStyle(fontWeight: FontWeight.bold)),
                          const SizedBox(height: 8),
                          ...List.generate(
                            (q['options'] as List).length,
                            (index) => RadioListTile<int>(
                              title: Text(q['options'][index]),
                              value: index,
                              groupValue: selectedOptions[i],
                              onChanged: submitted
                                  ? null
                                  : (val) => setState(() => selectedOptions[i] = val),
                            ),
                          ),
                          if (submitted)
                            Padding(
                              padding: const EdgeInsets.only(top: 4),
                              child: Text(
                                'Respuesta correcta: ${(q['options'] as List)[q['answerIndex']]}',
                                style: const TextStyle(color: Colors.green),
                              ),
                            ),
                        ],
                      ),
                    ),
                  );
                },
              ),
            ),
            ElevatedButton(
              onPressed: submitted ? null : _submit,
              child: Text(submitted ? 'Quiz enviado' : 'Enviar respuestas'),
            ),
            if (submitted)
              Padding(
                padding: const EdgeInsets.only(top: 12),
                child: Text(
                  'Puntaje: $score / ${questions.length}',
                  style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
              ),
          ],
        ),
      ),
    );
  }
}
