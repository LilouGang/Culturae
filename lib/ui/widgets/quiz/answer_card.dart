import 'package:flutter/material.dart';

class AnswerCard extends StatefulWidget {
  final String answer;
  final int index;

  const AnswerCard({super.key, required this.answer, required this.index});

  @override
  State<AnswerCard> createState() => _AnswerCardState();
}

class _AnswerCardState extends State<AnswerCard> {
  bool _isHovered = false;

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      onEnter: (_) => setState(() => _isHovered = true),
      onExit: (_) => setState(() => _isHovered = false),
      cursor: SystemMouseCursors.click,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        decoration: BoxDecoration(
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
          child: Text(
            "${widget.index + 1}. ${widget.answer}",
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w600,
              color: _isHovered ? Colors.white : Colors.black87,
            ),
          ),
        ),
      ),
    );
  }
}