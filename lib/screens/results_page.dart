// lib/screens/results_page.dart

import 'package:flutter/material.dart';
import '../widgets/page_layout.dart';

class ResultsPage extends StatelessWidget {
  final int score;
  final int totalQuestions;

  const ResultsPage({
    super.key,
    required this.score,
    required this.totalQuestions,
  });

  @override
  Widget build(BuildContext context) {
    final double percentage = totalQuestions > 0 ? (score / totalQuestions) * 100 : 0;
    
    String getResultMessage() {
      if (percentage >= 90) return "Excellent !";
      if (percentage >= 70) return "Très bien !";
      if (percentage >= 50) return "Pas mal !";
      return "Continue tes efforts !";
    }

    return PageLayout(
      title: 'Résultats',
      child: Center(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                getResultMessage(),
                textAlign: TextAlign.center,
                style: const TextStyle(fontSize: 28, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 20),
              Text(
                'Votre score',
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 18, color: Colors.grey.shade600),
              ),
              Text(
                '$score / $totalQuestions',
                textAlign: TextAlign.center,
                style: const TextStyle(fontSize: 60, fontWeight: FontWeight.bold),
              ),
              Text(
                '(${percentage.toStringAsFixed(1)}%)',
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 20, color: Colors.grey.shade700),
              ),
              const SizedBox(height: 40),
              ElevatedButton(
                onPressed: () {
                  int count = 0;
                  Navigator.popUntil(context, (route) {
                    return count++ == 2;
                  });
                },
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 16),
                ),
                child: const Text('Rejouer un autre quiz', style: TextStyle(fontSize: 16)),
              ),
            ],
          ),
        ),
      ),
    );
  }
}