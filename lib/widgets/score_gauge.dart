import 'dart:math';
import 'package:flutter/material.dart';

class ScoreGauge extends StatelessWidget {
  final int score;
  final int total;
  final double radius;

  const ScoreGauge({
    super.key,
    required this.score,
    required this.total,
    this.radius = 40.0,
  });

  @override
  Widget build(BuildContext context) {
    // On n'a pas besoin de rh ici car tout dépend du 'radius'
    final double percentage = total > 0 ? (max(0, score) / total) : 0.0;

    const Color lowScoreColor = Color(0xFFFF3B30);
    const Color midScoreColor = Color(0xFFFFCC00);
    const Color highScoreColor = Color(0xFF34C759);
    final Color progressColor = percentage < 0.5
        ? Color.lerp(lowScoreColor, midScoreColor, percentage * 2)!
        : Color.lerp(midScoreColor, highScoreColor, (percentage - 0.5) * 2)!;
    
    // On calcule l'épaisseur de l'anneau en fonction du rayon
    final double strokeWidth = radius * 0.15;

    return SizedBox(
      width: radius * 2,
      height: radius * 2,
      child: Stack(
        fit: StackFit.expand,
        children: [
          CircularProgressIndicator(
            value: 1.0,
            strokeWidth: strokeWidth, // On utilise la valeur proportionnelle
            backgroundColor: Colors.black.withOpacity(0.1),
            color: Colors.transparent,
          ),
          CircularProgressIndicator(
            value: percentage,
            strokeWidth: strokeWidth, // On utilise la valeur proportionnelle
            valueColor: AlwaysStoppedAnimation<Color>(progressColor),
            backgroundColor: Colors.transparent,
          ),
          Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  score.toString(),
                  style: TextStyle(
                    color: Colors.black87,
                    fontSize: radius * 0.5,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Text(
                  "Score",
                  style: TextStyle(
                    color: Colors.black54,
                    fontSize: radius * 0.25,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}