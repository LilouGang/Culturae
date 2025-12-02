import 'package:flutter/material.dart';
import '../widgets/quiz/answer_card.dart';

class DesktopQuizView extends StatelessWidget {
  // Ici, tu injecterais tes données depuis ton DataManager
  final String questionText = "Quel est le framework utilisé pour cette interface ?";
  final List<String> answers = ["React", "Vue", "Flutter", "Angular"];

  DesktopQuizView({super.key});

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Indicateur de progression
        LinearProgressIndicator(value: 0.4, minHeight: 8, borderRadius: BorderRadius.circular(4)),
        const SizedBox(height: 40),

        // La Question (Grande et lisible)
        Text(
          questionText,
          style: Theme.of(context).textTheme.headlineMedium?.copyWith(
            fontWeight: FontWeight.bold,
            color: Colors.black87,
          ),
        ),
        const SizedBox(height: 60),

        // La Grille de Réponses
        Expanded(
          child: GridView.builder(
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 2, // 2 Colonnes
              childAspectRatio: 3.5, // Format rectangulaire large
              crossAxisSpacing: 20,
              mainAxisSpacing: 20,
            ),
            itemCount: answers.length,
            itemBuilder: (context, index) {
              return AnswerCard(answer: answers[index], index: index);
            },
          ),
        ),
      ],
    );
  }
}