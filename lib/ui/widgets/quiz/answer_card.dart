import 'package:flutter/material.dart';

class AnswerCard extends StatefulWidget {
  final String answer;
  final int index;
  final VoidCallback? onTap; // Ajout du callback pour le clic

  const AnswerCard({
    super.key, 
    required this.answer, 
    required this.index,
    this.onTap, // Ajout au constructeur
  });

  @override
  State<AnswerCard> createState() => _AnswerCardState();
}

class _AnswerCardState extends State<AnswerCard> {
  bool _isHovered = false;

  @override
  Widget build(BuildContext context) {
    // On enveloppe tout dans un GestureDetector pour gérer le clic
    return GestureDetector(
      onTap: widget.onTap,
      child: MouseRegion(
        onEnter: (_) => setState(() => _isHovered = true),
        onExit: (_) => setState(() => _isHovered = false),
        cursor: SystemMouseCursors.click,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          decoration: BoxDecoration(
            // Utilisation de .withValues pour Flutter 3.27+
            color: _isHovered ? Colors.blueAccent : Colors.white,
            borderRadius: BorderRadius.circular(16),
            boxShadow: [
              BoxShadow(
                color: _isHovered ? Colors.blue.withValues(alpha: 0.3) : Colors.black12,
                blurRadius: _isHovered ? 12 : 4,
                offset: const Offset(0, 4),
              )
            ],
            border: Border.all(
              color: _isHovered ? Colors.blueAccent : Colors.grey.shade300,
              width: 2,
            ),
          ),
          child: Center(
            child: Padding(
              padding: const EdgeInsets.all(8.0),
              child: Text(
                // Si c'est un thème (index -1 ou autre logique), on n'affiche pas de numéro, 
                // sinon on affiche "1. Réponse". Ici je garde la logique générique.
                "${widget.index + 1}. ${widget.answer}",
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w600,
                  color: _isHovered ? Colors.white : Colors.black87,
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}